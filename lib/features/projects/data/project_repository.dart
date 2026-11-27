import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/remote/supabase_client_provider.dart';
import '../../tasks/data/inbox_repository.dart';
import '../../tasks/presentation/inbox_provider.dart';
import '../domain/study_project.dart';

final projectRepositoryProvider = Provider(
  (ref) => ProjectRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(inboxRepositoryProvider),
  ),
);
final projectListProvider = FutureProvider.autoDispose<List<StudyProject>>(
  (ref) => ref.watch(projectRepositoryProvider).list(),
  retry: (_, _) => null,
);

class ProjectRepository {
  ProjectRepository(this.client, this.inbox);
  final SupabaseClient client;
  final InboxRepository inbox;
  Future<List<StudyProject>> list() async {
    final user = await inbox.ensureUserId();
    final result = <StudyProject>[];
    for (var offset = 0; ; offset += 100) {
      final rows = await client
          .from('projects')
          .select('id,name,description,deadline,color_hex,icon_name,status')
          .eq('user_id', user)
          .eq('status', 'ACTIVE')
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + 99);
      result.addAll(rows.map(StudyProject.fromJson));
      if (rows.length < 100) return result;
    }
  }

  Future<String> create(Map<String, dynamic> request) async {
    await inbox.ensureUserId();
    return await client
            .rpc('create_study_project', params: request)
            .timeout(const Duration(seconds: 15))
        as String;
  }
}
