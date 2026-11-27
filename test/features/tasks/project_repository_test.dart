import 'dart:convert';

import 'package:chang_app/features/projects/data/project_repository.dart';
import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:chang_app/features/tasks/data/task_detail_repository.dart';
import 'package:chang_app/features/tasks/domain/task_detail.dart';
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
  test('projects paginate, scope to owner and retain metadata', () async {
    var page = 0;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        expect(request.url.queryParameters['user_id'], 'eq.user-1');
        expect(request.url.queryParameters['status'], 'eq.ACTIVE');
        expect(request.url.queryParameters['offset'], '${page * 100}');
        final rows = List.generate(
          page++ == 0 ? 100 : 1,
          (i) => {
            'id': '$page-$i',
            'name': 'Ôn thi cuối kỳ',
            'description': 'Ôn tập',
            'deadline': '2026-12-15T16:59:59Z',
            'color_hex': '#28B463',
            'icon_name': 'book',
          },
        );
        return http.Response(
          jsonEncode(rows),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final projects = await ProjectRepository(client, _Identity(client)).list();
    expect(projects.length, 101);
    expect(projects.last.iconName, 'book');
    expect(projects.last.description, 'Ôn tập');
    expect(projects.last.deadline, DateTime.utc(2026, 12, 15, 16, 59, 59));
  });

  test(
    'project creation retries send identical UUID and payload to RPC',
    () async {
      final bodies = <String>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/rest/v1/rpc/create_study_project');
          bodies.add(request.body);
          return http.Response(
            '"project-1"',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final repository = ProjectRepository(client, _Identity(client));
      final payload = {
        'p_id': 'project-1',
        'p_name': 'Đồ án UI/UX',
        'p_description': 'Mục tiêu',
        'p_deadline': null,
        'p_color': '#006BFF',
        'p_icon': 'folder',
      };
      expect(await repository.create(payload), 'project-1');
      expect(await repository.create(payload), 'project-1');
      expect(bodies[0], bodies[1]);
      expect(jsonDecode(bodies[0]), payload);
    },
  );

  test('reopen updates task only, preserves steps and receives cleared completion date', () async {
    final writes = <String>[];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.method == 'PATCH') {
          writes.add(request.url.path);
          expect(request.url.queryParameters['user_id'], 'eq.user-1');
          expect(jsonDecode(request.body), {'status': 'IN_PROGRESS'});
          return http.Response(
            '{"id":"t1"}',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'id': 't1',
            'title': 'Việc đã mở lại',
            'status': 'IN_PROGRESS',
            'completed_at': null,
            'subtasks': [
              {
                'id': 's1',
                'title': 'Bước giữ nguyên',
                'order_index': 1,
                'is_completed': true,
              },
            ],
          }),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final reopened = await TaskDetailRepository(client, _Identity(client))
        .setTaskStatus(
          taskId: 't1',
          status: TaskStatus.inProgress,
          hasSubtasks: true,
        );
    expect(writes, ['/rest/v1/tasks']);
    expect(reopened.completedAt, isNull);
    expect(reopened.subtasks.single.isCompleted, isTrue);
  });
}
