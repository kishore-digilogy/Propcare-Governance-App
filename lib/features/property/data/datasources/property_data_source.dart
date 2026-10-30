import '../../../../core/errors/exceptions.dart';
import '../models/property_model.dart';

/// Contract for remote data operations.
abstract class PropertyRemoteDataSource {
  Future<List<PropertyModel>> getProperties();
  Future<PropertyModel> getPropertyById(String id);
}

/// Contract for local/cache data operations.
abstract class PropertyLocalDataSource {
  Future<List<PropertyModel>> getCachedProperties();
  Future<void> cacheProperties(List<PropertyModel> properties);
}

// ─────────────────────────────────────────────────────────────────
//  Implementations (wire up your HTTP client / local DB here)
// ─────────────────────────────────────────────────────────────────

class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  // inject Dio / http client here
  // final Dio dio;
  // PropertyRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<PropertyModel>> getProperties() async {
    // TODO: replace with real HTTP call
    // final response = await dio.get('/properties');
    // return (response.data as List).map(PropertyModel.fromJson).toList();
    throw const ServerException(message: 'Not implemented yet.');
  }

  @override
  Future<PropertyModel> getPropertyById(String id) async {
    // TODO: replace with real HTTP call
    throw const ServerException(message: 'Not implemented yet.');
  }
}

class PropertyLocalDataSourceImpl implements PropertyLocalDataSource {
  // inject SharedPreferences / Hive / Isar here
  // final SharedPreferences prefs;

  @override
  Future<List<PropertyModel>> getCachedProperties() async {
    // TODO: read from local storage
    throw const CacheException(message: 'No cached data.');
  }

  @override
  Future<void> cacheProperties(List<PropertyModel> properties) async {
    // TODO: persist to local storage
  }
}
