import 'dart:async';
import 'dart:convert';

import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:chang_app/features/tasks/data/task_management_repository.dart';
import 'package:chang_app/features/tasks/data/task_repository.dart';
import 'package:chang_app/features/tasks/domain/task_detail.dart';
import 'package:chang_app/features/tasks/domain/task_edit_draft.dart';
import 'package:chang_app/features/tasks/domain/task_filters.dart';
import 'package:chang_app/features/tasks/presentation/edit_task_page.dart';
import 'package:chang_app/features/tasks/presentation/manage_steps_page.dart';
import 'package:chang_app/features/tasks/presentation/task_list_page.dart';
import 'package:chang_app/features/tasks/presentation/widgets/task_filter_sheet.dart';
import 'package:chang_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

TaskDetail sample({
  String id = 'task-1',
  String title = 'Chuẩn bị bài thuyết trình',
  DateTime? due,
  String updated = '2026-11-24T10:00:00Z',
  String? scheduled,
  String status = 'IN_PROGRESS',
  String priority = 'HIGH',
  String project = 'p1',
}) => TaskDetail.fromJson({
  'id': id,
  'title': title,
  'description': 'Nội dung 100% đầy đủ',
  'priority': priority,
  'due_date': due?.toIso8601String(),
  'scheduled_date': scheduled,
  'status': status,
  'is_archived': false,
  'progress_percentage': 50,
  'estimated_minutes': 25,
  'updated_at': updated,
  'projects': {'id': project, 'name': 'Dự án học tập', 'color_hex': '#006BFF'},
  'subtasks': [
    {
      'id': 's1',
      'task_id': id,
      'title': 'Đọc tài liệu',
      'order_index': 1,
      'estimated_minutes': 10,
      'is_completed': true,
    },
    {
      'id': 's2',
      'task_id': id,
      'title': 'Viết dàn ý',
      'order_index': 2,
      'estimated_minutes': 15,
      'is_completed': false,
    },
  ],
});

class RecordingRepository extends TaskManagementRepository {
  RecordingRepository(super.client, super.inbox);
  final details = <Map<String, dynamic>>[], steps = <Map<String, dynamic>>[];
  bool failOnce = false;
  TaskDetail current = sample();
  @override
  Future<void> saveDetails(Map<String, dynamic> request) async {
    details.add(jsonDecode(jsonEncode(request)) as Map<String, dynamic>);
    if (failOnce) {
      failOnce = false;
      throw TimeoutException('Unknown commit outcome');
    }
  }

  @override
  Future<void> saveSteps(Map<String, dynamic> request) async {
    steps.add(jsonDecode(jsonEncode(request)) as Map<String, dynamic>);
    current = sample(updated: '2026-11-24T11:00:00Z');
  }
}

