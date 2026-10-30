/// Supported deployment environments for PropCare Governance.
enum AppEnvironment { stage, live }

/// Central application and environment configuration.
///
/// Switch environments by:
/// 1. Changing [currentEnvironment] here (e.g. `AppEnvironment.live` or `AppEnvironment.stage`).
/// 2. Or passing `--dart-define=ENV=live` during `flutter run` / `flutter build`.
/// 3. Or programmatically via [setEnvironment].
class AppConfig {
  AppConfig._();

  /// The active environment. Defaults to Stage (or compile-time `--dart-define=ENV=live`).
  static AppEnvironment currentEnvironment = _resolveDefaultEnvironment();

  /// Stage / Testing root URL
  static const String stageUrl = 'https://stagegovernance.digilogy.dev';

  /// Live / Production root URL
  static const String liveUrl = 'https://governance.digilogy.dev';

  /// Backend API path prefix
  static const String apiPrefix = '/api';

  /// Returns the base API URL for the currently active environment.
  static String get baseUrl {
    switch (currentEnvironment) {
      case AppEnvironment.live:
        return '$liveUrl$apiPrefix';
      case AppEnvironment.stage:
        return '$stageUrl$apiPrefix';
    }
  }

  /// Returns the root domain for the active environment.
  static String get rootUrl {
    switch (currentEnvironment) {
      case AppEnvironment.live:
        return liveUrl;
      case AppEnvironment.stage:
        return stageUrl;
    }
  }

  /// Human-readable label of the active environment.
  static String get environmentName {
    switch (currentEnvironment) {
      case AppEnvironment.live:
        return 'Live / Production';
      case AppEnvironment.stage:
        return 'Stage / UAT';
    }
  }

  /// Helper to check if currently on Live.
  static bool get isLive => currentEnvironment == AppEnvironment.live;

  /// Helper to check if currently on Stage.
  static bool get isStage => currentEnvironment == AppEnvironment.stage;

  /// Programmatically switch the environment.
  static void setEnvironment(AppEnvironment env) {
    currentEnvironment = env;
  }

  /// Resolves the default environment from compile-time `--dart-define=ENV=live|stage`.
  static AppEnvironment _resolveDefaultEnvironment() {
    const envArg = String.fromEnvironment('ENV', defaultValue: 'stage');
    if (envArg.toLowerCase() == 'live' || envArg.toLowerCase() == 'prod') {
      return AppEnvironment.live;
    }
    return AppEnvironment.stage;
  }
}
