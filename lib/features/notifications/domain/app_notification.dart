enum NotificationKind {
  task('REMINDER_TASK', 'Công việc'),
  schedule('SCHEDULE_CONFLICT', 'Lịch học'),
  milestone('MILESTONE', 'Cột mốc'),
  assistant('AI_PLAN', 'Gợi ý AI'),
  system('SYSTEM', 'Hệ thống');

  const NotificationKind(this.dbValue, this.label);
  final String dbValue, label;
  static NotificationKind fromDb(String? value) =>
      values.where((kind) => kind.dbValue == value).firstOrNull ?? system;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.isRead,
    required this.createdAt,
    this.scheduledAt,
    this.referenceId,
  });
  final String id, title, body;
  final String? referenceId;
  final NotificationKind kind;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  DateTime get deliveredAt => scheduledAt ?? createdAt;
  String? get taskId => kind == NotificationKind.task ? referenceId : null;
  factory AppNotification.fromJson(Map<String, dynamic> row) => AppNotification(
    id: row['id'] as String,
    title: row['title'] as String,
    body: row['body'] as String,
    kind: NotificationKind.fromDb(row['type'] as String?),
    isRead: row['is_read'] == true,
    referenceId: row['reference_id'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
    scheduledAt: DateTime.tryParse(row['scheduled_at'] as String? ?? ''),
  );
}
