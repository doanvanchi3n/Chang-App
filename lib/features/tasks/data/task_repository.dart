import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/remote/supabase_client_provider.dart';
import '../domain/task_detail.dart';
import '../presentation/inbox_provider.dart';
import 'inbox_repository.dart';
export '../presentation/task_detail_provider.dart' show taskDetailProvider;

final taskRepositoryProvider = Provider(
  (ref) => TaskRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(inboxRepositoryProvider),
  ),
);
final taskProjectsProvider = FutureProvider.autoDispose<List<TaskProject>>(
  (ref) => ref.watch(taskRepositoryProvider).projects(),
  retry: (_, _) => null,
);
final focusTaskChoicesProvider = FutureProvider.autoDispose<List<TaskProject>>(
  (ref) => ref.watch(taskRepositoryProvider).focusChoices(),
  retry: (_, _) => null,
);

class TaskRepository {
  TaskRepository(this.client, this.inbox);
  final SupabaseClient client;
  final InboxRepository inbox;
  Future<TaskDetail> detail(String id) async {
    final user = await inbox.ensureUserId();
    return TaskDetail.fromJson(
      await client
          .from('tasks')
          .select(
            'id,title,description,due_date,scheduled_date,priority,status,is_archived,estimated_minutes,updated_at,completed_at,progress_percentage,projects(id,name,color_hex),'
            'subtasks(id,title,order_index,estimated_minutes,is_completed)',
          )
          .eq('user_id', user)
          .eq('id', id)
          .single(),
    );
  }

  Future<List<TaskProject>> projects() async {
    final user = await inbox.ensureUserId();
    final result = <TaskProject>[];
    for (var offset = 0; ; offset += 100) {
      final rows = await client
          .from('projects')
          .select('id,name')
          .eq('user_id', user)
          .eq('status', 'ACTIVE')
          .order('name')
          .order('id')
          .range(offset, offset + 99);
      result.addAll(rows.map(TaskProject.fromJson));
      if (rows.length < 100) return result;
    }
  }

  Future<String> create(Map<String, dynamic> payload) async {
    await inbox.ensureUserId();
    return await client
            .rpc('create_task_with_steps', params: payload)
            .timeout(const Duration(seconds: 15))
        as String;
  }

  Future<List<TaskProject>> focusChoices() async {
    final user = await inbox.ensureUserId();
    final result = <TaskProject>[];
    for (var offset = 0; ; offset += 100) {
      final rows = await client
          .from('tasks')
          .select('id,name:title')
          .eq('user_id', user)
          .eq('is_archived', false)
          .inFilter('status', ['TODO', 'IN_PROGRESS'])
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + 99);
      result.addAll(rows.map(TaskProject.fromJson));
      if (rows.length < 100) return result;
    }
  }

  Future<void> completeStep(String task, String step, bool value) async {
    await inbox.ensureUserId();
    await client.rpc(
      'set_task_step_complete',
      params: {'p_task': task, 'p_step': step, 'p_complete': value},
    );
  }
}
