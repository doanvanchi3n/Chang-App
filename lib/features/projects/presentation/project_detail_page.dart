import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/feature_surface.dart';
import '../../tasks/data/task_management_repository.dart';
import '../../tasks/domain/task_detail.dart';
import '../../tasks/presentation/completed_tasks_page.dart';
import '../../tasks/presentation/create_task_page.dart';
import '../../tasks/presentation/edit_task_page.dart';
import '../../tasks/presentation/task_detail_page.dart';
import '../../tasks/presentation/task_detail_provider.dart';
import '../../tasks/presentation/widgets/reopen_task_sheet.dart';
import '../../tasks/presentation/widgets/task_draft_helpers.dart';
import '../data/project_repository.dart';
import '../domain/study_project.dart';
import 'widgets/project_widgets.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  const ProjectDetailPage({super.key, required this.projectId});
  final String projectId;
  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage>
    with WidgetsBindingObserver {
  String _tab = 'all';
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
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() {
    ref.invalidate(projectListProvider);
    ref.invalidate(taskListProvider);
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) _reload();
  }

  Future<void> _toggle(TaskDetail task) async {
    if (_busy.contains(task.id)) return;
    if (task.status == TaskStatus.completed) {
      await showReopenTaskSheet(context, task);
      return;
    }
    setState(() => _busy.add(task.id));
    try {
      await ref
          .read(taskDetailRepositoryProvider)
          .setTaskStatus(
            taskId: task.id,
            status: TaskStatus.completed,
            hasSubtasks: task.subtasks.isNotEmpty,
          );
      if (mounted) invalidateTaskViews(ref, task.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa xác nhận được trạng thái công việc. Hãy tải lại để kiểm tra.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(task.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectListProvider),
        tasks = ref.watch(taskListProvider);
    return FeatureSurface(
      title: 'Dự án',
      onBack: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go('/projects');
        }
      },
      trailing: IconButton(
        tooltip: 'Làm mới',
        onPressed: _reload,
        icon: const Icon(Icons.refresh),
      ),
      child: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ProjectLoadError(onRetry: _reload),
        data: (items) {
          final project = items
              .where((p) => p.id == widget.projectId)
              .firstOrNull;
          if (project == null) {
            return const FeatureCard(
              child: Text(
                'Không tìm thấy dự án hoặc dự án không còn khả dụng.',
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                project.name,
                style: const TextStyle(
                  color: changInk,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (project.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  project.description!,
                  style: const TextStyle(
                    color: changMuted,
                    fontSize: 17,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, color: changBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      project.deadline == null
                          ? 'Chưa đặt hạn hoàn thành'
                          : 'Hạn ${projectDate(project.deadline!)}',
                      style: const TextStyle(color: changMuted, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              tasks.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => ProjectLoadError(onRetry: _reload),
                data: (allTasks) {
                  final progress = ProjectProgress(project.id, allTasks);
                  final visible = progress.tasks
                      .where(
                        (t) =>
                            _tab == 'all' ||
                            (t.status == TaskStatus.completed) ==
                                (_tab == 'done'),
                      )
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FeatureCard(
                        color: changSoft,
                        child: ProjectProgressView(
                          progress: progress,
                          explain: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          const Text(
                            'Công việc trong dự án',
                            style: TextStyle(
                              color: changInk,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: changBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _open(
                              CreateTaskPage(
                                initialProject: TaskProjectSummary(
                                  id: project.id,
                                  name: project.name,
                                  colorHex: project.colorHex,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm việc'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          for (final tab in [
                            ('all', 'Tất cả', progress.total),
                            (
                              'todo',
                              'Chưa xong',
                              progress.total - progress.completed,
                            ),
                            ('done', 'Đã xong', progress.completed),
                          ])
                            ChoiceChip(
                              label: Text('${tab.$2} ${tab.$3}'),
                              selected: _tab == tab.$1,
                              onSelected: (_) => setState(() => _tab = tab.$1),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (visible.isEmpty)
                        FeatureCard(
                          color: changSoft,
                          child: Text(
                            progress.total == 0
                                ? 'Dự án chưa có công việc. Nhấn “Thêm việc” để bắt đầu.'
                                : 'Không có công việc trong tab này.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: changMuted),
                          ),
                        ),
                      for (final task in visible) _taskRow(task),
                      if (_tab == 'done')
                        TextButton.icon(
                          onPressed: () => _open(
                            CompletedTasksPage(initialProjectId: project.id),
                          ),
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Xem danh sách đã hoàn thành'),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'ⓘ  Bạn có thể mở lại công việc đã hoàn thành.',
                        style: TextStyle(color: changMuted),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _taskRow(TaskDetail task) {
    final done = task.status == TaskStatus.completed;
    final overdue = task.isOverdue(DateTime.now());
    final color = done
        ? const Color(0xFF159A73)
        : overdue
        ? Colors.red.shade700
        : changBlue;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: changBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: done,
            onChanged: _busy.contains(task.id) ? null : (_) => _toggle(task),
            semanticLabel: done
                ? 'Mở lại ${task.title}'
                : 'Hoàn thành ${task.title}',
          ),
          Expanded(
            child: InkWell(
              onTap: () => _open(TaskDetailPage(taskId: task.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: done ? changMuted : changInk,
                        fontWeight: FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        if (task.subtasks.isNotEmpty)
                          Text(
                            '${task.completedSteps}/${task.subtasks.length} bước',
                            style: const TextStyle(
                              color: changMuted,
                              fontSize: 12,
                            ),
                          ),
                        if (task.dueDate != null)
                          Text(
                            projectDate(task.dueDate!),
                            style: const TextStyle(
                              color: changMuted,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          '●  ${done
                              ? 'Đã hoàn thành'
                              : overdue
                              ? 'Quá hạn'
                              : task.status.label}',
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn công việc',
            enabled: !_busy.contains(task.id),
            onSelected: (value) {
              if (value == 'edit') {
                _open(EditTaskPage(task: task));
              } else {
                _toggle(task);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
              PopupMenuItem(
                value: 'status',
                child: Text(done ? 'Mở lại công việc' : 'Đánh dấu hoàn thành'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
