import 'package:flutter_bloc/flutter_bloc.dart';

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
    try {
      final data = await _dataSource.getDashboard();
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}

