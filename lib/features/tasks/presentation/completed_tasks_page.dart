import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/choice_sheet.dart';
import '../../../app/widgets/feature_surface.dart';
import '../../projects/presentation/widgets/project_widgets.dart';
import '../data/task_management_repository.dart';
import '../domain/task_detail.dart';
import 'task_detail_page.dart';
import 'widgets/reopen_task_sheet.dart';

class CompletedTasksPage extends ConsumerStatefulWidget {
  const CompletedTasksPage({super.key, this.initialProjectId});
  final String? initialProjectId;
  @override
  ConsumerState<CompletedTasksPage> createState() => _CompletedTasksPageState();
}

class _CompletedTasksPageState extends ConsumerState<CompletedTasksPage>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  late String? _projectId = widget.initialProjectId;
  bool _completed = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(taskListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    return FeatureSurface(
      onBack: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go('/tasks');
        }
      },
      title: _completed ? 'Đã hoàn thành' : 'Chưa xong',
      trailing: IconButton(
        tooltip: 'Làm mới',
        onPressed: () => ref.invalidate(taskListProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: changInput(
              _completed
                  ? 'Tìm công việc đã hoàn thành…'
                  : 'Tìm công việc chưa xong…',
            ).copyWith(prefixIcon: const Icon(Icons.search)),
          ),
          const SizedBox(height: 14),
          tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => ProjectLoadError(
              onRetry: () => ref.invalidate(taskListProvider),
            ),
            data: (items) {
              final projects = <String, TaskProjectSummary>{
                for (final task in items)
                  if (task.project != null) task.project!.id: task.project!,
              };
              final scoped = items
                  .where(
                    (t) => _projectId == null || t.project?.id == _projectId,
                  )
                  .toList();
              final doneCount = scoped
                  .where((t) => t.status == TaskStatus.completed)
                  .length;
              final term = _search.text.trim().toLowerCase();
              final visible =
                  scoped
                      .where(
                        (t) =>
                            (t.status == TaskStatus.completed) == _completed &&
                            t.title.toLowerCase().contains(term),
                      )
                      .toList()
                    ..sort(
                      (a, b) => (b.completedAt ?? b.updatedAt).compareTo(
                        a.completedAt ?? a.updatedAt,
                      ),
                    );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ChoiceField(
                    label: 'Dự án',
                    icon: Icons.folder_outlined,
                    value: _projectId == null
                        ? 'Tất cả dự án'
                        : projects[_projectId]?.name ?? 'Dự án đã chọn',
                    onTap: () async {
                      final id = await showChangChoices(
                        context,
                        title: 'Lọc theo dự án',
                        subtitle: 'Xem công việc của một dự án hoặc tất cả.',
                        selected: _projectId ?? '',
                        choices: [
                          const ChangChoice(
                            '',
                            'Tất cả dự án',
                            icon: Icons.folder_outlined,
                          ),
                          for (final p in projects.values)
                            ChangChoice(
                              p.id,
                              p.name,
                              icon: Icons.folder_outlined,
                            ),
                        ],
                      );
                      if (mounted && id != null) {
                        setState(() => _projectId = id.isEmpty ? null : id);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('Chưa xong ${scoped.length - doneCount}'),
                        selected: !_completed,
                        onSelected: (_) => setState(() => _completed = false),
                      ),
                      ChoiceChip(
                        label: Text('Đã hoàn thành $doneCount'),
                        selected: _completed,
                        onSelected: (_) => setState(() => _completed = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    FeatureCard(
                      color: changSoft,
                      child: Text(
                        term.isNotEmpty
                            ? 'Không tìm thấy công việc phù hợp.'
                            : _completed
                            ? 'Chưa có công việc đã hoàn thành.'
                            : 'Bạn đã hoàn thành tất cả công việc trong danh sách này.',
                        style: const TextStyle(color: changMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final task in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _card(task),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _card(TaskDetail task) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: changBorder),
    ),
    child: InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => TaskDetailPage(taskId: task.id),
          ),
        );
        if (mounted) ref.invalidate(taskListProvider);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _completed
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _completed ? const Color(0xFF159A73) : changBlue,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: changInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.folder_outlined, size: 18, color: changMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.project?.name ?? 'Không gắn dự án',
                    style: const TextStyle(color: changMuted),
                  ),
                ),
              ],
            ),
            if (_completed) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: changMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.completedAt == null
                          ? 'Chưa có ngày hoàn thành'
                          : '${projectDate(task.completedAt!)} · ${TimeOfDay.fromDateTime(task.completedAt!.toLocal()).format(context)}',
                      style: const TextStyle(color: changMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => showReopenTaskSheet(context, task),
                  child: const Text('Mở lại'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
