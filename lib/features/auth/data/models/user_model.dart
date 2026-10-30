import '../../domain/entities/user_entity.dart';

/// Auth data model with robust JSON serialization for PropCare Governance.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.role = '',
    super.scope = const {},
    super.active = true,
    super.mustChangePassword = false,
    super.token,
    super.csrfToken,
    super.sessionCookie,
    super.createdAt,
    super.updatedAt,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String? sessionCookie,
  }) {
    // Backend returns `{ user: { id, name, email, role, ... }, csrfToken: "..." }`
    final userData = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    final scopeData = userData['scope'] is Map<String, dynamic>
        ? userData['scope'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return UserModel(
      id: (userData['id'] ?? userData['_id'] ?? '').toString(),
      name: (userData['name'] ??
              userData['fullName'] ??
              userData['email'] ??
              'PropCare User')
          .toString(),
      email: (userData['email'] ?? '').toString(),
      role: (userData['role'] ?? '').toString(),
      scope: scopeData,
      active: userData['active'] as bool? ?? true,
      mustChangePassword: userData['mustChangePassword'] as bool? ?? false,
      token: (json['token'] ??
              json['accessToken'] ??
              userData['token'] ??
              sessionCookie ??
              '')
          .toString(),
      csrfToken: (json['csrfToken'] ?? userData['csrfToken'])?.toString(),
      sessionCookie: sessionCookie ??
          (json['sessionCookie'] ?? userData['sessionCookie'])?.toString(),
      createdAt: userData['createdAt']?.toString(),
      updatedAt: userData['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'scope': scope,
        'active': active,
        'mustChangePassword': mustChangePassword,
        'token': token,
        'csrfToken': csrfToken,
        'sessionCookie': sessionCookie,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
