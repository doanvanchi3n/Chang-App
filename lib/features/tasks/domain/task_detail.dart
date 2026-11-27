enum TaskStatus {
  todo('TODO', 'Chưa làm'),
  inProgress('IN_PROGRESS', 'Đang làm'),
  completed('COMPLETED', 'Hoàn thành');

  const TaskStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static TaskStatus fromDb(String? value) {
    return switch (value) {
      'IN_PROGRESS' => TaskStatus.inProgress,
      'COMPLETED' => TaskStatus.completed,
      _ => TaskStatus.todo,
    };
  }
}

enum TaskPriority {
  low('LOW', 'Thấp'),
  medium('MEDIUM', 'Trung bình'),
  high('HIGH', 'Cao');

  const TaskPriority(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static TaskPriority fromDb(String? value) {
    return switch (value) {
      'HIGH' => TaskPriority.high,
      'LOW' => TaskPriority.low,
      _ => TaskPriority.medium,
    };
  }
}

class TaskProjectSummary {
  const TaskProjectSummary({
    required this.id,
    required this.name,
    required this.colorHex,
  });

  final String id;
  final String name;
  final String colorHex;

  factory TaskProjectSummary.fromJson(Map<String, dynamic> json) {
    return TaskProjectSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: (json['color_hex'] as String?) ?? '#345D83',
    );
  }
}

