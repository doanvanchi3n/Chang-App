import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/onboarding_store.dart';
import '../widgets/intro_content.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, this.autoForward = true});
  final bool autoForward;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _saving = false;
  bool _completionRequested = false;
  String? _error;

  Future<void> _complete() async {
    if (_saving) return;
    // A button tap owns completion; the animation must not retry a failed save.
    _completionRequested = true;
    if (!widget.autoForward && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(onboardingStoreProvider).complete();
      if (mounted) ref.invalidate(onboardingCompletedProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa lưu được thiết lập. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IntroContent(
        saving: _saving,
        error: _error,
        onContinue: _complete,
        onIntroFinished: () {
          if (widget.autoForward && !_completionRequested) _complete();
        },
      ),
    );
  }
}
