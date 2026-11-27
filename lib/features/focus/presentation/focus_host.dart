import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../application/focus_controller.dart';
import '../domain/focus_session.dart';
import 'focus_navigation.dart';
import 'widgets/focus_session_widgets.dart';

class FocusHost extends ConsumerStatefulWidget {
  const FocusHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<FocusHost> createState() => _FocusHostState();
}

class _FocusHostState extends ConsumerState<FocusHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(focusControllerProvider.notifier).restore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final focus = ref.watch(focusControllerProvider);
    final controller = ref.read(focusControllerProvider.notifier);
    final session = focus.session;
    final show =
        !focus.expanded && (focus.pending || session != null && !session.saved);

    if (!show) return widget.child;

    final remaining = controller.remainingSeconds;
    final progress = session == null
        ? 0.0
        : computeFocusProgress(controller.elapsedMs, session.targetSeconds);
    final canQuickToggle =
        session != null &&
        !session.reviewing &&
        !focus.busy &&
        !focus.pending &&
        remaining > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = isFocusDesktopWidth(constraints.maxWidth);
        if (isDesktop) {
          return Stack(
            children: [
              Positioned.fill(child: widget.child),
              Positioned(
                right: AppSpacing.s24,
                bottom: AppSpacing.s24,
                child: SafeArea(
                  child: _DesktopFocusPipCard(
                    session: session,
                    remainingSeconds: remaining,
                    progress: progress,
                    canQuickToggle: canQuickToggle,
                    onTogglePause: () => controller.command(
                      session!.paused ? 'RESUME' : 'PAUSE',
                    ),
                    onExpand: () => openFocusSession(ref),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Expanded(child: widget.child),
            _MobileFocusMiniBar(
              session: session,
              remainingSeconds: remaining,
              progress: progress,
              canQuickToggle: canQuickToggle,
              onTogglePause: () =>
                  controller.command(session!.paused ? 'RESUME' : 'PAUSE'),
              onExpand: () => openFocusSession(ref),
            ),
          ],
        );
      },
    );
  }
}

class _DesktopFocusPipCard extends StatelessWidget {
  const _DesktopFocusPipCard({
    required this.session,
    required this.remainingSeconds,
    required this.progress,
    required this.canQuickToggle,
    required this.onTogglePause,
    required this.onExpand,
  });

  final FocusSession? session;
  final int remainingSeconds;
  final double progress;
  final bool canQuickToggle;
  final VoidCallback onTogglePause;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final paused = session?.paused == true;
    final reviewing = session?.reviewing == true;
    final accent = paused ? AppColors.warning : focusPrimaryBlue;

    return Material(
      key: const ValueKey('focus-desktop-pip'),
      color: AppColors.surface,
      elevation: 10,
      shadowColor: const Color(0x280E2A47),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: reviewing ? 1.0 : progress,
              minHeight: 4,
              color: accent,
              backgroundColor: focusTrackColor,
            ),
            InkWell(
              onTap: onExpand,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: paused ? AppColors.honeySoft : focusSoftBlue,
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                      child: Icon(
                        reviewing
                            ? Icons.check_circle_outline
                            : paused
                            ? Icons.pause_rounded
                            : Icons.timer_outlined,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            reviewing
                                ? 'Phiên học chờ tổng kết'
                                : session?.title ?? 'Phiên đang chờ đồng bộ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: focusInk,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            session == null
                                ? 'Mở để kiểm tra'
                                : reviewing
                                ? 'Lưu thời gian và xác nhận tiến độ'
                                : session!.stepTitle != null
                                ? 'Bước ${session!.stepOrder} · ${session!.stepTitle}'
                                : paused
                                ? 'Đang tạm dừng'
                                : 'Đang tập trung',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    if (session != null && !reviewing)
                      Text(
                        formatFocusClock(remainingSeconds),
                        style: TextStyle(
                          color: accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    if (canQuickToggle)
                      Semantics(
                        button: true,
                        label: paused ? 'Tiếp tục học' : 'Tạm dừng',
                        child: IconButton(
                          key: const ValueKey('focus-pip-toggle-button'),
                          onPressed: onTogglePause,
                          icon: Icon(
                            paused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: accent,
                          ),
                        ),
                      ),
                    Semantics(
                      button: true,
                      label: 'Mở rộng phiên tập trung',
                      child: IconButton(
                        key: const ValueKey('focus-pip-expand-button'),
                        onPressed: onExpand,
                        icon: const Icon(
                          Icons.open_in_full_rounded,
                          color: focusPrimaryBlue,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileFocusMiniBar extends StatelessWidget {
  const _MobileFocusMiniBar({
    required this.session,
    required this.remainingSeconds,
    required this.progress,
    required this.canQuickToggle,
    required this.onTogglePause,
    required this.onExpand,
  });

  final FocusSession? session;
  final int remainingSeconds;
  final double progress;
  final bool canQuickToggle;
  final VoidCallback onTogglePause;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final paused = session?.paused == true;
    final reviewing = session?.reviewing == true;
    final accent = paused ? AppColors.warning : focusPrimaryBlue;

    return Material(
      key: const ValueKey('focus-mobile-mini-bar'),
      color: AppColors.surface,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: reviewing ? 1.0 : progress,
              minHeight: 3,
              color: accent,
              backgroundColor: focusTrackColor,
            ),
            InkWell(
              onTap: onExpand,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      reviewing
                          ? Icons.check_circle_outline
                          : paused
                          ? Icons.pause_circle_outline
                          : Icons.timer_outlined,
                      color: accent,
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            reviewing
                                ? 'Phiên học chờ tổng kết'
                                : session?.title ?? 'Phiên đang chờ đồng bộ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: focusInk,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            session == null
                                ? 'Mở để kiểm tra'
                                : reviewing
                                ? 'Lưu thời gian và xác nhận tiến độ'
                                : '${paused ? 'Tạm dừng' : 'Đang học'} · ${formatFocusClock(remainingSeconds)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canQuickToggle)
                      Semantics(
                        button: true,
                        label: paused ? 'Tiếp tục học' : 'Tạm dừng',
                        child: IconButton(
                          key: const ValueKey('focus-mini-toggle-button'),
                          onPressed: onTogglePause,
                          icon: Icon(
                            paused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: accent,
                          ),
                        ),
                      ),
                    Semantics(
                      button: true,
                      label: 'Mở rộng phiên tập trung',
                      child: IconButton(
                        key: const ValueKey('focus-mini-expand-button'),
                        onPressed: onExpand,
                        icon: const Icon(
                          Icons.open_in_full_rounded,
                          color: focusPrimaryBlue,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