class TaskSubtask {
  const TaskSubtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.orderIndex,
    required this.estimatedMinutes,
    required this.isCompleted,
    this.completedAt,
  });

  final String id;
  final String taskId;
  final String title;
  final int orderIndex;
  final int estimatedMinutes;
  final bool isCompleted;
  final DateTime? completedAt;

  int get order => orderIndex;
  int get minutes => estimatedMinutes;
  bool get completed => isCompleted;

  factory TaskSubtask.fromJson(Map<String, dynamic> json) {
    return TaskSubtask(
      id: json['id'] as String,
      taskId: (json['task_id'] as String?) ?? '',
      title: json['title'] as String,
      orderIndex: json['order_index'] as int,
      estimatedMinutes: (json['estimated_minutes'] as int?) ?? 25,
      isCompleted: json['is_completed'] == true,
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
    );
  }

  TaskSubtask copyWith({
    String? title,
    int? orderIndex,
    int? estimatedMinutes,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TaskSubtask(
      id: id,
      taskId: taskId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}

class TaskDetail {
  static const int maxSubtasks = 5;
  static const int maxSubtaskTitleLength = 200;
  static const int minEstimatedMinutes = 1;
  static const int maxEstimatedMinutes = 1440;

  TaskDetail({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    this.dueDate,
    this.scheduledDate,
    required this.status,
    required this.isArchived,
    required this.progressPercentage,
    this.estimatedMinutes,
    this.project,
    required List<TaskSubtask> subtasks,
    required this.updatedAt,
    this.completedAt,
  }) : subtasks = List.unmodifiable(
         List<TaskSubtask>.from(subtasks)
           ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
       );

  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? scheduledDate;
  final TaskStatus status;
  final bool isArchived;
  final int progressPercentage;
  final int? estimatedMinutes;
  final TaskProjectSummary? project;
  final List<TaskSubtask> subtasks;
  final DateTime updatedAt;
  final DateTime? completedAt;

  factory TaskDetail.fromJson(Map<String, dynamic> json) {
    final projectRaw = json['projects'] as Map<String, dynamic>?;
    final subtasksRaw = (json['subtasks'] as List?) ?? const [];
    return TaskDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriority.fromDb(json['priority'] as String?),
      dueDate: DateTime.tryParse(json['due_date'] as String? ?? ''),
      scheduledDate: json['scheduled_date'] as String?,
      status: TaskStatus.fromDb(json['status'] as String?),
      isArchived: json['is_archived'] == true,
      progressPercentage: (json['progress_percentage'] as int?) ?? 0,
      estimatedMinutes: json['estimated_minutes'] as int?,
      project: projectRaw == null
          ? null
          : TaskProjectSummary.fromJson(projectRaw),
      subtasks: subtasksRaw
          .map((item) => TaskSubtask.fromJson(item as Map<String, dynamic>))
          .toList(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
    );
  }

  int get totalSubtaskCount => subtasks.length;

  int get completedSubtaskCount =>
      subtasks.where((step) => step.isCompleted).length;

  List<TaskSubtask> get steps => subtasks;
  int get completedSteps => completedSubtaskCount;
  bool get archived => isArchived;
  int? get minutes => estimatedMinutes;

  bool get canAddSubtask => subtasks.length < maxSubtasks;

  /// Returns the next valid `order_index` in `1..5`, or `null` if full.
  int? get nextOrderIndex {
    if (!canAddSubtask) return null;
    if (subtasks.isEmpty) return 1;
    final used = subtasks.map((step) => step.orderIndex).toSet();
    final highest = subtasks.last.orderIndex;
    if (highest < maxSubtasks && !used.contains(highest + 1)) {
      return highest + 1;
    }
    for (var i = 1; i <= maxSubtasks; i++) {
      if (!used.contains(i)) return i;
    }
    return null;
  }

  /// Mirrors PostgreSQL `recalculate_task_progress()` rounding behavior.
  int get computedProgressPercentage {
    if (subtasks.isEmpty) {
      if (status == TaskStatus.completed) return 100;
      return progressPercentage.clamp(0, 100);
    }
    return ((completedSubtaskCount / subtasks.length) * 100).round();
  }

  /// First incomplete step in display order, or `null` if none remain.
  TaskSubtask? get nextStep {
    for (final step in subtasks) {
      if (!step.isCompleted) return step;
    }
    return null;
  }

  /// Resolves the step to focus on: prefers [preferredStepId] if still
  /// incomplete, otherwise falls back to [nextStep].
  TaskSubtask? resolveFocusStep(String? preferredStepId) {
    if (preferredStepId != null) {
      for (final step in subtasks) {
        if (step.id == preferredStepId && !step.isCompleted) {
          return step;
        }
      }
    }
    return nextStep;
  }

  /// Expected session minutes for [focusStep], falling back to task estimate or 25.
  int expectedSessionMinutes([TaskSubtask? focusStep]) {
    final target = focusStep ?? nextStep;
    return target?.estimatedMinutes ?? estimatedMinutes ?? 25;
  }

  bool isOverdue(DateTime now) {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return dueDate!.isBefore(now);
  }

  TaskDetail withToggledSubtask(String subtaskId, {DateTime? now}) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    final updatedSubtasks = subtasks.map((step) {
      if (step.id != subtaskId) return step;
      final nextCompleted = !step.isCompleted;
      return step.copyWith(
        isCompleted: nextCompleted,
        completedAt: nextCompleted ? timestamp : null,
        clearCompletedAt: !nextCompleted,
      );
    }).toList();

    final completedCount = updatedSubtasks.where((s) => s.isCompleted).length;
    final nextPercent = updatedSubtasks.isEmpty
        ? progressPercentage
        : ((completedCount / updatedSubtasks.length) * 100).round();
    final nextStatus = nextPercent == 100
        ? TaskStatus.completed
        : nextPercent > 0
        ? TaskStatus.inProgress
        : TaskStatus.todo;

    return TaskDetail(
      id: id,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      scheduledDate: scheduledDate,
      status: nextStatus,
      isArchived: isArchived,
      progressPercentage: nextPercent,
      estimatedMinutes: estimatedMinutes,
      project: project,
      subtasks: updatedSubtasks,
      updatedAt: timestamp,
      completedAt: nextStatus == TaskStatus.completed
          ? completedAt ?? timestamp
          : null,
    );
  }

  TaskDetail withStatus(TaskStatus newStatus, {DateTime? now}) {
    final nextProgress = subtasks.isEmpty
        ? (newStatus == TaskStatus.completed ? 100 : 0)
        : computedProgressPercentage;
    return TaskDetail(
      id: id,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      scheduledDate: scheduledDate,
      status: newStatus,
      isArchived: isArchived,
      progressPercentage: nextProgress,
      estimatedMinutes: estimatedMinutes,
      project: project,
      subtasks: subtasks,
      updatedAt: (now ?? DateTime.now()).toUtc(),
      completedAt: newStatus == TaskStatus.completed
          ? completedAt ?? (now ?? DateTime.now()).toUtc()
          : null,
    );
  }
}

class TaskProject {
  TaskProject.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String;
  final String id, name;
}
