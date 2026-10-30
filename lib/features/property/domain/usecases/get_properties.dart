import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/property_entity.dart';
import '../repositories/property_repository.dart';

/// Use case: retrieve the full list of properties.
class GetProperties extends UseCase<List<PropertyEntity>, NoParams> {
  final PropertyRepository repository;

  GetProperties(this.repository);

  @override
  Future<Either<Failure, List<PropertyEntity>>> call(NoParams params) {
    return repository.getProperties();
  }
}
