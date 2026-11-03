import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propcare_governance/core/models/admin_user_model.dart';
import 'package:propcare_governance/core/services/user_service.dart';
import 'package:propcare_governance/core/storage/hive_storage.dart';

void main() {
  const sampleJson = {
    'items': [
      {
        'id': '63aa5647-0361-456d-af4a-636eae6a8974',
        'name': 'Abhimanyu',
        'email': 'abhimanyu.p@casagrandepropcare.com',
        'role': 'CLUSTER_LEAD',
        'scope': {
          'siteIds': <String>[],
          'zoneIds': ['a0e0a52d-6a51-4f40-9306-944e0581190a'],
          'groupIds': <String>[],
          'clusterIds': ['10142d83-e98a-4dfa-8edc-403dda223ba1']
        },
        'active': true,
        'mustChangePassword': true,
        'createdAt': '2026-10-30T04:02:56.278Z',
        'updatedAt': '2026-10-30T04:02:56.278Z'
      },
      {
        'id': '9247021a-b3c0-4f9c-b3f3-c86f52fdd8e6',
        'name': 'Aijth',
        'email': 'aijth.ops@import.casagrandepropcare.com',
        'role': 'FIELD_EXECUTIVE',
        'scope': {
          'siteIds': <String>[],
          'zoneIds': ['acb37f64-ea4e-4555-ad41-64a795b7ade7'],
          'groupIds': <String>[],
          'clusterIds': ['5bb7044a-6f7b-4c37-8832-06f3ea6ff365']
        },
        'active': true,
        'mustChangePassword': true,
        'createdAt': '2026-10-30T04:02:56.270Z',
        'updatedAt': '2026-10-30T04:02:56.270Z'
      }
    ],
    'total': 81
  };

  group('AdminUserModel & AdminUsersResponseModel Tests', () {
    test('parses AdminUsersResponseModel correctly', () {
      final response = AdminUsersResponseModel.fromJson(sampleJson);
      expect(response.total, 81);
      expect(response.items.length, 2);

      final user1 = response.items.first;
      expect(user1.id, '63aa5647-0361-456d-af4a-636eae6a8974');
      expect(user1.name, 'Abhimanyu');
      expect(user1.email, 'abhimanyu.p@casagrandepropcare.com');
      expect(user1.role, 'CLUSTER_LEAD');
      expect(user1.roleLabel, 'Cluster Lead');
      expect(user1.displayWithRole, 'Abhimanyu · Cluster Lead');
      expect(user1.initials, 'A');
      expect(user1.active, isTrue);
      expect(user1.mustChangePassword, isTrue);
      expect(user1.createdAt, DateTime.parse('2026-10-30T04:02:56.278Z'));

      expect(user1.scope.zoneIds, ['a0e0a52d-6a51-4f40-9306-944e0581190a']);
      expect(user1.scope.clusterIds, ['10142d83-e98a-4dfa-8edc-403dda223ba1']);
      expect(user1.hasZoneAccess('a0e0a52d-6a51-4f40-9306-944e0581190a'), isTrue);
      expect(user1.hasZoneAccess('other-zone'), isFalse);
    });

    test('serializes to and from JSON symmetrically', () {
      final itemsList = sampleJson['items'] as List<dynamic>;
      final model = AdminUserModel.fromJson(itemsList[0] as Map<String, dynamic>);
      final json = model.toJson();
      final roundTrip = AdminUserModel.fromJson(json);
      expect(roundTrip, model);
    });
  });

  group('UserService Tests', () {
    late Dio mockDio;

    setUp(() {
      mockDio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/admin/users') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: sampleJson,
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );
      UserService.instance.setMockDio(mockDio);
    });

    tearDown(() {
      UserService.instance.resetMockDio();
    });

    test('getAdminUsers fetches and caches users', () async {
      final res = await UserService.instance.getAdminUsers(forceRefresh: true);
      expect(res.total, 81);
      expect(res.items.length, 2);

      // Verify cached helpers
      expect(UserService.instance.users.length, 2);
      expect(UserService.instance.total, 81);
      expect(UserService.instance.isLoaded, isTrue);

      final user = UserService.instance.getUserById('63aa5647-0361-456d-af4a-636eae6a8974');
      expect(user?.name, 'Abhimanyu');

      final fieldExecs = UserService.instance.getUsersByRole('FIELD_EXECUTIVE');
      expect(fieldExecs.length, 1);
      expect(fieldExecs.first.name, 'Aijth');

      final searchResult = UserService.instance.searchUsers('aijth');
      expect(searchResult.length, 1);
      expect(searchResult.first.email, contains('aijth.ops'));
    });
  });

  group('HiveStorage L&D Role Tests', () {
    tearDown(() {
      HiveStorage.mockUserRole = null;
    });

    test('isLdRole correctly identifies LD roles and avoids false matches like FIELD_EXECUTIVE', () {
      // Test LD_HEAD
      HiveStorage.mockUserRole = 'LD_HEAD';
      expect(HiveStorage.isLdRole, isTrue);
      expect(HiveStorage.displayRole, 'L&D Head');

      // Test LD_LEAD
      HiveStorage.mockUserRole = 'LD_LEAD';
      expect(HiveStorage.isLdRole, isTrue);
      expect(HiveStorage.displayRole, 'L&D Lead');

      // Test L&D
      HiveStorage.mockUserRole = 'L&D';
      expect(HiveStorage.isLdRole, isTrue);
      expect(HiveStorage.displayRole, 'L&D');

      // Test FIELD_EXECUTIVE (must NOT be treated as LD role despite containing 'ld')
      HiveStorage.mockUserRole = 'FIELD_EXECUTIVE';
      expect(HiveStorage.isLdRole, isFalse);
      expect(HiveStorage.displayRole, 'FIELD_EXECUTIVE');

      // Test CRRM
      HiveStorage.mockUserRole = 'CRRM';
      expect(HiveStorage.isLdRole, isFalse);
      expect(HiveStorage.displayRole, 'CRRM / Super Admin');
    });
  });
}
