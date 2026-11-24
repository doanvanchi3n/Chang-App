import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/supabase_client_provider.dart';
import '../data/task_detail_repository.dart';
import '../domain/task_detail.dart';
import 'inbox_provider.dart';

final taskDetailRepositoryProvider = Provider<TaskDetailRepository>((ref) {
  return TaskDetailRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(inboxRepositoryProvider),
  );
});

final taskDetailProvider = FutureProvider.autoDispose
    .family<TaskDetail?, String>(
      (ref, taskId) => ref.watch(taskDetailRepositoryProvider).fetchById(taskId),
      retry: (retryCount, error) => null,
    );
