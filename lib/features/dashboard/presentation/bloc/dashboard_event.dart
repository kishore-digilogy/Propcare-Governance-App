import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  final String? zoneId;
  final String? clusterId;
  final String? role;

  const LoadDashboard({this.zoneId, this.clusterId, this.role});

  @override
  List<Object?> get props => [zoneId, clusterId, role];
}

