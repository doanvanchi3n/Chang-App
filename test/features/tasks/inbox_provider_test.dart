import 'package:chang_app/features/tasks/domain/entities/inbox_task.dart';
import 'package:chang_app/features/tasks/presentation/providers/inbox_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  List<InboxTask> tasks() => container.read(inboxTasksProvider);
  InboxTasksNotifier notifier() => container.read(inboxTasksProvider.notifier);

  test('mặc định có 3 việc chưa lên lịch, 2 việc đã chọn', () {
    expect(tasks(), hasLength(3));
    expect(tasks().where((t) => t.isSelected), hasLength(2));
    expect(tasks().every((t) => t.scheduledDate == null), isTrue);
  });

  test('quickAdd thêm việc mới lên đầu, không chọn sẵn', () {
    notifier().quickAdd('  Ôn toán rời rạc  ');

    expect(tasks(), hasLength(4));
    expect(tasks().first.title, 'Ôn toán rời rạc');
    expect(tasks().first.isSelected, isFalse);
    expect(tasks().first.recordedDateText, 'Ghi lại hôm nay');
    expect(tasks().first.scheduledDate, isNull);
  });

  test('quickAdd bỏ qua chuỗi trống', () {
    notifier().quickAdd('   ');
    expect(tasks(), hasLength(3));
  });

  test('toggleSelect đảo trạng thái một việc', () {
    notifier().toggleSelect('inbox-3');
    expect(tasks().singleWhere((t) => t.id == 'inbox-3').isSelected, isTrue);
    notifier().toggleSelect('inbox-3');
    expect(tasks().singleWhere((t) => t.id == 'inbox-3').isSelected, isFalse);
  });

  test('toggleSelectAll bỏ chọn hết rồi chọn lại hết', () {
    notifier().toggleSelectAll();
    expect(tasks().every((t) => t.isSelected), isFalse);
    notifier().toggleSelectAll();
    expect(tasks().every((t) => t.isSelected), isTrue);
  });

  test('updateTaskTitle đổi tên, bỏ qua tên trống', () {
    notifier().updateTaskTitle('inbox-1', '  Đọc chương 4  ');
    expect(tasks().singleWhere((t) => t.id == 'inbox-1').title, 'Đọc chương 4');
    notifier().updateTaskTitle('inbox-1', '   ');
    expect(tasks().singleWhere((t) => t.id == 'inbox-1').title, 'Đọc chương 4');
  });

  test('deleteTask gỡ việc khỏi hộp việc', () {
    notifier().deleteTask('inbox-2');
    expect(tasks().map((t) => t.id), ['inbox-1', 'inbox-3']);
  });

  test('scheduleSelectedForToday trả việc đã chọn và xóa khỏi inbox', () {
    final scheduled = notifier().scheduleSelectedForToday();

    expect(scheduled.map((t) => t.id), ['inbox-1', 'inbox-2']);
    expect(tasks(), hasLength(1));
    expect(tasks().single.id, 'inbox-3');
  });
}
