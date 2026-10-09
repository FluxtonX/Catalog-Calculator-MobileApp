import '../models/user_report.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<UserReport> reports;
  final double totalValue;
  final int totalPlatforms;

  DashboardLoaded({
    required this.reports,
    required this.totalValue,
    required this.totalPlatforms,
  });
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}
