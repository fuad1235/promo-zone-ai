class AppConfig {
  const AppConfig._();

  static const String laravelApiBaseUrl = String.fromEnvironment(
    'LARAVEL_API_BASE_URL',
    defaultValue: '',
  );

  static const int apiTimeoutMs = int.fromEnvironment(
    'API_TIMEOUT_MS',
    defaultValue: 12000,
  );

  static const int apiRetryCount = int.fromEnvironment(
    'API_RETRY_COUNT',
    defaultValue: 2,
  );

  static const bool apiRetryNonIdempotent = bool.fromEnvironment(
    'API_RETRY_NON_IDEMPOTENT',
    defaultValue: false,
  );

  static const bool enableVerboseApiLogs = bool.fromEnvironment(
    'ENABLE_VERBOSE_API_LOGS',
    defaultValue: false,
  );

  static bool get isLaravelApiConfigured => laravelApiBaseUrl.isNotEmpty;
}
