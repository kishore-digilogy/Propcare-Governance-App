import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/mom_remote_datasource.dart';
import 'mom_event.dart';
import 'mom_state.dart';

class MomBloc extends Bloc<MomEvent, MomState> {
  final MomRemoteDataSource dataSource;

  MomBloc({required this.dataSource}) : super(const MomInitial()) {
    on<LoadMomBySite>(_onLoadMomBySite);
    on<ChangeMomTab>(_onChangeMomTab);
    on<SearchMomQueryChanged>(_onSearchMomQueryChanged);
  }

  Future<void> _onLoadMomBySite(
    LoadMomBySite event,
    Emitter<MomState> emit,
  ) async {
    final currentState = state;
    if (!event.isRefresh || currentState is! MomLoaded) {
      emit(const MomLoading());
    }

    try {
      final result = await dataSource.getMomBySite();
      if (currentState is MomLoaded) {
        emit(currentState.copyWith(data: result));
      } else {
        emit(MomLoaded(data: result));
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? e.message)
          : e.message;
      emit(MomError(msg?.toString() ?? 'Unable to connect to server.'));
    } catch (e) {
      emit(MomError(e.toString()));
    }
  }

  void _onChangeMomTab(
    ChangeMomTab event,
    Emitter<MomState> emit,
  ) {
    if (state is MomLoaded) {
      final loaded = state as MomLoaded;
      emit(loaded.copyWith(selectedTabIndex: event.tabIndex));
    }
  }

  void _onSearchMomQueryChanged(
    SearchMomQueryChanged event,
    Emitter<MomState> emit,
  ) {
    if (state is MomLoaded) {
      final loaded = state as MomLoaded;
      emit(loaded.copyWith(searchQuery: event.query));
    }
  }
}

