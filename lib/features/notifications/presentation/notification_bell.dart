import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/feature_surface.dart';
import '../data/notification_repository.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationListProvider);
    final count = notifications.when(
      data: (items) => items.where((item) => !item.isRead).length,
      error: (_, _) => 0,
      loading: () => 0,
    );
    return IconButton(
      tooltip: 'Thông báo',
      onPressed: onPressed,
      icon: Semantics(
        label: notifications.hasError
            ? 'Chưa tải được thông báo'
            : '$count thông báo chưa đọc',
        child: Badge(
          isLabelVisible: count > 0 || notifications.hasError,
          label: Text(
            notifications.hasError
                ? '!'
                : count > 99
                ? '99+'
                : '$count',
          ),
          backgroundColor: notifications.hasError
              ? Theme.of(context).colorScheme.error
              : changBlue,
          child: const Icon(Icons.notifications_none, color: changInk),
        ),
      ),
    );
  }
}
