import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:chang_app/features/tasks/data/task_detail_repository.dart';
import 'package:chang_app/features/tasks/domain/task_detail.dart';
import 'package:chang_app/features/tasks/presentation/task_detail_page.dart';
import 'package:chang_app/features/tasks/presentation/task_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeTaskDetailRepository extends TaskDetailRepository {
  _FakeTaskDetailRepository(super.client, super.inbox, this.task);

  TaskDetail? task;
  bool failRead = false;
  bool failToggle = false;
  bool failAdd = false;

  @override
  Future<TaskDetail?> fetchById(String taskId) async {
    if (failRead) throw StateError('Read failed');
    return task;
  }

  @override
  Future<TaskDetail> toggleSubtask({
    required String taskId,
    required String subtaskId,
    required bool isCompleted,
  }) async {
    if (failToggle) throw StateError('Toggle failed');
    task = task!.withToggledSubtask(subtaskId);
    return task!;
  }

  @override
  Future<TaskDetail> addSubtask({
    required String taskId,
    required String title,
    required int orderIndex,
    int estimatedMinutes = 25,
  }) async {
    if (failAdd) throw StateError('Add failed');
    final current = task!;
    final nextSubtasks = [
      ...current.subtasks,
      TaskSubtask(
        id: 'new-$orderIndex',
        taskId: taskId,
        title: title.trim(),
        orderIndex: orderIndex,
        estimatedMinutes: estimatedMinutes,
        isCompleted: false,
      ),
    ];
    final completed = nextSubtasks.where((s) => s.isCompleted).length;
    final percent = ((completed / nextSubtasks.length) * 100).round();
    task = TaskDetail(
      id: current.id,
      title: current.title,
      description: current.description,
      priority: current.priority,
      dueDate: current.dueDate,
      scheduledDate: current.scheduledDate,
      status: percent == 100
          ? TaskStatus.completed
          : percent > 0
          ? TaskStatus.inProgress
          : TaskStatus.todo,
      isArchived: current.isArchived,
      progressPercentage: percent,
      estimatedMinutes: current.estimatedMinutes,
      project: current.project,
      subtasks: nextSubtasks,
      updatedAt: DateTime.utc(2026, 10, 8),
    );
    return task!;
  }
}

TaskDetail _designSampleTask({int subtaskCount = 5}) {
  final allSubtasks = const [
    TaskSubtask(
      id: 's1',
      taskId: 'task-13',
      title: 'Xác định người dùng',
      orderIndex: 1,
      estimatedMinutes: 25,
      isCompleted: true,
    ),
    TaskSubtask(
      id: 's2',
      taskId: 'task-13',
      title: 'Liệt kê thông tin cần nhập',
      orderIndex: 2,
      estimatedMinutes: 25,
      isCompleted: true,
    ),
    TaskSubtask(
      id: 's3',
      taskId: 'task-13',
      title: 'Vẽ luồng đăng ký',
      orderIndex: 3,
      estimatedMinutes: 25,
      isCompleted: false,
    ),
    TaskSubtask(
      id: 's4',
      taskId: 'task-13',
      title: 'Bổ sung trạng thái lỗi',
      orderIndex: 4,
      estimatedMinutes: 25,
      isCompleted: false,
    ),
    TaskSubtask(
      id: 's5',
      taskId: 'task-13',
      title: 'Rà soát luồng',
      orderIndex: 5,
      estimatedMinutes: 25,
      isCompleted: false,
    ),
  ];

  final list = allSubtasks.take(subtaskCount).toList();
  final done = list.where((s) => s.isCompleted).length;
  final pct = list.isEmpty ? 0 : ((done / list.length) * 100).round();

  return TaskDetail(
    id: 'task-13',
    title: 'Phác thảo luồng đăng ký',
    description:
        'Thiết kế luồng đăng ký tài khoản cho ứng dụng Chặng. Bao gồm nhập thông tin, xác thực và xử lý lỗi.',
    priority: TaskPriority.high,
    dueDate: DateTime.utc(2026, 10, 9),
    scheduledDate: '2026-10-09',
    status: pct == 100
        ? TaskStatus.completed
        : pct > 0
        ? TaskStatus.inProgress
        : TaskStatus.todo,
    isArchived: false,
    progressPercentage: pct,
    estimatedMinutes: 25,
    project: const TaskProjectSummary(
      id: 'proj-uiux',
      name: 'UI/UX',
      colorHex: '#345D83',
    ),
    subtasks: list,
    updatedAt: DateTime.utc(2026, 10, 8),
  );
}

