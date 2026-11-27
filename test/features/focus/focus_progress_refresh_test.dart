import 'dart:convert';

import 'package:chang_app/data/remote/supabase_client_provider.dart';
import 'package:chang_app/features/focus/application/focus_controller.dart';
import 'package:chang_app/features/focus/data/focus_repository.dart';
import 'package:chang_app/features/tasks/data/task_management_repository.dart';
import 'package:chang_app/features/tasks/data/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FocusRepository extends FocusRepository {
  _FocusRepository(super.client);
  final session = <String, dynamic>{
    'id': 'session-1',
    'task_id': 'task-1',
    'status': 'AWAITING_REVIEW',
    'target_duration_seconds': 1500,
    'elapsed_milliseconds': 1500000,
    'revision': 1,
    'ambient_sound': 'SILENT',
    'server_now': '2026-11-27T10:00:00Z',
  };

  @override
  Future<Map<String, dynamic>?> current() async => Map.of(session);

  @override
  Future<Map<String, dynamic>> execute(
    String method,
    Map<String, dynamic> params,
  ) async {
    expect(method, 'control_focus_session');
    expect(params['p_action'], 'SAVE');
    expect(params['p_complete'], true);
    return {...session, 'status': 'COMPLETED'};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Lưu phiên làm mới công việc và lựa chọn phiên kế tiếp', () async {
    SharedPreferences.setMockInitialValues({});
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'access_token': 'test-access-token',
            'refresh_token': 'test-refresh-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': '11111111-1111-4111-8111-111111111111',
              'app_metadata': {},
              'user_metadata': {},
              'aud': 'authenticated',
              'created_at': '2026-11-27T00:00:00Z',
              'is_anonymous': true,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );
    addTearDown(client.dispose);
    await client.auth.signInAnonymously();
    var taskReads = 0, choiceReads = 0;
    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
        focusRepositoryProvider.overrideWithValue(_FocusRepository(client)),
        taskListProvider.overrideWith((ref) async {
          taskReads++;
          return [];
        }),
        focusTaskChoicesProvider.overrideWith((ref) async {
          choiceReads++;
          return [];
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(taskListProvider, (_, _) {});
    container.listen(focusTaskChoicesProvider, (_, _) {});
    await container.read(taskListProvider.future);
    await container.read(focusTaskChoicesProvider.future);
    container.listen(focusControllerProvider, (_, _) {});
    await container.read(focusControllerProvider.notifier).restore();
    expect(container.read(focusControllerProvider).session?.reviewing, true);

    final saved = await container
        .read(focusControllerProvider.notifier)
        .command('SAVE', complete: true);
    expect(saved, true);
    await container.read(taskListProvider.future);
    await container.read(focusTaskChoicesProvider.future);
    expect(taskReads, 2);
    expect(choiceReads, 2);
  });
}
