import 'dart:convert';

import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:chang_app/features/tasks/data/task_detail_repository.dart';
import 'package:chang_app/features/tasks/domain/task_detail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _userId = '11111111-1111-4111-8111-111111111111';
const _taskId = '22222222-2222-4222-8222-222222222222';
const _subtaskId = '33333333-3333-4333-8333-333333333333';

http.Response _json(
  Object? value, {
  http.Request? request,
  int status = 200,
}) => http.Response(
  jsonEncode(value),
  status,
  request: request,
  headers: {'content-type': 'application/json'},
);

http.Response _guest(http.Request request) => _json({
  'access_token': 'test-access-token',
  'refresh_token': 'test-refresh-token',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': _userId,
    'app_metadata': {},
    'user_metadata': {},
    'aud': 'authenticated',
    'created_at': '2026-11-24T00:00:00Z',
    'is_anonymous': true,
  },
}, request: request);

Map<String, dynamic> _taskJson({
  int progress = 40,
  String status = 'IN_PROGRESS',
  List<Map<String, dynamic>>? subtasks,
}) => {
  'id': _taskId,
  'title': 'Phác thảo luồng đăng ký',
  'description': 'Thiết kế luồng đăng ký tài khoản cho ứng dụng Chặng.',
  'priority': 'HIGH',
  'due_date': '2026-10-09T00:00:00Z',
  'scheduled_date': '2026-10-09',
  'status': status,
  'is_archived': false,
  'progress_percentage': progress,
  'estimated_minutes': 25,
  'updated_at': '2026-10-08T10:00:00Z',
  'projects': {'id': 'proj-1', 'name': 'UI/UX', 'color_hex': '#345D83'},
  'subtasks':
      subtasks ??
      [
        {
          'id': _subtaskId,
          'task_id': _taskId,
          'title': 'Xác định người dùng',
          'order_index': 1,
          'estimated_minutes': 25,
          'is_completed': false,
          'completed_at': null,
        },
      ],
};

SupabaseClient _client(Future<http.Response> Function(http.Request) handler) =>
    SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(handler),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

void main() {
  test('fetchById truy vấn đúng task theo id + user_id và ánh xạ đủ trường', () async {
    final client = _client((request) async {
      if (request.url.path == '/auth/v1/signup') return _guest(request);
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/tasks');
      expect(request.url.queryParameters['id'], 'eq.$_taskId');
      expect(request.url.queryParameters['user_id'], 'eq.$_userId');
      return _json(_taskJson(), request: request);
    });
    addTearDown(client.dispose);

    final repo = TaskDetailRepository(client, InboxRepository(client));
    final task = await repo.fetchById(_taskId);
    expect(task, isNotNull);
    expect(task!.title, 'Phác thảo luồng đăng ký');
    expect(task.priority, TaskPriority.high);
    expect(task.project?.name, 'UI/UX');
    expect(task.subtasks, hasLength(1));
  });

  test('toggleSubtask cập nhật is_completed/completed_at và tải lại tiến độ mới', () async {
    var patched = false;
    final client = _client((request) async {
      if (request.url.path == '/auth/v1/signup') return _guest(request);
      if (request.method == 'PATCH' && request.url.path == '/rest/v1/subtasks') {
        patched = true;
        expect(request.url.queryParameters['id'], 'eq.$_subtaskId');
        expect(request.url.queryParameters['task_id'], 'eq.$_taskId');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['is_completed'], isTrue);
        expect(body['completed_at'], isNotNull);
        return _json({'id': _subtaskId}, request: request);
      }
      expect(request.method, 'GET');
      return _json(
        _taskJson(
          progress: 100,
          status: 'COMPLETED',
          subtasks: [
            {
              'id': _subtaskId,
              'task_id': _taskId,
              'title': 'Xác định người dùng',
              'order_index': 1,
              'estimated_minutes': 25,
              'is_completed': true,
              'completed_at': '2026-10-08T12:00:00Z',
            },
          ],
        ),
        request: request,
      );
    });
    addTearDown(client.dispose);

    final repo = TaskDetailRepository(client, InboxRepository(client));
    final updated = await repo.toggleSubtask(
      taskId: _taskId,
      subtaskId: _subtaskId,
      isCompleted: true,
    );
    expect(patched, isTrue);
    expect(updated.computedProgressPercentage, 100);
    expect(updated.status, TaskStatus.completed);
  });

  test('addSubtask chặn vượt quá 5 bước hoặc tên rỗng trước khi gọi mạng', () async {
    final client = _client(
      (_) async => throw StateError('Không được gửi request khi dữ liệu sai'),
    );
    addTearDown(client.dispose);

    final repo = TaskDetailRepository(client, InboxRepository(client));
    await expectLater(
      repo.addSubtask(taskId: _taskId, title: '   ', orderIndex: 1),
      throwsArgumentError,
    );
    await expectLater(
      repo.addSubtask(taskId: _taskId, title: 'Bước thứ 6', orderIndex: 6),
      throwsArgumentError,
    );
    await expectLater(
      repo.addSubtask(
        taskId: _taskId,
        title: 'Bước hợp lệ',
        orderIndex: 2,
        estimatedMinutes: 0,
      ),
      throwsArgumentError,
    );
  });

  test('addSubtask ghi đúng payload và tải lại danh sách bước', () async {
    var inserted = false;
    final client = _client((request) async {
      if (request.url.path == '/auth/v1/signup') return _guest(request);
      if (request.method == 'POST' && request.url.path == '/rest/v1/subtasks') {
        inserted = true;
        expect(jsonDecode(request.body), {
          'task_id': _taskId,
          'title': 'Kiểm thử luồng lỗi',
          'order_index': 2,
          'estimated_minutes': 30,
          'is_completed': false,
        });
        return _json({'id': 'sub-new'}, request: request, status: 201);
      }
      return _json(
        _taskJson(
          subtasks: [
            {
              'id': _subtaskId,
              'task_id': _taskId,
              'title': 'Xác định người dùng',
              'order_index': 1,
              'estimated_minutes': 25,
              'is_completed': false,
              'completed_at': null,
            },
            {
              'id': 'sub-new',
              'task_id': _taskId,
              'title': 'Kiểm thử luồng lỗi',
              'order_index': 2,
              'estimated_minutes': 30,
              'is_completed': false,
              'completed_at': null,
            },
          ],
        ),
        request: request,
      );
    });
    addTearDown(client.dispose);

    final repo = TaskDetailRepository(client, InboxRepository(client));
    final updated = await repo.addSubtask(
      taskId: _taskId,
      title: '  Kiểm thử luồng lỗi  ',
      orderIndex: 2,
      estimatedMinutes: 30,
    );
    expect(inserted, isTrue);
    expect(updated.subtasks, hasLength(2));
    expect(updated.subtasks.last.title, 'Kiểm thử luồng lỗi');
  });

  test('Lỗi Supabase được trả về rõ ràng, không dùng dữ liệu mẫu', () async {
    final client = _client((request) async {
      if (request.url.path == '/auth/v1/signup') return _guest(request);
      return _json(
        {'code': '42501', 'message': 'permission denied'},
        request: request,
        status: 403,
      );
    });
    addTearDown(client.dispose);

    final repo = TaskDetailRepository(client, InboxRepository(client));
    await expectLater(
      repo.fetchById(_taskId),
      throwsA(isA<PostgrestException>()),
    );
  });
}
