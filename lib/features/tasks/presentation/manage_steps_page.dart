import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/widgets/app_layout.dart';
import '../../../app/widgets/feature_surface.dart';
import '../data/task_management_repository.dart';
import '../domain/task_detail.dart';
import 'task_detail_provider.dart';
import 'widgets/task_draft_helpers.dart';

class ManageStepsPage extends ConsumerStatefulWidget {
  const ManageStepsPage({super.key, required this.task});
  final TaskDetail task;
  @override
  ConsumerState<ManageStepsPage> createState() => _ManageStepsPageState();
}

class _StepDraft {
  _StepDraft(this.id, String name, int minutes, this.completed)
    : title = TextEditingController(text: name),
      duration = TextEditingController(text: '$minutes');
  final String id;
  final TextEditingController title, duration;
  bool completed;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title.text.trim(),
    'estimated_minutes': int.tryParse(duration.text) ?? 0,
    'is_completed': completed,
  };
  void dispose() {
    title.dispose();
    duration.dispose();
  }
}

class _ManageStepsPageState extends ConsumerState<ManageStepsPage> {
  late TaskDetail _base;
  final _form = GlobalKey<FormState>();
  final _steps = <_StepDraft>[];
  final _retired = <_StepDraft>[];
  late String _original;
  String? _error;
  bool _saving = false, _leaving = false;
  Map<String, dynamic>? _pending;
  List<Map<String, dynamic>> get _payload =>
      _steps.map((s) => s.toJson()).toList();
  bool get _dirty => jsonEncode(_payload) != _original;
  @override
  void initState() {
    super.initState();
    _load(widget.task);
  }

  void _load(TaskDetail task) {
    _retired.addAll(_steps);
    _steps.clear();
    _base = task;
    _steps.addAll(
      task.subtasks.map(
        (s) => _StepDraft(s.id, s.title, s.estimatedMinutes, s.isCompleted),
      ),
    );
    _original = jsonEncode(_payload);
    _pending = null;
    _error = null;
  }

  @override
  void dispose() {
    for (final s in [..._steps, ..._retired]) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _leave([bool saved = false]) async {
    if (_saving) return;
    if (!saved && _pending != null) {
      if (!await confirmLeavePendingTaskSave(context) || !mounted) return;
      invalidateTaskViews(ref, _base.id);
    }
    if (!saved &&
        _pending == null &&
        _dirty &&
        !await confirmDiscardTaskDraft(context)) {
      return;
    }
    if (!mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, saved);
    });
  }

  Future<void> _reload() async {
    if (_dirty && !await confirmDiscardTaskDraft(context)) return;
    setState(() => _saving = true);
    try {
      ref.invalidate(taskDetailProvider(_base.id));
      final task = await ref.read(taskDetailProvider(_base.id).future);
      if (!mounted) return;
      if (task == null) {
        setState(() => _error = 'Công việc không còn tồn tại.');
      } else {
        setState(() => _load(task));
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Chưa tải được dữ liệu mới.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_pending == null && !_form.currentState!.validate()) return;
    _pending ??= {
      'p_task': _base.id,
      'p_request': const Uuid().v4(),
      'p_expected': _base.updatedAt.toUtc().toIso8601String(),
      'p_steps': _payload,
    };
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(taskManagementRepositoryProvider).saveSteps(_pending!);
      if (!mounted) return;
      invalidateTaskViews(ref, _base.id);
      _saving = false;
      await _leave(true);
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

  Future<void> _menu(_StepDraft step) async {
    final index = _steps.indexOf(step);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppLayout.pagePadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  step.title.text.trim().isEmpty
                      ? 'Bước ${index + 1}'
                      : step.title.text,
                  style: const TextStyle(
                    color: changInk,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  enabled: index > 0,
                  leading: const Icon(Icons.arrow_upward),
                  title: const Text('Đưa lên'),
                  onTap: () => Navigator.pop(sheet, 'up'),
                ),
                ListTile(
                  enabled: index < _steps.length - 1,
                  leading: const Icon(Icons.arrow_downward),
                  title: const Text('Đưa xuống'),
                  onTap: () => Navigator.pop(sheet, 'down'),
                ),
                ListTile(
                  textColor: Colors.red.shade700,
                  iconColor: Colors.red.shade700,
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Xóa bước'),
                  onTap: () => Navigator.pop(sheet, 'delete'),
                ),
                const Divider(color: changBorder),
                FeatureButton(
                  'Đóng',
                  secondary: true,
                  onPressed: () => Navigator.pop(sheet),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      final i = _steps.indexOf(step);
      if (action == 'delete') {
        _retired.add(_steps.removeAt(i));
      }
      if (action == 'up' && i > 0) {
        _steps.removeAt(i);
        _steps.insert(i - 1, step);
      }
      if (action == 'down' && i < _steps.length - 1) {
        _steps.removeAt(i);
        _steps.insert(i + 1, step);
      }
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _leaving || (!_dirty && !_saving && _pending == null),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: FeatureSurface(
      title: 'Quản lý bước nhỏ',
      onBack: _leave,
      child: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _base.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: changInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_steps.where((s) => s.completed).length}/${_steps.length} bước hoàn thành',
              style: const TextStyle(color: changMuted),
            ),
            const SizedBox(height: 20),
            AbsorbPointer(
              absorbing: _saving || _pending != null,
              child: ExcludeFocus(
                excluding: _saving || _pending != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final step in _steps)
                      Padding(
                        key: ValueKey(step.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: step.completed ? changSoft : Colors.white,
                            border: Border.all(color: changBorder),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: step.completed,
                                    activeColor: changBlue,
                                    onChanged: (v) =>
                                        setState(() => step.completed = v!),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: step.title,
                                      maxLength: 200,
                                      minLines: 1,
                                      maxLines: 3,
                                      decoration: changInput(
                                        'Bước ${_steps.indexOf(step) + 1}',
                                      ).copyWith(counterText: ''),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                          ? 'Nhập tên bước.'
                                          : null,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip:
                                        'Tùy chọn bước ${_steps.indexOf(step) + 1}',
                                    onPressed: () => _menu(step),
                                    icon: const Icon(
                                      Icons.more_horiz,
                                      color: changInk,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: step.duration,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: changInput('Thời lượng dự kiến')
                                    .copyWith(
                                      suffixText: 'phút',
                                      prefixIcon: const Icon(
                                        Icons.schedule,
                                        size: 20,
                                      ),
                                    ),
                                validator: (v) {
                                  final n = int.tryParse(v ?? '');
                                  return n == null || n < 1 || n > 1440
                                      ? 'Nhập 1–1440 phút.'
                                      : null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_steps.isEmpty)
                      const FeatureCard(
                        color: changSoft,
                        child: Text(
                          'Chia việc thành những bước vừa sức. Bạn có thể thêm tối đa 5 bước.',
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _steps.length >= 5
                          ? null
                          : () => setState(
                              () => _steps.add(
                                _StepDraft(const Uuid().v4(), '', 25, false),
                              ),
                            ),
                      icon: const Icon(Icons.add),
                      label: Text('Thêm bước · ${_steps.length}/5'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dùng menu ⋯ để đổi thứ tự hoặc xóa. Các thay đổi chỉ được cập nhật khi bạn lưu.',
              style: TextStyle(color: changMuted),
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
            const SizedBox(height: 20),
            FeatureButton(
              _saving
                  ? 'Đang lưu…'
                  : _pending != null
                  ? 'Thử lưu lại'
                  : 'Lưu các bước',
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
