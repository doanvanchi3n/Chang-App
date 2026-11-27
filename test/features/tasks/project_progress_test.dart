import 'package:chang_app/features/projects/domain/study_project.dart';
import 'package:chang_app/features/tasks/domain/task_detail.dart';
import 'package:flutter_test/flutter_test.dart';

TaskDetail task(
  String id,
  String status, {
  String project = 'p1',
  bool archived = false,
}) => TaskDetail.fromJson({
  'id': id,
  'title': id,
  'status': status,
  'is_archived': archived,
  'progress_percentage': 100,
  'completed_at': status == 'COMPLETED' ? '2026-11-27T10:00:00Z' : null,
  'projects': {'id': project, 'name': 'Đồ án UI/UX'},
  'subtasks': [
    {
      'id': 's1',
      'title': 'Bước đã xong',
      'order_index': 1,
      'is_completed': true,
    },
  ],
});

void main() {
  test('project progress counts task status, excludes other projects and archived tasks', () {
    final progress = ProjectProgress('p1', [
      task('1', 'COMPLETED'),
      task('2', 'IN_PROGRESS'),
      task('3', 'COMPLETED', project: 'p2'),
      task('4', 'COMPLETED', archived: true),
    ]);
    expect(progress.total, 2);
    expect(progress.completed, 1);
    expect(progress.percent, 50);
    expect(ProjectProgress('new', []).percent, 0);
    expect(ProjectProgress('new', []).label, 'Chưa có công việc');
  });

  test('reopening retains every step and clears completion timestamp', () {
    final done = task('1', 'COMPLETED');
    expect(done.completedAt, DateTime.utc(2026, 11, 27, 10));
    final reopened = done.withStatus(TaskStatus.inProgress);
    expect(reopened.completedAt, isNull);
    expect(reopened.status, TaskStatus.inProgress);
    expect(reopened.subtasks.single.isCompleted, isTrue);
    expect(ProjectProgress('p1', [reopened]).completed, 0);
  });
}
