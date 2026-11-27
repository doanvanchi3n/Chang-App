import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/app_layout.dart';
import '../../../app/widgets/choice_sheet.dart';
import '../../../app/widgets/feature_surface.dart';
import '../../tasks/presentation/task_detail_page.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

IconData _kindIcon(NotificationKind kind) => switch (kind) {
  NotificationKind.task => Icons.checklist_rounded,
  NotificationKind.schedule => Icons.calendar_month_outlined,
  NotificationKind.milestone => Icons.emoji_events_outlined,
  NotificationKind.assistant => Icons.auto_awesome_outlined,
  NotificationKind.system => Icons.notifications_outlined,
};

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});
  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with WidgetsBindingObserver {
  bool _unreadOnly = false, _markingAll = false;
  NotificationKind? _kind;
  final _busy = <String>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationListProvider);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(notificationListProvider);
    try {
      await ref.read(notificationListProvider.future);
    } catch (_) {
      /* Render error below. */
    }
  }

  void _writeError() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Chưa xác nhận được trạng thái đã đọc. Kiểm tra kết nối rồi thử lại.',
      ),
    ),
  );
  Future<void> _markAll() async {
    if (_markingAll || _busy.isNotEmpty) return;
    setState(() => _markingAll = true);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      if (mounted) await _refresh();
    } catch (_) {
      if (mounted) _writeError();
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _open(AppNotification item) async {
    if (_markingAll || _busy.isNotEmpty) return;
    setState(() => _busy.add(item.id));
    try {
      if (!item.isRead) {
        try {
          await ref.read(notificationRepositoryProvider).markRead(item.id);
          if (mounted) ref.invalidate(notificationListProvider);
        } catch (_) {
          if (mounted) _writeError();
        }
      }
      if (!mounted) return;
      if (item.taskId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => TaskDetailPage(taskId: item.taskId!),
          ),
        );
      } else {
        await showModalBottomSheet<void>(
          context: context,
          useSafeArea: true,
          showDragHandle: true,
          isScrollControlled: true,
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          builder: (context) => SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .8,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: changInk,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đóng thông báo',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.kind.label} · ${_time(item.deliveredAt)}',
                      style: const TextStyle(color: changMuted),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: changInk,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  String _time(DateTime timestamp) {
    final local = timestamp.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '${local.day}/${local.month}/${local.year} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationListProvider);
    return FeatureSurface(
      title: 'Thông báo',
      onBack: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go('/');
        }
      },
      trailing: IconButton(
        tooltip: 'Làm mới thông báo',
        onPressed: _refresh,
        icon: const Icon(Icons.refresh),
      ),
      child: notifications.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Đang tải thông báo',
            ),
          ),
        ),
        error: (_, _) => FeatureCard(
          color: changSoft,
          child: Column(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40, color: changMuted),
              const SizedBox(height: 12),
              const Text(
                'Chưa tải được thông báo. Kiểm tra kết nối và quyền truy cập Supabase rồi thử lại.',
                textAlign: TextAlign.center,
                style: TextStyle(color: changMuted),
              ),
              TextButton(onPressed: _refresh, child: const Text('Thử lại')),
            ],
          ),
        ),
        data: (items) {
          final unread = items.where((item) => !item.isRead).length;
          final visible = items
              .where(
                (item) =>
                    (!_unreadOnly || !item.isRead) &&
                    (_kind == null || item.kind == _kind),
              )
              .toList();
          final today = DateUtils.dateOnly(DateTime.now());
          final groups = <String, List<AppNotification>>{};
          for (final item in visible) {
            final label =
                DateUtils.dateOnly(item.deliveredAt.toLocal()) == today
                ? 'Hôm nay'
                : 'Trước đó';
            groups.putIfAbsent(label, () => []).add(item);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: changSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: changBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        unread == 0
                            ? 'Bạn đã đọc hết thông báo.'
                            : 'Bạn có $unread thông báo chưa đọc.',
                        style: const TextStyle(
                          color: changInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: unread == 0 || _markingAll || _busy.isNotEmpty
                      ? null
                      : _markAll,
                  icon: const Icon(Icons.done_all),
                  label: Text(
                    _markingAll ? 'Đang cập nhật…' : 'Đánh dấu tất cả đã đọc',
                  ),
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: !_unreadOnly,
                    onSelected: (_) => setState(() => _unreadOnly = false),
                  ),
                  ChoiceChip(
                    label: Text('Chưa đọc $unread'),
                    selected: _unreadOnly,
                    onSelected: (_) => setState(() => _unreadOnly = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ChoiceField(
                label: 'Loại thông báo',
                value: _kind?.label ?? 'Tất cả loại',
                icon: Icons.filter_list,
                onTap: () async {
                  final selected = await showChangChoices(
                    context,
                    title: 'Loại thông báo',
                    subtitle: 'Chọn nội dung bạn muốn xem.',
                    selected: _kind?.dbValue ?? '',
                    choices: [
                      const ChangChoice(
                        '',
                        'Tất cả loại',
                        icon: Icons.notifications_outlined,
                      ),
                      for (final kind in NotificationKind.values)
                        ChangChoice(
                          kind.dbValue,
                          kind.label,
                          icon: _kindIcon(kind),
                        ),
                    ],
                  );
                  if (mounted && selected != null) {
                    setState(
                      () => _kind = selected.isEmpty
                          ? null
                          : NotificationKind.fromDb(selected),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              if (visible.isEmpty)
                FeatureCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        color: changMuted,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        items.isEmpty
                            ? 'Chưa có thông báo'
                            : 'Không có thông báo phù hợp',
                        style: const TextStyle(
                          color: changInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Các thông báo mới sẽ xuất hiện tại đây.',
                        style: TextStyle(color: changMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              for (final group in groups.entries) ...[
                Text(
                  group.key,
                  style: const TextStyle(
                    color: changInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in group.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _card(item),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _card(AppNotification item) => Material(
    color: item.isRead ? Colors.white : changSoft,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: changBorder),
    ),
    child: InkWell(
      onTap: _markingAll || _busy.isNotEmpty ? null : () => _open(item),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(_kindIcon(item.kind), color: changBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: changInk,
                      fontSize: 16,
                      fontWeight: item.isRead
                          ? FontWeight.w600
                          : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: changMuted, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        _time(item.deliveredAt),
                        style: const TextStyle(color: changMuted, fontSize: 12),
                      ),
                      if (!item.isRead)
                        const Text(
                          '● Chưa đọc',
                          style: TextStyle(
                            color: changBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
