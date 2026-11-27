import '../../../app/widgets/app_layout.dart';
import '../../../app/widgets/adaptive_content.dart';

import 'package:flutter/material.dart';

import '../../../app/widgets/confirmation_dialog.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../home/data/dashboard_provider.dart';
import '../../home/presentation/widgets/dashboard_sections.dart'
    show dashboardDate;
import '../data/daily_plan_repository.dart';
import '../domain/daily_plan.dart';
import 'inbox_provider.dart';
import 'widgets/daily_plan_widgets.dart';
import 'widgets/daily_plan_task_picker.dart';
import 'widgets/inbox_widgets.dart';

class DailyPlanPage extends ConsumerStatefulWidget {
  const DailyPlanPage({super.key, this.initialTaskIds = const []});
  final List<String> initialTaskIds;

  @override
  ConsumerState<DailyPlanPage> createState() => _DailyPlanPageState();
}

class _DailyPlanPageState extends ConsumerState<DailyPlanPage> {
  final _form = GlobalKey<FormState>();
  final _available = TextEditingController();
  final _minutes = <String, TextEditingController>{};
  final _chosen = <PlanningTask>[];
  DailyPlanData? _data;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _needsReload = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _available.dispose();
    for (final controller in _minutes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final data = await ref
          .read(dailyPlanRepositoryProvider)
          .load(DateTime(now.year, now.month, now.day));
      if (!mounted) return;
      for (final controller in _minutes.values) {
        controller.dispose();
      }
      _minutes.clear();
      _chosen.clear();
      _chosen.addAll(data.todayTasks);
      for (final id in widget.initialTaskIds) {
        final matches = data.tasks.where((task) => task.id == id);
        if (matches.isNotEmpty && !_chosen.any((task) => task.id == id)) {
          _chosen.add(matches.first);
        }
      }
      for (final task in data.tasks) {
        _minutes[task.id] = TextEditingController(
          text: task.minutes?.toString() ?? '',
        );
      }
      _available.text = data.availableMinutes?.toString() ?? '';
      setState(() {
        _data = data;
        _dirty = false;
        _needsReload = false;
        _notice =
            widget.initialTaskIds.any(
              (id) => !data.tasks.any((t) => t.id == id),
            )
            ? 'Một số việc đã thay đổi và không còn khả dụng để lên kế hoạch.'
            : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _needsReload = true;
          _error = 'Chưa tải được kế hoạch. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reload() async {
    if (_saving || _loading) return;
    if (_dirty) {
      final discard = await showChangConfirmation(
        context,
        title: 'Tải lại kế hoạch?',
        message: 'Các chỉnh sửa chưa lưu sẽ được thay bằng dữ liệu đã lưu.',
        cancelLabel: 'Giữ chỉnh sửa',
        confirmLabel: 'Tải lại',
      );
      if (discard != true || !mounted) return;
    }
    await _load();
  }

  void _changed() => setState(() => _dirty = true);

  void _move(int from, int to) {
    if (to < 0 || to >= _chosen.length) return;
    setState(() {
      final task = _chosen.removeAt(from);
      _chosen.insert(to, task);
      _dirty = true;
    });
  }

  Future<void> _pick() async {
    final chosenIds = _chosen.map((task) => task.id).toSet();
    final pool = _data!.tasks
        .where((task) => !chosenIds.contains(task.id))
        .toList();
    final ids = await showPlanTaskPicker(
      context,
      tasks: pool,
      today: planDateKey(_data!.date),
    );
    if (!mounted || ids == null) return;
    setState(() {
      _chosen.addAll(pool.where((task) => ids.contains(task.id)));
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_saving || _needsReload || !_form.currentState!.validate()) return;
    final data = _data!;
    if (planDateKey(DateTime.now()) != planDateKey(data.date)) {
      setState(() {
        _needsReload = true;
        _error =
            'Đã sang ngày mới. Hãy tải lại trước khi lưu kế hoạch hôm nay.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    var saved = false;
    try {
      final count = await ref
          .read(dailyPlanRepositoryProvider)
          .save(
            original: data,
            availableMinutes: int.parse(_available.text),
            tasks: [
              for (final task in _chosen)
                {
                  ...task.snapshot,
                  'estimated_minutes': int.parse(_minutes[task.id]!.text),
                },
            ],
          );
      if (count != _chosen.length) throw StateError('Incomplete save');
      saved = true;
    } catch (error) {
      if (mounted) {
        setState(() {
          _needsReload = true;
          _error = error is PostgrestException && error.code == '40001'
              ? 'Kế hoạch hoặc công việc đã thay đổi. Hãy tải lại để tránh ghi đè dữ liệu mới.'
              : 'Chưa xác nhận được kế hoạch đã lưu. Hãy tải lại dữ liệu trước khi thử lại.';
        });
      }
    } finally {
      if (mounted) {
        ref.invalidate(inboxProvider);
        ref.invalidate(dashboardProvider);
        setState(() => _saving = false);
      }
    }
    if (!mounted) return;
    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu kế hoạch hôm nay với ${_chosen.length} việc.'),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_error!)));
    }
  }

  Future<void> _back() async {
    if (_saving) return;
    if (_dirty) {
      final leave = await showChangConfirmation(
        context,
        title: 'Bỏ chỉnh sửa chưa lưu?',
        message: 'Kế hoạch đã lưu và công việc của bạn vẫn được giữ nguyên.',
        cancelLabel: 'Ở lại',
        confirmLabel: 'Quay lại',
      );
      if (leave != true || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && !_dirty,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_saving) _back();
    },
    child: AbsorbPointer(
      absorbing: _saving,
      child: ExcludeFocus(
        excluding: _saving,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxDesktopWidth,
                  ),
                  child: Padding(
                    padding: AppLayout.pagePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InboxHeader(onRefresh: _reload, showBack: false),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _back,
                            icon: const Icon(Icons.arrow_back),
                            label: Text(
                              widget.initialTaskIds.isEmpty
                                  ? 'Quay lại'
                                  : 'Về hộp việc',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: inboxBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Hôm nay, bạn muốn làm gì?',
                          style: TextStyle(
                            color: inboxInk,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${dashboardDate(_data?.date ?? DateTime.now())}/${(_data?.date ?? DateTime.now()).year}',
                          style: const TextStyle(
                            color: inboxMuted,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CircularProgressIndicator(
                                semanticsLabel: 'Đang tải kế hoạch',
                              ),
                            ),
                          )
                        else ...[
                          if (_error != null) ...[
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _reload,
                                child: const Text('Tải lại dữ liệu'),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_data != null) _editor(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _editor() {
    final durations = _chosen
        .map((task) => int.tryParse(_minutes[task.id]!.text))
        .toList();
    final valid = durations.every((m) => m != null && m >= 1 && m <= 1440);
    final total = durations.fold<int>(0, (sum, m) => sum + (m ?? 0));
    final budget = int.tryParse(_available.text);
    final budgetValid = budget != null && budget >= 1 && budget <= 1440;
    final remaining = budgetValid ? budget - total : null;
    return Form(
      key: _form,
      child: AdaptiveColumns(
        primaryFlex: 2,
        secondaryFlex: 1,
        primary: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlanBudget(controller: _available, onChanged: _changed),
            const SizedBox(height: 24),
            Text(
              '${_chosen.length} việc trong kế hoạch',
              style: const TextStyle(
                color: inboxInk,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gồm việc đã lên lịch hôm nay và việc bạn chọn thêm.',
              style: TextStyle(color: inboxMuted),
            ),
            if (_notice != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: PlanNotice(_notice!),
              ),
            const SizedBox(height: 16),
            if (_chosen.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: PlanNotice(
                  'Chưa chọn việc nào. Thêm việc từ Hộp việc hoặc các kế hoạch còn dang dở.',
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                // Keep the card's rounded Material; the default drag proxy paints
                // a rectangle behind the entire item, including its spacing.
                proxyDecorator: (child, _, _) => child,
                itemCount: _chosen.length,
                onReorderItem: _move,
                itemBuilder: (_, index) {
                  final task = _chosen[index];
                  return PlanTaskCard(
                    key: ValueKey(task.id),
                    task: task,
                    index: index,
                    total: _chosen.length,
                    minutes: _minutes[task.id]!,
                    onChanged: _changed,
                    onMove: (delta) => _move(index, index + delta),
                    onRemove: () => setState(() {
                      _chosen.removeAt(index);
                      _dirty = true;
                    }),
                  );
                },
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.add),
                label: const Text('Chọn thêm từ hộp việc'),
                style: TextButton.styleFrom(foregroundColor: inboxBlue),
              ),
            ),
            const SizedBox(height: 8),
            const PlanNotice(
              'Thứ tự là gợi ý; bạn có thể bắt đầu với bất kỳ việc nào.',
            ),
          ],
        ),
        secondary: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      Text(
                        '${_chosen.length} việc đã chọn',
                        style: const TextStyle(
                          color: inboxInk,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        valid ? '$total phút dự kiến' : 'Chưa đủ thời lượng',
                        style: const TextStyle(
                          color: inboxInk,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    !valid || remaining == null
                        ? 'Nhập thời lượng từng việc và quỹ thời gian để so sánh.'
                        : remaining > 0
                        ? 'Còn $remaining phút so với thời gian bạn chọn.'
                        : remaining == 0
                        ? 'Vừa đủ thời gian bạn chọn.'
                        : 'Vượt ${-remaining} phút so với thời gian bạn chọn. Bạn có thể điều chỉnh lại.',
                    style: TextStyle(
                      color: valid && remaining != null && remaining >= 0
                          ? const Color(0xFF237344)
                          : inboxMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const PlanNotice(
                    'Chưa xếp giờ cụ thể. Các lịch hẹn hiện có không thay đổi.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PlanActions(
              saving: _saving,
              onSave:
                  _saving ||
                      _needsReload ||
                      (_chosen.isEmpty && _data!.todayTasks.isEmpty)
                  ? null
                  : _save,
              onBack: _back,
            ),
            const SizedBox(height: 16),
            const PlanNotice(
              'Chỉ lưu khi bạn xác nhận. Việc bỏ khỏi kế hoạch hôm nay sẽ trở về Hộp việc.',
            ),
          ],
        ),
      ),
    );
  }
}
