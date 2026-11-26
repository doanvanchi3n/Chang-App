import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/navigation.dart';
import '../../../app/widgets/feature_surface.dart';
import '../../home/data/dashboard_provider.dart';
import '../../tasks/data/task_repository.dart';
import '../application/focus_controller.dart';
import '../domain/focus_session.dart';
import 'rest_page.dart';

class FocusSummary extends ConsumerStatefulWidget {
  const FocusSummary({super.key, required this.session});
  final FocusSession session;
  @override
  ConsumerState<FocusSummary> createState() => _FocusSummaryState();
}

class _FocusSummaryState extends ConsumerState<FocusSummary> {
  late final TextEditingController _note;
  bool? _complete;
  @override
  void initState() {
    super.initState();
    final controller = ref.read(focusControllerProvider.notifier);
    _note = TextEditingController(text: controller.reviewNote);
    _complete = controller.reviewComplete;
  }

  @override
  void didUpdateWidget(covariant FocusSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.session.saved && widget.session.saved) {
      _note.text = widget.session.note ?? '';
      _complete = widget.session.raw['confirmed_step_complete'] as bool?;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(bool rest) async {
    final controller = ref.read(focusControllerProvider.notifier);
    if (!widget.session.saved) {
      final success = await controller.command(
        'SAVE',
        complete: _complete,
        note: _note.text.trim(),
      );
      if (!success || !mounted) return;
    }
    final nav = rootNavigatorKey.currentState!;
    nav.popUntil((route) => route.isFirst);
    if (rest) {
      nav.push(MaterialPageRoute<void>(builder: (_) => const RestPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final state = ref.watch(focusControllerProvider);
    final seconds = session.elapsedMs ~/ 1000;
    final full = seconds >= session.targetSeconds;
    final task = session.taskId == null
        ? null
        : ref.watch(taskDetailProvider(session.taskId!)).asData?.value;
    final dashboard = ref.watch(dashboardProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SvgPicture.asset(
          'assets/mascot/mascot-M30.svg',
          height: 170,
          semanticsLabel: 'Chặng ghi nhận phiên học',
        ),
        const SizedBox(height: 16),
        Text(
          full
              ? 'Bạn đã hoàn thành một phiên học.'
              : 'Bạn đã dành thời gian cho việc học.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: changInk,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          full
              ? 'Một chặng nhỏ đã hoàn thành.'
              : 'Phiên kết thúc sớm. Mọi giây tập trung đều được ghi nhận.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: changMuted, height: 1.5),
        ),
        const SizedBox(height: 20),
        FeatureCard(
          color: changSoft,
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 20,
            runSpacing: 12,
            children: [
              Column(
                children: [
                  const Icon(Icons.schedule, color: changBlue),
                  Text(
                    preciseDuration(seconds),
                    style: const TextStyle(
                      color: changInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text('tập trung thực tế'),
                ],
              ),
              Column(
                children: [
                  const Icon(Icons.bar_chart, color: changBlue),
                  const Text(
                    '1 phiên',
                    style: TextStyle(
                      color: changInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(full ? 'hoàn thành' : 'kết thúc sớm'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          session.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: changInk,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (session.stepTitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 20),
            child: Text(
              'Bước ${session.stepOrder} · ${session.stepTitle}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: changMuted),
            ),
          ),
        if (session.stepId != null)
          FeatureCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bước ${session.stepOrder} đã hoàn thành chưa?',
                  style: const TextStyle(
                    color: changInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                RadioGroup<bool>(
                  groupValue: _complete,
                  onChanged: (v) {
                    if (!state.busy && !state.pending && !session.saved) {
                      setState(() => _complete = v);
                      ref
                              .read(focusControllerProvider.notifier)
                              .reviewComplete =
                          v;
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        value: true,
                        enabled:
                            !state.busy && !state.pending && !session.saved,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Đã hoàn thành bước này'),
                      ),
                      RadioListTile<bool>(
                        value: false,
                        enabled:
                            !state.busy && !state.pending && !session.saved,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cần làm tiếp'),
                      ),
                    ],
                  ),
                ),
                Text(
                  task == null
                      ? 'Chưa chọn: giữ nguyên tiến độ đã lưu.'
                      : 'Chưa chọn: giữ nguyên tiến độ ${task.completedSteps}/${task.steps.length} bước.',
                  style: const TextStyle(color: changMuted, height: 1.5),
                ),
              ],
            ),
          )
        else
          const FeatureCard(
            child: Text(
              'Phiên này không gắn với bước nhỏ. Lưu phiên sẽ giữ nguyên trạng thái công việc.',
              style: TextStyle(color: changMuted, height: 1.5),
            ),
          ),
        const SizedBox(height: 20),
        TextField(
          controller: _note,
          onChanged: (value) =>
              ref.read(focusControllerProvider.notifier).reviewNote = value,
          enabled: !state.busy && !state.pending && !session.saved,
          maxLength: 2000,
          maxLines: 3,
          decoration: changInput('Ghi chú sau phiên (tùy chọn)'),
        ),
        const SizedBox(height: 16),
        dashboard.when(
          data: (data) => FeatureCard(
            color: const Color(0xFFFFF5D7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhịp học tuần này',
                  style: TextStyle(
                    color: changInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${preciseDuration(data.weekSeconds)} đã lưu · ${data.completedSessions} phiên hoàn thành',
                  style: const TextStyle(color: changMuted),
                ),
                if (data.weekTargetMinutes != null)
                  Text(
                    'Mục tiêu ${data.weekTargetMinutes} phút/tuần',
                    style: const TextStyle(color: changMuted),
                  ),
                if (!session.saved)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Số liệu cập nhật sau khi lưu phiên này.',
                      style: TextStyle(color: changMuted, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text(
            'Chưa tải được tiến độ tuần. Bạn vẫn có thể lưu phiên.',
            style: TextStyle(color: changMuted),
          ),
        ),
        const SizedBox(height: 20),
        if (state.error != null)
          Text(
            state.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (state.pending)
          FeatureButton(
            'Đồng bộ kết quả lưu',
            onPressed: state.busy
                ? null
                : () => ref.read(focusControllerProvider.notifier).reconcile(),
          )
        else ...[
          FeatureButton(
            state.busy
                ? 'Đang lưu…'
                : session.saved
                ? 'Nghỉ 5 phút'
                : 'Lưu và nghỉ 5 phút',
            onPressed: state.busy ? null : () => _save(true),
          ),
          const SizedBox(height: 10),
          FeatureButton(
            session.saved ? 'Về hôm nay' : 'Lưu và về hôm nay',
            secondary: true,
            onPressed: state.busy ? null : () => _save(false),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          session.saved
              ? 'Phiên đã được lưu.'
              : 'Lựa chọn của bạn chỉ được cập nhật khi bấm lưu.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: changMuted, fontSize: 13),
        ),
      ],
    );
  }
}
