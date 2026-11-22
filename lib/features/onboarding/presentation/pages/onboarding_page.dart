import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/app_colors.dart';
import '../../data/onboarding_store.dart';
import '../widgets/intro_mascot.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, this.autoForward = true});
  final bool autoForward;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _saving = false;
  String? _error;

  Future<void> _complete() async {
    if (_saving) return;
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
      backgroundColor: const Color(0xFFFEFDF9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final topSpace = (constraints.maxHeight * 0.16)
                .clamp(32.0, 110.0)
                .toDouble();
            final wordmarkToMascot = (constraints.maxHeight * 0.05)
                .clamp(20.0, 48.0)
                .toDouble();
            final sloganToSpinner = (constraints.maxHeight * 0.05)
                .clamp(24.0, 44.0)
                .toDouble();
            final bottomSpace = (constraints.maxHeight * 0.06)
                .clamp(20.0, 56.0)
                .toDouble();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    SizedBox(height: topSpace),
                    const _ChangWordmark(),
                    SizedBox(height: wordmarkToMascot),
                    IntroMascot(onFinished: _handleIntroFinished),
                    const SizedBox(height: 32),
                    const Text(
                      'Từng bước nhỏ, tiến xa hơn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF00092D),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: sloganToSpinner),
                    if (_error == null) ...[
                      const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1E67C6),
                            ),
                            backgroundColor: Color(0xFFCCE0F5),
                            semanticsLabel: 'Đang kiểm tra đăng nhập',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Đang kiểm tra đăng nhập...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF13305B),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (!widget.autoForward) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton.icon(
                            onPressed: _complete,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Vào trang chủ'),
                          ),
                        ),
                      ],
                    ] else ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      TextButton(
                        onPressed: _saving ? null : _complete,
                        child: const Text('Thử lại'),
                      ),
                    ],
                    SizedBox(height: bottomSpace),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleIntroFinished() {
    if (widget.autoForward) {
      _complete();
    }
  }
}

class _ChangWordmark extends StatelessWidget {
  const _ChangWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppConstants.name.toLowerCase(),
          style: const TextStyle(
            color: Color(0xFF00092D),
            fontSize: 48,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
        const SizedBox(width: 10),
        const _WordmarkDot(color: Color(0xFFA0C6EF)),
        const SizedBox(width: 6),
        const _WordmarkDot(color: Color(0xFFFAC858)),
        const SizedBox(width: 6),
        const _WordmarkDot(color: Color(0xFF2763A8)),
      ],
    );
  }
}

class _WordmarkDot extends StatelessWidget {
  const _WordmarkDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
