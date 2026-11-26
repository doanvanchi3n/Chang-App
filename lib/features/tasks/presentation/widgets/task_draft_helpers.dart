import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../home/data/dashboard_provider.dart';
import '../../data/task_management_repository.dart';
import '../../data/task_repository.dart';
import '../inbox_provider.dart';

Future<bool> confirmDiscardTaskDraft(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ thay đổi chưa lưu?'),
        content: const Text('Dữ liệu đã lưu được giữ nguyên.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục sửa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    ) ??
    false;

void invalidateTaskViews(WidgetRef ref, String id) {
  ref.invalidate(taskDetailProvider(id));
  ref.invalidate(taskListProvider);
  ref.invalidate(inboxProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(focusTaskChoicesProvider);
}

bool isDefiniteTaskRejection(Object e) =>
    e is PostgrestException &&
    [
      '40001',
      '22023',
      '42501',
      '23505',
      '22P02',
      '40P01',
      'PGRST202',
      '42883',
      '42703',
    ].contains(e.code);
String taskSaveError(Object error) {
  if (error is PostgrestException) {
    if (['PGRST202', '42883', '42703'].contains(error.code)) {
      return 'Máy chủ chưa được cập nhật cho tính năng này. Cần chạy file SQL FEAT-07, 08, 09 trong Supabase trước khi lưu.';
    }
    if (error.code == '40P01') {
      return 'Công việc đang được cập nhật. Vui lòng thử lưu lại.';
    }
    if (error.code == '40001') {
      return 'Công việc đã thay đổi ở nơi khác. Bản nháp của bạn vẫn được giữ; tải dữ liệu mới trước khi sửa tiếp.';
    }
    if (error.code == '42501') {
      return 'Công việc không còn khả dụng để chỉnh sửa.';
    }
    if (error.code == '22023' && error.message.contains('focus session')) {
      return 'Hãy kết thúc và lưu phiên học đang mở trước khi xóa công việc hoặc bước đang học.';
    }
    if (isDefiniteTaskRejection(error)) {
      return 'Chưa lưu thay đổi. Kiểm tra tên, thời lượng, hạn hoàn thành và các bước.';
    }
  }
  return 'Chưa xác nhận được kết quả lưu. Thử lại sẽ dùng cùng yêu cầu để tránh ghi trùng.';
}

Future<bool> confirmLeavePendingTaskSave(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Kết quả lưu chưa được xác nhận'),
        content: const Text(
          'Thay đổi có thể đã được lưu trên máy chủ. Nếu rời màn hình, hãy tải lại công việc để kiểm tra trước khi sửa tiếp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Ở lại thử lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Rời màn hình'),
          ),
        ],
      ),
    ) ??
    false;
