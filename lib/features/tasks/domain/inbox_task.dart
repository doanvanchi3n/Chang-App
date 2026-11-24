class InboxTask {
  const InboxTask({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;

  factory InboxTask.fromJson(Map<String, dynamic> json) => InboxTask(
    id: json['id'] as String,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
