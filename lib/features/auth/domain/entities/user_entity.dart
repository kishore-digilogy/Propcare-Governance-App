import 'package:equatable/equatable.dart';

/// Domain entity representing an authenticated PropCare user.
class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final Map<String, dynamic> scope;
  final bool active;
  final bool mustChangePassword;
  final String? token;
  final String? csrfToken;
  final String? sessionCookie;
  final String? createdAt;
  final String? updatedAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.role = '',
    this.scope = const {},
    this.active = true,
    this.mustChangePassword = false,
    this.token,
    this.csrfToken,
    this.sessionCookie,
    this.createdAt,
    this.updatedAt,
  });

  /// Formatted role string. CRRM is treated as equal to Super Admin.
  String get roleDisplay {
    final upper = role.trim().toUpperCase();
    if (upper == 'CRRM' ||
        upper == 'SUPER_ADMIN' ||
        upper == 'SUPERADMIN' ||
        upper == 'ADMIN') {
      return 'CRRM / Super Admin';
    }
    return role;
  }

  /// Whether user has Super Admin level access (CRRM / Super Admin).
  bool get isSuperAdmin {
    final upper = role.trim().toUpperCase();
    return upper == 'CRRM' ||
        upper == 'SUPER_ADMIN' ||
        upper == 'SUPERADMIN' ||
        upper == 'ADMIN' ||
        upper.contains('CRRM') ||
        upper.contains('SUPER');
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        scope,
        active,
        mustChangePassword,
        token,
        csrfToken,
        sessionCookie,
        createdAt,
        updatedAt,
      ];
}
