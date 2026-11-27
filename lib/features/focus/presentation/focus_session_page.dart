import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/feature_surface.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../application/focus_controller.dart';
import '../domain/focus_session.dart';
import 'focus_summary.dart';
import 'widgets/focus_session_widgets.dart';

class FocusSessionPage extends ConsumerWidget {
  const FocusSessionPage({super.key});

  void _minimize(BuildContext context, FocusController controller) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    controller.expanded(false);
    context.go('/');
  }

  Future<void> _confirmFinish(
    BuildContext context,
    FocusController controller,
  ) async {
    final end = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kết thúc phiên tại đây?'),
        content: const Text(
          'Thời gian đã tập trung sẽ được giữ nguyên để bạn xem và xác nhận tiến độ ở phần tổng kết.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tiếp tục phiên'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );
    if (end == true) {
      await controller.command('FINISH');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusControllerProvider);
    final controller = ref.read(focusControllerProvider.notifier);
    final session = state.session;
    final isSummary = session?.reviewing == true || session?.saved == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = isFocusDesktopWidth(constraints.maxWidth);
        final modeTitle = isSummary
            ? (isDesktop ? 'Tổng kết phiên học' : 'Tổng kết phiên')
            : isDesktop
            ? 'Chế độ tập trung'
            : 'Tập trung';

        return Scaffold(
          backgroundColor: AppColors.page,
          body: Column(
            children: [
              if (isDesktop)
                FocusWebTopBar(
                  modeLabel: modeTitle,
                  closeIcon: isSummary,
                  onMinimize: () => _minimize(context, controller),
                )
              else
                FocusMobileTopBar(
                  title: modeTitle,
                  onMinimize: () => _minimize(context, controller),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, bodyConstraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: bodyConstraints.maxHeight,
                        ),
                        child: Center(
                          child: session == null
                              ? _buildEmptyState(context, state, controller)
                              : isSummary
                              ? _buildSummaryBody(
                                  context,
                                  session,
                                  isDesktop: isDesktop,
                                )
                              : _buildActiveBody(
                                  context,
                                  state,
                                  controller,
                                  session,
                                  isDesktop: isDesktop,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    FocusState state,
    FocusController controller,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.timer_outlined, size: 44, color: focusPrimaryBlue),
            const SizedBox(height: AppSpacing.s12),
            Text(
              state.pending
                  ? 'Phiên học đang chờ xác nhận.'
                  : 'Chưa có phiên học đang mở.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            FeatureButton(
              'Đồng bộ lại',
              onPressed: state.busy ? null : controller.reconcile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBody(
    BuildContext context,
    FocusSession session, {
    required bool isDesktop,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isDesktop ? 760 : 520),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? AppSpacing.s32 : 20,
          isDesktop ? AppSpacing.s24 : AppSpacing.s8,
          isDesktop ? AppSpacing.s32 : 20,
          AppSpacing.s32,
        ),
        child: FocusSummary(
          key: ValueKey(session.id),
          session: session,
          isDesktop: isDesktop,
        ),
      ),
    );
  }

  Widget _buildActiveBody(
    BuildContext context,
    FocusState state,
    FocusController controller,
    FocusSession session, {
    required bool isDesktop,
  }) {
    final remaining = controller.remainingSeconds;
    final elapsed = controller.elapsedSeconds;
    final progress = computeFocusProgress(
      controller.elapsedMs,
      session.targetSeconds,
    );
    final targetMinutes = (session.targetSeconds / 60).round().clamp(1, 180);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isDesktop ? 680 : 520),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? AppSpacing.s32 : 20,
          isDesktop ? AppSpacing.s24 : AppSpacing.s8,
          isDesktop ? AppSpacing.s32 : 20,
          isDesktop ? AppSpacing.s32 : AppSpacing.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (session.project != null) ...[
              FocusPillBadge(label: session.project!),
              SizedBox(height: isDesktop ? 14 : 10),
            ],
            Text(
              session.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: focusInk,
                fontSize: isDesktop ? 30 : 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                height: 1.22,
              ),
            ),
            if (session.stepTitle != null) ...[
              const SizedBox(height: 6),
              Text(
                'Bước ${session.stepOrder} · ${session.stepTitle}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: isDesktop ? 16 : 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            SizedBox(height: isDesktop ? 14 : 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                FocusPillBadge(label: 'Phiên học · $targetMinutes phút'),
                if (session.paused)
                  const FocusPillBadge(
                    label: 'Đang tạm dừng',
                    icon: Icons.pause_rounded,
                    backgroundColor: AppColors.honeySoft,
                    foregroundColor: AppColors.warning,
                  ),
                if (state.pending)
                  const FocusPillBadge(
                    label: 'Đang chờ đồng bộ',
                    icon: Icons.sync,
                    backgroundColor: AppColors.subtle,
                    foregroundColor: AppColors.textSecondary,
                  ),
              ],
            ),
            SizedBox(height: isDesktop ? 14 : 10),
            Semantics(
              label: 'Thời gian còn lại ${formatFocusClock(remaining)}',
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatFocusClock(remaining),
                  key: const ValueKey('focus-countdown-text'),
                  style: TextStyle(
                    color: focusInk,
                    fontSize: isDesktop ? 84 : 62,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 14 : 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 520 : double.infinity,
              ),
              child: FocusProgressTrack(
                progress: progress,
                paused: session.paused,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              session.paused
                  ? 'Đã tập trung ${formatElapsedDuration(elapsed)} · Thời gian tạm dừng không được tính.'
                  : 'Đã trôi qua ${formatElapsedDuration(elapsed)} · Còn lại ${formatFocusClock(remaining)}',
              key: const ValueKey('focus-elapsed-caption'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            SizedBox(height: isDesktop ? 22 : 16),
            // Static PNG mascot pose (no looping animation; native PNG avoids Firefox SVG decode failures).
            Image.asset(
              session.paused
                  ? 'assets/mascot/mascot_m29.png'
                  : 'assets/mascot/mascot_m27.png',
              key: ValueKey(session.paused ? 'mascot-paused' : 'mascot-active'),
              height: isDesktop ? 164 : 136,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              semanticLabel: session.paused
                  ? 'Linh vật Chặng đang nghỉ ngơi'
                  : 'Linh vật Chặng đang tập trung học cùng bạn',
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              session.paused
                  ? 'Bạn có thể tiếp tục khi sẵn sàng.'
                  : 'Cứ làm từng bước thôi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13.5,
                ),
              ),
              TextButton(
                onPressed: state.busy ? null : controller.reconcile,
                child: const Text('Đồng bộ lại'),
              ),
            ],
            SizedBox(height: isDesktop ? 22 : 18),
            FocusActionControls(
              isDesktop: isDesktop,
              paused: session.paused,
              pauseEnabled: !state.busy && !state.pending && remaining > 0,
              finishEnabled: !state.busy && !state.pending,
              onPauseResume: () =>
                  controller.command(session.paused ? 'RESUME' : 'PAUSE'),
              onFinish: () => _confirmFinish(context, controller),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            FocusInlineAudioControl(
              code: session.soundCode,
              paused: session.paused,
              enabled: !state.busy && !state.pending,
              onChanged: (value) => controller.command('SOUND', sound: value),
            ),
            if (state.audioError != null) ...[
              const SizedBox(height: 6),
              Text(
                state.audioError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s12),
            const Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Kết thúc phiên không tự đánh dấu công việc hoàn thành.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
