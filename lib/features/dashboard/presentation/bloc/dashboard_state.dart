import 'package:equatable/equatable.dart';

import '../../data/models/dashboard_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  final DashboardModel? previousData;
  final String? selectedZoneId;
  final String? selectedClusterId;
  final String? selectedRole;
  final bool isFiltering;

  const DashboardLoading({
    this.previousData,
    this.selectedZoneId,
    this.selectedClusterId,
    this.selectedRole,
    this.isFiltering = false,
  });

  @override
  List<Object?> get props => [
        previousData,
        selectedZoneId,
        selectedClusterId,
        selectedRole,
        isFiltering,
      ];
}

class DashboardLoaded extends DashboardState {
  final DashboardModel data;
  final String? selectedZoneId;
  final String? selectedClusterId;
  final String? selectedRole;

  const DashboardLoaded(
    this.data, {
    this.selectedZoneId,
    this.selectedClusterId,
    this.selectedRole,
  });

  @override
  List<Object?> get props => [
        data,
        selectedZoneId,
        selectedClusterId,
        selectedRole,
      ];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

