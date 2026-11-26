import '../task_list_page.dart';
import '../../../../app/widgets/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/widgets/main_navigation.dart';
import '../../domain/inbox_task.dart';

const inboxInk = Color(0xFF082451);
const inboxBlue = Color(0xFF006BFF);
const inboxMuted = Color(0xFF4667A6);
const inboxBorder = Color(0xFFD8E7FF);
const inboxSoft = Color(0xFFE6F1FF);

class InboxHeader extends StatelessWidget {
  const InboxHeader({super.key, required this.onRefresh, this.showBack = true});
  final VoidCallback onRefresh;
  final bool showBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (showBack && Navigator.of(context).canPop())
        IconButton(
          tooltip: 'Về Dashboard',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: inboxInk),
        ),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              const Text(
                'chặng',
                style: TextStyle(
                  color: inboxInk,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              for (final color in const [
                Color(0xFF96C6FF),
                Color(0xFFFFC400),
                inboxBlue,
              ])
                Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
      IconButton(
        tooltip: 'Làm mới',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh, color: inboxMuted),
      ),
      const Tooltip(
        message: 'Phiên khách',
        child: CircleAvatar(
          backgroundColor: Color(0xFFFFAA9D),
          foregroundColor: inboxInk,
          child: Icon(Icons.person_outline),
        ),
      ),
    ],
  );
}

class InboxMascotMessage extends StatelessWidget {
  const InboxMascotMessage({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mascot = SvgPicture.asset(
        'assets/mascot/checktask.svg',
        width: constraints.maxWidth < 360 ? 120 : 160,
        height: constraints.maxWidth < 360 ? 110 : 145,
        semanticsLabel: 'Linh vật Chặng ghi chú công việc',
      );
      final message = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: inboxSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text(
          'Bạn quyết định việc nào cần làm hôm nay.',
          style: TextStyle(
            color: inboxInk,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      );
      if (MediaQuery.textScalerOf(context).scale(18) > 26) {
        return Column(children: [mascot, message]);
      }
      return Row(
        children: [
          mascot,
          const SizedBox(width: 4),
          const CustomPaint(size: Size(10, 20), painter: _SpeechPointer()),
          Expanded(child: message),
        ],
      );
    },
  );
}

String inboxRecordedDate(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) return 'Ghi lại hôm nay';
  if (day == DateTime(today.year, today.month, today.day - 1)) {
    return 'Ghi lại hôm qua';
  }
  return 'Ghi lại ${local.day}/${local.month}/${local.year}';
}

