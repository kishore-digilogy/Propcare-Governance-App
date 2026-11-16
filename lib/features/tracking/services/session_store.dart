import '../../../../core/storage/hive_storage.dart';

class SessionStore {
  static const String _authKey = 'propcare.auth.employeeId';
  static const String _onboardingKey = 'propcare.onboarding.seen';
  static const String _demoKey = 'propcare.demo.mode';

  static final Map<String, dynamic> _fallbackMemoryStore = {};

  Future<String?> employeeId() async {
    try {
      final val = HiveStorage.getString(_authKey);
      if (val != null) return val;
    } catch (_) {}
    return _fallbackMemoryStore[_authKey] as String?;
  }

  Future<void> saveEmployeeId(String id) async {
    _fallbackMemoryStore[_authKey] = id;
    try {
      await HiveStorage.put(_authKey, id);
    } catch (_) {}
  }

  Future<void> clearEmployeeId() async {
    _fallbackMemoryStore.remove(_authKey);
    try {
      await HiveStorage.delete(_authKey);
    } catch (_) {}
  }

  Future<bool> onboardingSeen() async {
    try {
      return HiveStorage.getBool(_onboardingKey, defaultValue: false);
    } catch (_) {
      return _fallbackMemoryStore[_onboardingKey] as bool? ?? false;
    }
  }

  Future<void> markOnboardingSeen() async {
    _fallbackMemoryStore[_onboardingKey] = true;
    try {
      await HiveStorage.put(_onboardingKey, true);
    } catch (_) {}
  }

  Future<bool> demoMode() async {
    try {
      return HiveStorage.getBool(_demoKey, defaultValue: true);
    } catch (_) {
      return _fallbackMemoryStore[_demoKey] as bool? ?? true;
    }
  }

  Future<void> setDemoMode(bool value) async {
    _fallbackMemoryStore[_demoKey] = value;
    try {
      await HiveStorage.put(_demoKey, value);
    } catch (_) {}
  }
}
