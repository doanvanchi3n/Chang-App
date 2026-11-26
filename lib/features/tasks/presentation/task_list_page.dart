import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/app_layout.dart';
import '../../../app/widgets/feature_surface.dart';
import '../../../app/widgets/main_navigation.dart';
import '../data/task_management_repository.dart';
import '../domain/task_detail.dart';
import '../domain/task_filters.dart';
import 'create_task_page.dart';
import 'edit_task_page.dart';
import 'inbox_page.dart';
import 'manage_steps_page.dart';
import 'task_detail_page.dart';
import 'widgets/task_filter_sheet.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});
  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  TaskFilters _filters = const TaskFilters();
  TaskTab _tab = TaskTab.all;
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(taskListProvider);
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) ref.invalidate(taskListProvider);
  }

  Future<void> _refresh() async {
    ref.invalidate(taskListProvider);
    try {
      await ref.read(taskListProvider.future);
    } catch (_) {
      /* Render AsyncValue error below. */
    }
  }

  static const _tabs = {
    TaskTab.all: 'Tất cả',
    TaskTab.today: 'Hôm nay',
    TaskTab.upcoming: 'Sắp tới',
    TaskTab.overdue: 'Quá hạn',
  };
  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: MainNavigation(
        inboxActive: true,
        onHome: () {
          if (Navigator.canPop(context)) {
            Navigator.popUntil(context, (r) => r.isFirst);
          } else {
            context.go('/');
          }
        },
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: AppLayout.pagePadding(context, bottom: 12),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              const Text(
                                'Công việc',
                                style: TextStyle(
                                  color: changInk,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: changBlue,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(100, 48),
                                ),
                                onPressed: () => _open(const CreateTaskPage()),
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm việc'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _search,
                                  onChanged: (v) => setState(
                                    () => _filters = _filters.withQuery(v),
                                  ),
                                  decoration: changInput('Tìm công việc…')
                                      .copyWith(
                                        filled: true,
                                        fillColor: changSoft,
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: _search.text.isEmpty
                                            ? null
                                            : IconButton(
                                                tooltip: 'Xóa tìm kiếm',
                                                icon: const Icon(Icons.close),
                                                onPressed: () => setState(() {
                                                  _search.clear();
                                                  _filters = _filters.withQuery(
                                                    '',
                                                  );
                                                }),
                                              ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton.filledTonal(
                                tooltip: 'Tìm và lọc',
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(52, 52),
                                  backgroundColor: changSoft,
                                  foregroundColor: changBlue,
                                ),
                                onPressed: tasks.asData == null
                                    ? null
                                    : () async {
                                        FocusScope.of(context).unfocus();
                                        final value = await showTaskFilters(
                                          context,
                                          _filters,
                                          tasks.requireValue,
                                        );
                                        if (mounted && value != null) {
                                          setState(() {
                                            _filters = value;
                                            _tab = TaskTab.all;
                                          });
                                        }
                                      },
                                icon: Badge(
                                  isLabelVisible: _filters.count > 0,
                                  label: Text('${_filters.count}'),
                                  child: const Icon(Icons.tune),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_filters.count > 0)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (_filters.projectId != null)
                                  _chip(
                                    'Dự án: ${tasks.asData?.value.where((t) => t.project?.id == _filters.projectId).firstOrNull?.project?.name ?? 'Đã chọn'}',
                                    'project',
                                  ),
                                if (_filters.state != null)
                                  _chip(
                                    _filters.state == 'OVERDUE'
                                        ? 'Quá hạn'
                                        : TaskStatus.values
                                              .firstWhere(
                                                (s) =>
                                                    s.dbValue == _filters.state,
                                              )
                                              .label,
                                    'state',
                                  ),
                                if (_filters.priority != null)
                                  _chip(
                                    'Ưu tiên: ${_filters.priority!.label}',
                                    'priority',
                                  ),
                                if (_filters.due != DueFilter.any)
                                  _chip(
                                    'Hạn: ${dueFilterLabel(_filters.due)}',
                                    'due',
                                  ),
                              ],
                            ),
                          TextButton.icon(
                            onPressed: () => _open(const InboxPage()),
                            icon: const Icon(Icons.inbox_outlined),
                            label: const Text('Mở Hộp việc chưa lên kế hoạch'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...tasks.when<List<Widget>>(
                    skipLoadingOnRefresh: false,
                    loading: () => [
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ],
                    error: (_, _) => [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Text(
                                'Chưa tải được công việc. Kiểm tra kết nối rồi thử lại.',
                              ),
                              TextButton(
                                onPressed: _refresh,
                                child: const Text('Tải lại'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    data: (items) {
                      final now = DateTime.now();
                      final matching = items
                          .where((t) => _filters.matches(t, now))
                          .toList();
                      final visible = matching
                          .where((t) => matchesTaskTab(t, _tab, now))
                          .toList();
                      return [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppLayout.gutter(context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final tab in _tabs.entries)
                                      ChoiceChip(
                                        label: Text(
                                          '${tab.value} ${matching.where((t) => matchesTaskTab(t, tab.key, now)).length}',
                                        ),
                                        selected: _tab == tab.key,
                                        selectedColor: changSoft,
                                        onSelected: (_) =>
                                            setState(() => _tab = tab.key),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${visible.length} công việc',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: changMuted,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                        if (visible.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(
                                AppLayout.gutter(context),
                              ),
                              child: FeatureCard(
                                color: changSoft,
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.checklist_rounded,
                                      size: 44,
                                      color: changBlue,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      items.isEmpty
                                          ? 'Bắt đầu từ một việc nhỏ'
                                          : 'Không có công việc phù hợp',
                                      style: const TextStyle(
                                        color: changInk,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      items.isEmpty
                                          ? 'Thêm công việc đầu tiên hoặc ghi nhanh vào Hộp việc.'
                                          : 'Thử đổi tab, từ khóa hoặc điều kiện lọc.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: changMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            AppLayout.gutter(context),
                            0,
                            AppLayout.gutter(context),
                            24,
                          ),
                          sliver: SliverList.builder(
                            itemCount: visible.length,
                            itemBuilder: (_, i) => _taskCard(visible[i], now),
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, String key) => InputChip(
    label: Text(text),
    backgroundColor: changSoft,
    side: BorderSide.none,
    onDeleted: () => setState(
      () => _filters = TaskFilters(
        query: _filters.query,
        projectId: key == 'project' ? null : _filters.projectId,
        state: key == 'state' ? null : _filters.state,
        priority: key == 'priority' ? null : _filters.priority,
        due: key == 'due' ? DueFilter.any : _filters.due,
      ),
    ),
  );
  Widget _taskCard(TaskDetail task, DateTime now) {
    final overdue = task.isOverdue(now), due = task.dueDate?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: changBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(TaskDetailPage(taskId: task.id)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Icon(
                        task.status == TaskStatus.completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: changBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            color: changInk,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Tùy chọn công việc',
                      onSelected: (v) => _open(
                        v == 'edit'
                            ? EditTaskPage(task: task)
                            : ManageStepsPage(task: task),
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Chỉnh sửa'),
                        ),
                        const PopupMenuItem(
                          value: 'steps',
                          child: Text('Quản lý các bước'),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 36, right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.subtasks.isNotEmpty)
                        Text(
                          '${task.completedSubtaskCount}/${task.subtasks.length} bước hoàn thành',
                          style: const TextStyle(color: changMuted),
                        ),
                      if (task.scheduledDate == taskDayKey(now))
                        const Text(
                          'Dự kiến hôm nay',
                          style: TextStyle(color: changBlue),
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (task.project != null)
                            Text(
                              '▱ ${task.project!.name}',
                              style: const TextStyle(color: changMuted),
                            ),
                          if (due != null)
                            Text(
                              '${due.day}/${due.month}/${due.year}',
                              style: TextStyle(
                                color: overdue
                                    ? Colors.red.shade700
                                    : changMuted,
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: overdue
                                  ? const Color(0xFFFFE8E3)
                                  : changSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              overdue ? 'Quá hạn' : task.status.label,
                              style: TextStyle(
                                color: overdue
                                    ? Colors.red.shade700
                                    : changBlue,
                                fontSize: 13,
                              ),
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
      ),
    );
  }
}
