import '../../../../app/widgets/app_layout.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/main_navigation.dart';
import '../../../tasks/presentation/inbox_page.dart';
import '../../../tasks/presentation/task_list_page.dart';
import '../../../tasks/presentation/create_task_page.dart';
import '../../../tasks/presentation/daily_plan_page.dart';
import '../../../tasks/presentation/task_detail_page.dart';
import '../../data/dashboard_provider.dart';
import '../widgets/dashboard_sections.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  Timer? _midnight;
  bool _inboxOpen = false;
  bool _planOpen = false;
  bool _taskOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    _midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (!mounted) return;
        ref.invalidate(dashboardProvider);
        _scheduleMidnight();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(dashboardProvider);
      _scheduleMidnight();
    }
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _openInbox() async {
    if (_inboxOpen || _planOpen || _taskOpen) return;
    _inboxOpen = true;
    try {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const InboxPage()));
    } finally {
      _inboxOpen = false;
      if (mounted) ref.invalidate(dashboardProvider);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(dashboardProvider);
    try {
      await ref.read(dashboardProvider.future);
    } catch (_) {
      // The dashboard renders its error state; refresh does not hide failures.
    }
  }

  Future<void> _openPlan() async {
    if (_planOpen || _inboxOpen || _taskOpen) return;
    _planOpen = true;
    try {
      await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => const DailyPlanPage()));
    } finally {
      _planOpen = false;
      if (mounted) ref.invalidate(dashboardProvider);
    }
  }

  Future<void> _openTaskPage(Widget page) async {
    if (_taskOpen || _inboxOpen || _planOpen) return;
    _taskOpen = true;
    try {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => page));
    } finally {
      _taskOpen = false;
      if (mounted) ref.invalidate(dashboardProvider);
    }
  }

  Future<void> _openTaskDetail(String taskId) async {
    await _openTaskPage(TaskDetailPage(taskId: taskId));
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardProvider);
    final name = dashboard.asData?.value.name;
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: MainNavigation(
        inboxActive: false,
        onInbox: () => _openTaskPage(const TaskListPage()),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.maxContentWidth,
                ),
                child: Padding(
                  padding: AppLayout.pagePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const Text(
                                    'chặng',
                                    style: TextStyle(
                                      color: dashboardInk,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  for (final color in const [
                                    Color(0xFF9DCDEE),
                                    Color(0xFFFFD060),
                                    dashboardBlue,
                                  ])
                                    Container(
                                      width: 11,
                                      height: 11,
                                      margin: const EdgeInsets.only(left: 4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _refresh,
                            tooltip: 'Làm mới Dashboard',
                            icon: const Icon(
                              Icons.refresh,
                              color: dashboardInk,
                            ),
                          ),
                          const Tooltip(
                            message: 'Thông báo chưa khả dụng',
                            child: IconButton(
                              onPressed: null,
                              icon: Icon(Icons.notifications_none),
                            ),
                          ),
                          const CircleAvatar(
                            backgroundColor: Color(0xFFFFB6A5),
                            child: Icon(
                              Icons.person_outline,
                              color: dashboardInk,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        name == null
                            ? 'Chào bạn, đi từng chặng nhé.'
                            : 'Chào $name, đi từng chặng nhé.',
                        style: const TextStyle(
                          color: dashboardInk,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dashboardDate(DateTime.now()),
                        style: const TextStyle(
                          color: dashboardMuted,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 24),
                      dashboard.when(
                        skipLoadingOnRefresh: false,
                        loading: () => const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Đang tải Dashboard',
                            ),
                          ),
                        ),
                        error: (error, stack) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chưa tải được Dashboard. Kiểm tra kết nối rồi thử lại.',
                              style: TextStyle(color: dashboardMuted),
                            ),
                            TextButton(
                              onPressed: _refresh,
                              child: const Text('Thử lại'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _openInbox,
                              icon: const Icon(Icons.inbox_outlined),
                              label: const Text('Mở Hộp việc'),
                            ),
                          ],
                        ),
                        data: (data) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DashboardSchedule(event: data.nextEvent),
                            const SizedBox(height: 24),
                            DashboardPriorities(
                              data: data,
                              onCreate: () =>
                                  _openTaskPage(const CreateTaskPage()),
                              onTask: (id) =>
                                  _openTaskPage(TaskDetailPage(taskId: id)),
                              onPlan: _openPlan,
                              onOpenTask: _openTaskDetail,
                            ),
                            const SizedBox(height: 20),
                            Material(
                              color: const Color(0xFFF2F7FD),
                              borderRadius: BorderRadius.circular(16),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                leading: const Icon(
                                  Icons.inbox_outlined,
                                  color: dashboardBlue,
                                ),
                                title: const Text(
                                  'Hộp việc',
                                  style: TextStyle(
                                    color: dashboardInk,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '${data.inboxCount} việc chưa lên lịch · Ghi lại trước, chọn lúc làm sau.',
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: dashboardBlue,
                                ),
                                onTap: _openInbox,
                              ),
                            ),
                            const SizedBox(height: 20),
                            DashboardWeek(data: data),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFDCEAF6),
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFFFF1CB),
                                    child: Icon(
                                      Icons.history,
                                      color: Color(0xFFCE8A1A),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data.overdueCount == 0
                                              ? 'Không có việc quá hạn'
                                              : '${data.overdueCount} việc cần rà soát',
                                          style: const TextStyle(
                                            color: dashboardInk,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data.overdueCount == 0
                                              ? 'Giữ nhịp học vừa sức với bạn nhé.'
                                              : 'Các việc đã qua hạn và chưa hoàn thành.',
                                          style: const TextStyle(
                                            color: dashboardMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
