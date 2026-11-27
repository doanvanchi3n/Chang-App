import '../../../../app/widgets/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/daily_plan.dart';
import 'inbox_widgets.dart';

Future<Set<String>?> showPlanTaskPicker(
  BuildContext context, {
  required List<PlanningTask> tasks,
  required String today,
}) => showModalBottomSheet<Set<String>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    side: BorderSide(color: inboxBorder),
  ),
  clipBehavior: Clip.antiAlias,
  constraints: const BoxConstraints(maxWidth: AppLayout.maxSheetWidth),
  builder: (_) => _TaskPicker(tasks: tasks, today: today),
);

class _TaskPicker extends StatefulWidget {
  const _TaskPicker({required this.tasks, required this.today});
  final List<PlanningTask> tasks;
  final String today;

  @override
  State<_TaskPicker> createState() => _TaskPickerState();
}

class _TaskPickerState extends State<_TaskPicker> {
  final _selected = <String>{};

  void _toggle(String id) => setState(() {
    if (!_selected.add(id)) _selected.remove(id);
  });

  @override
  Widget build(BuildContext context) {
    final inbox = widget.tasks
        .where((task) => task.scheduledDate == null)
        .toList();
    final unfinished = widget.tasks
        .where(
          (task) =>
              task.scheduledDate != null && task.scheduledDate != widget.today,
        )
        .toList();
    final today = widget.tasks
        .where((task) => task.scheduledDate == widget.today)
        .toList();
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Chọn thêm việc',
                            style: TextStyle(
                              color: inboxInk,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Đóng danh sách chọn việc',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F7FD),
                          ),
                          icon: const Icon(
                            Icons.close,
                            color: inboxMuted,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Thêm một việc nhỏ, tiến thêm một chặng.',
                      style: TextStyle(
                        color: inboxMuted,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PickerMessage(empty: widget.tasks.isEmpty),
                    if (widget.tasks.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            '${widget.tasks.length} việc có thể thêm',
                            style: const TextStyle(
                              color: inboxMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              if (_selected.length == widget.tasks.length) {
                                _selected.clear();
                              } else {
                                _selected.addAll(
                                  widget.tasks.map((task) => task.id),
                                );
                              }
                            }),
                            style: TextButton.styleFrom(
                              foregroundColor: inboxBlue,
                            ),
                            child: Text(
                              _selected.length == widget.tasks.length
                                  ? 'Bỏ chọn tất cả'
                                  : 'Chọn tất cả',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (inbox.isNotEmpty)
                      ..._group('Hộp việc', Icons.inbox_outlined, inbox),
                    if (unfinished.isNotEmpty)
                      ..._group(
                        'Chặng còn dang dở',
                        Icons.history_rounded,
                        unfinished,
                      ),
                    if (today.isNotEmpty)
                      ..._group(
                        'Kế hoạch hôm nay',
                        Icons.today_outlined,
                        today,
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: inboxBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      widget.tasks.isEmpty
                          ? 'Bạn có thể ghi lại việc mới trong Hộp việc.'
                          : _selected.isEmpty
                          ? 'Chọn những việc vừa sức với bạn hôm nay.'
                          : 'Đã chọn ${_selected.length} việc · Bạn có thể chỉnh thời lượng ở bước tiếp theo.',
                      style: const TextStyle(
                        color: inboxMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () =>
                              Navigator.of(context)
                                  .pop(Set<String>.of(_selected)),
                    style: FilledButton.styleFrom(
                      backgroundColor: inboxBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: inboxSoft,
                      disabledForegroundColor: inboxMuted,
                      minimumSize: const Size.fromHeight(52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _selected.isEmpty
                                ? 'Chọn việc để tiếp tục'
                                : 'Thêm ${_selected.length} việc vào kế hoạch',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _group(
    String title,
    IconData icon,
    List<PlanningTask> tasks,
  ) => [
    Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: inboxBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: inboxInk,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: inboxSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${tasks.length}',
              style: const TextStyle(color: inboxMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    ),
    for (final task in tasks)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _PickerTaskCard(
          task: task,
          selected: _selected.contains(task.id),
          today: widget.today,
          onToggle: () => _toggle(task.id),
        ),
      ),
  ];
}

class _PickerMessage extends StatelessWidget {
  const _PickerMessage({required this.empty});
  final bool empty;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5D7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final mascot = SvgPicture.asset(
          'assets/mascot/checktask.svg',
          width: 80,
          height: 88,
          excludeFromSemantics: true,
        );
        final message = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              empty
                  ? 'Một khoảng trống để nghỉ ngơi.'
                  : 'Đi từng việc, nhẹ từng chặng.',
              style: const TextStyle(
                color: inboxInk,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              empty
                  ? 'Chưa có việc nào để thêm. Bạn có thể ghi lại ý tưởng mới trong Hộp việc.'
                  : 'Chọn từ Hộp việc hoặc tiếp tục những việc còn dang dở.',
              style: const TextStyle(
                color: inboxMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        );
        if (constraints.maxWidth < 260 ||
            MediaQuery.textScalerOf(context).scale(16) > 22) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [mascot, const SizedBox(height: 8), message],
          );
        }
        return Row(
          children: [
            Expanded(child: message),
            const SizedBox(width: 12),
            mascot,
          ],
        );
      },
    ),
  );
}

class _PickerTaskCard extends StatelessWidget {
  const _PickerTaskCard({
    required this.task,
    required this.selected,
    required this.today,
    required this.onToggle,
  });
  final PlanningTask task;
  final bool selected;
  final String today;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(task.scheduledDate ?? '');
    final source = date == null
        ? 'Chưa lên lịch'
        : task.scheduledDate == today
        ? 'Đã có trong hôm nay'
        : 'Còn lại từ ${date.day}/${date.month}/${date.year}';
    return Material(
      color: selected ? inboxSoft : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? inboxBlue : inboxBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) => onToggle(),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: inboxBlue,
        checkColor: Colors.white,
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(
          task.title,
          style: const TextStyle(
            color: inboxInk,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            task.minutes == null
                ? source
                : '$source · ${task.minutes} phút dự kiến',
            style: const TextStyle(
              color: inboxMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
