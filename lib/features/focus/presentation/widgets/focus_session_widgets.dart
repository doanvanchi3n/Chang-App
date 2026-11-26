import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_dimensions.dart';
import '../../data/audio/audio_library.dart';
import '../../data/audio/local_sound.dart';
import '../background_audio_panel.dart';

const double focusDesktopBreakpoint = 840;
const Color focusPrimaryBlue = Color(0xFF1F66B5);
const Color focusSoftBlue = Color(0xFFE5F0FA);
const Color focusTrackColor = Color(0xFFE4ECF4);
const Color focusInk = Color(0xFF0E2A47);

bool isFocusDesktopWidth(double width) => width >= focusDesktopBreakpoint;

class FocusWebTopBar extends StatelessWidget {
  const FocusWebTopBar({
    super.key,
    required this.modeLabel,
    required this.onMinimize,
    this.showMinimize = true,
  });

  final String modeLabel;
  final VoidCallback onMinimize;
  final bool showMinimize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'chặng',
                        style: TextStyle(
                          color: focusInk,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      for (final color in const [
                        Color(0xFF9DCDEE),
                        AppColors.honey,
                        focusPrimaryBlue,
                      ])
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(left: 3),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        modeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (showMinimize)
                    TextButton.icon(
                      key: const ValueKey('minimize-focus-button'),
                      onPressed: onMinimize,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        minimumSize: const Size(48, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                        ),
                      ),
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      label: const Text(
                        'Thu gọn phiên',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 140),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FocusMobileTopBar extends StatelessWidget {
  const FocusMobileTopBar({
    super.key,
    required this.title,
    required this.onMinimize,
    this.minimizeLabel = 'Thu gọn',
  });

  final String title;
  final VoidCallback onMinimize;
  final String minimizeLabel;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(15) > 20;

    return Material(
      color: AppColors.page,
      child: SafeArea(
        bottom: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s4,
          ),
          child: Row(
            children: [
              TextButton(
                key: const ValueKey('minimize-focus-button'),
                onPressed: onMinimize,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: focusSoftBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: focusInk,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 6),
                      Text(
                        minimizeLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: focusInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: compact ? 48 : 96),
            ],
          ),
        ),
      ),
    );
  }
}

class FocusPillBadge extends StatelessWidget {
  const FocusPillBadge({
    super.key,
    required this.label,
    this.backgroundColor = focusSoftBlue,
    this.foregroundColor = focusPrimaryBlue,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foregroundColor),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FocusProgressTrack extends StatelessWidget {
  const FocusProgressTrack({
    super.key,
    required this.progress,
    this.paused = false,
  });

  final double progress;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final fillColor = paused ? AppColors.warning : focusPrimaryBlue;
    const dotSize = 12.0;

    return Semantics(
      label: 'Tiến độ phiên tập trung',
      value: '${(clamped * 100).round()}%',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final travel = (width - dotSize).clamp(0.0, double.infinity);
          final dotLeft = travel * clamped;

          return SizedBox(
            height: 16,
            width: width,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 8,
                  width: width,
                  decoration: BoxDecoration(
                    color: focusTrackColor,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                Container(
                  height: 8,
                  width: (dotLeft + dotSize / 2).clamp(0.0, width),
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                Positioned(
                  left: dotLeft,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: fillColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
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

class FocusActionControls extends StatelessWidget {
  const FocusActionControls({
    super.key,
    required this.isDesktop,
    required this.paused,
    required this.pauseEnabled,
    required this.finishEnabled,
    required this.onPauseResume,
    required this.onFinish,
  });

  final bool isDesktop;
  final bool paused;
  final bool pauseEnabled;
  final bool finishEnabled;
  final VoidCallback onPauseResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final primaryButton = FilledButton.icon(
      key: const ValueKey('focus-pause-resume-button'),
      onPressed: pauseEnabled ? onPauseResume : null,
      style: FilledButton.styleFrom(
        backgroundColor: focusPrimaryBlue,
        foregroundColor: AppColors.textInverse,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
      ),
      icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
      label: Text(paused ? 'Tiếp tục học' : 'Tạm dừng'),
    );

    final secondaryButton = OutlinedButton.icon(
      key: const ValueKey('focus-finish-button'),
      onPressed: finishEnabled ? onFinish : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: focusPrimaryBlue,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: focusPrimaryBlue, width: 1.2),
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
      ),
      icon: const Icon(Icons.stop_rounded),
      label: const Text('Kết thúc phiên'),
    );

    final useRow = isDesktop && MediaQuery.textScalerOf(context).scale(16) <= 24;
    if (useRow) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Row(
          key: const ValueKey('focus-desktop-actions-row'),
          children: [
            Expanded(child: primaryButton),
            const SizedBox(width: AppSpacing.s16),
            Expanded(child: secondaryButton),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('focus-mobile-actions-column'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primaryButton,
        const SizedBox(height: AppSpacing.s12),
        secondaryButton,
      ],
    );
  }
}

class FocusInlineAudioControl extends ConsumerStatefulWidget {
  const FocusInlineAudioControl({
    super.key,
    required this.code,
    required this.enabled,
    required this.paused,
    required this.onChanged,
  });

  final String code;
  final bool enabled;
  final bool paused;
  final ValueChanged<String> onChanged;

  @override
  ConsumerState<FocusInlineAudioControl> createState() =>
      _FocusInlineAudioControlState();
}

class _FocusInlineAudioControlState
    extends ConsumerState<FocusInlineAudioControl> {
  String _lastActiveSound = 'WHITE_NOISE';
  bool _choosing = false;

  Future<void> _openPicker() async {
    if (!widget.enabled || _choosing) return;
    setState(() => _choosing = true);
    try {
      final value = await showBackgroundAudioSheet(
        context,
        current: widget.code,
        protectedCode: widget.code,
      );
      if (mounted && value != null) widget.onChanged(value);
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sounds =
        ref.watch(audioLibraryProvider).asData?.value ?? const <LocalSound>[];
    final isOn = widget.code != 'SILENT';
    if (isOn) _lastActiveSound = widget.code;
    final customSound = sounds.where((s) => s.code == widget.code).firstOrNull;
    final statusLabel = !isOn
        ? 'Tắt'
        : widget.code == 'WHITE_NOISE'
        ? 'Nhiễu trắng'
        : customSound?.name ?? 'Âm thanh cá nhân';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s4,
          children: [
            const Text(
              'Âm thanh',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Semantics(
              label: 'Bật hoặc tắt âm thanh nền',
              toggled: isOn,
              child: Switch.adaptive(
                key: const ValueKey('focus-sound-switch'),
                value: isOn,
                activeThumbColor: AppColors.surface,
                activeTrackColor: focusPrimaryBlue,
                inactiveThumbColor: AppColors.surface,
                inactiveTrackColor: const Color(0xFF9FB4C8),
                onChanged: widget.enabled && !_choosing
                    ? (value) =>
                          widget.onChanged(value ? _lastActiveSound : 'SILENT')
                    : null,
              ),
            ),
            InkWell(
              key: const ValueKey('focus-sound-picker-button'),
              onTap: widget.enabled && !_choosing ? _openPicker : null,
              borderRadius: BorderRadius.circular(AppRadius.r8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isOn
                              ? focusPrimaryBlue
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: isOn ? focusPrimaryBlue : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (widget.paused && isOn)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'Âm thanh sẽ tự phát tiếp khi bạn tiếp tục học.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}
