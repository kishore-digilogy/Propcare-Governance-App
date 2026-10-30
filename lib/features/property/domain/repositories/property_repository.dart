import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/property_entity.dart';

/// Abstract contract for the property repository.
/// Implemented in the data layer.
abstract class PropertyRepository {
  /// Fetches all properties for the current user.
  Future<Either<Failure, List<PropertyEntity>>> getProperties();

  /// Fetches a single property by [id].
  Future<Either<Failure, PropertyEntity>> getPropertyById(String id);
}
