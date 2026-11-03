import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/governance_matrix_remote_datasource.dart';
import 'governance_matrix_event.dart';
import 'governance_matrix_state.dart';

class GovernanceMatrixBloc
    extends Bloc<GovernanceMatrixEvent, GovernanceMatrixState> {
  final GovernanceMatrixRemoteDataSource dataSource;

  GovernanceMatrixBloc({required this.dataSource})
      : super(const GovernanceMatrixInitial()) {
    on<LoadGovernanceMatrix>(_onLoadGovernanceMatrix);
    on<SelectTab>(_onSelectTab);
    on<ToggleViewMode>(_onToggleViewMode);
  }

  Future<void> _onLoadGovernanceMatrix(
    LoadGovernanceMatrix event,
    Emitter<GovernanceMatrixState> emit,
  ) async {
    final current = state;
    if (!event.isRefresh || current is! GovernanceMatrixLoaded) {
      emit(const GovernanceMatrixLoading());
    }

    try {
      final res = await dataSource.getGovernanceMatrix();
      final tabs = res.uniqueTabs;
      final defaultTab = tabs.isNotEmpty ? tabs.first.key : 'operations';

      final selectedTab = (current is GovernanceMatrixLoaded &&
              tabs.any((t) => t.key == current.selectedTabKey))
          ? current.selectedTabKey
          : defaultTab;

      final isCardView = current is GovernanceMatrixLoaded
          ? current.isCardView
          : true;

      emit(
        GovernanceMatrixLoaded(
          data: res,
          selectedTabKey: selectedTab,
          isCardView: isCardView,
        ),
      );
    } on DioException catch (e) {
      developer.log(
        'Failed to load governance matrix: ${e.message}',
        name: 'GovernanceMatrix',
      );
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ??
                e.response?.data['error'] ??
                e.message)
          : e.message;
      emit(GovernanceMatrixError(
        msg?.toString() ?? 'Failed to load governance matrix.',
      ));
    } catch (e) {
      developer.log(
        'Failed to load governance matrix: $e',
        name: 'GovernanceMatrix',
      );
      emit(GovernanceMatrixError(e.toString()));
    }
  }

  void _onSelectTab(
    SelectTab event,
    Emitter<GovernanceMatrixState> emit,
  ) {
    if (state is GovernanceMatrixLoaded) {
      final current = state as GovernanceMatrixLoaded;
      emit(current.copyWith(selectedTabKey: event.tabKey));
    }
  }

  void _onToggleViewMode(
    ToggleViewMode event,
    Emitter<GovernanceMatrixState> emit,
  ) {
    if (state is GovernanceMatrixLoaded) {
      final current = state as GovernanceMatrixLoaded;
      emit(current.copyWith(isCardView: event.isCardView));
    }
  }
}

