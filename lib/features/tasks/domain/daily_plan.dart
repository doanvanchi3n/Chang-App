String planDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class PlanningTask {
  PlanningTask.fromJson(Map<String, dynamic> row)
    : id = row['id'] as String,
      title = row['title'] as String,
      updatedAt = row['updated_at'] as String,
      scheduledDate = row['scheduled_date'] as String?,
      minutes = row['estimated_minutes'] as int? ?? _remainingMinutes(row);

  final String id;
  final String title;
  final String updatedAt;
  final String? scheduledDate;
  final int? minutes;

  static int? _remainingMinutes(Map<String, dynamic> row) {
    final steps = (row['subtasks'] as List).where(
      (step) => step['is_completed'] == false,
    );
    if (steps.isEmpty) return null;
    return steps.fold<int>(
      0,
      (total, step) => total + (step['estimated_minutes'] as int),
    );
  }

  Map<String, dynamic> get snapshot => {'id': id, 'updated_at': updatedAt};
}

class DailyPlanData {
  const DailyPlanData({
    required this.date,
    required this.availableMinutes,
    required this.updatedAt,
    required this.tasks,
  });

  final DateTime date;
  final int? availableMinutes;
  final String? updatedAt;
  final List<PlanningTask> tasks;

  List<PlanningTask> get todayTasks =>
      tasks.where((task) => task.scheduledDate == planDateKey(date)).toList();
}
