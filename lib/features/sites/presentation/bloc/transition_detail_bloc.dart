import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/sites_remote_datasource.dart';
import 'transition_detail_event.dart';
import 'transition_detail_state.dart';

class TransitionDetailBloc extends Bloc<TransitionDetailEvent, TransitionDetailState> {
  final SitesRemoteDataSource dataSource;

  TransitionDetailBloc({required this.dataSource}) : super(const TransitionDetailInitial()) {
    on<LoadTransitionDetail>(_onLoadTransitionDetail);
    on<SelectTransitionStep>(_onSelectTransitionStep);
  }

  Future<void> _onLoadTransitionDetail(
    LoadTransitionDetail event,
    Emitter<TransitionDetailState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(const TransitionDetailLoading());
    }

    try {
      final response = await dataSource.getTransitionDetail(event.siteId);

      // Determine default active step:
      // If site is already LIVE / Transition in progress, default to step 2 (Internal Checklist)
      // matching the user screenshot!
      int defaultStep = 2;
      if (response.site.status == 'DRAFT') {
        defaultStep = 1;
      } else if (response.site.ldTransitionComplete) {
        defaultStep = 4;
      }

      emit(TransitionDetailLoaded(
        response: response,
        selectedStep: defaultStep,
      ));
    } catch (e) {
      emit(TransitionDetailError(e.toString()));
    }
  }

  void _onSelectTransitionStep(
    SelectTransitionStep event,
    Emitter<TransitionDetailState> emit,
  ) {
    if (state is TransitionDetailLoaded) {
      final current = state as TransitionDetailLoaded;
      emit(current.copyWith(selectedStep: event.step));
    }
  }
}

