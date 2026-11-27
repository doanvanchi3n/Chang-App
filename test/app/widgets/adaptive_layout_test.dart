import 'dart:io';
import 'dart:ui' as ui;

import 'package:chang_app/app/widgets/adaptive_content.dart';
import 'package:chang_app/app/widgets/app_layout.dart';
import 'package:chang_app/app/widgets/feature_surface.dart';
import 'package:chang_app/app/widgets/main_navigation.dart';
import 'package:chang_app/features/focus/application/focus_controller.dart';
import 'package:chang_app/features/focus/data/audio/audio_library.dart';
import 'package:chang_app/features/focus/data/audio/local_sound.dart';
import 'package:chang_app/features/focus/domain/focus_session.dart';
import 'package:chang_app/features/focus/presentation/focus_prep_page.dart';
import 'package:chang_app/features/focus/presentation/focus_session_page.dart';
import 'package:chang_app/features/home/data/dashboard_provider.dart';
import 'package:chang_app/features/home/presentation/pages/home_page.dart';
import 'package:chang_app/features/notifications/data/notification_repository.dart';
import 'package:chang_app/features/notifications/domain/app_notification.dart';
import 'package:chang_app/features/notifications/presentation/notifications_page.dart';
import 'package:chang_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:chang_app/features/projects/data/project_repository.dart';
import 'package:chang_app/features/projects/domain/study_project.dart';
import 'package:chang_app/features/projects/presentation/create_project_page.dart';
import 'package:chang_app/features/projects/presentation/project_detail_page.dart';
import 'package:chang_app/features/projects/presentation/project_list_page.dart';
import 'package:chang_app/features/tasks/data/daily_plan_repository.dart';
import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:chang_app/features/tasks/data/task_management_repository.dart';
import 'package:chang_app/features/tasks/data/task_repository.dart';
import 'package:chang_app/features/tasks/domain/daily_plan.dart';
import 'package:chang_app/features/tasks/domain/inbox_task.dart';
import 'package:chang_app/features/tasks/domain/task_detail.dart';
import 'package:chang_app/features/tasks/presentation/completed_tasks_page.dart';
import 'package:chang_app/features/tasks/presentation/create_task_page.dart';
import 'package:chang_app/features/tasks/presentation/daily_plan_page.dart';
import 'package:chang_app/features/tasks/presentation/edit_task_page.dart';
import 'package:chang_app/features/tasks/presentation/inbox_page.dart';
import 'package:chang_app/features/tasks/presentation/inbox_provider.dart';
import 'package:chang_app/features/tasks/presentation/manage_steps_page.dart';
import 'package:chang_app/features/tasks/presentation/task_detail_page.dart';
import 'package:chang_app/features/tasks/presentation/task_list_page.dart';
import 'package:chang_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _task = TaskDetail.fromJson({
  'id': 't1',
  'title': 'Phác thảo luồng đăng ký và chuẩn bị nội dung thuyết trình',
  'description': 'Thiết kế luồng sử dụng ứng dụng hỗ trợ tự học của sinh viên.',
  'status': 'IN_PROGRESS',
  'priority': 'HIGH',
  'estimated_minutes': 25,
  'updated_at': '2026-11-27T10:00:00Z',
  'projects': {'id': 'p1', 'name': 'Đồ án UI/UX'},
  'subtasks': [
    for (var i = 1; i <= 3; i++)
      {
        'id': 's$i',
        'title': 'Bước $i: thu thập và phân tích yêu cầu',
        'order_index': i,
        'estimated_minutes': 10,
        'is_completed': i == 1,
      },
  ],
});
final _projects = List.generate(
  6,
  (i) => StudyProject(
    id: 'p${i + 1}',
    name: i == 0 ? 'Đồ án UI/UX' : 'Dự án học tập ${i + 1}',
    description: 'Gom các công việc cùng hướng đến mục tiêu học tập.',
    deadline: DateTime(2026, 12, 30),
  ),
);

