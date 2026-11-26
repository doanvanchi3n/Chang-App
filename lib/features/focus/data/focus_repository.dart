import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/remote/supabase_client_provider.dart';

final focusRepositoryProvider = Provider(
  (ref) => FocusRepository(ref.watch(supabaseClientProvider)),
);

class FocusRepository {
  FocusRepository(this.client);
  final SupabaseClient client;
  Future<Map<String, dynamic>?> current() async {
    final result = await client
        .rpc('current_focus_session')
        .timeout(const Duration(seconds: 15));
    return result == null ? null : Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> execute(
    String method,
    Map<String, dynamic> params,
  ) async => Map<String, dynamic>.from(
    await client
            .rpc(method, params: params)
            .timeout(const Duration(seconds: 15))
        as Map,
  );
}
