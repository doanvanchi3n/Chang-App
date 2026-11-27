import 'package:flutter/material.dart';

import '../../../app/widgets/confirmation_dialog.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/widgets/choice_sheet.dart';
import '../../../app/widgets/deadline_picker.dart';
import '../../../app/widgets/feature_surface.dart';
import '../data/task_management_repository.dart';
import '../data/task_repository.dart';
import '../domain/task_detail.dart';
import '../domain/task_edit_draft.dart';
import 'manage_steps_page.dart';
import 'widgets/task_draft_helpers.dart';

enum TaskEditResult { saved, deleted }

class EditTaskPage extends ConsumerStatefulWidget {
  const EditTaskPage({super.key, required this.task});
  final TaskDetail task;
  @override
  ConsumerState<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends ConsumerState<EditTaskPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController(),
      _minutes = TextEditingController();
  late TaskDetail _base;
  late TaskPriority _priority;
  String? _project, _error;
  DateTime? _due;
  bool _saving = false, _leaving = false;
  Map<String, dynamic>? _pending;
  TaskEditDraft get _draft => TaskEditDraft(
    title: _title.text,
    description: _description.text,
    projectId: _project,
    dueDate: _due,
    priority: _priority,
    minutes: int.tryParse(_minutes.text) ?? 0,
  );
  bool get _dirty => !_draft.sameAs(TaskEditDraft.fromTask(_base));
  @override
  void initState() {
    super.initState();
    _load(widget.task);
  }

