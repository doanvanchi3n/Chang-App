import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../theme/app_colors.dart';
import '../../data/dashboard_provider.dart';

const dashboardInk = Color(0xFF0B2451);
const dashboardBlue = Color(0xFF1F66B5);
const dashboardMuted = Color(0xFF5374A3);

String dashboardDate(DateTime date) {
  const weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day}/${date.month}';
}

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class DashboardSchedule extends StatelessWidget {
  const DashboardSchedule({
    super.key,
    required this.event,
    this.isDesktop = false,
  });
  final DashboardEvent? event;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5DA),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: dashboardInk,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Sắp tới',
              style: TextStyle(
                color: dashboardInk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 18,
                child: VerticalDivider(color: Color(0xFFD8B09F), width: 1),
              ),
            ),
            Expanded(
              child: Text(
                event != null
                    ? '${_time(event!.start)} – ${_time(event!.end)} · ${event!.title}'
                    : 'Chưa có lịch sắp tới · Một khoảng trống để bạn chủ động.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: dashboardInk,
                  fontSize: 15,
                  fontWeight: event != null ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE2D7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: dashboardInk,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LỊCH GẦN NHẤT',
                  style: TextStyle(color: dashboardInk, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  event?.title ?? 'Chưa có lịch sắp tới',
                  style: const TextStyle(
                    color: dashboardInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                if (event != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${dashboardDate(event!.start)} · ${_time(event!.start)}–${_time(event!.end)}',
                    style: const TextStyle(color: dashboardInk),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Một khoảng trống để bạn chủ động.',
                      style: TextStyle(color: dashboardMuted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardPriorities extends StatelessWidget {
  const DashboardPriorities({
    super.key,
    required this.data,
    required this.onCreate,
    required this.onTask,
    required this.onPlan,
    this.onOpenTask,
    this.onFocusTask,
    this.isDesktop = false,
  });
  final DashboardData data;
  final VoidCallback onCreate;
  final ValueChanged<String> onTask;
  final VoidCallback onPlan;
  final ValueChanged<String>? onOpenTask;
  final ValueChanged<String>? onFocusTask;
  final bool isDesktop;

  void _openTask(String id) {
    if (onOpenTask != null) {
      onOpenTask!(id);
    } else {
      onTask(id);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              isDesktop ? 'Chặng hôm nay' : 'Việc ưu tiên',
              style: const TextStyle(
                color: dashboardInk,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (isDesktop)
            OutlinedButton.icon(
              onPressed: onPlan,
              style: OutlinedButton.styleFrom(
                foregroundColor: dashboardBlue,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.borderSubtle),
                minimumSize: const Size(48, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('Lên kế hoạch hôm nay'),
            )
          else
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Thêm việc'),
              style: FilledButton.styleFrom(
                backgroundColor: dashboardBlue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      if (!isDesktop) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onPlan,
          icon: const Icon(Icons.edit_calendar_outlined),
          label: const Text('Lên kế hoạch hôm nay'),
        ),
      ],
      const SizedBox(height: 12),
      Text(
        'Hôm nay: ${data.todayDone}/${data.todayCount} việc hoàn thành',
        style: const TextStyle(color: dashboardMuted),
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          minHeight: 8,
          value: data.todayCount == 0
              ? 0
              : (data.todayDone / data.todayCount).clamp(0.0, 1.0),
          color: dashboardBlue,
          backgroundColor: const Color(0xFFE4EFF7),
          semanticsLabel:
              'Tiến độ công việc hôm nay: ${data.todayDone} trên ${data.todayCount} việc',
        ),
      ),
      const SizedBox(height: 16),
      if (data.tasks.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: const Color(0xFFDCEAF6)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            data.todayCount > 0 && data.todayDone == data.todayCount
                ? 'Bạn đã hoàn thành các việc hôm nay. Một chặng thật tốt!'
                : 'Chưa có việc được lên kế hoạch hôm nay. Bạn có thể ghi lại ý tưởng trong Hộp việc.',
            style: const TextStyle(color: dashboardMuted, height: 1.5),
          ),
        )
      else
        CustomPaint(
          painter: const _TimelinePainter(),
          child: Column(
            children: [
              for (var i = 0; i < data.tasks.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: i == 0
                            ? dashboardBlue
                            : const Color(0xFFE3F1FA),
                        foregroundColor: i == 0 ? Colors.white : dashboardInk,
                        child: Text(
                          '${i + 1}'.padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: i == 0
                              ? const Color(0xFFEAF5FD)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Color(0xFFDCEAF6)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _openTask(data.tasks[i].id),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: isDesktop
                                  ? _buildDesktopTaskRow(data.tasks[i], i == 0)
                                  : _buildMobileTaskColumn(data.tasks[i]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      if (isDesktop && data.tasks.isNotEmpty) ...[
        const SizedBox(height: 6),
        const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Bạn có thể bắt đầu ở bất kỳ chặng nào.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _buildDesktopTaskRow(DashboardTask task, bool primary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 520) {
          return _buildWideDesktopTaskRow(task, primary);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMobileTaskColumn(task),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => onFocusTask != null
                  ? onFocusTask!(task.id)
                  : _openTask(task.id),
              child: Text(
                task.estimatedMinutes != null
                    ? 'Bắt đầu ${task.estimatedMinutes} phút'
                    : 'Bắt đầu',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWideDesktopTaskRow(DashboardTask task, bool primary) {
    final subtitleParts = <String>[
      if (task.project != null) task.project!,
      if (task.dueDate != null) 'Hạn ${dashboardDate(task.dueDate!.toLocal())}',
      if (task.estimatedMinutes != null) '${task.estimatedMinutes} phút',
    ];
    final startLabel = task.estimatedMinutes != null
        ? 'Bắt đầu ${task.estimatedMinutes} phút'
        : 'Bắt đầu';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  color: dashboardInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitleParts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    subtitleParts.join(' · '),
                    style: const TextStyle(color: dashboardMuted, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 10),
              if (task.steps > 0)
                Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: task.completedSteps / task.steps,
                            color: dashboardBlue,
                            backgroundColor: const Color(0xFFCEE1ED),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${task.completedSteps}/${task.steps} bước',
                      style: const TextStyle(
                        color: dashboardMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'Chưa chia bước nhỏ',
                  style: TextStyle(color: dashboardMuted, fontSize: 13),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (primary)
              FilledButton(
                onPressed: () {
                  if (onFocusTask != null) {
                    onFocusTask!(task.id);
                  } else {
                    _openTask(task.id);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: dashboardBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(148, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  startLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            else
              FilledButton.tonal(
                onPressed: () {
                  if (onFocusTask != null) {
                    onFocusTask!(task.id);
                  } else {
                    _openTask(task.id);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE7F1FC),
                  foregroundColor: dashboardBlue,
                  minimumSize: const Size(116, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Bắt đầu',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => _openTask(task.id),
              style: TextButton.styleFrom(
                foregroundColor: dashboardBlue,
                minimumSize: const Size(48, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text(
                'Chi tiết & chia bước',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileTaskColumn(DashboardTask task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: const TextStyle(
            color: dashboardInk,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (task.project != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              task.project!,
              style: const TextStyle(color: dashboardMuted),
            ),
          ),
        if (task.dueDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Hạn ${dashboardDate(task.dueDate!.toLocal())}',
              style: const TextStyle(color: dashboardMuted),
            ),
          ),
        const SizedBox(height: 10),
        if (task.estimatedMinutes != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Dự kiến ${task.estimatedMinutes} phút',
              style: const TextStyle(color: dashboardMuted),
            ),
          ),
        if (task.steps > 0) ...[
          LinearProgressIndicator(
            value: task.completedSteps / task.steps,
            color: dashboardBlue,
            backgroundColor: const Color(0xFFCEE1ED),
          ),
          const SizedBox(height: 6),
          Text(
            '${task.completedSteps}/${task.steps} bước',
            style: const TextStyle(color: dashboardMuted),
          ),
        ] else
          const Text(
            'Chưa chia bước nhỏ',
            style: TextStyle(color: dashboardMuted),
          ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _openTask(task.id),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Chi tiết và tập trung'),
          ),
        ),
      ],
    );
  }
}

class DashboardWeek extends StatelessWidget {
  const DashboardWeek({
    super.key,
    required this.data,
    this.isDesktop = false,
    this.onPlan,
  });
  final DashboardData data;
  final bool isDesktop;
  final VoidCallback? onPlan;

  @override
  Widget build(BuildContext context) {
    final target = data.weekTargetMinutes;

    if (isDesktop) {
      return Container(
        key: const ValueKey('home-desktop-week-card'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF1B8), Color(0xFFFDE084)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhịp học tuần này',
              style: TextStyle(
                color: dashboardInk,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${data.weekSeconds ~/ 60} phút tập trung',
              style: const TextStyle(
                color: dashboardInk,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${data.completedSessions} phiên hoàn thành',
              style: const TextStyle(
                color: dashboardInk,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (target != null && target > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: (data.weekSeconds / (target * 60)).clamp(0.0, 1.0),
                  color: dashboardBlue,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mục tiêu $target phút/tuần',
                style: const TextStyle(color: dashboardInk, fontSize: 13.5),
              ),
            ] else
              const Text(
                'Chưa thiết lập mục tiêu tuần.',
                style: TextStyle(color: dashboardInk, fontSize: 13.5),
              ),
            const SizedBox(height: 24),
            Center(
              child: SvgPicture.asset(
                'assets/mascot/reading.svg',
                width: 176,
                height: 184,
                semanticsLabel: 'Linh vật Chặng đang đọc sách',
              ),
            ),
            if (onPlan != null) ...[
              const SizedBox(height: 20),
              const Divider(color: Color(0x330B2451)),
              const SizedBox(height: 12),
              const Text(
                'Cần điều chỉnh kế hoạch?',
                style: TextStyle(
                  color: dashboardInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onPlan,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Lên kế hoạch hôm nay →',
                    style: TextStyle(
                      color: dashboardBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: dashboardBlue,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFBA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhịp học tuần này',
                style: TextStyle(
                  color: dashboardInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${data.weekSeconds ~/ 60} phút tập trung',
                style: const TextStyle(
                  color: dashboardInk,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${data.completedSessions} phiên hoàn thành',
                style: const TextStyle(color: dashboardInk),
              ),
              const SizedBox(height: 14),
              if (target != null && target > 0) ...[
                LinearProgressIndicator(
                  value: (data.weekSeconds / (target * 60)).clamp(0.0, 1.0),
                  color: dashboardBlue,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mục tiêu $target phút/tuần',
                  style: const TextStyle(color: dashboardInk),
                ),
              ] else
                const Text(
                  'Chưa thiết lập mục tiêu tuần.',
                  style: TextStyle(color: dashboardInk),
                ),
            ],
          );
          final mascot = SvgPicture.asset(
            'assets/mascot/reading.svg',
            width: 150,
            height: 160,
            semanticsLabel: 'Linh vật Chặng đang đọc sách',
          );
          if (constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(16) > 22) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                const SizedBox(height: 12),
                Center(child: mascot),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 12),
              mascot,
            ],
          );
        },
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF93BCDF)
      ..strokeWidth = 2;
    for (double y = 20; y < size.height - 36; y += 12) {
      canvas.drawLine(Offset(18, y), Offset(18, y + 6), paint);
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) => false;
}
