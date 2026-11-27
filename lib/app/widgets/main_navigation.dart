import 'app_layout.dart';

import 'package:flutter/material.dart';

import '../../features/onboarding/presentation/pages/onboarding_page.dart';

/// The dashboard and Inbox share the same destinations and active-tab rules.
class MainNavigation extends StatelessWidget {
  const MainNavigation({
    super.key,
    required this.inboxActive,
    this.onHome,
    this.onInbox,
  });
  final bool inboxActive;
  final VoidCallback? onHome;
  final VoidCallback? onInbox;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFD8E7FF))),
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.tabletBreakpoint,
            ),
            child: Row(
              children: [
                _item(Icons.home_rounded, 'Hôm nay', !inboxActive, onHome),
                _item(Icons.flag_outlined, 'Mục tiêu', false, null),
                _item(
                  Icons.check_box_outlined,
                  'Công việc',
                  inboxActive,
                  onInbox,
                ),
                _item(Icons.calendar_today_outlined, 'Lịch', false, null),
                _item(
                  Icons.more_horiz,
                  'Thêm',
                  false,
                  () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (sheetContext) => SafeArea(
                      child: ListTile(
                        leading: const Icon(Icons.waving_hand_outlined),
                        title: const Text('Xem lại giới thiệu Chặng'),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const OnboardingPage(autoForward: false),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _item(
    IconData icon,
    String text,
    bool selected,
    VoidCallback? onTap,
  ) => Expanded(
    child: Semantics(
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4268A2),
            disabledForegroundColor: selected
                ? const Color(0xFF0874CB)
                : const Color(0xFF8A97AA),
            backgroundColor: selected
                ? const Color(0xFFE8F3FF)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 25),
              const SizedBox(height: 5),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
