/// Keys used for Hive box and field storage.
class StorageKeys {
  StorageKeys._();

  // Box names
  static const String appBox = 'app_box';

  // Auth & Session
  static const String authToken = 'auth_token';
  static const String sessionCookie = 'session_cookie';
  static const String csrfToken = 'csrf_token';
  static const String userProfile = 'user_profile';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userRole = 'user_role';

  // App flags & history
  static const String isOnboardingSeen = 'is_onboarding_seen';
  static const String recentEmails = 'recent_emails';
}
