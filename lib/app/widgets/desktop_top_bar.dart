import 'package:flutter/material.dart';

import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import 'app_layout.dart';

enum DesktopNavTab { home, tasks }

const Color _topBarBlue = Color(0xFF1F66B5);
const Color _topBarInk = Color(0xFF0E2A47);

/// Shared desktop/web top navigation bar matching W05 and W13 designs.
class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({
    super.key,
    required this.activeTab,
    this.onTapHome,
    this.onTapTasks,
    this.onTapAddTask,
    this.onRefresh,
    this.notificationAction,
    this.avatarLetter = 'C',
  });

  final DesktopNavTab activeTab;
  final VoidCallback? onTapHome;
  final VoidCallback? onTapTasks;
  final VoidCallback? onTapAddTask;
  final VoidCallback? onRefresh;
  final Widget? notificationAction;
  final String avatarLetter;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('desktop-top-bar'),
      color: AppColors.surface,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxDesktopWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'chặng',
                        style: TextStyle(
                          color: _topBarInk,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      for (final color in const [
                        Color(0xFF9DCDEE),
                        AppColors.honey,
                        _topBarBlue,
                      ])
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(left: 3),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.s32),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _NavTabItem(
                            label: 'Hôm nay',
                            active: activeTab == DesktopNavTab.home,
                            onTap: onTapHome,
                          ),
                          _NavTabItem(
                            label: 'Công việc',
                            active: activeTab == DesktopNavTab.tasks,
                            onTap: onTapTasks,
                          ),
                          const _NavTabItem(
                            label: 'Lịch',
                            active: false,
                            onTap: null,
                          ),
                          const _NavTabItem(
                            label: 'Tiến độ',
                            active: false,
                            onTap: null,
                          ),
                          const _NavTabItem(
                            label: 'Trợ lý',
                            active: false,
                            onTap: null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  if (onRefresh != null)
                    IconButton(
                      onPressed: onRefresh,
                      tooltip: 'Làm mới',
                      icon: const Icon(Icons.refresh, color: _topBarInk),
                    ),
                  ?notificationAction,
                  if (onTapAddTask != null) ...[
                    const SizedBox(width: AppSpacing.s8),
                    FilledButton.icon(
                      key: const ValueKey('desktop-add-task-button'),
                      onPressed: onTapAddTask,
                      style: FilledButton.styleFrom(
                        backgroundColor: _topBarBlue,
                        foregroundColor: AppColors.textInverse,
                        minimumSize: const Size(48, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Thêm việc',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.s12),
                  PopupMenuButton<String>(
                    tooltip: 'Tài khoản & tùy chọn',
                    onSelected: (value) {
                      if (value == 'intro') {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const OnboardingPage(autoForward: false),
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'intro',
                        child: Text('Xem lại giới thiệu Chặng'),
                      ),
                    ],
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: AppColors.peach,
                      foregroundColor: _topBarInk,
                      child: Text(
                        avatarLetter,
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? _topBarBlue : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? _topBarBlue
                  : onTap == null
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
              fontSize: 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
