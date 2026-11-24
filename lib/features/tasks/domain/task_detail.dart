class TaskStep {
  TaskStep.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      title = json['title'] as String,
      order = json['order_index'] as int,
      minutes = json['estimated_minutes'] as int,
      completed = json['is_completed'] as bool;
  final String id;
  final String title;
  final int order;
  final int minutes;
  final bool completed;
}

class TaskDetail {
  TaskDetail.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      title = json['title'] as String,
      description = json['description'] as String?,
      project = (json['projects'] as Map<String, dynamic>?)?['name'] as String?,
      dueDate = DateTime.tryParse(json['due_date'] as String? ?? '')?.toLocal(),
      priority = json['priority'] as String,
      status = json['status'] as String,
      archived = json['is_archived'] as bool,
      minutes = json['estimated_minutes'] as int?,
      steps =
          (json['subtasks'] as List)
              .map((s) => TaskStep.fromJson(s as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));
  final String id, title, priority, status;
  final String? description, project;
  final DateTime? dueDate;
  final int? minutes;
  final bool archived;
  final List<TaskStep> steps;
  int get completedSteps => steps.where((s) => s.completed).length;
}

class TaskProject {
  TaskProject.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String;
  final String id, name;
}
