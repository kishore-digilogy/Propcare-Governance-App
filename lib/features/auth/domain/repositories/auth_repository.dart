import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Auth repository contract.
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> logout();
}
