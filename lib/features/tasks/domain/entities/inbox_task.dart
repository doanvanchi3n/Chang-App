class InboxTask {
  InboxTask({
    required this.id,
    required this.title,
    required this.recordedDateText,
    this.isSelected = false,
    this.scheduledDate,
    this.category = 'Học tập',
    this.estimatedMinutes = 25,
  });

  final String id;
  final String title;
  final String recordedDateText;
  final bool isSelected;
  final DateTime? scheduledDate;
  final String category;
  final int estimatedMinutes;

  InboxTask copyWith({
    String? id,
    String? title,
    String? recordedDateText,
    bool? isSelected,
    DateTime? scheduledDate,
    String? category,
    int? estimatedMinutes,
  }) {
    return InboxTask(
      id: id ?? this.id,
      title: title ?? this.title,
      recordedDateText: recordedDateText ?? this.recordedDateText,
      isSelected: isSelected ?? this.isSelected,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      category: category ?? this.category,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }
}