  void _load(TaskDetail task) {
    _base = task;
    final draft = TaskEditDraft.fromTask(task);
    _title.text = draft.title;
    _description.text = draft.description;
    _minutes.text = '${draft.minutes}';
    _priority = draft.priority;
    _project = draft.projectId;
    _due = draft.dueDate?.toLocal();
    _pending = null;
    _error = null;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _leave([TaskEditResult? result]) async {
    if (_saving) return;
    if (result == null && _pending != null) {
      if (!await confirmLeavePendingTaskSave(context) || !mounted) return;
      invalidateTaskViews(ref, _base.id);
    }
    if (result == null &&
        _pending == null &&
        _dirty &&
        !await confirmDiscardTaskDraft(context)) {
      return;
    }
    if (!mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  Future<void> _reload() async {
    if (_dirty && !await confirmDiscardTaskDraft(context)) return;
    setState(() => _saving = true);
    try {
      ref.invalidate(taskDetailProvider(_base.id));
      final latest = await ref.read(taskDetailProvider(_base.id).future);
      if (!mounted) return;
      if (latest == null) {
        setState(() => _error = 'Công việc không còn tồn tại.');
      } else {
        setState(() => _load(latest));
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Chưa tải được dữ liệu mới.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _manageSteps() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ManageStepsPage(task: _base)),
    );
    if (!mounted || saved != true) return;
    try {
      final latest = await ref.read(taskDetailProvider(_base.id).future);
      if (!mounted || latest == null) return;
      // Rebase the metadata draft only if the server changed steps, not metadata.
      if (TaskEditDraft.fromTask(latest)
          .sameAs(TaskEditDraft.fromTask(_base))) {
        setState(() => _base = latest);
      } else {
        setState(
          () => _error = 'Thông tin công việc đã thay đổi. Tải dữ liệu mới trước khi lưu bản nháp.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Đã lưu bước. Hãy tải lại thông tin công việc trước khi lưu chỉnh sửa.',
        );
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_pending == null) {
      if (!_form.currentState!.validate()) return;
      if (_due != null &&
          _due != _base.dueDate?.toLocal() &&
          !_due!.isAfter(DateTime.now())) {
        setState(() => _error = 'Hạn hoàn thành mới phải ở tương lai.');
        return;
      }
      _pending = {
        'p_task': _base.id,
        'p_request': const Uuid().v4(),
        'p_expected': _base.updatedAt.toUtc().toIso8601String(),
        'p_fields': _draft.toJson(),
      };
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(taskManagementRepositoryProvider).saveDetails(_pending!);
      if (!mounted) return;
      invalidateTaskViews(ref, _base.id);
      _saving = false;
      await _leave(TaskEditResult.saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = taskSaveError(e);
          if (isDefiniteTaskRejection(e)) _pending = null;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final yes = await showChangConfirmation(
      context,
      title: 'Xóa công việc?',
      message: 'Công việc và các bước nhỏ sẽ bị xóa. Không thể hoàn tác.',
      cancelLabel: 'Giữ lại',
      confirmLabel: 'Xóa công việc',
      destructive: true,
    );
    if (!mounted || yes != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(taskManagementRepositoryProvider).delete(_base);
      if (!mounted) return;
      invalidateTaskViews(ref, _base.id);
      _saving = false;
      await _leave(TaskEditResult.deleted);
    } catch (e) {
      if (mounted) setState(() => _error = taskSaveError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(taskProjectsProvider);
    return PopScope(
      canPop: _leaving || (!_dirty && !_saving && _pending == null),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: FeatureSurface(
        title: 'Chỉnh sửa công việc',
        onBack: _leave,
        trailing: PopupMenuButton<String>(
          enabled: !_saving && _pending == null,
          onSelected: (_) => _delete(),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'delete', child: Text('Xóa công việc')),
          ],
        ),
        child: Form(
          key: _form,
          onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_dirty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      backgroundColor: const Color(0xFFFFEDC6),
                      side: BorderSide.none,
                      label: const Text(
                        'Có thay đổi chưa lưu',
                        style: TextStyle(color: Color(0xFF8A4900)),
                      ),
                    ),
                  ),
                ),
              AbsorbPointer(
                absorbing: _saving || _pending != null,
                child: ExcludeFocus(
                  excluding: _saving || _pending != null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _title,
                        maxLength: 200,
                        decoration: changInput('Tên công việc *').copyWith(
                          suffixIcon: IconButton(
                            tooltip: 'Xóa tên',
                            onPressed: () => setState(_title.clear),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Nhập tên công việc.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _description,
                        maxLength: 4000,
                        minLines: 3,
                        maxLines: 6,
                        decoration: changInput('Mô tả'),
                      ),
                      const SizedBox(height: 16),
                      projects.when(
                        data: (items) => ChoiceField(
                          label: 'Dự án',
                          icon: Icons.folder_outlined,
                          value:
                              items
                                  .where((p) => p.id == _project)
                                  .firstOrNull
                                  ?.name ??
                              (_project == _base.project?.id
                                  ? _base.project?.name
                                  : null) ??
                              'Không gắn dự án',
                          onTap: () async {
                            final selected = await showChangChoices(
                              context,
                              title: 'Chọn dự án',
                              subtitle: 'Gắn công việc vào dự án học tập.',
                              selected: _project ?? '',
                              choices: [
                                const ChangChoice(
                                  '',
                                  'Không gắn dự án',
                                  icon: Icons.inbox_outlined,
                                ),
                                if (_base.project != null &&
                                    !items.any(
                                      (p) => p.id == _base.project!.id,
                                    ))
                                  ChangChoice(
                                    _base.project!.id,
                                    _base.project!.name,
                                  ),
                                for (final p in items)
                                  ChangChoice(
                                    p.id,
                                    p.name,
                                    icon: Icons.folder_outlined,
                                  ),
                              ],
                            );
                            if (mounted && selected != null) {
                              setState(
                                () => _project = selected.isEmpty
                                    ? null
                                    : selected,
                              );
                            }
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => TextButton(
                          onPressed: () => ref.invalidate(taskProjectsProvider),
                          child: const Text('Tải lại dự án'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ChoiceField(
                        label: 'Hạn hoàn thành',
                        icon: Icons.calendar_month_outlined,
                        value: _due == null
                            ? 'Chưa đặt hạn'
                            : _dateLabel(_due!),
                        onTap: () async {
                          final date = await showChangDeadline(
                            context,
                            initial: _due,
                          );
                          if (mounted && date != null) {
                            setState(() => _due = date);
                          }
                        },
                      ),
                      if (_due != _base.dueDate?.toLocal() &&
                          _base.dueDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Trước đó: ${_dateLabel(_base.dueDate!.toLocal())}',
                            style: const TextStyle(color: changMuted),
                          ),
                        ),
                      if (_due != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => _due = null),
                            child: const Text('Bỏ hạn hoàn thành'),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ưu tiên',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: changInk,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          for (final p in TaskPriority.values)
                            ChoiceChip(
                              label: Text(p.label),
                              selected: _priority == p,
                              selectedColor: p == TaskPriority.high
                                  ? const Color(0xFFFFDED6)
                                  : changSoft,
                              onSelected: (_) => setState(() => _priority = p),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _minutes,
                        decoration: changInput('Thời lượng dự kiến')
                            .copyWith(suffixText: 'phút'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n < 1 || n > 1440
                              ? 'Nhập 1–1440 phút.'
                              : null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ChoiceField(
                        label:
                            'Các bước nhỏ · ${_base.completedSubtaskCount}/${_base.subtasks.length} hoàn thành',
                        value: 'Quản lý ${_base.subtasks.length} bước',
                        icon: Icons.checklist_rounded,
                        onTap: _manageSteps,
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              if (_error != null && _pending == null)
                TextButton(
                  onPressed: _saving ? null : _reload,
                  child: const Text('Tải dữ liệu mới'),
                ),
              const SizedBox(height: 24),
              FeatureButton(
                _saving
                    ? 'Đang lưu…'
                    : _pending != null
                    ? 'Thử lưu lại'
                    : 'Lưu thay đổi',
                onPressed: _saving || (!_dirty && _pending == null)
                    ? null
                    : _save,
              ),
              const SizedBox(height: 10),
              FeatureButton(
                _pending != null ? 'Rời màn hình' : 'Hủy thay đổi',
                secondary: true,
                onPressed: _saving ? null : _leave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) =>
      '${date.day}/${date.month}/${date.year} · ${TimeOfDay.fromDateTime(date).format(context)}';
}
