import 'dart:developer' as developer;

class ActionTelemetryService {
  Future<T> run<T>({
    required String action,
    required Future<T> Function() task,
    Map<String, Object?> meta = const {},
  }) async {
    final start = DateTime.now();
    developer.log(
      'action_start',
      name: 'promozone.telemetry',
      error: {'action': action, 'meta': meta},
    );
    try {
      final result = await task();
      final durationMs = DateTime.now().difference(start).inMilliseconds;
      developer.log(
        'action_success',
        name: 'promozone.telemetry',
        error: {'action': action, 'meta': meta, 'durationMs': durationMs},
      );
      return result;
    } catch (error, stack) {
      final durationMs = DateTime.now().difference(start).inMilliseconds;
      developer.log(
        'action_failure',
        name: 'promozone.telemetry',
        error: {
          'action': action,
          'meta': meta,
          'durationMs': durationMs,
          'error': error.toString(),
        },
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
