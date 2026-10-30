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
