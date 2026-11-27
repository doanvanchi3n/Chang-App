import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/remote/supabase_client_provider.dart';
import '../../tasks/data/inbox_repository.dart';
import '../../tasks/presentation/inbox_provider.dart';
import '../domain/app_notification.dart';

final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(inboxRepositoryProvider),
  ),
);
final notificationListProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) {
      final timer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => ref.invalidateSelf(),
      );
      ref.onDispose(timer.cancel);
      return ref.watch(notificationRepositoryProvider).list();
    }, retry: (_, _) => null);

class NotificationRepository {
  NotificationRepository(this.client, this.inbox);
  final SupabaseClient client;
  final InboxRepository inbox;
  String _deliveredFilter(DateTime now) =>
      'scheduled_at.is.null,scheduled_at.lte.${now.toUtc().toIso8601String()}';

  Future<List<AppNotification>> list() async {
    final user = await inbox.ensureUserId();
    final filter = _deliveredFilter(DateTime.now());
    final result = <AppNotification>[];
    for (var offset = 0; ; offset += 100) {
      final rows = await client
          .from('notifications')
          .select(
            'id,title,body,type,reference_id,is_read,scheduled_at,created_at',
          )
          .eq('user_id', user)
          .or(filter)
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + 99)
          .timeout(const Duration(seconds: 15));
      result.addAll(rows.map(AppNotification.fromJson));
      if (rows.length < 100) {
        return result..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
      }
    }
  }

  Future<void> markRead(String id) async {
    final user = await inbox.ensureUserId();
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user)
        .eq('id', id)
        .select('id')
        .single()
        .timeout(const Duration(seconds: 15));
  }

  Future<void> markAllRead() async {
    final user = await inbox.ensureUserId();
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user)
        .eq('is_read', false)
        .or(_deliveredFilter(DateTime.now()))
        .timeout(const Duration(seconds: 15));
  }
}
