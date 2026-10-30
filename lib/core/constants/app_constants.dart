import '../config/app_config.dart';

/// App-wide constants for propcare_governance.
class AppConstants {
  AppConstants._();

  static const String appName = 'PropCare Governance';
  static const String appVersion = '1.0.0';

  /// Currently active environment configuration.
  static String get baseUrl => AppConfig.baseUrl;
  static String get environmentName => AppConfig.environmentName;
}
