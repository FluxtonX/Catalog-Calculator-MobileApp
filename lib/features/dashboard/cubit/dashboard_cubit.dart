import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_report.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardInitial());

  Future<void> fetchDashboardData() async {
    try {
      emit(DashboardLoading());

      final userId = Supabase.instance.client.auth.currentSession?.user.id;
      if (userId == null) {
        emit(DashboardError('User not authenticated'));
        return;
      }

      final response = await Supabase.instance.client
          .from('user_reports')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final reports = (response as List<dynamic>)
          .map((json) => UserReport.fromJson(json as Map<String, dynamic>))
          .toList();

      double totalValue = 0;
      final platforms = <String>{};

      for (var report in reports) {
        totalValue += report.estimatedValue;
        platforms.add(report.platform);
      }

      emit(DashboardLoaded(
        reports: reports,
        totalValue: totalValue,
        totalPlatforms: platforms.length,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
