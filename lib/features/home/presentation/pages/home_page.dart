import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../onboarding/data/onboarding_store.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';

// ---------------------------------------------------------------------------
// DATA MODEL FOR HOME DASHBOARD (M05)
// ---------------------------------------------------------------------------
class HomeTaskItem {
  HomeTaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.dueText,
    required this.completedSteps,
    required this.totalSteps,
    required this.durationMinutes,
    this.scheduledTime,
    this.isActive = false,
  });

  final String id;
  String title;
  String category;
  String dueText;
  int completedSteps;
  int totalSteps;
  int durationMinutes;
  String? scheduledTime;
  bool isActive;
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentTabIndex = 0;
  bool _isCheckingSupabase = false;
  String _supabaseStatus = 'Chưa kiểm tra';
  int _supabaseTaskCount = 0;

  // Dữ liệu mẫu M05 chuẩn theo bản thiết kế UI
  late List<HomeTaskItem> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = [
      HomeTaskItem(
        id: '1',
        title: 'Phác thảo luồng đăng ký',
        category: 'UI/UX',
        dueText: 'Hạn ngày mai',
        completedSteps: 2,
        totalSteps: 5,
        durationMinutes: 25,
        isActive: true,
      ),
      HomeTaskItem(
        id: '2',
        title: 'Ôn 15 từ TOEIC',
        category: 'Tiếng Anh',
        dueText: 'Hôm nay',
        completedSteps: 0,
        totalSteps: 5,
        durationMinutes: 25,
        scheduledTime: '19:00',
        isActive: false,
      ),
      HomeTaskItem(
        id: '3',
        title: 'Đọc tài liệu CSDL',
        category: 'Chuyên ngành',
        dueText: 'Tuần này',
        completedSteps: 0,
        totalSteps: 5,
        durationMinutes: 30,
        isActive: false,
      ),
    ];

    _checkSupabaseConnection();
  }

  Future<void> _checkSupabaseConnection() async {
    setState(() {
      _isCheckingSupabase = true;
      _supabaseStatus = 'Đang kiểm tra kết nối...';
    });

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('tasks')
          .select('id')
          .timeout(const Duration(seconds: 8));

      final count = (response as List).length;
      if (mounted) {
        setState(() {
          _supabaseTaskCount = count;
          _supabaseStatus = 'Đã kết nối ($count dòng dữ liệu)';
          _isCheckingSupabase = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _supabaseStatus = 'Ngoại tuyến / Chưa có phiên đăng nhập';
          _isCheckingSupabase = false;
        });
      }
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController(text: 'Học tập');

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Thêm việc mới',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D253C),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Tên công việc',
                  hintText: 'Ví dụ: Làm bài tập Đại số',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Danh mục',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E67C6),
                shape: const StadiumBorder(),
              ),
              onPressed: () {
                final text = titleController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _tasks.add(
                      HomeTaskItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: text,
                        category: categoryController.text.trim(),
                        dueText: 'Hôm nay',
                        completedSteps: 0,
                        totalSteps: 5,
                        durationMinutes: 25,
                      ),
                    );
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Thêm vào danh sách'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE3ED),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hồ sơ & Trạng thái hệ thống',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D253C),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2EAF4)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        color: _supabaseTaskCount > 0
                            ? const Color(0xFF28654C)
                            : const Color(0xFF1E67C6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Supabase Database:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D253C),
                              ),
                            ),
                            Text(
                              _supabaseStatus,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5E7590),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () {
                          _checkSupabaseConnection();
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(
                    Icons.visibility_outlined,
                    color: Color(0xFF1E67C6),
                  ),
                  title: const Text('Xem màn hình Onboarding (Mobile_005)'),
                  subtitle: const Text('Xem giao diện linh vật vẫy tay chào'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const OnboardingPage(autoForward: false),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.restart_alt_rounded,
                    color: Color(0xFFC77E15),
                  ),
                  title: const Text('Đặt lại Onboarding (Reset)'),
                  subtitle: const Text('Xóa dữ liệu để kiểm tra lại từ đầu'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(onboardingStoreProvider).reset();
                    ref.invalidate(onboardingCompletedProvider);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFDF9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                _HomeHeader(
                  onNotificationTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không có thông báo mới (M07).'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onAvatarTap: _showSettingsSheet,
                ),
                const SizedBox(height: 18),
                const _GreetingSection(),
                const SizedBox(height: 20),
                _UpcomingSessionCard(
                  onTapSchedule: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Mở Lịch tuần và Lịch ngày chi tiết (M21/M22)...',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 26),
                _PriorityTasksSection(
                  tasks: _tasks,
                  onAddTask: _showAddTaskDialog,
                  onStartFocus: (task) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bắt đầu phiên tập trung 25 phút cho "${task.title}" (M27)!',
                        ),
                      ),
                    );
                  },
                  onTaskTap: (task) {
                    setState(() {
                      if (task.completedSteps < task.totalSteps) {
                        task.completedSteps++;
                      } else {
                        task.completedSteps = 0;
                      }
                    });
                  },
                ),
                const SizedBox(height: 24),
                const _WeeklyRhythmCard(),
                const SizedBox(height: 18),
                _ReviewAlertCard(
                  onTapReview: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Mở Rà soát cuối ngày (M10): Bài tập Stack đã quá hạn hôm qua.',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _HomeBottomNav(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          if (index == 4) {
            _showSettingsSheet();
          } else {
            setState(() => _currentTabIndex = index);
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. TOP BAR HEADER
// ---------------------------------------------------------------------------
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onNotificationTap,
    required this.onAvatarTap,
  });

  final VoidCallback onNotificationTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _ChangWordmarkCompact(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF0D253C),
                size: 26,
              ),
              tooltip: 'Thông báo',
              onPressed: onNotificationTap,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7B6A4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'C',
                  style: TextStyle(
                    color: Color(0xFF0D253C),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChangWordmarkCompact extends StatelessWidget {
  const _ChangWordmarkCompact();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppConstants.name.toLowerCase(),
          style: const TextStyle(
            color: Color(0xFF0D253C),
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1,
          ),
        ),
        const SizedBox(width: 8),
        const _Dot(color: Color(0xFFA0C6EF), size: 12),
        const SizedBox(width: 4),
        const _Dot(color: Color(0xFFFAC858), size: 12),
        const SizedBox(width: 4),
        const _Dot(color: Color(0xFF2763A8), size: 12),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. GREETING & DATE
// ---------------------------------------------------------------------------
class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chào Chiến, đi từng chặng nhé.',
          style: TextStyle(
            color: Color(0xFF0D253C),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Thứ Bảy, 17/10',
          style: TextStyle(
            color: Color(0xFF5D7189),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. UPCOMING SESSION CARD ("PHIÊN SẮP TỚI")
// ---------------------------------------------------------------------------
class _UpcomingSessionCard extends StatelessWidget {
  const _UpcomingSessionCard({required this.onTapSchedule});
  final VoidCallback onTapSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEEE8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8D8CE),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF0D253C),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PHIÊN SẮP TỚI',
                  style: TextStyle(
                    color: Color(0xFF7A6862),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '19:00 – 19:25 · Tiếng Anh',
                  style: TextStyle(
                    color: Color(0xFF0D253C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ôn 15 từ TOEIC',
                  style: TextStyle(
                    color: Color(0xFF5A4D48),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: const Color(0xFFE8CEC6),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          GestureDetector(
            onTap: onTapSchedule,
            child: const Text(
              'Xem lịch →',
              style: TextStyle(
                color: Color(0xFF1E67C6),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF1E67C6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. PRIORITY TASKS SECTION ("Việc ưu tiên")
// ---------------------------------------------------------------------------
class _PriorityTasksSection extends StatelessWidget {
  const _PriorityTasksSection({
    required this.tasks,
    required this.onAddTask,
    required this.onStartFocus,
    required this.onTaskTap,
  });

  final List<HomeTaskItem> tasks;
  final VoidCallback onAddTask;
  final ValueChanged<HomeTaskItem> onStartFocus;
  final ValueChanged<HomeTaskItem> onTaskTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Việc ưu tiên',
              style: TextStyle(
                color: Color(0xFF0D253C),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            FilledButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm việc'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E67C6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (int i = 0; i < tasks.length; i++) ...[
          _TimelineItemRow(
            number: '0${i + 1}',
            isActive: i == 0,
            isFirst: i == 0,
            isLast: i == tasks.length - 1,
            child: i == 0
                ? _ActiveTaskCard(
                    task: tasks[i],
                    onStartFocus: () => onStartFocus(tasks[i]),
                    onTap: () => onTaskTap(tasks[i]),
                  )
                : _StandardTaskCard(
                    task: tasks[i],
                    onTap: () => onTaskTap(tasks[i]),
                  ),
          ),
        ],
      ],
    );
  }
}

class _TimelineItemRow extends StatelessWidget {
  const _TimelineItemRow({
    required this.number,
    required this.isActive,
    required this.isFirst,
    required this.isLast,
    required this.child,
  });

  final String number;
  final bool isActive;
  final bool isFirst;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1E67C6)
                        : const Color(0xFFEBF3FC),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number,
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF0D253C),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: isFirst ? 76 : 46,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: CustomPaint(
                      painter: _DashedLinePainter(
                        color: const Color(0xFFB5D1F2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double startY = 2;
    final x = size.width / 2;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActiveTaskCard extends StatelessWidget {
  const _ActiveTaskCard({
    required this.task,
    required this.onStartFocus,
    required this.onTap,
  });

  final HomeTaskItem task;
  final VoidCallback onStartFocus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F6FD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD6E7FA), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Color(0xFF0D253C),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.category}  ·  ${task.dueText}',
                    style: const TextStyle(
                      color: Color(0xFF5E7590),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 75,
                        child: Row(
                          children: [
                            for (int s = 0; s < task.totalSteps; s++) ...[
                              Expanded(
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: s < task.completedSteps
                                        ? const Color(0xFF1E67C6)
                                        : const Color(0xFFD3E4F7),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              if (s < task.totalSteps - 1)
                                const SizedBox(width: 3),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${task.completedSteps}/${task.totalSteps} bước',
                        style: const TextStyle(
                          color: Color(0xFF5E7590),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onStartFocus,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E67C6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text('Bắt đầu ${task.durationMinutes} phút'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandardTaskCard extends StatelessWidget {
  const _StandardTaskCard({required this.task, required this.onTap});

  final HomeTaskItem task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EEF5), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Color(0xFF0D253C),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: Color(0xFF5E7590),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        task.scheduledTime != null
                            ? '${task.durationMinutes} phút  ·  Đã lên lịch ${task.scheduledTime}'
                            : '${task.durationMinutes} phút  ·  Chưa lên lịch',
                        style: const TextStyle(
                          color: Color(0xFF5E7590),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF0D253C),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. WEEKLY RHYTHM CARD ("Nhịp học tuần này" + Mascot)
// ---------------------------------------------------------------------------
class _WeeklyRhythmCard extends StatelessWidget {
  const _WeeklyRhythmCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2CD),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhịp học tuần này',
                  style: TextStyle(
                    color: Color(0xFF0D253C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Color(0xFF0D253C)),
                    children: [
                      TextSpan(
                        text: '3/4 ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'buổi hoàn thành',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    _CheckDot(isChecked: true),
                    SizedBox(width: 10),
                    _CheckDot(isChecked: true),
                    SizedBox(width: 10),
                    _CheckDot(isChecked: true),
                    SizedBox(width: 10),
                    _CheckDot(isChecked: false),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Theo mục tiêu tuần của bạn.',
                  style: TextStyle(
                    color: Color(0xFF4A443B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 125,
              child: SvgPicture.asset(
                'assets/mascot/Chang_Mascot_Reading.svg',
                fit: BoxFit.contain,
                semanticsLabel: 'Linh vật chim cánh cụt Chặng đang đọc sách',
                placeholderBuilder: (context) => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.isChecked});
  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    if (isChecked) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFF1E67C6),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 19),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1E67C6), width: 1.8),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. REVIEW ALERT CARD ("1 việc cần rà soát")
// ---------------------------------------------------------------------------
class _ReviewAlertCard extends StatelessWidget {
  const _ReviewAlertCard({required this.onTapReview});
  final VoidCallback onTapReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0D4),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.access_time_rounded,
              color: Color(0xFFC77E15),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 việc cần rà soát',
                  style: TextStyle(
                    color: Color(0xFF0D253C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Bài tập Stack  ·  Quá hạn hôm qua',
                  style: TextStyle(
                    color: Color(0xFF5E7590),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTapReview,
            child: const Text(
              'Rà soát →',
              style: TextStyle(
                color: Color(0xFF1E67C6),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF1E67C6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. BOTTOM NAVIGATION BAR
// ---------------------------------------------------------------------------
class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFEFDF9),
        border: Border(top: BorderSide(color: Color(0xFFECEFF4), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFFFEFDF9),
              selectedItemColor: const Color(0xFF1E67C6),
              unselectedItemColor: const Color(0xFF5E7590),
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Hôm nay',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.flag_outlined),
                  label: 'Mục tiêu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_box_outlined),
                  label: 'Công việc',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  label: 'Lịch',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz_rounded),
                  label: 'Thêm',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
