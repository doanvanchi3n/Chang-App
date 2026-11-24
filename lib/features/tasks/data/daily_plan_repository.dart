import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/remote/supabase_client_provider.dart';
import '../domain/daily_plan.dart';
import '../presentation/inbox_provider.dart';
import 'inbox_repository.dart';

final dailyPlanRepositoryProvider = Provider<DailyPlanRepository>((ref) {
  return DailyPlanRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(inboxRepositoryProvider),
  );
});

class DailyPlanRepository {
  DailyPlanRepository(this._client, this._inbox);
  final SupabaseClient _client;
  final InboxRepository _inbox;

  Future<DailyPlanData> load(DateTime date) async {
    final userId = await _inbox.ensureUserId();
    final key = planDateKey(date);
    final results = await Future.wait<Object?>([
      _client
          .from('daily_plans')
          .select('available_minutes,updated_at')
          .eq('user_id', userId)
          .eq('plan_date', key)
          .maybeSingle(),
      _client
          .from('user_preferences')
          .select('daily_target_minutes')
          .eq('user_id', userId)
          .maybeSingle(),
      _loadTasks(userId, key),
    ]);
    final plan = results[0] as Map<String, dynamic>?;
    final preferences = results[1] as Map<String, dynamic>?;
    return DailyPlanData(
      date: date,
      availableMinutes:
          plan?['available_minutes'] as int? ??
          preferences?['daily_target_minutes'] as int?,
      updatedAt: plan?['updated_at'] as String?,
      tasks: results[2] as List<PlanningTask>,
    );
  }

  Future<List<PlanningTask>> _loadTasks(String userId, String date) async {
    final tasks = <PlanningTask>[];
    for (var offset = 0; ; offset += 100) {
      final rows = await _client
          .from('tasks')
          .select(
            'id,title,updated_at,scheduled_date,estimated_minutes,'
            'subtasks(estimated_minutes,is_completed)',
          )
          .eq('user_id', userId)
          .eq('is_archived', false)
          .inFilter('status', ['TODO', 'IN_PROGRESS'])
          .or('scheduled_date.is.null,scheduled_date.lte.$date')
          .order('daily_order', nullsFirst: false)
          .order('priority', ascending: false)
          .order('created_at')
          .order('id')
          .range(offset, offset + 99);
      tasks.addAll(rows.map(PlanningTask.fromJson));
      if (rows.length < 100) return tasks;
    }
  }

  Future<int> save({
    required DailyPlanData original,
    required int availableMinutes,
    required List<Map<String, dynamic>> tasks,
  }) async {
    await _inbox.ensureUserId();
    final result = await _client.rpc(
      'save_daily_plan',
      params: {
        'p_date': planDateKey(original.date),
        'p_available_minutes': availableMinutes,
        'p_plan_updated_at': original.updatedAt,
        'p_today_snapshot': original.todayTasks
            .map((task) => task.snapshot)
            .toList(),
        'p_tasks': tasks,
      },
    );
    return result as int;
  }
}
