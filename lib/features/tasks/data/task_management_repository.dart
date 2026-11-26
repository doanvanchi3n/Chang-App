import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/remote/supabase_client_provider.dart';
import '../domain/task_detail.dart';
import '../presentation/inbox_provider.dart';
import 'inbox_repository.dart';

final taskManagementRepositoryProvider = Provider(
  (ref) => TaskManagementRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(inboxRepositoryProvider),
  ),
);
final taskListProvider = FutureProvider.autoDispose<List<TaskDetail>>(
  (ref) => ref.watch(taskManagementRepositoryProvider).list(),
  retry: (_, _) => null,
);

class TaskManagementRepository {
  TaskManagementRepository(this.client, this.inbox);
  final SupabaseClient client;
  final InboxRepository inbox;
  Future<List<TaskDetail>> list() async {
    final user = await inbox.ensureUserId();
    final items = <String, TaskDetail>{};
    for (var offset = 0; ; offset += 100) {
      final rows = await client
          .from('tasks')
          .select(
            'id,title,description,priority,due_date,scheduled_date,status,is_archived,progress_percentage,estimated_minutes,updated_at,'
            'projects(id,name,color_hex),subtasks(id,task_id,title,order_index,estimated_minutes,is_completed,completed_at)',
          )
          .eq('user_id', user)
          .eq('is_archived', false)
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + 99);
      for (final row in rows) {
        final task = TaskDetail.fromJson(row);
        items[task.id] = task;
      }
      if (rows.length < 100) return items.values.toList();
    }
  }

  Future<void> saveDetails(Map<String, dynamic> request) =>
      _write('save_task_details', request);
  Future<void> saveSteps(Map<String, dynamic> request) =>
      _write('save_task_steps', request);
  Future<void> delete(TaskDetail task) => _write('delete_task_checked', {
    'p_task': task.id,
    'p_expected': task.updatedAt.toUtc().toIso8601String(),
  });
  Future<void> _write(String rpc, Map<String, dynamic> params) async {
    await inbox.ensureUserId();
    await client.rpc(rpc, params: params).timeout(const Duration(seconds: 15));
  }
}