class _Focus extends FocusController {
  @override
  FocusState build() => FocusState(
    session: FocusSession({
      'id': 'f1',
      'task_id': 't1',
      'task_title': _task.title,
      'status': 'IN_PROGRESS',
      'target_duration_seconds': 1500,
      'elapsed_milliseconds': 22000,
      'revision': 1,
      'ambient_sound': 'SILENT',
      'server_now': '2026-11-27T10:00:00Z',
    }),
    expanded: true,
  );
  @override
  int get elapsedMs => 22000;
  @override
  int get remainingSeconds => 1478;
}

class _Audio extends AudioLibrary {
  @override
  Future<List<LocalSound>> build() async => [];
}

class _Plans extends DailyPlanRepository {
  _Plans(SupabaseClient client) : super(client, InboxRepository(client));
  @override
  Future<DailyPlanData> load(DateTime date) async => DailyPlanData(
    date: date,
    availableMinutes: 90,
    updatedAt: null,
    tasks: [
      PlanningTask.fromJson({
        'id': 't1',
        'title': _task.title,
        'updated_at': '2026-11-27T10:00:00Z',
        'estimated_minutes': 25,
        'scheduled_date': planDateKey(date),
      }),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  late SupabaseClient client;
  setUp(
    () => client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    ),
  );
  tearDown(() => client.dispose());

  Future<void> pump(
    WidgetTester tester,
    Widget page,
    Size size,
    double scale,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskListProvider.overrideWith(
            (ref) async => [
              _task,
              TaskDetail.fromJson({
                'id': 't2',
                'title': 'Xác định phạm vi đề tài',
                'status': 'COMPLETED',
                'projects': {'id': 'p1', 'name': 'Đồ án UI/UX'},
                'completed_at': '2026-11-27T10:00:00Z',
              }),
            ],
          ),
          taskDetailProvider.overrideWith((ref, id) async => _task),
          taskProjectsProvider.overrideWith(
            (ref) async => [
              TaskProject.fromJson({'id': 'p1', 'name': 'Đồ án UI/UX'}),
            ],
          ),
          projectListProvider.overrideWith((ref) async => _projects),
          inboxProvider.overrideWith(
            (ref) async => [
              InboxTask(
                id: 't1',
                title: _task.title,
                createdAt: DateTime(2026, 11, 27),
              ),
            ],
          ),
          dailyPlanRepositoryProvider.overrideWithValue(_Plans(client)),
          dashboardProvider.overrideWith(
            (ref) async => DashboardData(
              name: 'Chiến',
              tasks: [
                DashboardTask.fromJson({
                  'id': 't1',
                  'title': _task.title,
                  'estimated_minutes': 25,
                  'projects': {'name': 'Đồ án UI/UX'},
                  'subtasks': [
                    {'is_completed': true},
                    {'is_completed': false},
                  ],
                }),
              ],
              todayCount: 2,
              todayDone: 1,
              inboxCount: 1,
              overdueCount: 1,
              nextEvent: null,
              weekSeconds: 4500,
              weekTargetMinutes: 420,
              completedSessions: 3,
            ),
          ),
          notificationListProvider.overrideWith(
            (ref) async => [
              AppNotification(
                id: 'n1',
                title: 'Đã đến giờ dành cho một chặng học mới',
                body: 'Bạn có thể mở kế hoạch và bắt đầu với bất kỳ công việc nào.',
                kind: NotificationKind.system,
                isRead: false,
                createdAt: DateTime(2026, 11, 27),
              ),
            ],
          ),
          focusControllerProvider.overrideWith(_Focus.new),
          audioLibraryProvider.overrideWith(_Audio.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: RepaintBoundary(
            key: const ValueKey('adaptive-capture'),
            child: page,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final screens = <String, Widget>{
    'home': const HomePage(),
    'inbox': const InboxPage(),
    'tasks': const TaskListPage(),
    'task_detail': const TaskDetailPage(taskId: 't1'),
    'projects': const ProjectListPage(),
    'project_detail': const ProjectDetailPage(projectId: 'p1'),
    'create_project': const CreateProjectPage(),
    'create_task': const CreateTaskPage(),
    'edit_task': EditTaskPage(task: _task),
    'steps': ManageStepsPage(task: _task),
    'completed': const CompletedTasksPage(),
    'notifications': const NotificationsPage(),
    'plan': const DailyPlanPage(),
    'focus_prep': const FocusPrepPage(taskId: 't1'),
    'focus': const FocusSessionPage(),
    'intro': const OnboardingPage(autoForward: false),
  };
  final viewports = [
    for (final width in [320.0, 390.0, 600.0, 768.0, 840.0, 1024.0, 1440.0])
      (Size(width, 900), 1.0),
    for (final size in [
      const Size(320, 568),
      const Size(768, 600),
      const Size(1440, 900),
    ])
      (size, 2.0),
    (const Size(844, 390), 1.0),
  ];
  for (final screen in screens.entries) {
    for (final (size, scale) in viewports) {
      testWidgets('${screen.key}: ${size.width}x${size.height} text $scale', (
        tester,
      ) async {
        await pump(tester, screen.value, size, scale);
        expect(tester.takeException(), isNull);
        if (['home', 'inbox', 'tasks', 'projects'].contains(screen.key)) {
          if (size.width < 600) {
            expect(find.byType(MainNavigation), findsOneWidget);
            expect(find.byType(NavigationRail), findsNothing);
          } else if (size.width < 1024) {
            expect(find.byType(MainNavigation), findsNothing);
            expect(find.byType(NavigationRail), findsOneWidget);
          } else {
            expect(find.byType(MainNavigation), findsNothing);
            expect(
              find.byKey(const ValueKey('desktop-top-bar')),
              findsOneWidget,
            );
          }
        }
        if (const bool.fromEnvironment('CAPTURE_ADAPTIVE_UI') &&
            scale == 1 &&
            [390.0, 768.0, 1440.0].contains(size.width)) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('adaptive-capture')),
            );
            final snapshot = await boundary.toImage();
            final bytes = await snapshot.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '/tmp/chang-responsive-${screen.key}-${size.width.toInt()}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            snapshot.dispose();
          });
        }
      });
    }
  }

  testWidgets(
    'FeatureSurface expands with window and panes stack at large text',
    (tester) async {
      const pane1 = SizedBox(key: ValueKey('pane-1'), height: 80);
      const pane2 = SizedBox(key: ValueKey('pane-2'), height: 80);
      const page = FeatureSurface(
        title: 'Bố cục',
        child: AdaptiveColumns(primary: pane1, secondary: pane2),
      );
      await pump(tester, page, const Size(1440, 900), 1);
      expect(
        tester.getTopLeft(find.byKey(pane1.key!)).dy,
        tester.getTopLeft(find.byKey(pane2.key!)).dy,
      );
      expect(tester.getTopLeft(find.byKey(pane2.key!)).dx, greaterThan(720));
      await pump(tester, page, const Size(768, 900), 2);
      expect(
        tester.getTopLeft(find.byKey(pane2.key!)).dy,
        greaterThan(tester.getTopLeft(find.byKey(pane1.key!)).dy),
      );
    },
  );

  testWidgets('Resizing a task draft retains all text and selected project', (
    tester,
  ) async {
    const page = CreateTaskPage(
      initialProject: TaskProjectSummary(
        id: 'p1',
        name: 'Đồ án UI/UX',
        colorHex: '#006BFF',
      ),
    );
    await pump(tester, page, const Size(390, 900), 1);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Bản nháp còn giữ',
    );
    for (final width in [768.0, 1440.0, 390.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      expect(find.text('Bản nháp còn giữ'), findsOneWidget);
      expect(find.text('Đồ án UI/UX'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test('Window classes include exact boundaries', () {
    expect(AppLayout.isMobileWidth(599), true);
    expect(AppLayout.isTabletWidth(600), true);
    expect(AppLayout.isTabletWidth(1023), true);
    expect(AppLayout.isDesktopWidth(1024), true);
  });

  testWidgets('Task form scrolls above the keyboard and keeps its draft', (
    tester,
  ) async {
    await pump(tester, const CreateTaskPage(), const Size(390, 700), 1);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Bản nháp với bàn phím',
    );
    await tester.pumpAndSettle();
    final saveButton = find.byType(FilledButton).last;
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    expect(tester.getRect(saveButton).bottom, lessThanOrEqualTo(400));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('Bản nháp với bàn phím'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
