import 'package:dartz/dartz.dart';

import '../errors/failures.dart';

/// Base interface for all use cases.
///
/// [T] — the return type on success.
/// [Params] — parameters required by the use case.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use this when a use case requires no parameters.
class NoParams {
  const NoParams();
}
