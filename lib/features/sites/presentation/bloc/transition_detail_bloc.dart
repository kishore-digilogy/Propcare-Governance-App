import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/hive_storage.dart';
import '../../data/datasources/sites_remote_datasource.dart';
import 'transition_detail_event.dart';
import 'transition_detail_state.dart';

class TransitionDetailBloc extends Bloc<TransitionDetailEvent, TransitionDetailState> {
  final SitesRemoteDataSource dataSource;

  TransitionDetailBloc({required this.dataSource}) : super(const TransitionDetailInitial()) {
    on<LoadTransitionDetail>(_onLoadTransitionDetail);
    on<SelectTransitionStep>(_onSelectTransitionStep);
    on<UpdateKickoffField>(_onUpdateKickoffField);
    on<UpdateChecklistItemEvent>(_onUpdateChecklistItem);
    on<SaveTransitionActionEvent>(_onSaveTransitionAction);
    on<RaiseTransitionIssueEvent>(_onRaiseTransitionIssue);
    on<UpdateManpowerEvent>(_onUpdateManpower);
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

      // 4-stage stepper step calculation:
      // Step 1: Site Creation (Completed)
      // Step 2: Internal Checklist
      // Step 3: L&D Transition Checklist
      // Step 4: Stability Verify
      int defaultStep = 2;
      final internalDone = response.ldPreview.internal.isNotEmpty &&
          response.ldPreview.internal.every((i) => i.done || i.status.toUpperCase() == 'COMPLETED');
      final ldDone = response.ldPreview.ldTransition.isNotEmpty &&
          response.ldPreview.ldTransition.every((i) => i.done || i.status.toUpperCase() == 'COMPLETED');

      final revStatus = response.ldPreview.review.status.toUpperCase();
      if (revStatus == 'VERIFIED' || revStatus == 'STABILITY_PENDING') {
        defaultStep = 4;
      } else if (internalDone && ldDone) {
        defaultStep = 4;
      } else if (internalDone) {
        defaultStep = 3;
      } else {
        defaultStep = 2;
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

  void _onUpdateKickoffField(
    UpdateKickoffField event,
    Emitter<TransitionDetailState> emit,
  ) {
    if (state is TransitionDetailLoaded) {
      final current = state as TransitionDetailLoaded;
      final oldKickoff = current.response.ldPreview.kickoff;
      final newKickoff = oldKickoff.copyWith(
        withClient: event.withClient,
        date: event.date,
        participants: event.participants,
        meeting: event.meeting,
      );
      final newPreview = current.response.ldPreview.copyWith(kickoff: newKickoff);
      emit(current.copyWith(
        response: current.response.copyWith(ldPreview: newPreview),
      ));
    }
  }

  void _onUpdateChecklistItem(
    UpdateChecklistItemEvent event,
    Emitter<TransitionDetailState> emit,
  ) {
    if (state is TransitionDetailLoaded) {
      final current = state as TransitionDetailLoaded;
      final preview = current.response.ldPreview;

      if (event.phase.toUpperCase() == 'INTERNAL') {
        final updatedInternal = preview.internal.map((item) {
          if (item.key == event.key) {
            return item.copyWith(
              status: event.status,
              done: event.done,
              startDate: event.startDate ?? item.startDate,
              endDate: event.endDate ?? item.endDate,
            );
          }
          return item;
        }).toList();

        final newPreview = preview.copyWith(internal: updatedInternal);
        emit(current.copyWith(
          response: current.response.copyWith(ldPreview: newPreview),
        ));
      } else {
        final updatedLd = preview.ldTransition.map((item) {
          if (item.key == event.key) {
            return item.copyWith(
              status: event.status,
              done: event.done,
              startDate: event.startDate ?? item.startDate,
              endDate: event.endDate ?? item.endDate,
            );
          }
          return item;
        }).toList();

        final newPreview = preview.copyWith(ldTransition: updatedLd);
        emit(current.copyWith(
          response: current.response.copyWith(ldPreview: newPreview),
        ));
      }
    }
  }

  Future<void> _onSaveTransitionAction(
    SaveTransitionActionEvent event,
    Emitter<TransitionDetailState> emit,
  ) async {
    if (state is TransitionDetailLoaded) {
      final current = state as TransitionDetailLoaded;

      if ((event.action == 'stability' || event.action == 'verify') &&
          HiveStorage.isSuperAdmin) {
        emit(current.copyWith(
          errorMessage: 'Admin does not have access to stability check.',
          isSaving: false,
        ));
        return;
      }

      if (current.response.ldPreview.kickoff.isWithClientYes &&
          current.response.ldPreview.kickoff.date.trim().isEmpty) {
        emit(current.copyWith(
          errorMessage: 'Kick-Off Date is mandatory when Kick-Off with Client is Yes.',
          isSaving: false,
        ));
        return;
      }

      emit(current.copyWith(isSaving: true));

      try {
        final preview = current.response.ldPreview;
        final items = [
          ...preview.internal.map((e) => e.toJson()),
          ...preview.ldTransition.map((e) => e.toJson()),
        ];
        final kickoff = preview.kickoff.toJson();

        final updatedResponse = await dataSource.saveTransitionAction(
          event.siteId,
          action: event.action,
          items: items,
          kickoff: kickoff,
        );

        int nextStep = current.selectedStep;
        if (event.action == 'save') {
          if (current.selectedStep == 1) {
            nextStep = 2;
          } else if (current.selectedStep == 2) {
            nextStep = 3;
          } else if (current.selectedStep == 3) {
            nextStep = 4;
          }
        } else if (event.action == 'stability') {
          nextStep = 4;
        }

        String message = 'Progress saved successfully';
        if (event.action == 'stability') {
          message = 'Submitted for Stability Check';
        } else if (event.action == 'verify') {
          message = 'Stability successfully verified!';
        }

        emit(current.copyWith(
          response: updatedResponse,
          selectedStep: nextStep,
          isSaving: false,
          actionMessage: message,
        ));
      } catch (e) {
        String errorMsg = 'Failed to save transition. Please try again.';
        if (e is DioException) {
          final res = e.response;
          if (res?.data != null) {
            final data = res!.data;
            if (data is Map) {
              if (data['details'] is List && (data['details'] as List).isNotEmpty) {
                final details = (data['details'] as List)
                    .map((d) => d is Map ? (d['message'] ?? d.toString()) : d.toString())
                    .join(', ');
                errorMsg = details;
              } else {
                errorMsg = data['message'] ?? data['error'] ?? data['msg'] ?? errorMsg;
              }
            } else if (data is String && data.isNotEmpty) {
              errorMsg = data;
            }
          } else if (res?.statusCode == 422) {
            errorMsg = 'Validation error: Please ensure all required fields are filled (e.g. Kick-Off Date).';
          } else if (e.message != null && e.message!.isNotEmpty) {
            errorMsg = e.message!;
          }
        } else if (e is Exception) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        emit(current.copyWith(
          isSaving: false,
          errorMessage: errorMsg,
        ));
      }
    }
  }

  Future<void> _onRaiseTransitionIssue(
    RaiseTransitionIssueEvent event,
    Emitter<TransitionDetailState> emit,
  ) async {
    if (state is TransitionDetailLoaded) {
      final current = state as TransitionDetailLoaded;
      emit(current.copyWith(isSaving: true));

      try {
        await dataSource.raiseTransitionIssue(
          event.siteId,
          phase: event.phase,
          key: event.key,
          issue: event.issue,
          ownerId: event.ownerId,
          remarks: event.remarks,
        );

        final preview = current.response.ldPreview;
        final updatedInternal = preview.internal.map((item) {
          if (item.key == event.key) {
            return item.copyWith(
              status: 'PENDING',
              done: false,
              issue: event.issue,
              remarks: event.remarks,
            );
          }
          return item;
        }).toList();

        emit(current.copyWith(
          response: current.response.copyWith(
            ldPreview: preview.copyWith(internal: updatedInternal),
          ),
          isSaving: false,
          actionMessage: 'Issue raised successfully for ${event.key}!',
        ));
      } catch (e) {
        String errorMsg = 'Failed to save transition. Please try again.';
        if (e is DioException) {
          final res = e.response;
          if (res?.data != null) {
            final data = res!.data;
            if (data is Map) {
              if (data['details'] is List && (data['details'] as List).isNotEmpty) {
                final details = (data['details'] as List)
                    .map((d) => d is Map ? (d['message'] ?? d.toString()) : d.toString())
                    .join(', ');
                errorMsg = details;
              } else {
                errorMsg = data['message'] ?? data['error'] ?? data['msg'] ?? errorMsg;
              }
            } else if (data is String && data.isNotEmpty) {
              errorMsg = data;
            }
          } else if (res?.statusCode == 422) {
            errorMsg = 'Validation error: Please ensure all required fields are filled (e.g. Kick-Off Date).';
          } else if (e.message != null && e.message!.isNotEmpty) {
            errorMsg = e.message!;
          }
        } else if (e is Exception) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        emit(current.copyWith(
          isSaving: false,
          errorMessage: errorMsg,
        ));
      }
    }
  }

  Future<void> _onUpdateManpower(
    UpdateManpowerEvent event,
    Emitter<TransitionDetailState> emit,
  ) async {
    if (state is TransitionDetailLoaded) {
      final current = state as TransitionDetailLoaded;
      emit(current.copyWith(isSaving: true));

      try {
        await dataSource.updateManpower(
          event.siteId,
          manpowerRequired: event.manpowerRequired,
          manpowerDeployed: event.manpowerDeployed,
        );

        final newShortage = (event.manpowerRequired - event.manpowerDeployed).clamp(0, event.manpowerRequired);
        final updatedSite = current.response.site.copyWith(
          manpowerRequired: event.manpowerRequired,
          manpowerDeployed: event.manpowerDeployed,
          shortage: newShortage,
        );

        emit(current.copyWith(
          response: current.response.copyWith(site: updatedSite),
          isSaving: false,
          actionMessage: 'Manpower updated successfully',
        ));
      } catch (e) {
        String errorMsg = 'Failed to update manpower. Please try again.';
        if (e is DioException) {
          final res = e.response;
          if (res?.data != null) {
            final data = res!.data;
            if (data is Map) {
              errorMsg = data['message'] ?? data['error'] ?? data['msg'] ?? errorMsg;
            } else if (data is String && data.isNotEmpty) {
              errorMsg = data;
            }
          } else if (e.message != null && e.message!.isNotEmpty) {
            errorMsg = e.message!;
          }
        } else if (e is Exception) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        emit(current.copyWith(
          isSaving: false,
          errorMessage: errorMsg,
        ));
      }
    }
  }
}

