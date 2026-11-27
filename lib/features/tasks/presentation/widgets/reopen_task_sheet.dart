import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/app_layout.dart';
import '../../../../app/widgets/feature_surface.dart';
import '../../../projects/domain/study_project.dart';
import '../../data/task_management_repository.dart';
import '../../domain/task_detail.dart';
import '../task_detail_provider.dart';
import 'task_draft_helpers.dart';

Future<bool> showReopenTaskSheet(BuildContext context, TaskDetail task) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: AppLayout.maxSheetWidth),
      builder: (_) => _ReopenTaskSheet(task: task),
    ) ??
    false;

class _ReopenTaskSheet extends ConsumerStatefulWidget {
  const _ReopenTaskSheet({required this.task});
  final TaskDetail task;
  @override
  ConsumerState<_ReopenTaskSheet> createState() => _ReopenTaskSheetState();
}

class _ReopenTaskSheetState extends ConsumerState<_ReopenTaskSheet> {
  bool _saving = false;
  String? _error;
  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(taskDetailRepositoryProvider)
          .setTaskStatus(
            taskId: widget.task.id,
            status: TaskStatus.inProgress,
            hasSubtasks: widget.task.subtasks.isNotEmpty,
          );
      if (!mounted) return;
      invalidateTaskViews(ref, widget.task.id);
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chưa xác nhận được kết quả. Kiểm tra kết nối rồi thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final tasks = ref.watch(taskListProvider).asData?.value;
    final progress = task.project == null || tasks == null
        ? null
        : ProjectProgress(task.project!.id, tasks);
    final wasCompleted =
        progress?.tasks.any(
          (item) => item.id == task.id && item.status == TaskStatus.completed,
        ) ??
        false;
    final afterReopen = (progress?.completed ?? 0) - (wasCompleted ? 1 : 0);
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mở lại công việc?',
                      style: TextStyle(
                        color: changInk,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                task.title,
                style: const TextStyle(
                  color: changInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (progress != null)
                Text(
                  'Tiến độ dự án: ${progress.completed}/${progress.total} → $afterReopen/${progress.total} công việc.',
                  style: const TextStyle(color: changMuted, fontSize: 16),
                ),
              const SizedBox(height: 6),
              const Text(
                'Công việc chuyển về Đang làm. Các bước nhỏ được giữ nguyên.',
                style: TextStyle(color: changMuted, height: 1.5),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              FeatureButton(
                _saving ? 'Đang mở lại…' : 'Mở lại công việc',
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: 10),
              FeatureButton(
                'Hủy',
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                secondary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
