import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/feature_surface.dart';
import '../../home/data/dashboard_provider.dart';
import '../../focus/presentation/focus_prep_page.dart';
import '../data/task_repository.dart';
import '../domain/task_detail.dart';
import 'inbox_provider.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  const TaskDetailPage({super.key, required this.taskId});
  final String taskId;
  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  bool _saving = false;
  bool _preparing = false;
  String? _error;
  Future<void> _toggle(TaskStep step, bool value) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(taskRepositoryProvider)
          .completeStep(widget.taskId, step.id, value);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa xác nhận được tiến độ. Hãy kiểm tra dữ liệu đã tải lại trước khi thử tiếp.',
        );
      }
    } finally {
      if (mounted) {
        ref.invalidate(taskDetailProvider(widget.taskId));
        ref.invalidate(dashboardProvider);
        ref.invalidate(inboxProvider);
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _prepare([String? step]) async {
    if (_preparing || _saving) return;
    _preparing = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              FocusPrepPage(taskId: widget.taskId, initialStep: step),
        ),
      );
    } finally {
      _preparing = false;
      if (mounted) ref.invalidate(taskDetailProvider(widget.taskId));
    }
  }

  @override
  Widget build(BuildContext context) => FeatureSurface(
    title: 'Chi tiết công việc',
    trailing: IconButton(
      tooltip: 'Làm mới công việc',
      onPressed: _saving
          ? null
          : () => ref.invalidate(taskDetailProvider(widget.taskId)),
      icon: const Icon(Icons.refresh, color: changMuted),
    ),
    child: ref
        .watch(taskDetailProvider(widget.taskId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Column(
            children: [
              const Text(
                'Chưa tải được công việc hoặc công việc không còn tồn tại.',
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(taskDetailProvider(widget.taskId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
          data: (task) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FeatureCard(
                color: changSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.project != null)
                      Chip(
                        label: Text(task.project!),
                        backgroundColor: Colors.white,
                      ),
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: changInk,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            task.status == 'COMPLETED'
                                ? 'Đã hoàn thành'
                                : task.status == 'IN_PROGRESS'
                                ? 'Đang thực hiện'
                                : 'Chưa thực hiện',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'Ưu tiên ${task.priority == 'HIGH'
                                ? 'cao'
                                : task.priority == 'LOW'
                                ? 'thấp'
                                : 'vừa'}',
                          ),
                        ),
                      ],
                    ),
                    if (task.dueDate != null)
                      Text(
                        'Hạn ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year} · ${TimeOfDay.fromDateTime(task.dueDate!).format(context)}',
                        style: const TextStyle(color: changMuted),
                      ),
                    if (task.minutes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Dự kiến ${task.minutes} phút',
                          style: const TextStyle(color: changMuted),
                        ),
                      ),
                  ],
                ),
              ),
              if (task.description?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    task.description!,
                    style: const TextStyle(color: changInk, height: 1.6),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                '${task.completedSteps}/${task.steps.length} bước đã hoàn thành',
                style: const TextStyle(
                  color: changInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: task.steps.isEmpty
                    ? 0
                    : task.completedSteps / task.steps.length,
                color: changBlue,
                backgroundColor: changSoft,
                semanticsLabel: 'Tiến độ bước nhỏ',
              ),
              const SizedBox(height: 16),
              if (task.steps.isEmpty)
                const FeatureCard(
                  child: Text(
                    'Công việc này chưa có bước nhỏ. Bạn vẫn có thể tập trung vào toàn bộ công việc.',
                    style: TextStyle(color: changMuted, height: 1.5),
                  ),
                ),
              for (final step in task.steps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FeatureCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: step.completed,
                          onChanged: _saving || task.archived
                              ? null
                              : (value) => _toggle(step, value!),
                          activeColor: changBlue,
                          title: Text(
                            'Bước ${step.order} · ${step.title}',
                            style: TextStyle(
                              color: changInk,
                              fontWeight: FontWeight.w600,
                              decoration: step.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text('${step.minutes} phút dự kiến'),
                        ),
                        if (!step.completed && !task.archived)
                          TextButton.icon(
                            onPressed: _saving ? null : () => _prepare(step.id),
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Tập trung vào bước này'),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (!task.archived && task.status != 'COMPLETED')
                FeatureButton(
                  'Chuẩn bị phiên học',
                  onPressed: _saving ? null : () => _prepare(),
                ),
            ],
          ),
        ),
  );
}
