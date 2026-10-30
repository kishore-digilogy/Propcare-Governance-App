import 'package:get_it/get_it.dart';

import 'core/network/dio_client.dart';
import 'core/network/network_info.dart';
import 'core/storage/hive_storage.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/property/data/datasources/property_data_source.dart';
import 'features/property/data/repositories/property_repository_impl.dart';
import 'features/property/domain/repositories/property_repository.dart';
import 'features/property/domain/usecases/get_properties.dart';
import 'features/property/presentation/bloc/property_bloc.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Initialise Hive storage first, then register all dependencies.
Future<void> initDependencies() async {
  // ── Storage ────────────────────────────────────────────────────────────────
  await HiveStorage.init();

  // ── Network ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => DioClient.instance);

  // ══ AUTH feature ══════════════════════════════════════════════════════════

  // BLoC
  sl.registerFactory(
    () => AuthBloc(loginUseCase: sl(), authRepository: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  // ══ PROPERTY feature ══════════════════════════════════════════════════════

  // BLoC
  sl.registerFactory(
    () => PropertyBloc(getProperties: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetProperties(sl()));

  // Repository
  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<PropertyRemoteDataSource>(
    () => PropertyRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<PropertyLocalDataSource>(
    () => PropertyLocalDataSourceImpl(),
  );

  // ── Core ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<NetworkInfo>(() => _NetworkInfoImpl());
}

/// Minimal NetworkInfo implementation.
/// Replace with connectivity_plus when needed.
class _NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}
