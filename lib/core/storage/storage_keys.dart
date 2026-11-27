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

  // Continuous Location Tracking
  static const String activeTrackingActivityId = 'active_tracking_activity_id';
  static const String activeTrackingSiteName = 'active_tracking_site_name';
  static const String activeTrackingStartTime = 'active_tracking_start_time';
  static const String activeTrackingLastPingTime = 'active_tracking_last_ping_time';
  static const String activeTrackingLastLat = 'active_tracking_last_lat';
  static const String activeTrackingLastLng = 'active_tracking_last_lng';
  static const String activeTrackingPingCount = 'active_tracking_ping_count';
}
