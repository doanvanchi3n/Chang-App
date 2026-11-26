import '../../../app/widgets/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/widgets/feature_surface.dart';
import '../../../app/widgets/choice_sheet.dart';
import 'background_audio_panel.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/task_detail.dart';
import '../application/focus_controller.dart';
import 'focus_navigation.dart';

class FocusPrepPage extends ConsumerStatefulWidget {
  const FocusPrepPage({super.key, required this.taskId, this.initialStep});
  final String taskId;
  final String? initialStep;
  @override
  ConsumerState<FocusPrepPage> createState() => _FocusPrepPageState();
}

class _FocusPrepPageState extends ConsumerState<FocusPrepPage> {
  final _custom = TextEditingController(text: '25');
  final _form = GlobalKey<FormState>();
  late String _taskId;
  String? _step;
  bool _stepChosen = false, _customMode = false;
  String _sound = 'SILENT';
  int _duration = 25;
  @override
  void initState() {
    super.initState();
    _taskId = widget.taskId;
    _step = widget.initialStep;
    _stepChosen = widget.initialStep != null;
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _changeTask() async {
    ref.invalidate(focusTaskChoicesProvider);
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
      builder: (context) => Consumer(
        builder: (context, ref, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ref
                .watch(focusTaskChoicesProvider)
                .when(
                  loading: () => const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => TextButton(
                    onPressed: () => ref.invalidate(focusTaskChoicesProvider),
                    child: const Text('Chưa tải được công việc. Thử lại'),
                  ),
                  data: (tasks) => ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .65,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        const Text(
                          'Chọn công việc',
                          style: TextStyle(
                            color: changInk,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (tasks.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Chưa có công việc đang thực hiện.'),
                          ),
                        for (final task in tasks)
                          ListTile(
                            title: Text(task.name),
                            leading: const Icon(
                              Icons.task_alt,
                              color: changBlue,
                            ),
                            onTap: () => Navigator.pop(context, task.id),
                          ),
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
    if (mounted && id != null) {
      setState(() {
        _taskId = id;
        _step = null;
        _stepChosen = false;
      });
    }
  }

  Future<void> _start(TaskDetail task, String? step) async {
    if (_customMode && !_form.currentState!.validate()) return;
    final controller = ref.read(focusControllerProvider.notifier);
    if (await controller.start(
      task.id,
      step,
      (_customMode ? int.parse(_custom.text) : _duration) * 60,
      _sound,
    )) {
      if (mounted) await openFocusSession(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final focus = ref.watch(focusControllerProvider);
    final ongoing = focus.session != null && !focus.session!.saved;
    return FeatureSurface(
      title: 'Chuẩn bị phiên học',
      trailing: IconButton(
        tooltip: 'Làm mới công việc',
        onPressed: focus.busy
            ? null
            : () => ref.invalidate(taskDetailProvider(_taskId)),
        icon: const Icon(Icons.refresh, color: changMuted),
      ),
      child: ref
          .watch(taskDetailProvider(_taskId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Column(
              children: [
                const Text('Chưa tải được công việc.'),
                TextButton(
                  onPressed: () => ref.invalidate(taskDetailProvider(_taskId)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
            data: (task) {
              if (task == null) {
                return const Text('Công việc không còn tồn tại.');
              }
              final pending = task.steps.where((s) => !s.completed).toList();
              final step = _stepChosen
                  ? pending.where((s) => s.id == _step).firstOrNull?.id
                  : pending.firstOrNull?.id;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FeatureCard(
                    color: changSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Công việc đã chọn',
                          style: TextStyle(color: changMuted, fontSize: 17),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.title,
                          style: const TextStyle(
                            color: changInk,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (task.project != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(label: Text(task.project!.name)),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${task.completedSteps}/${task.steps.length} bước đã hoàn thành',
                          style: const TextStyle(color: changMuted),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: changBorder),
                        ),
                        ChoiceField(
                          label: 'Tập trung vào',
                          icon: Icons.checklist_rounded,
                          value: step == null
                              ? 'Toàn bộ công việc'
                              : 'Bước ${pending.firstWhere((s) => s.id == step).order} · ${pending.firstWhere((s) => s.id == step).title}',
                          onTap: focus.busy || focus.pending
                              ? null
                              : () async {
                                  final value = await showChangChoices(
                                    context,
                                    title: 'Bạn muốn tập trung vào đâu?',
                                    subtitle: 'Chọn một bước nhỏ, hoặc dành phiên này cho cả công việc.',
                                    selected: step ?? '',
                                    choices: [
                                      const ChangChoice(
                                        '',
                                        'Toàn bộ công việc',
                                        subtitle: 'Tập trung chung, giữ nguyên tiến độ từng bước',
                                        icon: Icons.layers_outlined,
                                      ),
                                      for (final s in pending)
                                        ChangChoice(
                                          s.id,
                                          'Bước ${s.order} · ${s.title}',
                                          subtitle: '${s.minutes} phút dự kiến',
                                        ),
                                    ],
                                  );
                                  if (mounted && value != null) {
                                    setState(() {
                                      _step = value.isEmpty ? null : value;
                                      _stepChosen = true;
                                    });
                                  }
                                },
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: focus.busy ? null : _changeTask,
                            child: const Text('Đổi công việc'),
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/mascot/mascot-M27.svg',
                          height: 155,
                          semanticsLabel: 'Chặng chuẩn bị đọc sách',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Mình bắt đầu từ bước này nhé.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: changMuted, fontSize: 17),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FeatureCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Thiết lập phiên',
                          style: TextStyle(
                            color: changInk,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            for (final minutes in [15, 25, 45])
                              ChoiceChip(
                                label: Text('$minutes phút'),
                                selected: !_customMode && _duration == minutes,
                                selectedColor: changBlue,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: !_customMode && _duration == minutes
                                      ? Colors.white
                                      : changInk,
                                  fontWeight: FontWeight.w600,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(color: changBorder),
                                onSelected: focus.busy
                                    ? null
                                    : (_) => setState(() {
                                        _duration = minutes;
                                        _customMode = false;
                                      }),
                              ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: focus.busy
                                ? null
                                : () => setState(
                                    () => _customMode = !_customMode,
                                  ),
                            child: const Text('Tùy chỉnh'),
                          ),
                        ),
                        if (_customMode)
                          Form(
                            key: _form,
                            child: TextFormField(
                              controller: _custom,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              decoration: changInput('Thời lượng (1–180 phút)'),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                return n == null || n < 1 || n > 180
                                    ? 'Nhập 1–180 phút.'
                                    : null;
                              },
                            ),
                          ),
                        BackgroundAudioPanel(
                          code: _sound,
                          protectedCode: ongoing
                              ? focus.session?.soundCode
                              : null,
                          enabled: !focus.busy && !focus.pending,
                          onChanged: (value) => setState(() => _sound = value),
                        ),
                        const Divider(color: changBorder),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Phiên học không tự chặn các ứng dụng khác.',
                            style: TextStyle(color: changMuted),
                          ),
                        ),
                        if (focus.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              focus.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (focus.pending)
                          FeatureButton(
                            'Đồng bộ phiên đang chờ',
                            onPressed: focus.busy
                                ? null
                                : () => ref
                                      .read(focusControllerProvider.notifier)
                                      .reconcile(),
                          )
                        else if (ongoing)
                          FeatureButton(
                            'Mở phiên học đang có',
                            onPressed: () => openFocusSession(ref),
                          )
                        else
                          FeatureButton(
                            focus.busy ? 'Đang kết nối…' : 'Bắt đầu tập trung',
                            onPressed:
                                focus.busy ||
                                    task.isArchived ||
                                    task.status == TaskStatus.completed
                                ? null
                                : () => _start(task, step),
                          ),
                        const SizedBox(height: 10),
                        FeatureButton(
                          'Quay lại công việc',
                          onPressed: focus.busy
                              ? null
                              : () => Navigator.of(context).pop(),
                          secondary: true,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}
