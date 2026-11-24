import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/supabase_client_provider.dart';
import '../data/inbox_repository.dart';
import '../domain/inbox_task.dart';

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => InboxRepository(ref.watch(supabaseClientProvider)),
);

final inboxProvider = FutureProvider.autoDispose<List<InboxTask>>(
  (ref) => ref.watch(inboxRepositoryProvider).fetch(),
  // Errors need an explicit retry; do not repeatedly create guest sessions.
  retry: (retryCount, error) => null,
);
