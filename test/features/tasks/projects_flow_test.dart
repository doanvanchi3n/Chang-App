import 'dart:async';

import 'package:chang_app/features/projects/data/project_repository.dart';
import 'package:chang_app/features/projects/domain/study_project.dart';
import 'package:chang_app/features/projects/presentation/create_project_page.dart';
import 'package:chang_app/features/projects/presentation/project_detail_page.dart';
import 'package:chang_app/features/projects/presentation/project_list_page.dart';
import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:chang_app/features/tasks/data/task_detail_repository.dart';
import 'package:chang_app/features/tasks/data/task_management_repository.dart';
import 'package:chang_app/features/tasks/data/task_repository.dart';
import 'package:chang_app/features/tasks/domain/task_detail.dart';
import 'package:chang_app/features/tasks/presentation/completed_tasks_page.dart';
import 'package:chang_app/features/tasks/presentation/create_task_page.dart';
import 'package:chang_app/features/tasks/presentation/task_detail_page.dart';
import 'package:chang_app/features/tasks/presentation/task_detail_provider.dart';
import 'package:chang_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _project = StudyProject(
  id: 'p1',
  name: 'Đồ án UI/UX',
  description: 'Thiết kế ứng dụng hỗ trợ tự học.',
);
TaskDetail _task({
  String id = 't1',
  String project = 'p1',
  String title = 'Thu thập yêu cầu sinh viên',
  String status = 'COMPLETED',
}) => TaskDetail.fromJson({
  'id': id,
  'title': title,
  'status': status,
  'completed_at': status == 'COMPLETED' ? '2026-11-27T10:00:00Z' : null,
  'projects': {
    'id': project,
    'name': project == 'p1' ? _project.name : 'Ôn TOEIC',
  },
  'subtasks': [
    {'id': 's1', 'title': 'Phỏng vấn', 'order_index': 1, 'is_completed': true},
  ],
});

class _Memory {
  List<StudyProject> projects = [_project];
  List<TaskDetail> tasks = [
    _task(),
    _task(id: 't2', project: 'p2', title: 'Ôn từ vựng'),
  ];
  final requests = <Map<String, dynamic>>[];
  final taskRequests = <Map<String, dynamic>>[];
  bool failCreateOnce = false, failRead = false, failStatus = false;
  int writes = 0;
}

class _Projects extends ProjectRepository {
  _Projects(super.client, super.inbox, this.memory);
  final _Memory memory;
  @override
  Future<List<StudyProject>> list() async {
    if (memory.failRead) throw StateError('offline');
    return [...memory.projects];
  }

  @override
  Future<String> create(Map<String, dynamic> request) async {
    memory.requests.add(Map.of(request));
    if (memory.failCreateOnce) {
      memory.failCreateOnce = false;
      throw TimeoutException('unknown result');
    }
    memory.projects.add(
      StudyProject(
        id: request['p_id'],
        name: request['p_name'],
        description: request['p_description'],
        colorHex: request['p_color'],
        iconName: request['p_icon'],
      ),
    );
    return request['p_id'];
  }
}

class _Tasks extends TaskManagementRepository {
  _Tasks(super.client, super.inbox, this.memory);
  final _Memory memory;
  @override
  Future<List<TaskDetail>> list() async => [...memory.tasks];
}

class _Details extends TaskDetailRepository {
  _Details(super.client, super.inbox, this.memory);
  final _Memory memory;
  @override
  Future<TaskDetail?> fetchById(String taskId) async =>
      memory.tasks.where((t) => t.id == taskId).firstOrNull;
  @override
  Future<TaskDetail> setTaskStatus({
    required String taskId,
    required TaskStatus status,
    required bool hasSubtasks,
  }) async {
    if (memory.failStatus) throw StateError('offline');
    memory.writes++;
    final index = memory.tasks.indexWhere((t) => t.id == taskId);
    return memory.tasks[index] = memory.tasks[index].withStatus(status);
  }
}

