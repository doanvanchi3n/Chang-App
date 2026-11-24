import 'package:chang_app/features/tasks/domain/task_detail.dart';
import 'package:flutter_test/flutter_test.dart';

TaskDetail _sampleTask({
  List<TaskSubtask>? subtasks,
  TaskStatus status = TaskStatus.inProgress,
  int progressPercentage = 40,
  DateTime? dueDate,
}) {
  return TaskDetail(
    id: 'task-1',
    title: 'Phác thảo luồng đăng ký',
    description: 'Thiết kế luồng đăng ký tài khoản cho ứng dụng Chặng.',
    priority: TaskPriority.high,
    dueDate: dueDate ?? DateTime.utc(2026, 10, 9),
    scheduledDate: '2026-10-09',
    status: status,
    isArchived: false,
    progressPercentage: progressPercentage,
    estimatedMinutes: 25,
    project: const TaskProjectSummary(
      id: 'proj-1',
      name: 'UI/UX',
      colorHex: '#345D83',
    ),
    subtasks:
        subtasks ??
        const [
          TaskSubtask(
            id: 's3',
            taskId: 'task-1',
            title: 'Vẽ luồng đăng ký',
            orderIndex: 3,
            estimatedMinutes: 30,
            isCompleted: false,
          ),
          TaskSubtask(
            id: 's1',
            taskId: 'task-1',
            title: 'Xác định người dùng',
            orderIndex: 1,
            estimatedMinutes: 25,
            isCompleted: true,
          ),
          TaskSubtask(
            id: 's2',
            taskId: 'task-1',
            title: 'Liệt kê thông tin cần nhập',
            orderIndex: 2,
            estimatedMinutes: 25,
            isCompleted: true,
          ),
          TaskSubtask(
            id: 's5',
            taskId: 'task-1',
            title: 'Rà soát luồng',
            orderIndex: 5,
            estimatedMinutes: 20,
            isCompleted: false,
          ),
          TaskSubtask(
            id: 's4',
            taskId: 'task-1',
            title: 'Bổ sung trạng thái lỗi',
            orderIndex: 4,
            estimatedMinutes: 25,
            isCompleted: false,
          ),
        ],
    updatedAt: DateTime.utc(2026, 10, 8),
  );
}

void main() {
  test('Subtasks luôn được sắp xếp theo orderIndex tăng dần', () {
    final task = _sampleTask();
    expect(task.subtasks.map((s) => s.orderIndex).toList(), [1, 2, 3, 4, 5]);
    expect(task.completedSubtaskCount, 2);
    expect(task.totalSubtaskCount, 5);
    expect(task.computedProgressPercentage, 40);
    expect(task.nextStep?.id, 's3');
    expect(task.expectedSessionMinutes(), 30);
  });

  test('Tick bước 1 trên công việc 5 bước chưa xong -> tiến độ nhảy 20%', () {
    final task = _sampleTask(
      status: TaskStatus.todo,
      progressPercentage: 0,
      subtasks: [
        for (var i = 1; i <= 5; i++)
          TaskSubtask(
            id: 's$i',
            taskId: 'task-1',
            title: 'Bước $i',
            orderIndex: i,
            estimatedMinutes: 25,
            isCompleted: false,
          ),
      ],
    );

    final updated = task.withToggledSubtask('s1');
    expect(updated.completedSubtaskCount, 1);
    expect(updated.computedProgressPercentage, 20);
    expect(updated.status, TaskStatus.inProgress);
    expect(updated.nextStep?.orderIndex, 2);
  });

  test('Hoàn thành tất cả các bước chuyển trạng thái sang COMPLETED 100%', () {
    final task = _sampleTask(
      subtasks: const [
        TaskSubtask(
          id: 's1',
          taskId: 'task-1',
          title: 'Bước 1',
          orderIndex: 1,
          estimatedMinutes: 25,
          isCompleted: true,
        ),
        TaskSubtask(
          id: 's2',
          taskId: 'task-1',
          title: 'Bước 2',
          orderIndex: 2,
          estimatedMinutes: 25,
          isCompleted: false,
        ),
      ],
    );

    final completed = task.withToggledSubtask('s2');
    expect(completed.computedProgressPercentage, 100);
    expect(completed.status, TaskStatus.completed);
    expect(completed.nextStep, isNull);

    final reopened = completed.withToggledSubtask('s2');
    expect(reopened.computedProgressPercentage, 50);
    expect(reopened.status, TaskStatus.inProgress);
    expect(reopened.nextStep?.id, 's2');
  });

  test('Quy tắc tối đa 5 bước và tính nextOrderIndex an toàn khi khuyết số', () {
    final full = _sampleTask();
    expect(full.canAddSubtask, isFalse);
    expect(full.nextOrderIndex, isNull);

    final withGap = _sampleTask(
      subtasks: const [
        TaskSubtask(
          id: 's1',
          taskId: 'task-1',
          title: 'Bước 1',
          orderIndex: 1,
          estimatedMinutes: 25,
          isCompleted: false,
        ),
        TaskSubtask(
          id: 's5',
          taskId: 'task-1',
          title: 'Bước 5',
          orderIndex: 5,
          estimatedMinutes: 25,
          isCompleted: false,
        ),
      ],
    );
    expect(withGap.canAddSubtask, isTrue);
    expect(withGap.nextOrderIndex, 2);
  });

  test('resolveFocusStep ưu tiên bước đang chọn nếu chưa hoàn thành', () {
    final task = _sampleTask();
    expect(task.resolveFocusStep(null)?.id, 's3');
    expect(task.resolveFocusStep('s4')?.id, 's4');
    // Bước 1 đã hoàn thành -> tự lùi về nextStep (s3).
    expect(task.resolveFocusStep('s1')?.id, 's3');
  });

  test('isOverdue chỉ báo quá hạn khi chưa hoàn thành và qua dueDate', () {
    final task = _sampleTask(
      dueDate: DateTime.utc(2026, 10, 9),
      status: TaskStatus.inProgress,
    );
    expect(task.isOverdue(DateTime.utc(2026, 10, 10)), isTrue);
    expect(task.isOverdue(DateTime.utc(2026, 10, 8)), isFalse);
    expect(
      task.withStatus(TaskStatus.completed).isOverdue(DateTime.utc(2026, 10, 10)),
      isFalse,
    );
  });
}
