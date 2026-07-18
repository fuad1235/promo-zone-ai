import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'app_config.dart';
import 'session_storage.dart';

class StorageService {
  const StorageService(this._http);

  final http.Client _http;

  Future<String> uploadFile({
    required String path,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    if (!AppConfig.isLaravelApiConfigured) {
      throw StateError(
        'Missing LARAVEL_API_BASE_URL. Pass --dart-define=LARAVEL_API_BASE_URL=https://your-api',
      );
    }

    final token = await SessionStorage.readToken();
    if (token == null || token.isEmpty) {
      throw StateError('Missing auth token. Please login again.');
    }

    final uri = Uri.parse('${AppConfig.laravelApiBaseUrl}/api/uploads');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['folder'] = _folderFromPath(path)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    onProgress?.call(0.2);
    final streamed = await _http.send(req);
    onProgress?.call(0.8);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final details = _extractErrorMessage(response.body, response.statusCode);
      throw StateError('Upload failed (${response.statusCode}): $details');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic> || payload['url'] == null) {
      throw StateError('Invalid upload response');
    }

    onProgress?.call(1.0);
    return payload['url'].toString();
  }

  String _folderFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    if (parts.length <= 1) return 'uploads';
    return parts.sublist(0, parts.length - 1).join('/');
  }

  String _extractErrorMessage(String body, int statusCode) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic>) {
        final message = payload['message']?.toString();
        final errors = payload['errors'];
        if (errors is Map) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) {
              return '${message ?? 'Validation failed'}: ${value.first}';
            }
            if (value is String && value.isNotEmpty) {
              return '${message ?? 'Validation failed'}: $value';
            }
          }
        }
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Ignore parse failure and continue with plain-text fallback.
    }

    final plain = body.trim();
    if (plain.isNotEmpty) {
      final compact = plain.replaceAll(RegExp(r'\s+'), ' ');
      return compact.length > 220 ? '${compact.substring(0, 220)}...' : compact;
    }

    if (statusCode == 422) {
      return 'Validation failed. Check file type/size and try a smaller file.';
    }
    if (statusCode == 401) {
      return 'Session expired. Please login again.';
    }
    return 'Request failed';
  }
}
