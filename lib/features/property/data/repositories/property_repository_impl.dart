import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/property_data_source.dart';

/// Concrete implementation of [PropertyRepository].
class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyRemoteDataSource remoteDataSource;
  final PropertyLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  PropertyRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<PropertyEntity>>> getProperties() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProperties = await remoteDataSource.getProperties();
        await localDataSource.cacheProperties(remoteProperties);
        return Right(remoteProperties.cast<PropertyEntity>());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final localProperties = await localDataSource.getCachedProperties();
        return Right(localProperties.cast<PropertyEntity>());
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, PropertyEntity>> getPropertyById(String id) async {
    try {
      final property = await remoteDataSource.getPropertyById(id);
      return Right(property);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
