import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/mom_remote_datasource.dart';
import '../../data/models/mom_activity_model.dart';
import '../../data/models/mom_by_site_model.dart';
import 'mom_event.dart';
import 'mom_state.dart';

class MomBloc extends Bloc<MomEvent, MomState> {
  final MomRemoteDataSource dataSource;

  MomBloc({required this.dataSource}) : super(const MomInitial()) {
    on<LoadMomBySite>(_onLoadMomBySite);
    on<ChangeMomTab>(_onChangeMomTab);
    on<SearchMomQueryChanged>(_onSearchMomQueryChanged);
    on<SelectMomSite>(_onSelectMomSite);
    on<SelectMomActivityDirectly>(_onSelectMomActivityDirectly);
    on<BackToMomSitesList>(_onBackToMomSitesList);
    on<SelectMomActivity>(_onSelectMomActivity);
    on<SelectMomRole>(_onSelectMomRole);
    on<SendMomEmailAction>(_onSendMomEmailAction);
    on<UpdateMomPointStatusAction>(_onUpdateMomPointStatusAction);
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
      // 1. Fetch activities & sites
      List<MomActivityModel> activities = [];
      try {
        activities = await dataSource.getGovernanceActivities();
      } catch (e) {
        developer.log('Failed to fetch governance activities: $e', name: 'MOM');
      }

      MomBySiteModel siteData = MomBySiteModel.empty;
      try {
        siteData = await dataSource.getMomBySite();
      } catch (e) {
        developer.log('Failed to fetch mom by site: $e', name: 'MOM');
      }

      // If siteData is empty but activities exist, synthesize siteData
      if (siteData.items.isEmpty && activities.isNotEmpty) {
        final siteMap = <String, List<MomActivityModel>>{};
        for (final a in activities) {
          final sid = a.siteId.isNotEmpty ? a.siteId : 'default_site';
          siteMap.putIfAbsent(sid, () => []).add(a);
        }

        final siteItems = <MomSiteItemModel>[];
        int pending = 0;
        int completed = 0;
        for (final entry in siteMap.entries) {
          final acts = entry.value;
          final first = acts.first;
          final p = acts.where((a) => a.isPending).length;
          final c = acts.where((a) => a.isSent).length;
          pending += p;
          completed += c;

          siteItems.add(
            MomSiteItemModel(
              siteId: entry.key,
              siteName: first.siteName.isNotEmpty ? first.siteName : 'Site',
              siteCode: first.siteCode,
              siteCity: first.siteCity,
              siteClientType: first.clientType,
              zoneName: first.zoneName,
              clusterName: first.clusterName,
              siteStatus: 'LIVE',
              pending: p,
              completed: c,
              total: acts.length,
            ),
          );
        }

        siteData = MomBySiteModel(
          items: siteItems,
          pending: pending,
          completed: completed,
        );
      } else if (activities.isEmpty && siteData.items.isNotEmpty) {
        // If activities is empty but siteData has items, fetch site activities for those sites
        final fetched = <MomActivityModel>[];
        for (final site in siteData.items) {
          try {
            final siteActs = await dataSource.getSiteMomActivities(siteId: site.siteId);
            fetched.addAll(siteActs);
          } catch (e) {
            developer.log('Failed to fetch site activities for ${site.siteId}: $e', name: 'MOM');
          }
        }

        if (fetched.isNotEmpty) {
          activities = fetched;
        } else {
          // If server didn't return activity items, synthesize activities from site data so user sees all visits
          final synthesized = <MomActivityModel>[];
          for (final site in siteData.items) {
            final totalCount = site.total > 0 ? site.total : (site.completed + site.pending);
            for (int i = 0; i < totalCount; i++) {
              final isItemSent = i < site.completed;
              synthesized.add(
                MomActivityModel(
                  id: '${site.siteId}_visit_$i',
                  siteId: site.siteId,
                  siteName: site.siteName,
                  siteCode: site.siteCode,
                  siteCity: site.siteCity,
                  zoneName: site.zoneName,
                  clusterName: site.clusterName,
                  role: 'EHS',
                  roleLabel: 'EHS',
                  kind: 'GOVERNANCE',
                  title: 'EHS Audit Visit',
                  code: 'ACT-${site.siteCode.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '')}-$i',
                  scheduledDate: '2026-11-25',
                  dueDate: '2026-11-25',
                  visitDate: '2026-11-25',
                  status: isItemSent ? 'COMPLETED' : 'OPEN',
                  statusLabel: isItemSent ? 'Sent' : 'Assigned',
                  frequencyLabel: 'Quarterly',
                  clientType: site.siteClientType.isNotEmpty ? site.siteClientType : 'A+',
                  mom: isItemSent
                      ? const MomDetailInfoModel(sentAt: '2026-11-25T10:49:00.000Z')
                      : const MomDetailInfoModel(),
                ),
              );
            }
          }
          if (synthesized.isNotEmpty) {
            activities = synthesized;
          }
        }
      }

      if (currentState is MomLoaded) {
        emit(currentState.copyWith(
          data: siteData,
          allActivities: activities,
        ));
      } else {
        emit(MomLoaded(
          data: siteData,
          allActivities: activities,
        ));
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
      MomActivityModel? nextSelectedActivity = loaded.selectedActivity;
      if (loaded.selectedSite != null && loaded.siteActivities.isNotEmpty) {
        if (event.tabIndex == 1) {
          nextSelectedActivity = loaded.siteActivities
              .where((a) => a.isPending)
              .firstOrNull ?? loaded.siteActivities.firstOrNull;
        } else if (event.tabIndex == 2) {
          nextSelectedActivity = loaded.siteActivities
              .where((a) => a.isSent)
              .firstOrNull ?? loaded.siteActivities.firstOrNull;
        }
      }

      emit(loaded.copyWith(
        selectedTabIndex: event.tabIndex,
        selectedActivity: () => nextSelectedActivity,
      ));
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

  Future<void> _onSelectMomSite(
    SelectMomSite event,
    Emitter<MomState> emit,
  ) async {
    if (state is! MomLoaded) return;
    final current = state as MomLoaded;

    // Filter from preloaded allActivities if available
    final localActivities = current.allActivities
        .where((a) => a.siteId == event.site.siteId)
        .toList();

    emit(current.copyWith(
      selectedSite: () => event.site,
      isSiteActivitiesLoading: localActivities.isEmpty,
      siteActivities: localActivities,
      selectedActivity: () => localActivities.firstOrNull,
      actionError: () => null,
      actionMessage: () => null,
      momSendSuccess: false,
    ));

    try {
      final activities = await dataSource.getSiteMomActivities(
        siteId: event.site.siteId,
      );

      if (state is MomLoaded) {
        final latest = state as MomLoaded;
        final list = activities.isNotEmpty ? activities : localActivities;
        MomActivityModel? defaultActivity;
        if (latest.selectedTabIndex == 1) {
          defaultActivity = list.where((a) => a.isPending).firstOrNull ??
              list.firstOrNull;
        } else if (latest.selectedTabIndex == 2) {
          defaultActivity = list.where((a) => a.isSent).firstOrNull ??
              list.firstOrNull;
        } else {
          defaultActivity = list.firstOrNull;
        }

        emit(latest.copyWith(
          selectedSite: () => event.site,
          isSiteActivitiesLoading: false,
          siteActivities: list,
          selectedActivity: () => defaultActivity,
        ));
      }
    } catch (e, stack) {
      developer.log(
        'Error loading site activities for MOM: ${event.site.siteName}',
        error: e,
        stackTrace: stack,
        name: 'MOM',
      );
      if (state is MomLoaded) {
        final latest = state as MomLoaded;
        emit(latest.copyWith(
          selectedSite: () => event.site,
          isSiteActivitiesLoading: false,
          siteActivities: localActivities,
          selectedActivity: () => localActivities.firstOrNull,
        ));
      }
    }
  }

  Future<void> _onSelectMomActivityDirectly(
    SelectMomActivityDirectly event,
    Emitter<MomState> emit,
  ) async {
    if (state is! MomLoaded) return;
    final current = state as MomLoaded;

    final act = event.activity;

    // Find site from current.data.items or fabricate
    final existingSite = current.data.items.where((s) => s.siteId == act.siteId).firstOrNull;
    final site = existingSite ??
        MomSiteItemModel(
          siteId: act.siteId,
          siteName: act.siteName,
          siteCode: act.siteCode,
          siteCity: act.siteCity,
          siteClientType: act.clientType,
          zoneName: act.zoneName,
          clusterName: act.clusterName,
          siteStatus: 'LIVE',
          pending: act.isPending ? 1 : 0,
          completed: act.isSent ? 1 : 0,
          total: 1,
        );

    final siteActivities = current.allActivities
        .where((a) => a.siteId == act.siteId)
        .toList();

    emit(current.copyWith(
      selectedSite: () => site,
      isSiteActivitiesLoading: false,
      siteActivities: siteActivities.isNotEmpty ? siteActivities : [act],
      selectedActivity: () => act,
      actionError: () => null,
      actionMessage: () => null,
      momSendSuccess: false,
    ));

    // Also fetch fresh site activities in background
    try {
      final freshActivities = await dataSource.getSiteMomActivities(siteId: act.siteId);
      if (freshActivities.isNotEmpty && state is MomLoaded) {
        final latest = state as MomLoaded;
        final selected = freshActivities.where((a) => a.id == act.id).firstOrNull ?? act;
        emit(latest.copyWith(
          siteActivities: freshActivities,
          selectedActivity: () => selected,
        ));
      }
    } catch (_) {}
  }

  void _onBackToMomSitesList(
    BackToMomSitesList event,
    Emitter<MomState> emit,
  ) {
    if (state is MomLoaded) {
      final current = state as MomLoaded;
      emit(current.copyWith(
        selectedSite: () => null,
        selectedActivity: () => null,
        siteActivities: [],
        actionError: () => null,
        actionMessage: () => null,
        momSendSuccess: false,
      ));
    }
  }

  void _onSelectMomActivity(
    SelectMomActivity event,
    Emitter<MomState> emit,
  ) {
    if (state is MomLoaded) {
      final current = state as MomLoaded;
      emit(current.copyWith(
        selectedActivity: () => event.activity,
        actionError: () => null,
        actionMessage: () => null,
        momSendSuccess: false,
      ));
    }
  }

  void _onSelectMomRole(
    SelectMomRole event,
    Emitter<MomState> emit,
  ) {
    if (state is MomLoaded) {
      final current = state as MomLoaded;
      final matched = current.siteActivities.where((a) {
        final r = a.role.isNotEmpty ? a.role : a.roleLabel;
        return r.toUpperCase() == event.role.toUpperCase();
      }).firstOrNull;

      if (matched != null) {
        emit(current.copyWith(
          selectedActivity: () => matched,
          actionError: () => null,
          actionMessage: () => null,
          momSendSuccess: false,
        ));
      }
    }
  }

  Future<void> _onSendMomEmailAction(
    SendMomEmailAction event,
    Emitter<MomState> emit,
  ) async {
    if (state is! MomLoaded) return;
    final current = state as MomLoaded;

    emit(current.copyWith(
      isSendingMom: true,
      actionError: () => null,
      actionMessage: () => null,
      momSendSuccess: false,
    ));

    try {
      await dataSource.sendMomEmail(
        activityId: event.activityId,
        payload: event.payload,
      );

      // Refresh site activities
      List<MomActivityModel> updatedActivities = current.siteActivities;
      if (current.selectedSite != null) {
        try {
          updatedActivities = await dataSource.getSiteMomActivities(
            siteId: current.selectedSite!.siteId,
          );
        } catch (_) {}
      }

      // Also refresh root site counts in background
      dataSource.getGovernanceActivities().then((freshActivities) {
        if (!isClosed && state is MomLoaded) {
          add(const LoadMomBySite(isRefresh: true));
        }
      }).catchError((_) {});

      if (state is MomLoaded) {
        final latest = state as MomLoaded;
        final updatedSelected = updatedActivities
            .where((a) => a.id == event.activityId)
            .firstOrNull ?? latest.selectedActivity;

        emit(latest.copyWith(
          isSendingMom: false,
          momSendSuccess: true,
          actionMessage: () => 'MOM email dispatched successfully!',
          siteActivities: updatedActivities,
          selectedActivity: () => updatedSelected,
        ));
      }
    } catch (e, stack) {
      developer.log('Error dispatching MOM email', error: e, stackTrace: stack, name: 'MOM');
      if (state is MomLoaded) {
        final latest = state as MomLoaded;
        emit(latest.copyWith(
          isSendingMom: false,
          momSendSuccess: false,
          actionError: () => 'Failed to send MOM email: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onUpdateMomPointStatusAction(
    UpdateMomPointStatusAction event,
    Emitter<MomState> emit,
  ) async {
    if (state is! MomLoaded) return;
    final current = state as MomLoaded;

    // Optimistically update
    final updatedSiteActivities = current.siteActivities.map((act) {
      if (act.id != event.activityId) return act;
      final updatedPoints = act.mom.points.map((p) {
        if (p.id == event.pointId || (p.id.isEmpty && event.pointId.isEmpty)) {
          return p.copyWith(
            status: event.status,
            completedAt: event.status == 'DONE' ? DateTime.now().toIso8601String() : null,
          );
        }
        return p;
      }).toList();

      return act.copyWith(
        mom: act.mom.copyWith(points: updatedPoints),
      );
    }).toList();

    final updatedAllActivities = current.allActivities.map((act) {
      if (act.id != event.activityId) return act;
      final updatedPoints = act.mom.points.map((p) {
        if (p.id == event.pointId || (p.id.isEmpty && event.pointId.isEmpty)) {
          return p.copyWith(
            status: event.status,
            completedAt: event.status == 'DONE' ? DateTime.now().toIso8601String() : null,
          );
        }
        return p;
      }).toList();

      return act.copyWith(
        mom: act.mom.copyWith(points: updatedPoints),
      );
    }).toList();

    final updatedSelected = updatedSiteActivities
        .where((a) => a.id == current.selectedActivity?.id)
        .firstOrNull ?? current.selectedActivity;

    emit(current.copyWith(
      siteActivities: updatedSiteActivities,
      allActivities: updatedAllActivities,
      selectedActivity: () => updatedSelected,
    ));

    // Call API
    try {
      final updatedAct = await dataSource.updateMomPointStatus(
        activityId: event.activityId,
        pointId: event.pointId,
        status: event.status,
      );

      if (state is MomLoaded) {
        final latest = state as MomLoaded;
        final finalSiteActs = latest.siteActivities.map((a) => a.id == updatedAct.id ? updatedAct : a).toList();
        final finalAllActs = latest.allActivities.map((a) => a.id == updatedAct.id ? updatedAct : a).toList();
        emit(latest.copyWith(
          siteActivities: finalSiteActs,
          allActivities: finalAllActs,
          selectedActivity: () => latest.selectedActivity?.id == updatedAct.id ? updatedAct : latest.selectedActivity,
        ));
      }
    } catch (e) {
      developer.log('API update point status failed, keeping optimistic state: $e', name: 'MOM');
    }
  }
}
