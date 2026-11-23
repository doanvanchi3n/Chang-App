import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/inbox_task.dart';
import '../providers/inbox_provider.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key, this.onScheduledForToday});

  final void Function(List<InboxTask> scheduledTasks)? onScheduledForToday;

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  final TextEditingController _quickAddController = TextEditingController();
  final FocusNode _quickAddFocusNode = FocusNode();

  @override
  void dispose() {
    _quickAddController.dispose();
    _quickAddFocusNode.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final text = _quickAddController.text.trim();
    if (text.isNotEmpty) {
      ref.read(inboxTasksProvider.notifier).quickAdd(text);
      _quickAddController.clear();
      _quickAddFocusNode.unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm "$text" vào Hộp việc.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEditTaskDialog(InboxTask task) {
    final editController = TextEditingController(text: task.title);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Sửa tên công việc',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D253C),
            ),
          ),
          content: TextField(
            controller: editController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Tên công việc',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E67C6),
                shape: const StadiumBorder(),
              ),
              onPressed: () {
                final newTitle = editController.text.trim();
                if (newTitle.isNotEmpty) {
                  ref
                      .read(inboxTasksProvider.notifier)
                      .updateTaskTitle(task.id, newTitle);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(inboxTasksProvider);
    final selectedCount = tasks.where((t) => t.isSelected).length;
    final areAllSelected = tasks.isNotEmpty && tasks.every((t) => t.isSelected);

    return Scaffold(
      backgroundColor: const Color(0xFFFEFDF9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    children: [
                      _InboxTopHeader(
                        onAvatarTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Hồ sơ học tập của Chiến (M08)'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Hộp việc',
                        style: TextStyle(
                          color: Color(0xFF0D253C),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ghi lại trước, chọn lúc làm sau.',
                        style: TextStyle(
                          color: Color(0xFF5D7189),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _QuickInputBar(
                        controller: _quickAddController,
                        focusNode: _quickAddFocusNode,
                        onSubmitted: (_) => _handleAdd(),
                        onAddPressed: _handleAdd,
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFF1E67C6),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Chưa cần chọn ngày hoặc giờ.',
                            style: TextStyle(
                              color: Color(0xFF5D7189),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _MascotSpeechBanner(),
                      const SizedBox(height: 24),
                      Text(
                        'Chưa lên kế hoạch · ${tasks.length} việc',
                        style: const TextStyle(
                          color: Color(0xFF0D253C),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (tasks.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F7FC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2EAF4)),
                          ),
                          alignment: Alignment.center,
                          child: const Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Color(0xFF1E67C6),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Hộp việc đang trống',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF0D253C),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Hãy ghi lại những việc bạn cần làm ở trên nhé!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5D7189),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        _InboxCardList(
                          tasks: tasks,
                          selectedCount: selectedCount,
                          areAllSelected: areAllSelected,
                          onToggleAll: () {
                            ref
                                .read(inboxTasksProvider.notifier)
                                .toggleSelectAll();
                          },
                          onToggleTask: (id) {
                            ref
                                .read(inboxTasksProvider.notifier)
                                .toggleSelect(id);
                          },
                          onEditTask: _showEditTaskDialog,
                          onDeleteTask: (id) {
                            ref
                                .read(inboxTasksProvider.notifier)
                                .deleteTask(id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xóa việc khỏi Hộp việc.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                _StickyBottomActionBar(
                  selectedCount: selectedCount,
                  onScheduleToday: () {
                    if (selectedCount == 0) return;
                    final scheduledTasks = ref
                        .read(inboxTasksProvider.notifier)
                        .scheduleSelectedForToday();
                    widget.onScheduledForToday?.call(scheduledTasks);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. TOP HEADER (WORDMARK + AVATAR)
// ---------------------------------------------------------------------------
class _InboxTopHeader extends StatelessWidget {
  const _InboxTopHeader({required this.onAvatarTap});
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppConstants.name.toLowerCase(),
              style: const TextStyle(
                color: Color(0xFF0D253C),
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFA0C6EF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFFAC858),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF2763A8),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFF7B6A4),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'C',
              style: TextStyle(
                color: Color(0xFF0D253C),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. QUICK INPUT BAR ("Bạn cần làm gì?" + "+ Ghi lại")
// ---------------------------------------------------------------------------
class _QuickInputBar extends StatelessWidget {
  const _QuickInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onAddPressed,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD0E2F6), width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF5D7189),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: const Key('inbox-quick-add'),
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: onSubmitted,
                    style: const TextStyle(
                      color: Color(0xFF0D253C),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Bạn cần làm gì?',
                      hintStyle: TextStyle(
                        color: Color(0xFF8B9BB0),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          key: const Key('inbox-quick-add-submit'),
          onPressed: onAddPressed,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ghi lại'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1E67C6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. MASCOT & SPEECH BUBBLE BANNER
// ---------------------------------------------------------------------------
class _MascotSpeechBanner extends StatelessWidget {
  const _MascotSpeechBanner();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mascotWidth = (constraints.maxWidth * 0.36).clamp(112.0, 152.0);
        final mascotHeight = mascotWidth * 0.86;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: mascotWidth,
              height: mascotHeight,
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.42),
                  child: SizedBox(
                    width: 550,
                    height: 430,
                    child: SvgPicture.asset(
                      'assets/mascot/checktask.svg',
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      semanticsLabel: 'Linh vật chim cánh cụt Chặng cầm sổ tay ghi chú công việc',
                      placeholderBuilder: (_) => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: const Size(10, 18),
                    painter: _SpeechTailPainter(),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Bạn quyết định việc nào cần làm hôm nay.',
                        style: TextStyle(
                          color: Color(0xFF0D253C),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpeechTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEAF3FC);
    final path = Path()
      ..moveTo(size.width, 2)
      ..lineTo(0, size.height * 0.55)
      ..lineTo(size.width, size.height - 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 4. INBOX CARD LIST
// ---------------------------------------------------------------------------
class _InboxCardList extends StatelessWidget {
  const _InboxCardList({
    required this.tasks,
    required this.selectedCount,
    required this.areAllSelected,
    required this.onToggleAll,
    required this.onToggleTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final List<InboxTask> tasks;
  final int selectedCount;
  final bool areAllSelected;
  final VoidCallback onToggleAll;
  final ValueChanged<String> onToggleTask;
  final ValueChanged<InboxTask> onEditTask;
  final ValueChanged<String> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E6F8), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header chọn tất cả
          InkWell(
            onTap: onToggleAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFE4F0FD),
              child: Row(
                children: [
                  _CustomCheckbox(
                    isChecked: areAllSelected,
                    onTap: onToggleAll,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Đã chọn $selectedCount việc',
                    style: const TextStyle(
                      color: Color(0xFF0D253C),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Danh sách các công việc
          for (int i = 0; i < tasks.length; i++) ...[
            _InboxTaskItemRow(
              task: tasks[i],
              onToggle: () => onToggleTask(tasks[i].id),
              onEdit: () => onEditTask(tasks[i]),
              onDelete: () => onDeleteTask(tasks[i].id),
            ),
            if (i < tasks.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2EDF9),
                indent: 48,
              ),
          ],
        ],
      ),
    );
  }
}

class _InboxTaskItemRow extends StatelessWidget {
  const _InboxTaskItemRow({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final InboxTask task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CustomCheckbox(isChecked: task.isSelected, onTap: onToggle),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Color(0xFF0D253C),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        size: 14,
                        color: Color(0xFF1E67C6),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        task.recordedDateText,
                        style: const TextStyle(
                          color: Color(0xFF5D7189),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF0D253C),
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Sửa tên'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomCheckbox extends StatelessWidget {
  const _CustomCheckbox({required this.isChecked, required this.onTap});
  final bool isChecked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isChecked,
      inMutuallyExclusiveGroup: false,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isChecked ? const Color(0xFF1E67C6) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF1E67C6), width: 1.8),
          ),
          alignment: Alignment.center,
          child: isChecked
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. STICKY BOTTOM ACTION BAR ("Đã chọn X việc" + "Lên kế hoạch hôm nay")
// ---------------------------------------------------------------------------
class _StickyBottomActionBar extends StatelessWidget {
  const _StickyBottomActionBar({
    required this.selectedCount,
    required this.onScheduleToday,
  });

  final int selectedCount;
  final VoidCallback onScheduleToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFEFDF9),
        border: Border(top: BorderSide(color: Color(0xFFECEFF4), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Đã chọn $selectedCount việc',
              style: const TextStyle(
                color: Color(0xFF0D253C),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FilledButton.icon(
              key: const Key('inbox-schedule-today'),
              onPressed: selectedCount > 0 ? onScheduleToday : null,
              icon: const Icon(Icons.event_available_outlined, size: 18),
              label: const Text('Lên kế hoạch hôm nay'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E67C6),
                disabledBackgroundColor: const Color(0xFFB5D1F2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