void main() {
  late SupabaseClient client;
  late _FakeTaskDetailRepository repository;

  setUp(() {
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    repository = _FakeTaskDetailRepository(
      client,
      InboxRepository(client),
      _designSampleTask(),
    );
  });

  tearDown(() => client.dispose());

  Future<void> pumpDetail(
    WidgetTester tester, {
    required Size size,
    FocusStepCallback? onStartFocus,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskDetailRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: TaskDetailPage(
            taskId: 'task-13',
            onStartFocus: onStartFocus,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('W13 (Web) hiển thị 2 cột, tiến độ 40%, bước tiếp theo và nút tập trung bước 3', (
    tester,
  ) async {
    await pumpDetail(tester, size: const Size(1280, 900));

    expect(find.text('Phác thảo luồng đăng ký'), findsOneWidget);
    expect(find.text('Đang làm'), findsOneWidget);
    expect(find.text('Các bước thực hiện'), findsOneWidget);
    expect(find.text('2/5 bước hoàn thành'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Bước tiếp theo'), findsOneWidget);
    expect(find.text('Thông tin công việc'), findsOneWidget);
    expect(find.text('UI/UX'), findsOneWidget);
    expect(find.text('09/10/2026'), findsOneWidget);
    expect(find.text('Cao'), findsOneWidget);
    expect(find.text('25 phút'), findsOneWidget);
    expect(find.text('Tập trung vào bước 3'), findsOneWidget);
    expect(find.text('Xếp vào lịch'), findsOneWidget);
    expect(find.text('Cần chia nhỏ hơn?'), findsOneWidget);

    // Đủ 5 bước -> nút Thêm bước bị vô hiệu hóa theo quy tắc 5 bước.
    final addButton = tester.widget<TextButton>(
      find.byKey(const ValueKey('add-subtask-button')),
    );
    expect(addButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('M13 (Mobile) tick bước 3 cập nhật 3/5 (60%) và chuyển CTA sang bước 4', (
    tester,
  ) async {
    await pumpDetail(tester, size: const Size(390, 844));

    expect(find.text('Chi tiết công việc'), findsOneWidget);
    expect(find.text('· 2/5 hoàn thành'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Tập trung vào bước 3'), findsOneWidget);

    final step3Checkbox = find.byKey(const ValueKey('subtask-checkbox-s3'));
    await tester.ensureVisible(step3Checkbox);
    await tester.pumpAndSettle();
    await tester.tap(step3Checkbox);
    await tester.pumpAndSettle();

    expect(find.text('· 3/5 hoàn thành'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('Tập trung vào bước 4'), findsOneWidget);
  });

  testWidgets('Chọn bước cụ thể (bước 4) cập nhật nút kích hoạt phiên học cho bước đó', (
    tester,
  ) async {
    TaskSubtask? focusedStep;
    await pumpDetail(
      tester,
      size: const Size(390, 844),
      onStartFocus: (task, step) => focusedStep = step,
    );

    final step4Row = find.byKey(const ValueKey('subtask-row-s4'));
    await tester.ensureVisible(step4Row);
    await tester.pumpAndSettle();
    await tester.tap(step4Row);
    await tester.pumpAndSettle();

    expect(find.text('Tập trung vào bước 4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('focus-step-button')));
    await tester.pumpAndSettle();

    expect(focusedStep?.id, 's4');
    expect(focusedStep?.orderIndex, 4);
  });

  testWidgets('Lỗi khi tick bước nhỏ sẽ hoàn nguyên tiến độ và hiện thông báo', (
    tester,
  ) async {
    repository.failToggle = true;
    await pumpDetail(tester, size: const Size(390, 844));

    final step3Checkbox = find.byKey(const ValueKey('subtask-checkbox-s3'));
    await tester.ensureVisible(step3Checkbox);
    await tester.pumpAndSettle();
    await tester.tap(step3Checkbox);
    await tester.pumpAndSettle();

    expect(find.text('40%'), findsOneWidget);
    expect(
      find.text('Chưa cập nhật được trạng thái bước nhỏ. Vui lòng thử lại.'),
      findsOneWidget,
    );
  });

  testWidgets('Khi có dưới 5 bước, người dùng có thể thêm bước mới và tính lại %', (
    tester,
  ) async {
    repository.task = _designSampleTask(subtaskCount: 3);
    await pumpDetail(tester, size: const Size(1280, 900));

    expect(find.text('2/3 bước hoàn thành'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-subtask-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('new-subtask-title-field')),
      'Bổ sung trạng thái lỗi',
    );
    await tester.tap(find.byKey(const ValueKey('submit-new-subtask-button')));
    await tester.pumpAndSettle();

    expect(find.text('Bổ sung trạng thái lỗi'), findsOneWidget);
    expect(find.text('2/4 bước hoàn thành'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('Màn hình nhỏ 320px với cỡ chữ lớn 2.0x không bị tràn giao diện', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      size: const Size(320, 568),
      textScale: 2.0,
    );

    expect(find.text('Phác thảo luồng đăng ký'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hiển thị trạng thái lỗi với nút Thử lại khi đọc thất bại', (
    tester,
  ) async {
    repository.failRead = true;
    await pumpDetail(tester, size: const Size(390, 844));

    expect(find.text('Thử lại'), findsOneWidget);
    repository.failRead = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Phác thảo luồng đăng ký'), findsOneWidget);
  });
}
