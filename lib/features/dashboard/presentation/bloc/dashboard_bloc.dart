import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/meta_service.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRemoteDataSource _dataSource;

  DashboardBloc({required DashboardRemoteDataSource dataSource})
      : _dataSource = dataSource,
        super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
  }

  Future<void> _onLoad(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    // Pre-cache global metadata (zones, clusters, sites, users) in the background
    MetaService.instance.fetchMetadata().catchError((_) => MetaService.instance.meta);
    try {
      final data = await _dataSource.getDashboard();
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}

