import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/dashboard_provider.dart';

const dashboardInk = Color(0xFF0B2451);
const dashboardBlue = Color(0xFF1876C8);
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
  const DashboardSchedule({super.key, required this.event});
  final DashboardEvent? event;

  @override
  Widget build(BuildContext context) => Container(
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

class DashboardPriorities extends StatelessWidget {
  const DashboardPriorities({
    super.key,
    required this.data,
    required this.onInbox,
    required this.onPlan,
  });
  final DashboardData data;
  final VoidCallback onInbox;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          const Text(
            'Việc ưu tiên',
            style: TextStyle(
              color: dashboardInk,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          FilledButton.icon(
            onPressed: onInbox,
            icon: const Icon(Icons.add),
            label: const Text('Thêm việc'),
            style: FilledButton.styleFrom(
              backgroundColor: dashboardBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: onPlan,
        icon: const Icon(Icons.edit_calendar_outlined),
        label: const Text('Lên kế hoạch hôm nay'),
      ),
      const SizedBox(height: 12),
      Text(
        'Hôm nay: ${data.todayDone}/${data.todayCount} việc hoàn thành',
        style: const TextStyle(color: dashboardMuted),
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: data.todayCount == 0
            ? 0
            : (data.todayDone / data.todayCount).clamp(0.0, 1.0),
        color: dashboardBlue,
        backgroundColor: const Color(0xFFE4EFF7),
        semanticsLabel: 'Tiến độ công việc hôm nay',
        semanticsValue: '${data.todayDone} trên ${data.todayCount} việc',
      ),
      const SizedBox(height: 16),
      if (data.tasks.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
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
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: i == 0
                                ? const Color(0xFFEAF5FD)
                                : Colors.white,
                            border: Border.all(color: const Color(0xFFDCEAF6)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.tasks[i].title,
                                style: const TextStyle(
                                  color: dashboardInk,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (data.tasks[i].project != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    data.tasks[i].project!,
                                    style: const TextStyle(
                                      color: dashboardMuted,
                                    ),
                                  ),
                                ),
                              if (data.tasks[i].dueDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Hạn ${dashboardDate(data.tasks[i].dueDate!.toLocal())}',
                                    style: const TextStyle(
                                      color: dashboardMuted,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              if (data.tasks[i].estimatedMinutes != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'Dự kiến ${data.tasks[i].estimatedMinutes} phút',
                                    style: const TextStyle(
                                      color: dashboardMuted,
                                    ),
                                  ),
                                ),
                              if (data.tasks[i].steps > 0) ...[
                                LinearProgressIndicator(
                                  value:
                                      data.tasks[i].completedSteps /
                                      data.tasks[i].steps,
                                  color: dashboardBlue,
                                  backgroundColor: const Color(0xFFCEE1ED),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${data.tasks[i].completedSteps}/${data.tasks[i].steps} bước',
                                  style: const TextStyle(color: dashboardMuted),
                                ),
                              ] else
                                const Text(
                                  'Chưa chia bước nhỏ',
                                  style: TextStyle(color: dashboardMuted),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

class DashboardWeek extends StatelessWidget {
  const DashboardWeek({super.key, required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEFBA),
      borderRadius: BorderRadius.circular(20),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final target = data.weekTargetMinutes;
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
