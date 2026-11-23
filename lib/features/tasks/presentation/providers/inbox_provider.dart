import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/inbox_task.dart';

final inboxTasksProvider =
    NotifierProvider<InboxTasksNotifier, List<InboxTask>>(
      InboxTasksNotifier.new,
    );

class InboxTasksNotifier extends Notifier<List<InboxTask>> {
  @override
  List<InboxTask> build() {
    return [
      InboxTask(
        id: 'inbox-1',
        title: 'Đọc chương 3 cơ sở dữ liệu',
        recordedDateText: 'Ghi lại hôm nay',
        isSelected: true,
        category: 'Cơ sở dữ liệu',
        estimatedMinutes: 30,
      ),
      InboxTask(
        id: 'inbox-2',
        title: 'Chuẩn bị câu hỏi cho buổi review',
        recordedDateText: 'Ghi lại hôm nay',
        isSelected: true,
        category: 'Đồ án',
        estimatedMinutes: 20,
      ),
      InboxTask(
        id: 'inbox-3',
        title: 'Tìm tài liệu luyện nghe',
        recordedDateText: 'Ghi lại hôm qua',
        category: 'Tiếng Anh',
        estimatedMinutes: 25,
      ),
    ];
  }

  void quickAdd(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    state = [
      InboxTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: trimmed,
        recordedDateText: 'Ghi lại hôm nay',
      ),
      ...state,
    ];
  }

  void toggleSelect(String id) {
    state = [
      for (final task in state)
        if (task.id == id)
          task.copyWith(isSelected: !task.isSelected)
        else
          task,
    ];
  }

  void toggleSelectAll() {
    final areAllSelected = state.isNotEmpty && state.every((t) => t.isSelected);
    state = [
      for (final task in state) task.copyWith(isSelected: !areAllSelected),
    ];
  }

  void deleteTask(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  void updateTaskTitle(String id, String newTitle) {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;
    state = [
      for (final task in state)
        if (task.id == id) task.copyWith(title: trimmed) else task,
    ];
  }

  List<InboxTask> scheduleSelectedForToday() {
    final selected = state.where((t) => t.isSelected).toList();
    state = state.where((t) => !t.isSelected).toList();
    return selected;
  }
}
