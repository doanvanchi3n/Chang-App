import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation.dart';
import '../../../app/widgets/feature_surface.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../home/data/dashboard_provider.dart';
import '../../tasks/data/task_repository.dart';
import '../application/focus_controller.dart';
import '../domain/focus_session.dart';
import 'rest_page.dart';
import 'widgets/focus_session_widgets.dart';

class FocusSummary extends ConsumerStatefulWidget {
  const FocusSummary({
    super.key,
    required this.session,
    this.isDesktop = false,
  });

  final FocusSession session;
  final bool isDesktop;

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
    final isDesktop = widget.isDesktop;
    final state = ref.watch(focusControllerProvider);
    final seconds = session.elapsedMs ~/ 1000;
    final full = seconds >= session.targetSeconds;
    final task = session.taskId == null
        ? null
        : ref.watch(taskDetailProvider(session.taskId!)).asData?.value;
    final dashboard = ref.watch(dashboardProvider);
    final canEdit = !state.busy && !state.pending && !session.saved;

    return Column(
      key: ValueKey(
        isDesktop ? 'focus-summary-desktop-layout' : 'focus-summary-mobile-layout',
      ),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Image.asset(
            'assets/mascot/mascot_m30.png',
            key: const ValueKey('mascot-summary'),
            height: isDesktop ? 156 : 136,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            semanticLabel: 'Chặng ghi nhận phiên học',
          ),
        ),
        SizedBox(height: isDesktop ? 14 : 12),
        Text(
          full
              ? 'Bạn đã hoàn thành một phiên học.'
              : 'Bạn đã dành thời gian cho việc học.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: focusInk,
            fontSize: isDesktop ? 30 : 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          full
              ? 'Một khoảng thời gian dành cho việc học của bạn.'
              : 'Phiên kết thúc sớm. Mọi giây tập trung đều được ghi nhận.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isDesktop ? 15.5 : 14,
            height: 1.45,
          ),
        ),
        SizedBox(height: isDesktop ? 18 : 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            _MetricPill(
              icon: Icons.schedule_rounded,
              value: preciseDuration(seconds),
              label: 'tập trung thực tế',
            ),
            _MetricPill(
              icon: Icons.bar_chart_rounded,
              value: '1 phiên',
              label: full ? 'hoàn thành' : 'kết thúc sớm',
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 20 : 16),
        Text(
          session.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: focusInk,
            fontSize: isDesktop ? 21 : 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (session.stepTitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Bước ${session.stepOrder} · ${session.stepTitle}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.5,
              ),
            ),
          ),
        SizedBox(height: isDesktop ? 18 : 16),
        if (session.stepId != null)
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r16),
              side: const BorderSide(color: AppColors.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bước ${session.stepOrder} đã hoàn thành chưa?',
                    style: const TextStyle(
                      color: focusInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<bool>(
                    groupValue: _complete,
                    onChanged: (v) {
                      if (canEdit) {
                        setState(() => _complete = v);
                        ref
                                .read(focusControllerProvider.notifier)
                                .reviewComplete =
                            v;
                      }
                    },
                    child: isDesktop
                        ? Wrap(
                            key: const ValueKey('summary-desktop-radios'),
                            spacing: 28,
                            runSpacing: 4,
                            children: [
                              _InlineRadioOption(
                                value: true,
                                enabled: canEdit,
                                label:
                                    'Đã hoàn thành bước ${session.stepOrder}',
                                onSelect: (v) {
                                  setState(() => _complete = v);
                                  ref
                                          .read(focusControllerProvider.notifier)
                                          .reviewComplete =
                                      v;
                                },
                              ),
                              _InlineRadioOption(
                                value: false,
                                enabled: canEdit,
                                label: 'Cần làm tiếp',
                                onSelect: (v) {
                                  setState(() => _complete = v);
                                  ref
                                          .read(focusControllerProvider.notifier)
                                          .reviewComplete =
                                      v;
                                },
                              ),
                            ],
                          )
                        : Column(
                            key: const ValueKey('summary-mobile-radios'),
                            children: [
                              RadioListTile<bool>(
                                value: true,
                                enabled: canEdit,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: Text(
                                  'Đã hoàn thành bước ${session.stepOrder}',
                                ),
                              ),
                              RadioListTile<bool>(
                                value: false,
                                enabled: canEdit,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text('Cần làm tiếp'),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task == null
                        ? 'Chưa chọn: giữ nguyên tiến độ đã lưu.'
                        : 'Chưa chọn: giữ nguyên tiến độ ${task.completedSteps}/${task.steps.length} bước.',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const FeatureCard(
            child: Text(
              'Phiên này không gắn với bước nhỏ. Lưu phiên sẽ giữ nguyên trạng thái công việc.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Ghi chú sau phiên (tuỳ chọn)',
          style: TextStyle(
            color: focusInk,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          onChanged: (value) =>
              ref.read(focusControllerProvider.notifier).reviewNote = value,
          enabled: canEdit,
          maxLength: 2000,
          maxLines: isDesktop ? 1 : 2,
          decoration: InputDecoration(
            hintText: 'Bạn muốn ghi nhớ điều gì?',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide: const BorderSide(
                color: focusPrimaryBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        dashboard.when(
          data: (data) => _WeeklySummaryBanner(
            data: data,
            saved: session.saved,
            isDesktop: isDesktop,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text(
            'Chưa tải được tiến độ tuần. Bạn vẫn có thể lưu phiên.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              state.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (state.pending)
          FeatureButton(
            'Đồng bộ kết quả lưu',
            onPressed: state.busy
                ? null
                : () => ref.read(focusControllerProvider.notifier).reconcile(),
          )
        else
          _SummaryActionButtons(
            isDesktop: isDesktop,
            busy: state.busy,
            saved: session.saved,
            onSaveAndRest: () => _save(true),
            onSaveAndHome: () => _save(false),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                session.saved
                    ? 'Phiên đã được lưu.'
                    : 'Lựa chọn của bạn chỉ được cập nhật khi nhấn Lưu.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: focusSoftBlue,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: focusPrimaryBlue, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: focusInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineRadioOption extends StatelessWidget {
  const _InlineRadioOption({
    required this.value,
    required this.enabled,
    required this.label,
    required this.onSelect,
  });

  final bool value;
  final bool enabled;
  final String label;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r8),
      onTap: enabled ? () => onSelect(value) : null,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<bool>(
              value: value,
              enabled: enabled,
              activeColor: focusPrimaryBlue,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              label,
              style: const TextStyle(
                color: focusInk,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklySummaryBanner extends StatelessWidget {
  const _WeeklySummaryBanner({
    required this.data,
    required this.saved,
    required this.isDesktop,
  });

  final DashboardData data;
  final bool saved;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    const totalDots = 4;
    final filledDots = data.completedSessions.clamp(0, totalDots);
    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < totalDots; i++)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: i < filledDots ? focusPrimaryBlue : Colors.transparent,
              border: Border.all(color: focusPrimaryBlue, width: 1.5),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );

    final summaryText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Nhịp học tuần này',
              style: TextStyle(
                color: focusInk,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            Text(
              '· ${preciseDuration(data.weekSeconds)} đã lưu · ${data.completedSessions} phiên hoàn thành',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
        if (data.weekTargetMinutes != null || !saved)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              [
                if (data.weekTargetMinutes != null)
                  'Mục tiêu ${data.weekTargetMinutes} phút/tuần',
                if (!saved) 'Cập nhật sau khi lưu phiên này',
              ].join(' · '),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 18 : 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CC),
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: summaryText),
                const SizedBox(width: 12),
                dots,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                summaryText,
                const SizedBox(height: 8),
                dots,
              ],
            ),
    );
  }
}

class _SummaryActionButtons extends StatelessWidget {
  const _SummaryActionButtons({
    required this.isDesktop,
    required this.busy,
    required this.saved,
    required this.onSaveAndRest,
    required this.onSaveAndHome,
  });

  final bool isDesktop;
  final bool busy;
  final bool saved;
  final VoidCallback onSaveAndRest;
  final VoidCallback onSaveAndHome;

  @override
  Widget build(BuildContext context) {
    final primary = FilledButton(
      onPressed: busy ? null : onSaveAndRest,
      style: FilledButton.styleFrom(
        backgroundColor: focusPrimaryBlue,
        foregroundColor: AppColors.textInverse,
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
      ),
      child: Text(
        busy
            ? 'Đang lưu…'
            : saved
            ? 'Nghỉ 5 phút'
            : 'Lưu và nghỉ 5 phút',
      ),
    );

    final secondary = OutlinedButton(
      onPressed: busy ? null : onSaveAndHome,
      style: OutlinedButton.styleFrom(
        foregroundColor: focusPrimaryBlue,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: focusPrimaryBlue, width: 1.2),
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
      ),
      child: Text(saved ? 'Về hôm nay' : 'Lưu và về hôm nay'),
    );

    final useRow = isDesktop && MediaQuery.textScalerOf(context).scale(16) <= 24;
    if (useRow) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            key: const ValueKey('summary-desktop-actions-row'),
            children: [
              Expanded(child: primary),
              const SizedBox(width: AppSpacing.s16),
              Expanded(child: secondary),
            ],
          ),
        ),
      );
    }

    return Column(
      key: const ValueKey('summary-mobile-actions-column'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [primary, const SizedBox(height: 10), secondary],
    );
  }
}
