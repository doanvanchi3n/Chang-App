import 'package:chang_app/app/widgets/main_navigation.dart';
import 'package:chang_app/features/home/data/dashboard_provider.dart';
import 'package:chang_app/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

DashboardData _sampleDashboard() => DashboardData(
  name: 'Chiến',
  tasks: [
    DashboardTask.fromJson({
      'id': 'task-1',
      'title': 'Phác thảo luồng đăng ký',
      'estimated_minutes': 25,
      'projects': {'name': 'UI/UX'},
      'due_date': '2026-11-27T10:00:00Z',
      'subtasks': [
        {'is_completed': true},
        {'is_completed': true},
        {'is_completed': false},
        {'is_completed': false},
        {'is_completed': false},
      ],
    }),
  ],
  todayCount: 3,
  todayDone: 1,
  inboxCount: 2,
  overdueCount: 0,
  nextEvent: DashboardEvent.fromJson({
    'title': 'Tiếng Anh',
    'start_time': '2026-11-26T12:00:00Z',
    'end_time': '2026-11-26T13:00:00Z',
  }),
  weekSeconds: 4500,
  weekTargetMinutes: 420,
  completedSessions: 3,
);

void main() {
  Future<void> pumpHome(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardProvider.overrideWith((ref) async => _sampleDashboard()),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'W05 (Desktop 1920x1080) hiển thị top bar web, 2 cột và ẩn thanh bottom nav mobile',
    (tester) async {
      await pumpHome(tester, const Size(1920, 1080));

      expect(find.byKey(const ValueKey('desktop-top-bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-desktop-layout')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-desktop-week-card')),
        findsOneWidget,
      );
      expect(find.byType(MainNavigation), findsNothing);
      expect(find.text('Chào Chiến, đi từng chặng nhé.'), findsOneWidget);
      expect(find.text('Chặng hôm nay'), findsOneWidget);
      expect(find.text('Bắt đầu 25 phút'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'M05 (Mobile 390x844) hiển thị 1 cột mobile kèm thanh MainNavigation dưới đáy',
    (tester) async {
      await pumpHome(tester, const Size(390, 844));

      expect(find.byKey(const ValueKey('home-mobile-layout')), findsOneWidget);
      expect(find.byType(MainNavigation), findsOneWidget);
      expect(find.byKey(const ValueKey('desktop-top-bar')), findsNothing);
      expect(find.byKey(const ValueKey('home-desktop-layout')), findsNothing);
      expect(find.text('Việc ưu tiên'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
