import 'package:dartz/dartz.dart';

import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/storage/hive_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Persist session cookie
      if (user.sessionCookie != null && user.sessionCookie!.isNotEmpty) {
        await HiveStorage.saveSessionCookie(user.sessionCookie!);
      }

      // Persist CSRF token
      if (user.csrfToken != null && user.csrfToken!.isNotEmpty) {
        await HiveStorage.saveCsrfToken(user.csrfToken!);
      }

      // Persist user profile details
      await HiveStorage.saveUserProfile(user.toJson());

      // Persist auth token
      final token = user.token ?? user.sessionCookie ?? '';
      await HiveStorage.saveAuthToken(token);

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      await HiveStorage.clearAuth();
    }
    return const Right(null);
  }
}
