import 'dart:convert';

import 'task_detail.dart';

class TaskEditDraft {
  const TaskEditDraft({
    required this.title,
    required this.description,
    required this.projectId,
    required this.dueDate,
    required this.priority,
    required this.minutes,
  });
  factory TaskEditDraft.fromTask(TaskDetail task) => TaskEditDraft(
    title: task.title,
    description: task.description ?? '',
    projectId: task.project?.id,
    dueDate: task.dueDate,
    priority: task.priority,
    minutes:
        task.estimatedMinutes ??
        task.subtasks
            .fold<int>(0, (n, s) => n + s.estimatedMinutes)
            .clamp(1, 1440),
  );
  final String title, description;
  final String? projectId;
  final DateTime? dueDate;
  final TaskPriority priority;
  final int minutes;
  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'description': description.trim(),
    'project_id': projectId,
    'due_date': dueDate?.toUtc().toIso8601String(),
    'priority': priority.dbValue,
    'estimated_minutes': minutes,
  };
  bool sameAs(TaskEditDraft other) =>
      jsonEncode(toJson()) == jsonEncode(other.toJson());
}
