import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/remote/supabase_client_provider.dart';
import '../../tasks/presentation/inbox_provider.dart';

class DashboardTask {
  DashboardTask.fromJson(Map<String, dynamic> row)
    : title = row['title'] as String,
      project = (row['projects'] as Map<String, dynamic>?)?['name'] as String?,
      dueDate = DateTime.tryParse(row['due_date'] as String? ?? ''),
      steps = (row['subtasks'] as List).length,
      completedSteps = (row['subtasks'] as List)
          .where((step) => step['is_completed'] == true)
          .length;

  final String title;
  final String? project;
  final DateTime? dueDate;
  final int steps;
  final int completedSteps;
}

class DashboardEvent {
  DashboardEvent.fromJson(Map<String, dynamic> row)
    : title = row['title'] as String,
      start = DateTime.parse(row['start_time'] as String).toLocal(),
      end = DateTime.parse(row['end_time'] as String).toLocal();
  final String title;
  final DateTime start;
  final DateTime end;
}

class DashboardData {
  const DashboardData({
    required this.name,
    required this.tasks,
    required this.todayCount,
    required this.todayDone,
    required this.inboxCount,
    required this.overdueCount,
    required this.nextEvent,
    required this.weekSeconds,
    required this.weekTargetMinutes,
    required this.completedSessions,
  });
  final String? name;
  final List<DashboardTask> tasks;
  final int todayCount;
  final int todayDone;
  final int inboxCount;
  final int overdueCount;
  final DashboardEvent? nextEvent;
  final int weekSeconds;
  final int? weekTargetMinutes;
  final int completedSessions;
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final repository = ref.watch(inboxRepositoryProvider);
  final userId = await repository.ensureUserId();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = DateTime(
    today.year,
    today.month,
    today.day - today.weekday + 1,
  );
  final date =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  // All requests use the same user and date snapshot. RLS enforces ownership.
  final results = await Future.wait<Object?>([
    client.from('profiles').select('full_name').eq('id', userId).maybeSingle(),
    client
        .from('tasks')
        .select('title,due_date,projects(name),subtasks(is_completed)')
        .eq('user_id', userId)
        .eq('scheduled_date', date)
        .eq('is_archived', false)
        .inFilter('status', ['TODO', 'IN_PROGRESS'])
        .order('priority', ascending: false)
        .order('due_date')
        .order('created_at')
        .limit(3),
    client
        .from('tasks')
        .count(CountOption.exact)
        .eq('user_id', userId)
        .eq('scheduled_date', date)
        .eq('is_archived', false),
    client
        .from('tasks')
        .count(CountOption.exact)
        .eq('user_id', userId)
        .eq('scheduled_date', date)
        .eq('is_archived', false)
        .eq('status', 'COMPLETED'),
    client
        .from('tasks')
        .count(CountOption.exact)
        .eq('user_id', userId)
        .isFilter('scheduled_date', null)
        .eq('is_archived', false)
        .inFilter('status', ['TODO', 'IN_PROGRESS']),
    client
        .from('tasks')
        .count(CountOption.exact)
        .eq('user_id', userId)
        .eq('is_archived', false)
        .inFilter('status', ['TODO', 'IN_PROGRESS'])
        .lt('due_date', now.toUtc().toIso8601String()),
    client
        .from('schedule_events')
        .select('title,start_time,end_time')
        .eq('user_id', userId)
        .gte('start_time', now.toUtc().toIso8601String())
        .order('start_time')
        .limit(1),
    client
        .from('user_preferences')
        .select('daily_target_minutes')
        .eq('user_id', userId)
        .maybeSingle(),
    _weekSessions(client, userId, weekStart, now),
  ]);
  final profile = results[0] as Map<String, dynamic>?;
  final preferences = results[7] as Map<String, dynamic>?;
  final events = results[6] as List;
  final sessions = results[8] as List<Map<String, dynamic>>;
  final name = (profile?['full_name'] as String?)?.trim();
  final dailyMinutes = preferences?['daily_target_minutes'] as int?;
  return DashboardData(
    name: name == null || name.isEmpty ? null : name,
    tasks: (results[1] as List)
        .map((row) => DashboardTask.fromJson(row as Map<String, dynamic>))
        .toList(),
    todayCount: results[2] as int,
    todayDone: results[3] as int,
    inboxCount: results[4] as int,
    overdueCount: results[5] as int,
    nextEvent: events.isEmpty
        ? null
        : DashboardEvent.fromJson(events.first as Map<String, dynamic>),
    weekSeconds: sessions.fold<int>(
      0,
      (sum, row) => sum + (row['actual_duration_seconds'] as int),
    ),
    weekTargetMinutes: dailyMinutes == null ? null : dailyMinutes * 7,
    completedSessions: sessions
        .where((row) => row['status'] == 'COMPLETED')
        .length,
  );
}, retry: (retryCount, error) => null);

Future<List<Map<String, dynamic>>> _weekSessions(
  SupabaseClient client,
  String userId,
  DateTime start,
  DateTime end,
) async {
  final result = <Map<String, dynamic>>[];
  for (var offset = 0; ; offset += 100) {
    final rows = await client
        .from('focus_sessions')
        .select('actual_duration_seconds,status')
        .eq('user_id', userId)
        .inFilter('status', ['COMPLETED', 'EARLY_STOPPED'])
        .gte('ended_at', start.toUtc().toIso8601String())
        .lte('ended_at', end.toUtc().toIso8601String())
        .order('ended_at')
        .order('id')
        .range(offset, offset + 99);
    result.addAll(rows);
    if (rows.length < 100) return result;
  }
}
