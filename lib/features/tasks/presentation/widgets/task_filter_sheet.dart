import 'package:flutter/material.dart';

import '../../../../app/widgets/app_layout.dart';
import '../../../../app/widgets/choice_sheet.dart';
import '../../../../app/widgets/feature_surface.dart';
import '../../domain/task_detail.dart';
import '../../domain/task_filters.dart';

Future<TaskFilters?> showTaskFilters(
  BuildContext context,
  TaskFilters current,
  List<TaskDetail> tasks,
) => showModalBottomSheet<TaskFilters>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.white,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: AppLayout.maxSheetWidth),
  builder: (_) => _FilterSheet(current: current, tasks: tasks),
);

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.tasks});
  final TaskFilters current;
  final List<TaskDetail> tasks;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _project = widget.current.projectId,
      _status = widget.current.state;
  late TaskPriority? _priority = widget.current.priority;
  late DueFilter _due = widget.current.due;
  static const _statuses = {
    '': 'Tất cả',
    'TODO': 'Chưa làm',
    'IN_PROGRESS': 'Đang làm',
    'COMPLETED': 'Hoàn thành',
    'OVERDUE': 'Quá hạn',
  };
  Future<void> _choose(
    String title,
    String selected,
    List<ChangChoice> values,
    void Function(String) accept,
  ) async {
    final value = await showChangChoices(
      context,
      title: title,
      subtitle: 'Chọn một điều kiện cho danh sách.',
      selected: selected,
      choices: values,
    );
    if (mounted && value != null) setState(() => accept(value));
  }

  @override
  Widget build(BuildContext context) {
    final projects = {
      for (final t in widget.tasks)
        if (t.project != null) t.project!.id: t.project!.name,
    };
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: AppLayout.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Bộ lọc',
                        style: TextStyle(
                          fontSize: 26,
                          color: changInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng bộ lọc',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text(
                  'Chọn điều kiện rồi áp dụng cho danh sách.',
                  style: TextStyle(color: changMuted),
                ),
                const SizedBox(height: 24),
                ChoiceField(
                  label: 'Dự án',
                  icon: Icons.folder_outlined,
                  value: _project == null
                      ? 'Tất cả'
                      : projects[_project] ?? 'Dự án đã chọn',
                  onTap: () => _choose('Lọc theo dự án', _project ?? '', [
                    const ChangChoice('', 'Tất cả'),
                    for (final p in projects.entries)
                      ChangChoice(p.key, p.value),
                  ], (v) => _project = v.isEmpty ? null : v),
                ),
                const SizedBox(height: 20),
                ChoiceField(
                  label: 'Trạng thái',
                  icon: Icons.radio_button_checked,
                  value: _statuses[_status ?? '']!,
                  onTap: () => _choose('Lọc theo trạng thái', _status ?? '', [
                    for (final s in _statuses.entries)
                      ChangChoice(s.key, s.value),
                  ], (v) => _status = v.isEmpty ? null : v),
                ),
                const SizedBox(height: 20),
                ChoiceField(
                  label: 'Hạn hoàn thành',
                  icon: Icons.calendar_month_outlined,
                  value: dueFilterLabel(_due),
                  onTap: () => _choose('Lọc theo hạn hoàn thành', _due.name, [
                    for (final d in DueFilter.values)
                      ChangChoice(d.name, dueFilterLabel(d)),
                  ], (v) => _due = DueFilter.values.byName(v)),
                ),
                const SizedBox(height: 20),
                ChoiceField(
                  label: 'Ưu tiên',
                  icon: Icons.flag_outlined,
                  value: _priority?.label ?? 'Tất cả',
                  onTap: () => _choose(
                    'Lọc theo ưu tiên',
                    _priority?.name ?? '',
                    [
                      const ChangChoice('', 'Tất cả'),
                      for (final p in TaskPriority.values)
                        ChangChoice(p.name, p.label),
                    ],
                    (v) => _priority = v.isEmpty
                        ? null
                        : TaskPriority.values.byName(v),
                  ),
                ),
                const SizedBox(height: 28),
                FeatureButton(
                  'Áp dụng',
                  onPressed: () => Navigator.pop(
                    context,
                    TaskFilters(
                      query: widget.current.query,
                      projectId: _project,
                      state: _status,
                      priority: _priority,
                      due: _due,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FeatureButton(
                  'Đặt lại',
                  secondary: true,
                  onPressed: () => setState(() {
                    _project = null;
                    _status = null;
                    _priority = null;
                    _due = DueFilter.any;
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
