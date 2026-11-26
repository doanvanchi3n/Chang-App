import 'dart:convert';

import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:chang_app/features/tasks/data/task_management_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Identity extends InboxRepository {
  _Identity(super.client);
  @override
  Future<String> ensureUserId() async => 'user-1';
}

http.Response json(Object value, http.Request request) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json'},
  request: request,
);
void main() {
  test('list fetches every page scoped to the current user and preserves nested steps', () async {
    var calls = 0;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        final query = request.url.queryParameters;
        expect(query['user_id'], 'eq.user-1');
        expect(query['is_archived'], 'eq.false');
        expect(query['offset'], calls == 0 ? '0' : '100');
        expect(query['limit'], '100');
        final offset = calls++ * 100;
        return json(
          List.generate(
            offset == 0 ? 100 : 1,
            (i) => {
              'id': 'task-${offset + i}',
              'title': 'Việc ${offset + i}',
              'priority': 'MEDIUM',
              'status': 'TODO',
              'is_archived': false,
              'progress_percentage': 0,
              'estimated_minutes': 25,
              'updated_at': '2026-11-24T00:00:00Z',
              'subtasks': [
                {
                  'id': 's-${offset + i}',
                  'task_id': 'task-${offset + i}',
                  'title': 'Một bước',
                  'order_index': 1,
                  'estimated_minutes': 25,
                  'is_completed': false,
                },
              ],
            },
          ),
          request,
        );
      }),
    );
    addTearDown(client.dispose);
    final tasks = await TaskManagementRepository(
      client,
      _Identity(client),
    ).list();
    expect(calls, 2);
    expect(tasks, hasLength(101));
    expect(tasks.last.subtasks.single.taskId, 'task-100');
  });
  test('draft writes call atomic RPCs with their version and stable request unchanged', () async {
    final received = <http.Request>[];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        received.add(request);
        return json('task-1', request);
      }),
    );
    addTearDown(client.dispose);
    final repo = TaskManagementRepository(client, _Identity(client));
    final details = {
      'p_task': 'task-1',
      'p_request': 'request-1',
      'p_expected': '2026-11-24T00:00:00Z',
      'p_fields': {'title': 'Mới'},
    };
    final steps = {
      'p_task': 'task-1',
      'p_request': 'request-2',
      'p_expected': '2026-11-24T00:00:00Z',
      'p_steps': [],
    };
    await repo.saveDetails(details);
    await repo.saveSteps(steps);
    expect(received.map((r) => r.url.path), [
      '/rest/v1/rpc/save_task_details',
      '/rest/v1/rpc/save_task_steps',
    ]);
    expect(jsonDecode(received[0].body), details);
    expect(jsonDecode(received[1].body), steps);
  });
}
