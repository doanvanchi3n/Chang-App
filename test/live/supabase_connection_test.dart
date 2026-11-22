import 'package:chang_app/core/config/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'Publishable key kết nối được bảng tasks qua Supabase SDK',
    () async {
      final client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);

      // limit(0) kiểm tra endpoint mà không tải nội dung công việc.
      final rows = await client
          .from('tasks')
          .select('id')
          .limit(0)
          .timeout(const Duration(seconds: 15));

      expect(client.auth.currentSession, isNull);
      expect(rows, isEmpty);
    },
    skip: !const bool.fromEnvironment('RUN_SUPABASE_CHECK'),
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
