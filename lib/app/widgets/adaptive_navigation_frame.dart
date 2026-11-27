import 'package:flutter/material.dart';

import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import 'app_layout.dart';

/// Tablet navigation sits alongside content; mobile/desktop use their own bars.
class AdaptiveNavigationFrame extends StatelessWidget {
  const AdaptiveNavigationFrame({
    super.key,
    required this.child,
    required this.workSelected,
    required this.onHome,
    required this.onWork,
  });

  final Widget child;
  final bool workSelected;
  final VoidCallback onHome, onWork;

  @override
  Widget build(BuildContext context) {
    if (!AppLayout.isTabletWidth(MediaQuery.sizeOf(context).width)) {
      return child;
    }
    return Row(
      children: [
        SafeArea(
          right: false,
          child: NavigationRail(
            key: const ValueKey('tablet-navigation-rail'),
            selectedIndex: workSelected ? 1 : 0,
            scrollable: true,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) {
              if (index == 0) onHome();
              if (index == 1) onWork();
            },
            trailing: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: IconButton(
                tooltip: 'Xem lại giới thiệu Chặng',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OnboardingPage(autoForward: false),
                  ),
                ),
                icon: const Icon(Icons.more_horiz),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: Text('Hôm nay'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.checklist_outlined),
                label: Text('Công việc'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                label: Text('Lịch'),
                disabled: true,
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ],
    );
  }
}
