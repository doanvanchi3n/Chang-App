import '../../../app/widgets/app_layout.dart';
import '../../../app/widgets/desktop_top_bar.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../focus/presentation/focus_prep_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_task_page.dart';
import 'edit_task_page.dart';
import 'manage_steps_page.dart';
import 'widgets/task_draft_helpers.dart';
import 'widgets/reopen_task_sheet.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../domain/task_detail.dart';
import 'daily_plan_page.dart';
import 'task_detail_provider.dart';
import 'widgets/task_detail_widgets.dart';

typedef FocusStepCallback = void Function(TaskDetail task, TaskSubtask? step);
typedef TaskDetailActionCallback = void Function(TaskDetail task);

class TaskDetailPage extends ConsumerStatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.taskId,
    this.onStartFocus,
    this.onScheduleTask,
    this.onEditTask,
    this.onAskAssistant,
  });

  final String taskId;
  final FocusStepCallback? onStartFocus;
  final FocusStepCallback? onScheduleTask;
  final TaskDetailActionCallback? onEditTask;
  final TaskDetailActionCallback? onAskAssistant;

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  TaskDetail? _localOverride;
  String? _selectedStepId;
  final Set<String> _busySubtaskIds = <String>{};
  bool _updatingStatus = false;
  bool _showAddStepForm = false;
  bool _addingStep = false;
  final _addFormKey = GlobalKey<FormState>();
  final _addTitleController = TextEditingController();
  final _addMinutesController = TextEditingController(text: '25');

  @override
  void dispose() {
    _addTitleController.dispose();
    _addMinutesController.dispose();
    super.dispose();
  }

  void _invalidateRelated() {
    invalidateTaskViews(ref, widget.taskId);
  }

  Future<void> _refresh() async {
    setState(() => _localOverride = null);
    ref.invalidate(taskDetailProvider(widget.taskId));
    try {
      await ref.read(taskDetailProvider(widget.taskId).future);
    } catch (_) {
      // Error state is rendered by AsyncValue.when.
    }
  }

  Future<void> _toggleSubtask(TaskDetail current, TaskSubtask step) async {
    if (_busySubtaskIds.isNotEmpty || _updatingStatus || _addingStep) return;
    final previous = current;
    final optimistic = current.withToggledSubtask(step.id);
    setState(() {
      _busySubtaskIds.add(step.id);
      _localOverride = optimistic;
      if (_selectedStepId == step.id && !step.isCompleted) {
        _selectedStepId = null;
      }
    });
    try {
      final saved = await ref
          .read(taskDetailRepositoryProvider)
          .toggleSubtask(
            taskId: current.id,
            subtaskId: step.id,
            isCompleted: !step.isCompleted,
          );
      if (!mounted) return;
      setState(() => _localOverride = saved);
      _invalidateRelated();
    } catch (_) {
      if (!mounted) return;
      setState(() => _localOverride = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa cập nhật được trạng thái bước nhỏ. Vui lòng thử lại.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busySubtaskIds.remove(step.id));
      }
    }
  }

  Future<void> _submitNewSubtask(TaskDetail current) async {
    if (_addingStep || !_addFormKey.currentState!.validate()) return;
    final orderIndex = current.nextOrderIndex;
    if (orderIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mỗi công việc chỉ được phép có tối đa 5 bước nhỏ.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _addingStep = true);
    try {
      final saved = await ref
          .read(taskDetailRepositoryProvider)
          .addSubtask(
            taskId: current.id,
            title: _addTitleController.text,
            orderIndex: orderIndex,
            estimatedMinutes: int.parse(_addMinutesController.text),
          );
      if (!mounted) return;
      _addTitleController.clear();
      _addMinutesController.text = '25';
      setState(() {
        _localOverride = saved;
        _showAddStepForm = false;
      });
      _invalidateRelated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm bước $orderIndex vào công việc.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa lưu được bước nhỏ mới. Vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingStep = false);
    }
  }

  Future<void> _toggleTaskCompletion(TaskDetail current) async {
    if (_updatingStatus || _busySubtaskIds.isNotEmpty || _addingStep) return;
    if (current.status == TaskStatus.completed) {
      if (await showReopenTaskSheet(context, current) && mounted) {
        await _refresh();
      }
      return;
    }
    const nextStatus = TaskStatus.completed;
    final previous = current;
    setState(() {
      _updatingStatus = true;
      _localOverride = current.withStatus(nextStatus);
    });
    try {
      final saved = await ref
          .read(taskDetailRepositoryProvider)
          .setTaskStatus(
            taskId: current.id,
            status: nextStatus,
            hasSubtasks: current.subtasks.isNotEmpty,
          );
      if (!mounted) return;
      setState(() => _localOverride = saved);
      _invalidateRelated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus == TaskStatus.completed
                ? 'Đã đánh dấu hoàn thành công việc.'
                : 'Đã mở lại công việc.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _localOverride = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa cập nhật được trạng thái công việc.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _handleStartFocus(
    TaskDetail task,
    TaskSubtask? focusStep,
  ) async {
    if (widget.onStartFocus != null) {
      widget.onStartFocus!(task, focusStep);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FocusPrepPage(taskId: task.id, initialStep: focusStep?.id),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _handleSchedule(TaskDetail task, TaskSubtask? focusStep) async {
    if (widget.onScheduleTask != null) {
      widget.onScheduleTask!(task, focusStep);
      return;
    }
    if (task.status == TaskStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Công việc đã hoàn thành, không cần xếp thêm vào lịch.',
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DailyPlanPage(initialTaskIds: [task.id]),
      ),
    );
    if (mounted) {
      _refresh();
      _invalidateRelated();
    }
  }

  Future<void> _handleEdit(TaskDetail task) async {
    if (widget.onEditTask != null) {
      widget.onEditTask!(task);
      return;
    }
    final result = await Navigator.push<TaskEditResult>(
      context,
      MaterialPageRoute(builder: (_) => EditTaskPage(task: task)),
    );
    if (!mounted) return;
    if (result == TaskEditResult.deleted) {
      _navigateBack();
      return;
    }
    await _refresh();
  }

  Future<void> _manageSteps(TaskDetail task) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ManageStepsPage(task: task)),
    );
    if (mounted) await _refresh();
  }

  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/tasks');
    }
  }

  Widget _buildMoreMenu(TaskDetail task, {required bool includeEdit}) {
    return PopupMenuButton<String>(
      enabled: !_addingStep && !_updatingStatus && _busySubtaskIds.isEmpty,
      key: const ValueKey('task-more-menu'),
      tooltip: 'Tùy chọn công việc',
      icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _handleEdit(task);
          case 'toggle_status':
            _toggleTaskCompletion(task);
          case 'steps':
            _manageSteps(task);
          case 'refresh':
            _refresh();
        }
      },
      itemBuilder: (_) => [
        if (includeEdit)
          const PopupMenuItem(
            value: 'edit',
            child: Text('Chỉnh sửa công việc'),
          ),
        PopupMenuItem(
          value: 'toggle_status',
          child: Text(
            task.status == TaskStatus.completed
                ? 'Mở lại công việc'
                : 'Đánh dấu hoàn thành',
          ),
        ),
        const PopupMenuItem(value: 'steps', child: Text('Quản lý các bước')),
        const PopupMenuItem(value: 'refresh', child: Text('Làm mới')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncTask = ref.watch(taskDetailProvider(widget.taskId));
    final resolvedTask = _localOverride ?? asyncTask.asData?.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = AppLayout.isDesktopWidth(constraints.maxWidth);
        return Scaffold(
          backgroundColor: isDesktop ? AppColors.page : Colors.white,
          appBar: isDesktop
              ? null
              : AppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1, color: AppColors.borderSubtle),
                  ),
                  leading: IconButton(
                    tooltip: 'Quay lại',
                    onPressed: _navigateBack,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  title: const Text(
                    'Chi tiết công việc',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  actions: [
                    if (resolvedTask != null)
                      _buildMoreMenu(resolvedTask, includeEdit: true),
                  ],
                ),
          bottomNavigationBar: !isDesktop &&
                  resolvedTask != null &&
                  MediaQuery.viewInsetsOf(context).bottom == 0
              ? _MobileBottomActions(
                  task: resolvedTask,
                  focusStep: resolvedTask.resolveFocusStep(_selectedStepId),
                  onStartFocus: () => _handleStartFocus(
                    resolvedTask,
                    resolvedTask.resolveFocusStep(_selectedStepId),
                  ),
                  onSchedule: () => _handleSchedule(
                    resolvedTask,
                    resolvedTask.resolveFocusStep(_selectedStepId),
                  ),
                )
              : null,
          body: Column(
            children: [
              if (isDesktop)
                DesktopTopBar(
                  activeTab: DesktopNavTab.tasks,
                  onTapHome: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } else {
                      context.go('/');
                    }
                  },
                  onTapTasks: _navigateBack,
                  onTapAddTask: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateTaskPage(),
                      ),
                    );
                    if (mounted) await _refresh();
                  },
                  onRefresh: _refresh,
                ),
              Expanded(
                child: asyncTask.when(
                  skipLoadingOnRefresh: false,
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Đang tải chi tiết công việc',
                    ),
                  ),
                  error: (_, _) => _ErrorView(onRetry: _refresh),
                  data: (fetched) {
                    final task = _localOverride ?? fetched;
                    if (task == null) return _NotFoundView(onBack: _navigateBack);
                    final focusStep = task.resolveFocusStep(_selectedStepId);
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: isDesktop
                            ? _buildDesktopBody(task, focusStep)
                            : _buildMobileBody(task, focusStep),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopBody(TaskDetail task, TaskSubtask? focusStep) {
    final breadcrumbTail = task.project != null
        ? 'Dự án ${task.project!.name}'
        : task.scheduledDate == null
        ? 'Hộp việc'
        : 'Kế hoạch hôm nay';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxDesktopWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24,
            AppSpacing.s24,
            AppSpacing.s24,
            AppSpacing.s40,
          ),
          child: Column(
            key: const ValueKey('task-detail-desktop-layout'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.s8,
                children: [
                  InkWell(
                    onTap: _navigateBack,
                    borderRadius: BorderRadius.circular(AppRadius.r4),
                    child: const Text(
                      'Công việc',
                      style: TextStyle(
                        color: AppColors.textLink,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Text(
                    '/',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  Text(
                    breadcrumbTail,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.s12,
                      runSpacing: AppSpacing.s8,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        TaskStatusBadge(status: task.status),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  TextButton.icon(
                    onPressed: () => _manageSteps(task),
                    icon: const Icon(Icons.checklist, size: 18),
                    label: Text('Quản lý ${task.subtasks.length} bước'),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  OutlinedButton(
                    key: const ValueKey('edit-task-button'),
                    onPressed: () => _handleEdit(task),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.borderSubtle),
                      minimumSize: const Size(48, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                    ),
                    child: const Text(
                      'Chỉnh sửa',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: _buildMoreMenu(task, includeEdit: false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 15,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.s24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DescriptionSection(description: task.description),
                          const SizedBox(height: AppSpacing.s24),
                          SubtaskListSection(
                            task: task,
                            isWide: true,
                            focusStep: focusStep,
                            busySubtaskIds: _busySubtaskIds,
                            addingStep: _addingStep,
                            showAddForm: _showAddStepForm,
                            addTitleController: _addTitleController,
                            addMinutesController: _addMinutesController,
                            addFormKey: _addFormKey,
                            onToggleSubtask: (step) =>
                                _toggleSubtask(task, step),
                            onSelectFocusStep: (step) =>
                                setState(() => _selectedStepId = step.id),
                            onOpenAddForm: () =>
                                setState(() => _showAddStepForm = true),
                            onCancelAddForm: () {
                              _addTitleController.clear();
                              _addMinutesController.text = '25';
                              setState(() => _showAddStepForm = false);
                            },
                            onSubmitNewSubtask: () => _submitNewSubtask(task),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s24),
                  SizedBox(
                    width: 356,
                    child: TaskInfoSidebarCard(
                      task: task,
                      focusStep: focusStep,
                      onStartFocus: () => _handleStartFocus(task, focusStep),
                      onSchedule: () => _handleSchedule(task, focusStep),
                      onAskAssistant: () {
                        if (widget.onAskAssistant != null) {
                          widget.onAskAssistant!(task);
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Trợ lý AI gợi ý chia nhỏ bước (M41) sẽ sớm ra mắt.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBody(TaskDetail task, TaskSubtask? focusStep) {
    final overdue = task.isOverdue(DateTime.now());
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
        child: Padding(
          padding: AppLayout.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              TaskStatusBadge(status: task.status),
              const SizedBox(height: AppSpacing.s12),
              Wrap(
                spacing: AppSpacing.s12,
                runSpacing: AppSpacing.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (task.project != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(AppRadius.r8),
                      ),
                      child: Text(
                        task.project!.name,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (task.dueDate != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: overdue
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Hạn ${formatShortDate(task.dueDate!)}',
                            style: TextStyle(
                              color: overdue
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              fontSize: 13.5,
                              fontWeight: overdue
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  TaskPriorityBadge(priority: task.priority),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('edit-task-button'),
                    onPressed: () => _handleEdit(task),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Chỉnh sửa'),
                  ),
                  TextButton.icon(
                    onPressed: () => _manageSteps(task),
                    icon: const Icon(Icons.checklist),
                    label: Text('Quản lý ${task.subtasks.length} bước'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DescriptionSection(description: task.description),
              const SizedBox(height: AppSpacing.s16),
              SubtaskListSection(
                task: task,
                isWide: false,
                focusStep: focusStep,
                busySubtaskIds: _busySubtaskIds,
                addingStep: _addingStep,
                showAddForm: _showAddStepForm,
                addTitleController: _addTitleController,
                addMinutesController: _addMinutesController,
                addFormKey: _addFormKey,
                onToggleSubtask: (step) => _toggleSubtask(task, step),
                onSelectFocusStep: (step) =>
                    setState(() => _selectedStepId = step.id),
                onOpenAddForm: () => setState(() => _showAddStepForm = true),
                onCancelAddForm: () {
                  _addTitleController.clear();
                  _addMinutesController.text = '25';
                  setState(() => _showAddStepForm = false);
                },
                onSubmitNewSubtask: () => _submitNewSubtask(task),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    final text = description?.trim();
    final hasDescription = text != null && text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mô tả',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          hasDescription ? text : 'Chưa có mô tả cho công việc này.',
          style: TextStyle(
            color: hasDescription
                ? AppColors.textSecondary
                : AppColors.textMuted,
            fontSize: 14.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _MobileBottomActions extends StatelessWidget {
  const _MobileBottomActions({
    required this.task,
    required this.focusStep,
    required this.onStartFocus,
    required this.onSchedule,
  });

  final TaskDetail task;
  final TaskSubtask? focusStep;
  final VoidCallback onStartFocus;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: Padding(
                padding: AppLayout.pagePadding(context, top: 12, bottom: 12),
                child: TaskActionButtons(
                  task: task,
                  focusStep: focusStep,
                  onStartFocus: onStartFocus,
                  onSchedule: onSchedule,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.error),
              const SizedBox(height: AppSpacing.s12),
              const Text(
                'Chưa tải được chi tiết công việc. Kiểm tra kết nối rồi thử lại.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_late_outlined,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.s12),
              const Text(
                'Không tìm thấy công việc này hoặc công việc đã bị xóa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              OutlinedButton(onPressed: onBack, child: const Text('Quay lại')),
            ],
          ),
        ),
      ),
    );
  }
}
