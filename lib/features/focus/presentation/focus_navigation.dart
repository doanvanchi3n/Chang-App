import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation.dart';
import '../application/focus_controller.dart';
import 'focus_session_page.dart';

Future<void> openFocusSession(WidgetRef ref) async {
  if (ref.read(focusControllerProvider).expanded) return;
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return;
  final controller = ref.read(focusControllerProvider.notifier);
  controller.expanded(true);
  try {
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const FocusSessionPage()),
    );
  } finally {
    controller.expanded(false);
  }
}
