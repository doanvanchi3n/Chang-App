import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/widgets/feature_surface.dart';
import '../application/focus_controller.dart';
import 'focus_summary.dart';
import 'background_audio_panel.dart';

class FocusSessionPage extends ConsumerWidget {
  const FocusSessionPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusControllerProvider);
    final controller = ref.read(focusControllerProvider.notifier);
    final session = state.session;
    return FeatureSurface(
      title: session?.reviewing == true || session?.saved == true
          ? 'Tổng kết phiên'
          : 'Tập trung',
      onBack: () => Navigator.of(context).pop(),
      trailing: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Thu gọn'),
      ),
      child: session == null
          ? Column(
              children: [
                Text(
                  state.pending
                      ? 'Phiên học đang chờ xác nhận.'
                      : 'Chưa có phiên học đang mở.',
                  style: const TextStyle(color: changMuted),
                ),
                if (state.error != null) Text(state.error!),
                const SizedBox(height: 16),
                FeatureButton(
                  'Đồng bộ lại',
                  onPressed: state.busy ? null : controller.reconcile,
                ),
              ],
            )
          : session.reviewing || session.saved
          ? FocusSummary(key: ValueKey(session.id), session: session)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (session.project != null)
                  Center(
                    child: Chip(
                      label: Text(session.project!),
                      backgroundColor: changSoft,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  session.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: changInk,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (session.stepTitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Bước ${session.stepOrder} · ${session.stepTitle}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: changMuted, fontSize: 17),
                    ),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: Chip(
                    label: Text(
                      'Phiên học · ${session.targetSeconds ~/ 60} phút',
                    ),
                    backgroundColor: changSoft,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Chip(
                    avatar: Icon(
                      session.paused ? Icons.pause : Icons.play_arrow,
                      color: session.paused
                          ? const Color(0xFFA96B00)
                          : changBlue,
                      size: 18,
                    ),
                    label: Text(
                      state.pending
                          ? 'Đang chờ đồng bộ'
                          : session.paused
                          ? 'Đang tạm dừng'
                          : 'Đang tập trung',
                    ),
                    backgroundColor: session.paused
                        ? const Color(0xFFFFEDBD)
                        : changSoft,
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    clockDuration(controller.remainingSeconds),
                    style: const TextStyle(
                      color: changInk,
                      fontSize: 84,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value:
                        (controller.elapsedMs / (session.targetSeconds * 1000))
                            .clamp(0, 1),
                    color: changBlue,
                    backgroundColor: changSoft,
                    semanticsLabel: 'Tiến độ phiên học',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Đã tập trung ${preciseDuration(controller.elapsedSeconds)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: changMuted),
                ),
                if (session.paused)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Thời gian tạm dừng không được tính.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: changMuted),
                    ),
                  ),
                const SizedBox(height: 20),
                SvgPicture.asset(
                  session.paused
                      ? 'assets/mascot/mascot-M29.svg'
                      : 'assets/mascot/mascot-M27.svg',
                  height: 170,
                  semanticsLabel: session.paused
                      ? 'Chặng nghỉ ngơi'
                      : 'Chặng đang học',
                ),
                const SizedBox(height: 20),
                if (state.error != null) ...[
                  Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: state.busy ? null : controller.reconcile,
                    child: const Text('Đồng bộ lại'),
                  ),
                ],
                FeatureButton(
                  session.paused ? 'Tiếp tục học' : 'Tạm dừng',
                  onPressed:
                      state.busy ||
                          state.pending ||
                          controller.remainingSeconds == 0
                      ? null
                      : () => controller.command(
                          session.paused ? 'RESUME' : 'PAUSE',
                        ),
                ),
                const SizedBox(height: 10),
                FeatureButton(
                  'Kết thúc phiên',
                  secondary: true,
                  onPressed: state.busy || state.pending
                      ? null
                      : () async {
                          final end = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Kết thúc phiên tại đây?'),
                              content: const Text(
                                'Thời gian đã tập trung sẽ được giữ để bạn xem và lưu ở phần tổng kết.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Tiếp tục phiên'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Kết thúc'),
                                ),
                              ],
                            ),
                          );
                          if (end == true) await controller.command('FINISH');
                        },
                ),
                const SizedBox(height: 12),
                BackgroundAudioPanel(
                  code: session.soundCode,
                  paused: session.paused,
                  enabled: !state.busy && !state.pending,
                  onChanged: (value) =>
                      controller.command('SOUND', sound: value),
                ),
                if (state.audioError != null)
                  Text(
                    state.audioError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  session.paused
                      ? 'Bạn có thể tiếp tục khi sẵn sàng.'
                      : 'Thu gọn để quay lại công việc; đồng hồ vẫn tiếp tục.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: changMuted, height: 1.5),
                ),
              ],
            ),
    );
  }
}
