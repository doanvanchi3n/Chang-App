import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/task_detail.dart';
import 'inbox_repository.dart';

class TaskDetailRepository {
  TaskDetailRepository(this._client, this._inbox);

  final SupabaseClient _client;
  final InboxRepository _inbox;

  static const _selectColumns =
      'id,title,description,priority,due_date,scheduled_date,status,'
      'is_archived,progress_percentage,estimated_minutes,updated_at,'
      'projects(id,name,color_hex),'
      'subtasks(id,task_id,title,order_index,estimated_minutes,is_completed,completed_at)';

  Future<TaskDetail?> fetchById(String taskId) async {
    final trimmedId = taskId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('Mã công việc không hợp lệ.');
    }
    final userId = await _inbox.ensureUserId();
    final row = await _client
        .from('tasks')
        .select(_selectColumns)
        .eq('id', trimmedId)
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return TaskDetail.fromJson(row);
  }

  Future<TaskDetail> toggleSubtask({
    required String taskId,
    required String subtaskId,
    required bool isCompleted,
  }) async {
    await _inbox.ensureUserId();
    await _client
        .from('subtasks')
        .update({
          'is_completed': isCompleted,
          'completed_at': isCompleted
              ? DateTime.now().toUtc().toIso8601String()
              : null,
        })
        .eq('id', subtaskId)
        .eq('task_id', taskId)
        .select('id')
        .single();

    final refreshed = await fetchById(taskId);
    if (refreshed == null) {
      throw StateError('Không tìm thấy công việc sau khi cập nhật bước nhỏ.');
    }
    return refreshed;
  }

  Future<TaskDetail> addSubtask({
    required String taskId,
    required String title,
    required int orderIndex,
    int estimatedMinutes = 25,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty ||
        trimmedTitle.runes.length > TaskDetail.maxSubtaskTitleLength) {
      throw ArgumentError('Tên bước nhỏ phải có từ 1 đến 200 ký tự.');
    }
    if (orderIndex < 1 || orderIndex > TaskDetail.maxSubtasks) {
      throw ArgumentError('Mỗi công việc chỉ được phép có tối đa 5 bước nhỏ.');
    }
    if (estimatedMinutes < TaskDetail.minEstimatedMinutes ||
        estimatedMinutes > TaskDetail.maxEstimatedMinutes) {
      throw ArgumentError('Thời lượng dự kiến phải từ 1 đến 1440 phút.');
    }

    await _inbox.ensureUserId();
    await _client
        .from('subtasks')
        .insert({
          'task_id': taskId,
          'title': trimmedTitle,
          'order_index': orderIndex,
          'estimated_minutes': estimatedMinutes,
          'is_completed': false,
        })
        .select('id')
        .single();

    final refreshed = await fetchById(taskId);
    if (refreshed == null) {
      throw StateError('Không tìm thấy công việc sau khi thêm bước nhỏ.');
    }
    return refreshed;
  }

  Future<TaskDetail> setTaskStatus({
    required String taskId,
    required TaskStatus status,
    required bool hasSubtasks,
  }) async {
    final userId = await _inbox.ensureUserId();
    final payload = <String, dynamic>{
      'status': status.dbValue,
      if (!hasSubtasks)
        'progress_percentage': status == TaskStatus.completed ? 100 : 0,
    };
    await _client
        .from('tasks')
        .update(payload)
        .eq('id', taskId)
        .eq('user_id', userId)
        .select('id')
        .single();

    final refreshed = await fetchById(taskId);
    if (refreshed == null) {
      throw StateError('Không tìm thấy công việc sau khi cập nhật trạng thái.');
    }
    return refreshed;
  }
}
