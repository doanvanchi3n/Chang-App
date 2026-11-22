import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/app_dimensions.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.name)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
