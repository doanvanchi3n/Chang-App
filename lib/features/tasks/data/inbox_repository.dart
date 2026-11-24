import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/inbox_task.dart';

class InboxRepository {
  InboxRepository(this._client);
  final SupabaseClient _client;
  Future<AuthResponse>? _guestSignIn;

  Future<String> ensureUserId() async {
    final current = _client.auth.currentUser;
    if (current != null) return current.id;
    // Share one request when refresh and quick-add happen at the same time.
    final pending = _guestSignIn ??= _client.auth.signInAnonymously();
    try {
      final response = await pending;
      final user = response.user;
      if (user == null) throw StateError('Không tạo được phiên khách.');
      return user.id;
    } finally {
      if (identical(_guestSignIn, pending)) _guestSignIn = null;
    }
  }

  Future<List<InboxTask>> fetch() async {
    final userId = await ensureUserId();
    final tasks = <InboxTask>[];
    const pageSize = 100;
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('tasks')
          .select('id,title,created_at')
          .eq('user_id', userId)
          .isFilter('scheduled_date', null)
          .eq('is_archived', false)
          .inFilter('status', ['TODO', 'IN_PROGRESS'])
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + pageSize - 1);
      tasks.addAll(rows.map(InboxTask.fromJson));
      if (rows.length < pageSize) return tasks;
    }
  }

  Future<Set<String>> planToday(Iterable<String> taskIds) async {
    final ids = taskIds.toSet();
    if (ids.isEmpty) return <String>{};
    final userId = await ensureUserId();
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    // One update for the selected Inbox rows. Never overwrite another plan,
    // resurrect a completed task, or modify another user's work.
    final rows = await _client
        .from('tasks')
        .update({'scheduled_date': date})
        .eq('user_id', userId)
        .inFilter('id', ids.toList())
        .isFilter('scheduled_date', null)
        .eq('is_archived', false)
        .inFilter('status', ['TODO', 'IN_PROGRESS'])
        .select('id');
    return rows.map((row) => row['id'] as String).toSet();
  }

  Future<InboxTask> add(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.runes.length > 200) {
      throw ArgumentError('Tên việc phải có từ 1 đến 200 ký tự.');
    }
    final userId = await ensureUserId();
    final row = await _client
        .from('tasks')
        .insert({
          'user_id': userId,
          'title': trimmed,
          'scheduled_date': null,
          'status': 'TODO',
          'is_archived': false,
        })
        .select('id,title,created_at')
        .single();
    return InboxTask.fromJson(row);
  }
}