class InboxTaskList extends StatelessWidget {
  const InboxTaskList({
    super.key,
    required this.items,
    required this.selected,
    required this.onToggle,
    required this.onToggleAll,
    this.onOpenDetail,
    this.onOpen,
    this.isDesktop = false,
    this.planning = false,
    this.onPlanToday,
    this.onClearSelection,
  });
  final List<InboxTask> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onToggleAll;
  final ValueChanged<String>? onOpenDetail;
  final ValueChanged<String>? onOpen;
  final bool isDesktop;
  final bool planning;
  final VoidCallback? onPlanToday;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    final count = items.where((task) => selected.contains(task.id)).length;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: inboxBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ColoredBox(
            color: isDesktop ? const Color(0xFFF5F8FC) : inboxSoft,
            child: isDesktop
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: count == 0
                                  ? false
                                  : count == items.length
                                  ? true
                                  : null,
                              tristate: true,
                              activeColor: inboxBlue,
                              onChanged: (_) => onToggleAll(),
                            ),
                            Text(
                              'Đã chọn $count việc',
                              style: const TextStyle(
                                color: inboxInk,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          key: const ValueKey('inbox-desktop-plan-button'),
                          onPressed: planning || count == 0
                              ? null
                              : onPlanToday,
                          style: FilledButton.styleFrom(
                            backgroundColor: inboxBlue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(48, 42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: planning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.event_available_outlined,
                                  size: 18,
                                ),
                          label: Text(
                            planning ? 'Đang lưu…' : 'Lên kế hoạch hôm nay',
                          ),
                        ),
                        if (count > 0 && onClearSelection != null)
                          OutlinedButton.icon(
                            onPressed: planning ? null : onClearSelection,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: inboxInk,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: inboxBorder),
                              minimumSize: const Size(48, 42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Bỏ chọn'),
                          ),
                      ],
                    ),
                  )
                : CheckboxListTile(
                    value: count == 0
                        ? false
                        : count == items.length
                        ? true
                        : null,
                    tristate: true,
                    activeColor: inboxBlue,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (_) => onToggleAll(),
                    title: Text(
                      'Đã chọn $count việc',
                      style: const TextStyle(
                        color: inboxInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0 || isDesktop)
              const Divider(height: 1, color: inboxBorder),
            if (isDesktop)
              _buildDesktopRow(context, items[i])
            else
              _buildMobileRow(context, items[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopRow(BuildContext context, InboxTask item) {
    final isSelected = selected.contains(item.id);
    return InkWell(
      key: ValueKey(item.id),
      onTap: () => onToggle(item.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              activeColor: inboxBlue,
              semanticLabel: 'Chọn ${item.title}',
              onChanged: (_) => onToggle(item.id),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                item.title,
                style: TextStyle(
                  color: isSelected ? inboxBlue : inboxInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Icon(
                    Icons.event_note_outlined,
                    size: 16,
                    color: inboxMuted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      inboxRecordedDate(item.createdAt),
                      style: const TextStyle(color: inboxMuted, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            _buildMenu(context, item),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileRow(BuildContext context, InboxTask item) {
    return ListTile(
      key: ValueKey(item.id),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: Checkbox(
        value: selected.contains(item.id),
        activeColor: inboxBlue,
        semanticLabel: 'Chọn ${item.title}',
        onChanged: (_) => onToggle(item.id),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          color: inboxInk,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          inboxRecordedDate(item.createdAt),
          style: const TextStyle(color: inboxMuted),
        ),
      ),
      onTap: () => onToggle(item.id),
      trailing: _buildMenu(context, item),
    );
  }

  Widget _buildMenu(BuildContext context, InboxTask item) {
    return PopupMenuButton<String>(
      tooltip: 'Tùy chọn công việc',
      icon: const Icon(Icons.more_horiz, color: inboxInk),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'details', child: Text('Xem chi tiết')),
      ],
      onSelected: (_) {
        final openCb = onOpenDetail ?? onOpen;
        if (openCb != null) {
          openCb(item.id);
          return;
        }
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(inboxRecordedDate(item.createdAt)),
                  const SizedBox(height: 8),
                  const Text('Chưa lên lịch'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class InboxBottomBar extends StatelessWidget {
  const InboxBottomBar({
    super.key,
    required this.selectedCount,
    this.onPlanToday,
    this.planning = false,
  });
  final int selectedCount;
  final VoidCallback? onPlanToday;
  final bool planning;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: inboxBorder)),
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final label = Text(
                      'Đã chọn $selectedCount việc',
                      style: const TextStyle(
                        color: inboxInk,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                    final button = Tooltip(
                      message: selectedCount == 0
                          ? 'Chọn ít nhất một việc để lên kế hoạch.'
                          : 'Đưa các việc đã chọn vào kế hoạch hôm nay.',
                      child: FilledButton.icon(
                        onPressed: planning || selectedCount == 0
                            ? null
                            : onPlanToday,
                        style: FilledButton.styleFrom(
                          backgroundColor: inboxBlue,
                          foregroundColor: Colors.white,
                        ),
                        icon: planning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  semanticsLabel: 'Đang lưu kế hoạch',
                                ),
                              )
                            : const Icon(Icons.event_available_outlined),
                        label: Text(
                          planning ? 'Đang lưu…' : 'Lên kế hoạch hôm nay',
                        ),
                      ),
                    );
                    if (constraints.maxWidth < 480 ||
                        MediaQuery.textScalerOf(context).scale(14) > 20) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [label, const SizedBox(height: 8), button],
                      );
                    }
                    return Row(
                      children: [
                        label,
                        const SizedBox(width: 16),
                        Expanded(child: button),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        MainNavigation(
          inboxActive: true,
          onInbox: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const TaskListPage()),
          ),
          onHome: Navigator.of(context).canPop()
              ? () => Navigator.of(context).popUntil((route) => route.isFirst)
              : null,
        ),
      ],
    ),
  );
}

class _SpeechPointer extends CustomPainter {
  const _SpeechPointer();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = inboxSoft);
  }

  @override
  bool shouldRepaint(_SpeechPointer oldDelegate) => false;
}
