import 'dart:convert';

import 'package:chang_app/features/notifications/data/notification_repository.dart';
import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Identity extends InboxRepository {
  _Identity(super.client);
  @override
  Future<String> ensureUserId() async => 'user-1';
}

void main() {
  test('notifications paginate, scope user and hide future delivery', () async {
    var calls = 0;
    String? filter;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        final query = request.url.queryParameters;
        expect(query['user_id'], 'eq.user-1');
        expect(query['offset'], '${calls * 100}');
        expect(query['or'], contains('scheduled_at.is.null,scheduled_at.lte.'));
        filter ??= query['or'];
        expect(query['or'], filter);
        final count = calls++ == 0 ? 100 : 1;
        return http.Response(
          jsonEncode(
            List.generate(
              count,
              (i) => {
                'id': '$calls-$i',
                'title': 'Nhắc ôn tập',
                'body': 'Bắt đầu một bước nhỏ.',
                'type': 'REMINDER_TASK',
                'reference_id': 'task-1',
                'is_read': false,
                'created_at': '2026-11-27T00:00:00Z',
                'scheduled_at': null,
              },
            ),
          ),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final items = await NotificationRepository(
      client,
      _Identity(client),
    ).list();
    expect(items.length, 101);
    expect(items.last.taskId, 'task-1');
  });

  test('read and mark all read only update notifications.is_read owned by current user', () async {
    var calls = 0;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/rest/v1/notifications');
        expect(request.method, 'PATCH');
        expect(request.url.queryParameters['user_id'], 'eq.user-1');
        expect(jsonDecode(request.body), {'is_read': true});
        if (calls++ == 0) {
          expect(request.url.queryParameters['id'], 'eq.n1');
          return http.Response(
            '{"id":"n1"}',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        expect(request.url.queryParameters['is_read'], 'eq.false');
        expect(
          request.url.queryParameters['or'],
          contains('scheduled_at.is.null,scheduled_at.lte.'),
        );
        return http.Response('', 204, request: request);
      }),
    );
    addTearDown(client.dispose);
    final repository = NotificationRepository(client, _Identity(client));
    await repository.markRead('n1');
    await repository.markAllRead();
    expect(calls, 2);
  });
}
