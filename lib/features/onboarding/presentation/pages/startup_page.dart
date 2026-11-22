import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/pages/home_page.dart';
import '../../data/onboarding_store.dart';
import 'onboarding_page.dart';

class StartupPage extends ConsumerWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(onboardingCompletedProvider)
        .when(
          data: (completed) =>
              completed ? const HomePage() : const OnboardingPage(),
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(semanticsLabel: 'Đang mở Chặng'),
            ),
          ),
          error: (error, stack) => Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Chưa thể đọc thiết lập đã lưu.'),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(onboardingCompletedProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }
}