class _CreateTasks extends TaskRepository {
  _CreateTasks(super.client, super.inbox, this.memory);
  final _Memory memory;
  @override
  Future<String> create(Map<String, dynamic> payload) async {
    memory.taskRequests.add(Map.of(payload));
    final project = memory.projects.singleWhere(
      (p) => p.id == payload['p_project_id'],
    );
    final steps = payload['p_steps'] as List;
    memory.tasks.add(
      TaskDetail.fromJson({
        'id': payload['p_id'],
        'title': payload['p_title'],
        'status': 'TODO',
        'projects': {
          'id': project.id,
          'name': project.name,
          'color_hex': project.colorHex,
        },
        'subtasks': [
          for (var i = 0; i < steps.length; i++)
            {
              'id': 'new-step-$i',
              'title': steps[i],
              'order_index': i + 1,
              'is_completed': false,
            },
        ],
      }),
    );
    return payload['p_id'];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  late SupabaseClient client;
  late _Memory memory;
  setUp(() {
    client = SupabaseClient(
      'https://example.supabase.co',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    memory = _Memory();
  });
  tearDown(() async => client.dispose());

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final inbox = InboxRepository(client);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectRepositoryProvider.overrideWithValue(
            _Projects(client, inbox, memory),
          ),
          taskManagementRepositoryProvider.overrideWithValue(
            _Tasks(client, inbox, memory),
          ),
          taskDetailRepositoryProvider.overrideWithValue(
            _Details(client, inbox, memory),
          ),
          taskRepositoryProvider.overrideWithValue(
            _CreateTasks(client, inbox, memory),
          ),
          taskProjectsProvider.overrideWith(
            (ref) async => memory.projects
                .map((p) => TaskProject.fromJson({'id': p.id, 'name': p.name}))
                .toList(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> capture(String name) async {
    if (const bool.fromEnvironment('CAPTURE_PROJECT_UI')) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(Uri.file('/tmp/chang-feat10-11-$name.png')),
      );
    }
  }

  testWidgets(
    'M18 validates, retries unchanged request, creates empty project and prefills M12',
    (tester) async {
      memory.failCreateOnce = true;
      await pump(tester, const CreateProjectPage());
      await tap(tester, find.widgetWithText(FilledButton, 'Tạo dự án'));
      expect(find.text('Nhập tên dự án.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Ôn thi cuối kỳ',
      );
      await tap(tester, find.widgetWithText(FilledButton, 'Tạo dự án'));
      expect(memory.requests, hasLength(1));
      await tap(tester, find.text('Thử lưu lại'));
      expect(memory.requests, hasLength(2));
      expect(memory.requests[0], memory.requests[1]);
      expect(find.byType(ProjectDetailPage), findsOneWidget);
      expect(find.text('Chưa có công việc'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      await tap(tester, find.text('Thêm việc'));
      expect(find.byType(CreateTaskPage), findsOneWidget);
      expect(find.text('Ôn thi cuối kỳ'), findsOneWidget);
      expect(memory.tasks, hasLength(2));
      await tester.enterText(
        find.byType(TextFormField).first,
        'Đọc tài liệu ôn thi',
      );
      for (var i = 1; i <= 3; i++) {
        final step = find.widgetWithText(TextFormField, 'Bước $i');
        await tester.ensureVisible(step);
        await tester.enterText(step, 'Nội dung bước $i');
        await tester.pumpAndSettle();
      }
      await tap(tester, find.widgetWithText(FilledButton, 'Tạo công việc'));
      expect(
        memory.taskRequests.single['p_project_id'],
        memory.requests.last['p_id'],
      );
      expect(find.byType(TaskDetailPage), findsOneWidget);
      expect(find.text('Đọc tài liệu ôn thi'), findsOneWidget);
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.byType(ProjectDetailPage), findsOneWidget);
      expect(find.text('0/1 công việc hoàn thành'), findsOneWidget);
      await tap(tester, find.text('Đọc tài liệu ôn thi'));
      expect(find.byType(TaskDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'M20 filters, cancels reopening, retains failed item and reopens without losing steps',
    (tester) async {
      await pump(tester, const CompletedTasksPage(initialProjectId: 'p1'));
      expect(find.text('Thu thập yêu cầu sinh viên'), findsOneWidget);
      expect(find.text('Ôn từ vựng'), findsNothing);
      await tester.enterText(find.byType(TextField).first, 'không có');
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy công việc phù hợp.'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      await tap(tester, find.text('Mở lại'));
      expect(find.textContaining('1/1 → 0/1'), findsOneWidget);
      await capture('M20-reopen');
      await tap(tester, find.text('Hủy'));
      expect(memory.writes, 0);
      await tap(tester, find.text('Mở lại'));
      memory.failStatus = true;
      await tap(tester, find.widgetWithText(FilledButton, 'Mở lại công việc'));
      expect(
        find.textContaining('Chưa xác nhận được kết quả.'),
        findsOneWidget,
      );
      expect(memory.tasks.first.status, TaskStatus.completed);
      memory.failStatus = false;
      await tap(tester, find.widgetWithText(FilledButton, 'Mở lại công việc'));
      expect(memory.writes, 1);
      expect(memory.tasks.first.status, TaskStatus.inProgress);
      expect(memory.tasks.first.completedAt, isNull);
      expect(memory.tasks.first.subtasks.single.isCompleted, isTrue);
      expect(find.text('Thu thập yêu cầu sinh viên'), findsNothing);
      await tap(tester, find.text('Chưa xong 1'));
      expect(find.text('Thu thập yêu cầu sinh viên'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'M19 progress and tabs follow task status even when every step is complete',
    (tester) async {
      memory.tasks.add(
        _task(
          id: 't3',
          title: 'Phác thảo luồng đăng ký',
          status: 'IN_PROGRESS',
        ),
      );
      await pump(tester, const ProjectDetailPage(projectId: 'p1'));
      expect(find.text('50%'), findsOneWidget);
      await tap(tester, find.text('Đã xong 1'));
      expect(find.text('Thu thập yêu cầu sinh viên'), findsOneWidget);
      expect(find.text('Phác thảo luồng đăng ký'), findsNothing);
      await tap(tester, find.text('Chưa xong 1'));
      expect(find.text('Phác thảo luồng đăng ký'), findsOneWidget);
      expect(find.text('Thu thập yêu cầu sinh viên'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('M17 distinguishes network failure, empty and search states', (
    tester,
  ) async {
    memory.failRead = true;
    await pump(tester, const ProjectListPage());
    expect(find.textContaining('Chưa tải được dữ liệu.'), findsOneWidget);
    memory.failRead = false;
    await tap(tester, find.text('Tải lại'));
    expect(find.text(_project.name), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'không tìm thấy');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy dự án'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 768.0, 1280.0]) {
    testWidgets('M17–M20 handle long content at $width', (tester) async {
      memory.projects = [
        const StudyProject(
          id: 'p1',
          name: 'Đồ án UI/UX và nghiên cứu trải nghiệm người dùng trên thiết bị di động',
          description: 'Mục tiêu học tập dài để kiểm tra xuống dòng.',
        ),
      ];
      for (final page in [
        const ProjectListPage(),
        const CreateProjectPage(),
        const ProjectDetailPage(projectId: 'p1'),
        const CompletedTasksPage(initialProjectId: 'p1'),
      ]) {
        await pump(tester, page, width: width, scale: width == 320 ? 1.3 : 1);
        if (width == 390) await capture(page.runtimeType.toString());
        final scrollable = find.byType(Scrollable).first;
        for (var i = 0; i < 5; i++) {
          await tester.drag(scrollable, const Offset(0, -320));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
}
