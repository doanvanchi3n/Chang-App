import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/feature_surface.dart';
import '../application/focus_controller.dart';
import 'focus_navigation.dart';

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
    final session = focus.session;
    final show =
        !focus.expanded && (focus.pending || session != null && !session.saved);
    return Column(
      children: [
        Expanded(child: widget.child),
        if (show)
          Material(
            color: changSoft,
            child: SafeArea(
              top: false,
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListTile(
                    leading: Icon(
                      session?.paused == true
                          ? Icons.pause_circle_outline
                          : Icons.timer_outlined,
                      color: changBlue,
                    ),
                    title: Text(
                      session?.reviewing == true
                          ? 'Phiên học chờ tổng kết'
                          : session?.title ?? 'Phiên đang chờ đồng bộ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: changInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      session == null
                          ? 'Mở để kiểm tra'
                          : session.reviewing
                          ? 'Lưu thời gian và xác nhận tiến độ'
                          : '${session.paused ? 'Tạm dừng' : 'Đang học'} · ${clockDuration(ref.read(focusControllerProvider.notifier).remainingSeconds)}',
                      style: const TextStyle(color: changMuted),
                    ),
                    trailing: const Icon(
                      Icons.open_in_full,
                      color: changBlue,
                      size: 20,
                    ),
                    onTap: () => openFocusSession(ref),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
