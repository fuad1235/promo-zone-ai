import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';
import 'session_storage.dart';

class ApiClient {
  ApiClient(this._http);

  final http.Client _http;

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool authenticated = true,
  }) async {
    final response = await _request('GET', path, authenticated: authenticated);
    return _decodeMap(response.body);
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    bool authenticated = true,
  }) async {
    final response = await _request('GET', path, authenticated: authenticated);
    final payload = jsonDecode(response.body);
    if (payload is List<dynamic>) return payload;
    if (payload is Map<String, dynamic> && payload['data'] is List<dynamic>) {
      return payload['data'] as List<dynamic>;
    }
    return const [];
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final response = await _request(
      'POST',
      path,
      body: body,
      authenticated: authenticated,
    );
    if (response.body.isEmpty) return <String, dynamic>{};
    return _decodeMap(response.body);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final response = await _request(
      'PUT',
      path,
      body: body,
      authenticated: authenticated,
    );
    if (response.body.isEmpty) return <String, dynamic>{};
    return _decodeMap(response.body);
  }

  Future<void> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    await _request('POST', path, body: body, authenticated: authenticated);
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    if (!AppConfig.isLaravelApiConfigured) {
      throw StateError(
        'Missing LARAVEL_API_BASE_URL. Pass --dart-define=LARAVEL_API_BASE_URL=https://your-api',
      );
    }

    final uri = Uri.parse('${AppConfig.laravelApiBaseUrl}$path');
    if (kReleaseMode && uri.scheme != 'https') {
      throw const ApiException(
        'In release builds the API URL must use HTTPS.',
      );
    }
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await SessionStorage.readToken();
      if (token == null || token.isEmpty) {
        throw StateError('Missing auth token. Please login again.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    if (_requiresIdempotencyKey(method, authenticated)) {
      headers['Idempotency-Key'] = _generateIdempotencyKey(method, path, body);
    }

    _logRequest(method, uri, body);
    final response = await _withRetry(
      method: method,
      path: path,
      uri: uri,
      task: () async {
        final future = switch (method) {
          'GET' => _http.get(uri, headers: headers),
          'POST' => _http.post(
              uri,
              headers: headers,
              body: jsonEncode(body ?? <String, dynamic>{}),
            ),
          'PUT' => _http.put(
              uri,
              headers: headers,
              body: jsonEncode(body ?? <String, dynamic>{}),
            ),
          _ => throw UnsupportedError('Unsupported HTTP method: $method'),
        };
        return future.timeout(Duration(milliseconds: AppConfig.apiTimeoutMs));
      },
    );
    _logResponse(method, uri, response.statusCode);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final message = _extractApiErrorMessage(payload);
      if (response.statusCode == 401) {
        await SessionStorage.clear();
        throw ApiException(
          'Session expired. Please login again.',
        );
      }
      throw ApiException(message);
    } on ApiException {
      rethrow;
    } catch (_) {
      if (response.statusCode == 401) {
        await SessionStorage.clear();
        throw const ApiException('Session expired. Please login again.');
      }
      throw ApiException('Request failed (${response.statusCode})');
    }
  }

  String _extractApiErrorMessage(Map<String, dynamic> payload) {
    final message = payload['message']?.toString();
    final errors = payload['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first?.toString();
          if (first != null && first.isNotEmpty) {
            return first;
          }
        }
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return 'Validation failed';
    }
    if (message != null && message.isNotEmpty) return message;
    return 'Request failed';
  }

  Future<http.Response> _withRetry({
    required String method,
    required String path,
    required Uri uri,
    required Future<http.Response> Function() task,
  }) async {
    final maxAttempts =
        _isMethodRetryable(method) ? AppConfig.apiRetryCount + 1 : 1;
    var attempt = 0;
    while (true) {
      attempt += 1;
      try {
        return await task();
      } on TimeoutException catch (e) {
        if (attempt >= maxAttempts) {
          throw ApiException(
            'Request timed out. Please try again. [$path]',
            cause: e,
          );
        }
      } on SocketException catch (e) {
        if (attempt >= maxAttempts) {
          throw ApiException(
            _socketFailureMessage(uri),
            cause: e,
          );
        }
      } on http.ClientException catch (e) {
        if (attempt >= maxAttempts) {
          throw ApiException('Network request failed. Please retry.', cause: e);
        }
      }

      await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
    }
  }

  bool _isMethodRetryable(String method) {
    if (method == 'GET') return true;
    return AppConfig.apiRetryNonIdempotent;
  }

  bool _requiresIdempotencyKey(String method, bool authenticated) {
    if (!authenticated) return false;
    return method == 'POST' || method == 'PUT';
  }

  String _generateIdempotencyKey(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final entropy = Random.secure().nextInt(1 << 32);
    final payload = jsonEncode(body ?? const <String, dynamic>{});
    final payloadHash = payload.hashCode.toUnsigned(32);
    return '$method-$path-$now-$entropy-$payloadHash';
  }

  String _socketFailureMessage(Uri uri) {
    final host = uri.host.toLowerCase();
    if (Platform.isAndroid && (host == '127.0.0.1' || host == 'localhost')) {
      return 'Cannot reach API at $uri from Android device. '
          'If this is a real phone, run: adb reverse tcp:8000 tcp:8000 '
          'or use your laptop LAN IP in LARAVEL_API_BASE_URL.';
    }
    return 'Cannot reach API at $uri. '
        'Check backend server, Wi-Fi/LAN path, and firewall.';
  }

  void _logRequest(String method, Uri uri, Map<String, dynamic>? body) {
    if (!AppConfig.enableVerboseApiLogs) return;
    developer.log(
      'api_request',
      name: 'promozone.api',
      error: {
        'method': method,
        'path': uri.path,
        'query': uri.query,
        'body': _redactMap(body),
      },
    );
  }

  void _logResponse(String method, Uri uri, int statusCode) {
    if (!AppConfig.enableVerboseApiLogs) return;
    developer.log(
      'api_response',
      name: 'promozone.api',
      error: {
        'method': method,
        'path': uri.path,
        'statusCode': statusCode,
      },
    );
  }

  Map<String, dynamic>? _redactMap(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final redacted = <String, dynamic>{};
    for (final entry in raw.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('password') ||
          key.contains('token') ||
          key.contains('authorization') ||
          key.contains('number')) {
        redacted[entry.key] = '***';
      } else {
        redacted[entry.key] = entry.value;
      }
    }
    return redacted;
  }

  Map<String, dynamic> _decodeMap(String source) {
    try {
      final payload = jsonDecode(source);
      if (payload is Map<String, dynamic>) return payload;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
