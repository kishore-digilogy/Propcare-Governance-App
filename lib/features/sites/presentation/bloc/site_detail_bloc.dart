import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/sites_remote_datasource.dart';
import 'site_detail_event.dart';
import 'site_detail_state.dart';

class SiteDetailBloc extends Bloc<SiteDetailEvent, SiteDetailState> {
  final SitesRemoteDataSource dataSource;

  SiteDetailBloc({required this.dataSource}) : super(const SiteDetailInitial()) {
    on<LoadSiteDetail>(_onLoadDetail);
    on<SubmitSpecialAttention>(_onSubmitSpecialAttention);
    on<SubmitClassification>(_onSubmitClassification);
    on<SubmitLifecycle>(_onSubmitLifecycle);
  }

  Future<void> _onLoadDetail(
    LoadSiteDetail event,
    Emitter<SiteDetailState> emit,
  ) async {
    emit(const SiteDetailLoading());
    try {
      final detail = await dataSource.getSiteDetail(event.siteId);
      emit(SiteDetailLoaded(detail: detail));
    } catch (e) {
      emit(SiteDetailError('Failed to load site details: $e'));
    }
  }

  Future<void> _onSubmitSpecialAttention(
    SubmitSpecialAttention event,
    Emitter<SiteDetailState> emit,
  ) async {
    final current = state;
    if (current is! SiteDetailLoaded) return;

    emit(current.copyWith(isSubmitting: true, successMessage: null, errorMessage: null));
    try {
      await dataSource.updateSpecialAttention(
        event.siteId,
        enabled: event.enabled,
        fromDate: event.fromDate,
        toDate: event.toDate,
        reason: event.reason,
      );
      final refreshed = await dataSource.getSiteDetail(event.siteId);
      emit(SiteDetailLoaded(
        detail: refreshed,
        isSubmitting: false,
        successMessage: 'Special attention status updated successfully',
      ));
    } catch (e) {
      emit(current.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to update special attention: $e',
      ));
    }
  }

  Future<void> _onSubmitClassification(
    SubmitClassification event,
    Emitter<SiteDetailState> emit,
  ) async {
    final current = state;
    if (current is! SiteDetailLoaded) return;

    emit(current.copyWith(isSubmitting: true, successMessage: null, errorMessage: null));
    try {
      await dataSource.updateClassification(
        event.siteId,
        clientType: event.clientType,
        effectiveDate: event.effectiveDate,
        reason: event.reason,
      );
      final refreshed = await dataSource.getSiteDetail(event.siteId);
      emit(SiteDetailLoaded(
        detail: refreshed,
        isSubmitting: false,
        successMessage: 'Client type updated to ${event.clientType}',
      ));
    } catch (e) {
      emit(current.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to update client classification: $e',
      ));
    }
  }

  Future<void> _onSubmitLifecycle(
    SubmitLifecycle event,
    Emitter<SiteDetailState> emit,
  ) async {
    final current = state;
    if (current is! SiteDetailLoaded) return;

    emit(current.copyWith(isSubmitting: true, successMessage: null, errorMessage: null));
    try {
      await dataSource.updateLifecycle(
        event.siteId,
        action: event.action,
        reason: event.reason,
      );
      final refreshed = await dataSource.getSiteDetail(event.siteId);
      emit(SiteDetailLoaded(
        detail: refreshed,
        isSubmitting: false,
        successMessage: 'Site marked as ${event.action}',
      ));
    } catch (e) {
      emit(current.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to update lifecycle: $e',
      ));
    }
  }
}

