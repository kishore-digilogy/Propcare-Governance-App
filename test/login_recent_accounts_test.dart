import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:propcare_governance/core/storage/hive_storage.dart';
import 'package:propcare_governance/core/storage/storage_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('hive_test_');

  setUpAll(() async {
    Hive.init(tempDir.path);
    final box = await Hive.openBox(StorageKeys.appBox);
    HiveStorage.box = box;
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await HiveStorage.clearRecentEmails();
  });

  test('HiveStorage.saveRecentEmail saves email and removes specific mistyped ones', () async {
    expect(HiveStorage.recentEmails, isEmpty);

    // Save initial successful login
    await HiveStorage.saveRecentEmail('admin@casagrandepropcare.com');
    expect(HiveStorage.recentEmails, ['admin@casagrandepropcare.com']);

    // Save a mistyped email
    await HiveStorage.saveRecentEmail('admin@casagarndepropcare.com');
    expect(HiveStorage.recentEmails, [
      'admin@casagarndepropcare.com',
      'admin@casagrandepropcare.com',
    ]);

    // Remove the mistyped email
    await HiveStorage.removeRecentEmail('admin@casagarndepropcare.com');
    expect(HiveStorage.recentEmails, ['admin@casagrandepropcare.com']);

    // Clear all
    await HiveStorage.clearRecentEmails();
    expect(HiveStorage.recentEmails, isEmpty);
  });
}
