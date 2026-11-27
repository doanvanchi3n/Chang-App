import 'package:chang_app/app/widgets/main_navigation.dart';
import 'package:chang_app/app/widgets/work_section_tabs.dart';
import 'package:chang_app/features/projects/data/project_repository.dart';
import 'package:chang_app/features/projects/presentation/project_list_page.dart';
import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:chang_app/features/tasks/data/task_management_repository.dart';
import 'package:chang_app/features/tasks/data/task_repository.dart';
import 'package:chang_app/features/tasks/domain/inbox_task.dart';
import 'package:chang_app/features/tasks/domain/task_detail.dart';
import 'package:chang_app/features/tasks/presentation/create_task_page.dart';
import 'package:chang_app/features/tasks/presentation/completed_tasks_page.dart';
import 'package:chang_app/features/tasks/presentation/inbox_page.dart';
import 'package:chang_app/features/tasks/presentation/inbox_provider.dart';
import 'package:chang_app/features/tasks/presentation/task_list_page.dart';
import 'package:chang_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeInboxRepo extends InboxRepository {
  _FakeInboxRepo(super.client, this.items);
  final List<InboxTask> items;
  @override
  Future<List<InboxTask>> fetch() async => items;
}

TaskDetail _sampleTask() => TaskDetail.fromJson({
  'id': 'task-1',
  'title': 'Phác thảo luồng đăng ký',
  'description': 'Mô tả ngắn',
  'priority': 'HIGH',
  'due_date': '2026-12-01T10:00:00Z',
  'scheduled_date': null,
  'status': 'IN_PROGRESS',
  'is_archived': false,
  'progress_percentage': 40,
  'estimated_minutes': 25,
  'updated_at': '2026-11-26T10:00:00Z',
  'projects': {'id': 'p1', 'name': 'UI/UX', 'color_hex': '#1F66B5'},
  'subtasks': [
    {
      'id': 's1',
      'task_id': 'task-1',
      'title': 'Bước 1',
      'order_index': 1,
      'estimated_minutes': 25,
      'is_completed': true,
    },
    {
      'id': 's2',
      'task_id': 'task-1',
      'title': 'Bước 2',
      'order_index': 2,
      'estimated_minutes': 25,
      'is_completed': false,
    },
  ],
});

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() => client.dispose());

  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final width in [390.0, 840.0, 1280.0]) {
    testWidgets('Công việc mở danh sách đã xong và dự án ở $width', (
      tester,
    ) async {
      setViewport(tester, Size(width, 1080));
      final router = GoRouter(
        initialLocation: '/tasks',
        routes: [
          GoRoute(path: '/tasks', builder: (_, _) => const TaskListPage()),
          GoRoute(
            path: '/projects',
            builder: (_, _) => const ProjectListPage(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskListProvider.overrideWith((ref) async => []),
            projectListProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đã hoàn thành · Mở lại công việc'));
      await tester.pumpAndSettle();
      expect(find.byType(CompletedTasksPage), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(WorkSectionTabs),
          matching: find.text('Dự án'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProjectListPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Form giữ tên dự án đã điền sẵn khi danh sách trống ở $width', (
      tester,
    ) async {
      setViewport(tester, Size(width, 1080));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [taskProjectsProvider.overrideWith((ref) async => [])],
          child: const MaterialApp(
            home: CreateTaskPage(
              initialProject: TaskProjectSummary(
                id: 'p1',
                name: 'Đồ án UI/UX',
                colorHex: '#006BFF',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đồ án UI/UX'), findsOneWidget);
      expect(find.text('Không gắn dự án'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Điều hướng desktop xác nhận trước khi bỏ nội dung form', (
    tester,
  ) async {
    setViewport(tester, const Size(1280, 1080));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskProjectsProvider.overrideWith((ref) async => [])],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateTaskPage(),
                  ),
                ),
                child: const Text('Mở form thử nghiệm'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở form thử nghiệm'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Nội dung chưa lưu',
    );
    final topBar = find.byKey(const ValueKey('desktop-top-bar'));
    await tester.tap(
      find.descendant(of: topBar, matching: find.text('Hôm nay')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rời form tạo việc?'), findsOneWidget);
    await tester.tap(find.text('Ở lại'));
    await tester.pumpAndSettle();
    expect(find.text('Nội dung chưa lưu'), findsOneWidget);
    await tester.tap(
      find.descendant(of: topBar, matching: find.text('Công việc')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rời form tạo việc?'), findsOneWidget);
    await tester.tap(find.text('Rời form'));
    await tester.pumpAndSettle();
    expect(find.text('Mở form thử nghiệm'), findsOneWidget);
    expect(find.byType(CreateTaskPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'Nền AppColors.page là tông gần trắng trung tính (không ám vàng/nâu)',
    () {
      expect(AppColors.page, const Color(0xFFFAFBFD));
    },
  );

  testWidgets(
    'W01 Desktop (1920x1080) hiển thị layout Web không có MainNavigation',
    (tester) async {
      setViewport(tester, const Size(1920, 1080));
      final repo = _FakeInboxRepo(client, [
        InboxTask(
          id: 't1',
          title: 'Đọc chương 3 cơ sở dữ liệu',
          createdAt: DateTime(2026, 11, 26),
        ),
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [inboxRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: InboxPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('desktop-top-bar')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('inbox-desktop-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('inbox-desktop-plan-button')),
        findsOneWidget,
      );
      expect(find.byType(MainNavigation), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'M01 Mobile (390x844) hiển thị layout Mobile kèm MainNavigation',
    (tester) async {
      setViewport(tester, const Size(390, 844));
      final repo = _FakeInboxRepo(client, const []);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [inboxRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: InboxPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('inbox-mobile-layout')), findsOneWidget);
      expect(find.byType(MainNavigation), findsOneWidget);
      expect(find.byKey(const ValueKey('desktop-top-bar')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'W11 Desktop (1920x1080) hiển thị bảng công việc Web và ẩn MainNavigation',
    (tester) async {
      setViewport(tester, const Size(1920, 1080));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskListProvider.overrideWith((ref) async => [_sampleTask()]),
          ],
          child: const MaterialApp(home: TaskListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('desktop-top-bar')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('task-list-desktop-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('task-list-desktop-table')),
        findsOneWidget,
      );
      expect(find.byType(MainNavigation), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('task-list-desktop-table')),
          matching: find.text('Dự án'),
        ),
        findsOneWidget,
      );
      expect(find.byType(WorkSectionTabs), findsOneWidget);
      expect(find.text('Đã hoàn thành · Mở lại công việc'), findsOneWidget);
      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text('Phác thảo luồng đăng ký'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'M11 Mobile (390x844) hiển thị danh sách Mobile kèm MainNavigation',
    (tester) async {
      setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskListProvider.overrideWith((ref) async => [_sampleTask()]),
          ],
          child: const MaterialApp(home: TaskListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('task-list-mobile-layout')),
        findsOneWidget,
      );
      expect(find.byType(MainNavigation), findsOneWidget);
      expect(find.byKey(const ValueKey('desktop-top-bar')), findsNothing);
      expect(find.byType(WorkSectionTabs), findsOneWidget);
      expect(find.text('Đã hoàn thành · Mở lại công việc'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('W12 Desktop (1920x1080) hiển thị form tạo việc 2 cột Web', (
    tester,
  ) async {
    setViewport(tester, const Size(1920, 1080));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskProjectsProvider.overrideWith(
            (ref) async => [
              TaskProject.fromJson({'id': 'p1', 'name': 'UI/UX'}),
            ],
          ),
        ],
        child: const MaterialApp(home: CreateTaskPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('desktop-top-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create-task-desktop-layout')),
      findsOneWidget,
    );
    expect(find.text('* Thông tin bắt buộc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('M12 Mobile (390x844) hiển thị form tạo việc 1 cột Mobile', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskProjectsProvider.overrideWith(
            (ref) async => [
              TaskProject.fromJson({'id': 'p1', 'name': 'UI/UX'}),
            ],
          ),
        ],
        child: const MaterialApp(home: CreateTaskPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('create-task-mobile-layout')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('desktop-top-bar')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