void main() {
  final today = DateTime(2026, 11, 24, 12);
  test(
    'filters combine query, project, status, priority, and local deadlines',
    () {
      final task = sample(due: DateTime(2026, 11, 24, 16));
      expect(
        const TaskFilters(
          query: '100%',
          projectId: 'p1',
          state: 'IN_PROGRESS',
          priority: TaskPriority.high,
          due: DueFilter.today,
        ).matches(task, today),
        isTrue,
      );
      expect(const TaskFilters(query: '%').matches(task, today), isTrue);
      expect(const TaskFilters(query: '_').matches(task, today), isFalse);
      expect(const TaskFilters(projectId: 'p2').matches(task, today), isFalse);
      expect(
        const TaskFilters(due: DueFilter.tomorrow).matches(task, today),
        isFalse,
      );
      expect(
        const TaskFilters(due: DueFilter.none).matches(sample(), today),
        isTrue,
      );
    },
  );
  test('today includes planned work, upcoming excludes completed, overdue uses actual deadline', () {
    final late = sample(due: DateTime(2026, 11, 24, 11));
    expect(matchesTaskTab(late, TaskTab.overdue, today), isTrue);
    expect(
      matchesTaskTab(sample(scheduled: '2026-11-24'), TaskTab.today, today),
      isTrue,
    );
    expect(
      matchesTaskTab(sample(scheduled: '2026-11-25'), TaskTab.upcoming, today),
      isTrue,
    );
    expect(
      matchesTaskTab(
        sample(status: 'COMPLETED', scheduled: '2026-11-25'),
        TaskTab.upcoming,
        today,
      ),
      isFalse,
    );
    expect(
      const TaskFilters(due: DueFilter.overdue).matches(
        sample(status: 'COMPLETED', due: DateTime(2026, 11, 23)),
        today,
      ),
      isFalse,
    );
    expect(
      const TaskFilters(due: DueFilter.week)
          .matches(sample(due: DateTime(2026, 11, 30)), today),
      isFalse,
    );
  });
  test('metadata draft excludes step state and order', () {
    final task = sample();
    expect(
      TaskEditDraft.fromTask(task)
          .sameAs(TaskEditDraft.fromTask(task.withToggledSubtask('s2'))),
      isTrue,
    );
  });

  late SupabaseClient client;
  late RecordingRepository repo;
  setUp(() {
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    repo = RecordingRepository(client, InboxRepository(client));
  });
  tearDown(() async {
    await client.dispose();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskManagementRepositoryProvider.overrideWithValue(repo),
          taskDetailProvider.overrideWith((ref, id) async => repo.current),
          taskProjectsProvider.overrideWith(
            (ref) async => [
              TaskProject.fromJson({'id': 'p1', 'name': 'Dự án học tập'}),
            ],
          ),
          taskListProvider.overrideWith(
            (ref) async => [
              sample(),
              sample(
                id: 'task-2',
                title: 'Ôn từ vựng',
                status: 'TODO',
                priority: 'LOW',
                project: 'p2',
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => page),
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('M14 M15 M11 remain responsive at $width', (tester) async {
      await pump(
        tester,
        EditTaskPage(task: sample()),
        width: width,
        scale: width == 320 ? 1.3 : 1,
      );
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Quản lý 2 bước'));
      expect(find.text('Quản lý bước nhỏ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await pump(
        tester,
        const TaskListPage(),
        width: width,
        scale: width == 320 ? 1.3 : 1,
      );
      expect(find.text('Chuẩn bị bài thuyết trình'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Tìm và lọc'));
      await tester.pumpAndSettle();
      expect(find.text('Bộ lọc'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
    'edit keeps changes local, cancellation confirms, retry uses identical request',
    (tester) async {
      await pump(tester, EditTaskPage(task: sample()));
      await tester.enterText(find.byType(TextFormField).first, 'Tên mới');
      await tester.pump();
      expect(find.text('Có thay đổi chưa lưu'), findsOneWidget);
      expect(repo.details, isEmpty);
      await tapVisible(tester, find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục sửa'));
      await tester.pumpAndSettle();
      repo.failOnce = true;
      await tapVisible(tester, find.text('Lưu thay đổi'));
      expect(repo.details, hasLength(1));
      expect(find.text('Thử lưu lại'), findsOneWidget);
      await tapVisible(tester, find.text('Thử lưu lại'));
      expect(repo.details, hasLength(2));
      expect(repo.details[1], repo.details[0]);
      expect(repo.details[0]['p_fields']['title'], 'Tên mới');
      expect(find.text('Mở'), findsOneWidget);
    },
  );
  testWidgets(
    'M15 reorder closes menu, saves stable step IDs only after Save',
    (tester) async {
      await pump(tester, ManageStepsPage(task: sample()));
      await tester.tap(find.byTooltip('Tùy chọn bước 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đưa lên'));
      await tester.pumpAndSettle();
      expect(find.text('Đưa lên'), findsNothing);
      expect(repo.steps, isEmpty);
      await tapVisible(tester, find.text('Lưu các bước'));
      expect(repo.steps, hasLength(1));
      expect((repo.steps.single['p_steps'] as List).map((s) => s['id']), [
        's2',
        's1',
      ]);
      expect(
        (repo.steps.single['p_steps'] as List).last['is_completed'],
        isTrue,
      );
      expect(find.text('Mở'), findsOneWidget);
    },
  );
  testWidgets(
    'saving steps from edit preserves metadata draft and rebases its version',
    (tester) async {
      await pump(tester, EditTaskPage(task: sample()));
      await tester.enterText(find.byType(TextFormField).first, 'Tên đang sửa');
      await tapVisible(tester, find.text('Quản lý 2 bước'));
      await tester.enterText(find.byType(TextFormField).first, 'Tên bước mới');
      await tapVisible(tester, find.text('Lưu các bước'));
      expect(repo.steps, hasLength(1));
      expect(repo.details, isEmpty);
      expect(find.text('Tên đang sửa'), findsOneWidget);
      await tapVisible(tester, find.text('Lưu thay đổi'));
      expect(repo.details.single['p_expected'], '2026-11-24T11:00:00.000Z');
      expect(repo.details.single['p_fields']['title'], 'Tên đang sửa');
    },
  );
  testWidgets(
    'filter dismissal preserves original; apply returns new filters',
    (tester) async {
      TaskFilters? result;
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showTaskFilters(
                  context,
                  const TaskFilters(priority: TaskPriority.high),
                  [sample()],
                );
              },
              child: const Text('Lọc'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Lọc'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Đặt lại'));
      await tapVisible(tester, find.byTooltip('Đóng bộ lọc'));
      expect(result, isNull);
      await tester.tap(find.text('Lọc'));
      await tester.pumpAndSettle();
      expect(find.text('Cao'), findsOneWidget);
      await tapVisible(tester, find.text('Áp dụng'));
      expect(result?.priority, TaskPriority.high);
    },
  );
}
