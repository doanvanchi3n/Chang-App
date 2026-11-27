import '../../tasks/domain/task_detail.dart';

const projectColors = {
  '#006BFF': 'Xanh dương',
  '#FFC83D': 'Vàng',
  '#FF8066': 'Cam đào',
  '#28B463': 'Xanh lá',
  '#345D83': 'Xanh trầm',
  '#E78AC3': 'Hồng',
};
const projectIcons = {'folder': 'Thư mục', 'school': 'Học tập', 'book': 'Sách'};

class StudyProject {
  const StudyProject({
    required this.id,
    required this.name,
    this.description,
    this.deadline,
    this.colorHex = '#006BFF',
    this.iconName = 'folder',
    this.status = 'ACTIVE',
  });
  final String id, name, colorHex, iconName, status;
  final String? description;
  final DateTime? deadline;
  factory StudyProject.fromJson(Map<String, dynamic> json) => StudyProject(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    deadline: DateTime.tryParse(json['deadline'] as String? ?? ''),
    colorHex: json['color_hex'] as String? ?? '#006BFF',
    iconName: json['icon_name'] as String? ?? 'folder',
    status: json['status'] as String? ?? 'ACTIVE',
  );
}

class ProjectProgress {
  ProjectProgress(String projectId, Iterable<TaskDetail> allTasks)
    : tasks = allTasks
          .where((t) => t.project?.id == projectId && !t.isArchived)
          .toList();
  final List<TaskDetail> tasks;
  int get total => tasks.length;
  int get completed =>
      tasks.where((t) => t.status == TaskStatus.completed).length;
  int get percent => total == 0 ? 0 : (completed * 100 / total).round();
  String get label => total == 0
      ? 'Chưa có công việc'
      : completed == total
      ? 'Đã hoàn thành'
      : 'Đang thực hiện';
}
