import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../app/widgets/app_layout.dart';
import '../../../app/widgets/choice_sheet.dart';
import '../../../app/widgets/confirmation_dialog.dart';
import '../../../app/widgets/deadline_picker.dart';
import '../../../app/widgets/desktop_top_bar.dart';
import '../../../app/widgets/feature_surface.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../home/data/dashboard_provider.dart';
import '../data/task_management_repository.dart';
import '../data/task_repository.dart';
import '../domain/task_detail.dart';
import 'inbox_provider.dart';
import 'task_detail_page.dart';

class CreateTaskPage extends ConsumerStatefulWidget {
  const CreateTaskPage({super.key, this.initialProject});
  final TaskProjectSummary? initialProject;
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
  bool _saving = false, _dirty = false, _confirmingExit = false;
  Map<String, dynamic>? _pending;

  @override
  void initState() {
    super.initState();
    _project = widget.initialProject?.id;
  }

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

  Future<void> _back({bool toHome = false}) async {
    if (_saving || _confirmingExit) return;
    if (_dirty || _pending != null) {
      _confirmingExit = true;
      try {
        final leave = await showChangConfirmation(
          context,
          title: 'Rời form tạo việc?',
          message: _pending == null ? 'Các thông tin chưa lưu sẽ bị bỏ.' : 'Kết quả lưu chưa được xác nhận. Hãy kiểm tra Hộp việc trước khi tạo lại.',
          cancelLabel: 'Ở lại',
          confirmLabel: 'Rời form',
        );
        if (!leave || !mounted) return;
      } finally {
        _confirmingExit = false;
      }
    }
    if (toHome) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        context.go('/');
      }
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/tasks');
    }
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

  Widget _buildTitleAndDescriptionFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _title,
          maxLength: 200,
          decoration: changInput('Tên công việc *')
              .copyWith(filled: true, fillColor: Colors.white),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Nhập tên công việc.' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _description,
          maxLines: 3,
          maxLength: 4000,
          decoration: changInput('Mô tả')
              .copyWith(filled: true, fillColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStepsSection({required bool framed}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Các bước nhỏ · ${_steps.length}/5 bước',
          style: const TextStyle(
            color: changInk,
            fontSize: 18,
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
                    decoration: changInput('Bước ${i + 1}')
                        .copyWith(filled: true, fillColor: Colors.white),
                    validator: (v) => v == null || v.trim().isEmpty
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
                          WidgetsBinding.instance.addPostFrameCallback((_) {
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
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _steps.length == 5
                ? null
                : () => setState(() {
                    _steps.add(TextEditingController());
                    _dirty = true;
                  }),
            icon: const Icon(Icons.add),
            label: const Text('Thêm bước nhỏ'),
          ),
        ),
      ],
    );

    if (!framed) return content;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: content,
    );
  }

  Widget _buildMetadataFields(AsyncValue<List<TaskProject>> projects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        projects.when(
          data: (items) => ChoiceField(
            label: 'Dự án',
            icon: Icons.folder_outlined,
            value:
                items.where((p) => p.id == _project).firstOrNull?.name ??
                (_project == widget.initialProject?.id
                    ? widget.initialProject?.name
                    : null) ??
                'Không gắn dự án',
            onTap: () async {
              final value = await showChangChoices(
                context,
                title: 'Chọn dự án',
                subtitle: 'Gắn công việc vào một chặng học của bạn.',
                selected: _project ?? '',
                choices: [
                  const ChangChoice(
                    '',
                    'Không gắn dự án',
                    icon: Icons.inbox_outlined,
                  ),
                  for (final p in items)
                    ChangChoice(p.id, p.name, icon: Icons.folder_outlined),
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
              Text(
                _project == null
                    ? 'Chưa tải được dự án. Bạn vẫn có thể tạo việc không gắn dự án.'
                    : 'Dự án: ${widget.initialProject?.name ?? 'Đã chọn'}. Chưa tải được danh sách dự án.',
              ),
              TextButton(
                onPressed: () => ref.invalidate(taskProjectsProvider),
                child: const Text('Tải lại dự án'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _pickDate,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            side: const BorderSide(color: changBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
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
            fontSize: 16,
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
        const SizedBox(height: 20),
        TextFormField(
          controller: _minutes,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: changInput('Thời lượng dự kiến (phút)')
              .copyWith(filled: true, fillColor: Colors.white),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return n == null || n < _steps.length || n > 1440
                ? 'Nhập ${_steps.length}–1440 phút.'
                : null;
          },
        ),
      ],
    );
  }

  Widget _buildActions({required bool horizontal}) {
    final saveButton = FeatureButton(
      _saving
          ? 'Đang lưu…'
          : _pending != null
          ? 'Thử lưu lại'
          : 'Tạo công việc',
      onPressed: _saving ? null : _save,
    );
    final cancelButton = FeatureButton(
      'Hủy',
      onPressed: _saving ? null : _back,
      secondary: true,
    );

    if (horizontal) {
      return Row(
        children: [
          Expanded(child: cancelButton),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: saveButton),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [saveButton, const SizedBox(height: 10), cancelButton],
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(taskProjectsProvider);
    final locked = _saving || _pending != null;

    return PopScope(
      canPop: !_saving && !_dirty && _pending == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = AppLayout.isDesktopWidth(constraints.maxWidth);
          if (!isDesktop) {
            return FeatureSurface(
              title: 'Tạo công việc',
              onBack: _back,
              child: Form(
                key: _form,
                onChanged: () {
                  if (!_dirty) setState(() => _dirty = true);
                },
                child: Column(
                  key: const ValueKey('create-task-mobile-layout'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AbsorbPointer(
                      absorbing: locked,
                      child: ExcludeFocus(
                        excluding: locked,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTitleAndDescriptionFields(),
                            const SizedBox(height: 16),
                            _buildMetadataFields(projects),
                            const SizedBox(height: 22),
                            _buildStepsSection(framed: false),
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
                    _buildActions(horizontal: false),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.page,
            body: Column(
              children: [
                DesktopTopBar(
                  activeTab: DesktopNavTab.tasks,
                  onTapHome: () => _back(toHome: true),
                  onTapTasks: _back,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.s24,
                            AppSpacing.s24,
                            AppSpacing.s24,
                            AppSpacing.s40,
                          ),
                          child: Form(
                            key: _form,
                            onChanged: () {
                              if (!_dirty) setState(() => _dirty = true);
                            },
                            child: Column(
                              key: const ValueKey('create-task-desktop-layout'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _back,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      size: 20,
                                    ),
                                    label: const Text('Về công việc'),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tạo công việc',
                                            style: TextStyle(
                                              color: changInk,
                                              fontSize: 30,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Bắt đầu từ một việc cụ thể.',
                                            style: TextStyle(
                                              color: changMuted,
                                              fontSize: 15.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '* Thông tin bắt buộc',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 12,
                                      child: AbsorbPointer(
                                        absorbing: locked,
                                        child: ExcludeFocus(
                                          excluding: locked,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _buildTitleAndDescriptionFields(),
                                              const SizedBox(height: 20),
                                              _buildStepsSection(framed: true),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 28),
                                    Expanded(
                                      flex: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.r16,
                                          ),
                                          border: Border.all(
                                            color: AppColors.borderSubtle,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            AbsorbPointer(
                                              absorbing: locked,
                                              child: ExcludeFocus(
                                                excluding: locked,
                                                child: _buildMetadataFields(
                                                  projects,
                                                ),
                                              ),
                                            ),
                                            if (_error != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 16,
                                                ),
                                                child: Text(
                                                  _error!,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 24),
                                            _buildActions(horizontal: true),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
