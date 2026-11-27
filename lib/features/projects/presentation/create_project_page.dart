import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../app/widgets/choice_sheet.dart';
import '../../../app/widgets/deadline_picker.dart';
import '../../../app/widgets/feature_surface.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/presentation/widgets/task_draft_helpers.dart';
import '../data/project_repository.dart';
import '../domain/study_project.dart';
import 'project_detail_page.dart';
import 'widgets/project_widgets.dart';

class CreateProjectPage extends ConsumerStatefulWidget {
  const CreateProjectPage({super.key});
  @override
  ConsumerState<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends ConsumerState<CreateProjectPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _goal = TextEditingController();
  final _id = const Uuid().v4();
  String _color = '#006BFF', _icon = 'folder';
  String? _error;
  DateTime? _deadline;
  bool _dirty = false, _saving = false;
  Map<String, dynamic>? _pending;
  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (_saving) return;
    if (_pending != null) {
      if (!await confirmLeavePendingTaskSave(context) || !mounted) return;
    } else if (_dirty) {
      if (!await confirmDiscardTaskDraft(context) || !mounted) return;
    }
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go('/projects');
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showChangDate(
      context,
      initial: _deadline,
      title: 'Hạn hoàn thành dự án',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _deadline = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_pending == null) {
      if (!_form.currentState!.validate()) return;
      if (_deadline != null && !_deadline!.isAfter(DateTime.now())) {
        setState(() => _error = 'Chọn hạn hoàn thành từ hôm nay trở đi.');
        return;
      }
      _pending = {
        'p_id': _id,
        'p_name': _name.text.trim(),
        'p_description': _goal.text.trim(),
        'p_deadline': _deadline?.toUtc().toIso8601String(),
        'p_color': _color,
        'p_icon': _icon,
      };
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    FocusScope.of(context).unfocus();
    try {
      final id = await ref.read(projectRepositoryProvider).create(_pending!);
      if (!mounted) return;
      ref.invalidate(projectListProvider);
      ref.invalidate(taskProjectsProvider);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ProjectDetailPage(projectId: id),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (isDefiniteTaskRejection(error)) _pending = null;
        _error =
            error is PostgrestException &&
                ['PGRST202', '42883', '42703'].contains(error.code)
            ? 'Cần chạy file SQL FEAT-10, 11 trong Supabase trước khi tạo dự án.'
            : _pending == null
            ? 'Chưa lưu dự án. Kiểm tra thông tin rồi thử lại.'
            : 'Chưa xác nhận được kết quả lưu. Thử lại sẽ dùng cùng yêu cầu để tránh tạo trùng.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && !_dirty && _pending == null,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: FeatureSurface(
      title: 'Về dự án',
      onBack: _back,
      child: Form(
        key: _form,
        onChanged: () => setState(() => _dirty = true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tạo dự án học tập',
              style: TextStyle(
                color: changInk,
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bắt đầu tổ chức kế hoạch học tập của bạn.',
              style: TextStyle(color: changMuted, height: 1.5),
            ),
            const SizedBox(height: 22),
            AbsorbPointer(
              absorbing: _saving || _pending != null,
              child: ExcludeFocus(
                excluding: _saving || _pending != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      maxLength: 150,
                      decoration: changInput('Tên dự án *').copyWith(
                        suffixIcon: _name.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Xóa tên dự án',
                                onPressed: () => setState(_name.clear),
                                icon: const Icon(Icons.close),
                              ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Nhập tên dự án.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _goal,
                      maxLength: 4000,
                      minLines: 2,
                      maxLines: 4,
                      decoration: changInput('Mục tiêu'),
                    ),
                    const SizedBox(height: 14),
                    ChoiceField(
                      label: 'Hạn hoàn thành',
                      icon: Icons.calendar_month_outlined,
                      value: _deadline == null
                          ? 'Chọn ngày (không bắt buộc)'
                          : projectDate(_deadline!),
                      onTap: _pickDeadline,
                    ),
                    if (_deadline != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() {
                            _deadline = null;
                            _dirty = true;
                          }),
                          child: const Text('Bỏ hạn hoàn thành'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ChoiceField(
                      label: 'Biểu tượng',
                      icon: projectIcon(_icon),
                      value: projectIcons[_icon]!,
                      onTap: () async {
                        final icon = await showChangChoices(
                          context,
                          title: 'Biểu tượng dự án',
                          subtitle:
                              'Chọn biểu tượng giúp bạn dễ nhận ra dự án.',
                          selected: _icon,
                          choices: [
                            for (final item in projectIcons.entries)
                              ChangChoice(
                                item.key,
                                item.value,
                                icon: projectIcon(item.key),
                              ),
                          ],
                        );
                        if (mounted && icon != null) {
                          setState(() {
                            _icon = icon;
                            _dirty = true;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Màu nhận diện',
                      style: TextStyle(
                        color: changInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final item in projectColors.entries)
                            SizedBox(
                              width: (constraints.maxWidth - 10) / 2,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  minimumSize: const Size(0, 48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                  backgroundColor: _color == item.key
                                      ? changSoft
                                      : Colors.white,
                                  side: BorderSide(
                                    color: _color == item.key
                                        ? changBlue
                                        : changBorder,
                                  ),
                                ),
                                onPressed: () => setState(() {
                                  _color = item.key;
                                  _dirty = true;
                                }),
                                icon: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: projectColor(item.key),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _color == item.key
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                label: Text(item.value),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Xem trước',
              style: TextStyle(color: changInk, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            FeatureCard(
              color: changSoft,
              child: Row(
                children: [
                  ProjectSymbol(colorHex: _color, iconName: _icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name.text.trim().isEmpty
                              ? 'Tên dự án của bạn'
                              : _name.text.trim(),
                          style: const TextStyle(
                            color: changInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _deadline == null
                              ? 'Chưa đặt hạn'
                              : 'Hạn ${projectDate(_deadline!)}',
                          style: const TextStyle(
                            color: changMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Chưa có công việc',
                          style: TextStyle(color: changMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bạn có thể thêm công việc sau khi tạo dự án.',
              style: TextStyle(color: changMuted, fontSize: 13),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 18),
            FeatureButton(
              _saving
                  ? 'Đang tạo…'
                  : _pending != null
                  ? 'Thử lưu lại'
                  : 'Tạo dự án',
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
