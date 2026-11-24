import 'dart:convert';

import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _userId = '11111111-1111-4111-8111-111111111111';
const _taskId = '22222222-2222-4222-8222-222222222222';

http.Response _json(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _guest() => _json({
  'access_token': 'test-access-token',
  'refresh_token': 'test-refresh-token',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': _userId,
    'app_metadata': {},
    'user_metadata': {},
    'aud': 'authenticated',
    'created_at': '2026-11-23T00:00:00Z',
    'is_anonymous': true,
  },
});

SupabaseClient _client(Future<http.Response> Function(http.Request) handler) =>
    SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(handler),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

void main() {
  test('Chỉ truy vấn Inbox của phiên khách và tái sử dụng phiên', () async {
    var signIns = 0;
    final client = _client((request) async {
      if (request.url.path == '/auth/v1/signup') {
        signIns++;
        return _guest();
      }
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/tasks');
      expect(request.url.queryParameters['user_id'], 'eq.$_userId');
      expect(request.url.queryParameters['scheduled_date'], 'is.null');
      expect(request.url.queryParameters['is_archived'], 'eq.false');
      expect(request.url.queryParameters['status'], 'in.(TODO,IN_PROGRESS)');
      return _json([]);
    });
    addTearDown(client.dispose);
    final repository = InboxRepository(client);
    expect(await repository.fetch(), isEmpty);
    expect(await repository.fetch(), isEmpty);
    expect(signIns, 1);
  });

  test('Thêm việc ghi user_id, tên đã trim và scheduled_date null', () async {
    final client = _client((request) async {
      if (request.url.path == '/auth/v1/signup') return _guest();
      expect(request.method, 'POST');
      expect(jsonDecode(request.body), {
        'user_id': _userId,
        'title': 'Đọc bài mới',
        'scheduled_date': null,
        'status': 'TODO',
        'is_archived': false,
      });
      return _json({
        'id': _taskId,
        'title': 'Đọc bài mới',
        'created_at': '2026-11-23T00:00:00Z',
      }, 201);
    });
    addTearDown(client.dispose);
    final task = await InboxRepository(client).add('  Đọc bài mới  ');
    expect(task.id, _taskId);
    expect(task.title, 'Đọc bài mới');
  });

  test('Tên rỗng hoặc quá dài không gửi request tới Supabase', () async {
    final client = _client(
      (_) async => throw StateError('Không được gọi mạng'),
    );
    addTearDown(client.dispose);
    final repository = InboxRepository(client);
    await expectLater(repository.add('  '), throwsArgumentError);
    await expectLater(
      repository.add(List.filled(201, 'a').join()),
      throwsArgumentError,
    );
  });

  test('Lỗi Supabase được trả về, không thay bằng dữ liệu mẫu', () async {
    final client = _client((request) async {
      if (request.url.path == '/auth/v1/signup') return _guest();
      return _json({'code': '42501', 'message': 'permission denied'}, 403);
    });
    addTearDown(client.dispose);
    await expectLater(
      InboxRepository(client).fetch(),
      throwsA(isA<PostgrestException>()),
    );
  });
}
