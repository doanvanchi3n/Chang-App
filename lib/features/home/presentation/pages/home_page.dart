import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/app_dimensions.dart';
import '../../../onboarding/data/onboarding_store.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.name),
        actions: [
          IconButton(
            tooltip: 'Xem màn hình Onboarding (Ảnh UI)',
            icon: const Icon(Icons.preview_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OnboardingPage(autoForward: false),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.route_rounded,
                  size: AppSpacing.s64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.s24),
                Text(
                  AppConstants.tagline,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s16),
                const Text(
                  'Lên kế hoạch · Tập trung · Nhìn lại',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s32),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingPage(autoForward: false),
                      ),
                    );
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Xem màn hình Onboarding (Mobile_005)'),
                ),
                const SizedBox(height: AppSpacing.s12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(onboardingStoreProvider).reset();
                    ref.invalidate(onboardingCompletedProvider);
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Đặt lại Onboarding (Chạy lại từ đầu)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
