import 'task_detail.dart';

enum TaskTab { all, today, upcoming, overdue }

enum DueFilter { any, today, tomorrow, week, overdue, none }

class TaskFilters {
  const TaskFilters({
    this.query = '',
    this.projectId,
    this.state,
    this.priority,
    this.due = DueFilter.any,
  });
  final String query;
  final String? projectId, state;
  final TaskPriority? priority;
  final DueFilter due;
  int get count => [
    projectId != null,
    state != null,
    priority != null,
    due != DueFilter.any,
  ].where((v) => v).length;
  bool matches(TaskDetail task, DateTime now) {
    final term = query.trim().toLowerCase();
    if (term.isNotEmpty &&
        !'${task.title} ${task.description ?? ''}'.toLowerCase().contains(term)) {
      return false;
    }
    if (projectId != null && task.project?.id != projectId) return false;
    if (state == 'OVERDUE'
        ? !task.isOverdue(now)
        : state != null && task.status.dbValue != state) {
      return false;
    }
    if (priority != null && task.priority != priority) return false;
    final date = task.dueDate?.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    bool within(DateTime start, DateTime end) =>
        date != null && !date.isBefore(start) && date.isBefore(end);
    return switch (due) {
      DueFilter.any => true,
      DueFilter.today => within(today, tomorrow),
      DueFilter.tomorrow => within(
        tomorrow,
        DateTime(now.year, now.month, now.day + 2),
      ),
      DueFilter.week => within(
        DateTime(now.year, now.month, now.day - today.weekday + 1),
        DateTime(now.year, now.month, now.day + 8 - today.weekday),
      ),
      DueFilter.overdue => task.isOverdue(now),
      DueFilter.none => date == null,
    };
  }

  TaskFilters withQuery(String value) => TaskFilters(
    query: value,
    projectId: projectId,
    state: state,
    priority: priority,
    due: due,
  );
}

String taskDayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
bool matchesTaskTab(TaskDetail task, TaskTab tab, DateTime now) {
  final today = taskDayKey(now);
  final due = task.dueDate == null ? null : taskDayKey(task.dueDate!.toLocal());
  return switch (tab) {
    TaskTab.all => true,
    TaskTab.today => task.scheduledDate == today || due == today,
    TaskTab.upcoming =>
      task.status != TaskStatus.completed &&
          ((task.scheduledDate?.compareTo(today) ?? -1) > 0 ||
              (due?.compareTo(today) ?? -1) > 0),
    TaskTab.overdue => task.isOverdue(now),
  };
}

String dueFilterLabel(DueFilter filter) => switch (filter) {
  DueFilter.any => 'Tất cả',
  DueFilter.today => 'Hôm nay',
  DueFilter.tomorrow => 'Ngày mai',
  DueFilter.week => 'Tuần này',
  DueFilter.overdue => 'Quá hạn',
  DueFilter.none => 'Chưa có hạn',
};
