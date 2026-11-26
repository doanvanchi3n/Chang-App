import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/widgets/feature_surface.dart';
import '../../../app/widgets/choice_sheet.dart';
import '../../../app/widgets/deadline_picker.dart';
import '../../home/data/dashboard_provider.dart';
import '../data/task_repository.dart';
import '../data/task_management_repository.dart';
import 'inbox_provider.dart';
import 'task_detail_page.dart';

class CreateTaskPage extends ConsumerStatefulWidget {
  const CreateTaskPage({super.key});
  @override
  ConsumerState<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends ConsumerState<CreateTaskPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController(),
      _minutes = TextEditingController(text: '25');
  final _steps = List.generate(3, (_) => TextEditingController());
  final _id = const Uuid().v4();
  String? _project, _error;
  String _priority = 'MEDIUM';
  DateTime? _due;
  bool _saving = false, _dirty = false;
  Map<String, dynamic>? _pending;
  @override
  void dispose() {
    for (final c in [_title, _description, _minutes, ..._steps]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final due = await showChangDeadline(context, initial: _due);
    if (!mounted || due == null) return;
    setState(() {
      _due = due;
      _dirty = true;
    });
  }

  Future<void> _back() async {
    if (_saving) return;
    if (_dirty || _pending != null) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rời form tạo việc?'),
          content: Text(
            _pending == null ? 'Các thông tin chưa lưu sẽ bị bỏ.' : 'Kết quả lưu chưa được xác nhận. Hãy kiểm tra Hộp việc trước khi tạo lại.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ở lại'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Rời form'),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_pending == null) {
      if (!_form.currentState!.validate()) return;
      if (_due != null && !_due!.isAfter(DateTime.now())) {
        setState(() => _error = 'Hạn hoàn thành phải ở tương lai.');
        return;
      }
      _pending = {
        'p_id': _id,
        'p_title': _title.text.trim(),
        'p_description': _description.text.trim(),
        'p_project_id': _project,
        'p_due_date': _due?.toUtc().toIso8601String(),
        'p_priority': _priority,
        'p_minutes': int.parse(_minutes.text),
        'p_steps': _steps.map((c) => c.text.trim()).toList(),
      };
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await ref.read(taskRepositoryProvider).create(_pending!);
      if (!mounted) return;
      ref.invalidate(taskListProvider);
      ref.invalidate(inboxProvider);
      ref.invalidate(dashboardProvider);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => TaskDetailPage(taskId: id)),
      );
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          if (['22023', '42501'].contains(error.code)) {
            _pending = null;
            if (error.code == '42501') _project = null;
            _error = 'Chưa lưu công việc. Kiểm tra hạn hoàn thành, dự án và các bước rồi thử lại.';
            ref.invalidate(taskProjectsProvider);
          } else {
            _error = 'Chưa lưu được công việc. Kiểm tra kết nối rồi thử lại.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa xác nhận được công việc đã lưu. Thử lại sẽ dùng cùng yêu cầu, không tạo việc trùng.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(taskProjectsProvider);
    return PopScope(
      canPop: !_saving && !_dirty && _pending == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: FeatureSurface(
        title: 'Tạo công việc',
        onBack: _back,
        child: Form(
          key: _form,
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        decoration: changInput('Tên công việc *'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Nhập tên công việc.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _description,
                        maxLines: 3,
                        maxLength: 4000,
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
                              'Không gắn dự án',
                          onTap: () async {
                            final value = await showChangChoices(
                              context,
                              title: 'Chọn dự án',
                              subtitle:
                                  'Gắn công việc vào một chặng học của bạn.',
                              selected: _project ?? '',
                              choices: [
                                const ChangChoice(
                                  '',
                                  'Không gắn dự án',
                                  icon: Icons.inbox_outlined,
                                ),
                                for (final p in items)
                                  ChangChoice(
                                    p.id,
                                    p.name,
                                    icon: Icons.folder_outlined,
                                  ),
                              ],
                            );
                            if (mounted && value != null) {
                              setState(() {
                                _project = value.isEmpty ? null : value;
                                _dirty = true;
                              });
                            }
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => Column(
                          children: [
                            const Text(
                              'Chưa tải được dự án. Bạn vẫn có thể tạo việc không gắn dự án.',
                            ),
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(taskProjectsProvider),
                              child: const Text('Tải lại dự án'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          _due == null
                              ? 'Chọn hạn hoàn thành (không bắt buộc)'
                              : '${_due!.day}/${_due!.month}/${_due!.year} · ${TimeOfDay.fromDateTime(_due!).format(context)}',
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
                      const SizedBox(height: 18),
                      const Text(
                        'Ưu tiên',
                        style: TextStyle(
                          color: changInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          for (final pair in [
                            ('LOW', 'Thấp'),
                            ('MEDIUM', 'Vừa'),
                            ('HIGH', 'Cao'),
                          ])
                            ChoiceChip(
                              label: Text(pair.$2),
                              selected: _priority == pair.$1,
                              selectedColor: pair.$1 == 'HIGH'
                                  ? const Color(0xFFFFE2D7)
                                  : changSoft,
                              onSelected: (_) => setState(() {
                                _priority = pair.$1;
                                _dirty = true;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _minutes,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: changInput('Thời lượng dự kiến (phút)'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n < _steps.length || n > 1440
                              ? 'Nhập ${_steps.length}–1440 phút.'
                              : null;
                        },
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Các bước nhỏ · ${_steps.length}/5 bước',
                        style: const TextStyle(
                          color: changInk,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Chia thành 1–5 bước rõ ràng. Thời lượng dự kiến được chia đều giữa các bước.',
                        style: TextStyle(color: changMuted, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < _steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: ObjectKey(_steps[i]),
                                  controller: _steps[i],
                                  maxLength: 200,
                                  decoration: changInput('Bước ${i + 1}'),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Nhập nội dung bước.'
                                      : null,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Bỏ bước ${i + 1}',
                                onPressed: _steps.length <= 1
                                    ? null
                                    : () {
                                        final removed = _steps.removeAt(i);
                                        setState(() => _dirty = true);
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              removed.dispose();
                                            });
                                      },
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: changMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextButton.icon(
                        onPressed: _steps.length == 5
                            ? null
                            : () => setState(() {
                                _steps.add(TextEditingController());
                                _dirty = true;
                              }),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm bước nhỏ'),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FeatureButton(
                _saving
                    ? 'Đang lưu…'
                    : _pending != null
                    ? 'Thử lưu lại'
                    : 'Tạo công việc',
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: 10),
              FeatureButton(
                'Hủy',
                onPressed: _saving ? null : _back,
                secondary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
