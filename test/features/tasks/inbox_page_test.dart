import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:chang_app/features/tasks/domain/inbox_task.dart';
import 'package:chang_app/features/tasks/presentation/inbox_page.dart';
import 'package:chang_app/features/tasks/presentation/inbox_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Repository extends InboxRepository {
  _Repository(super.client);
  final items = <InboxTask>[];
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<List<InboxTask>> fetch() async {
    if (failRead) throw StateError('Read failed');
    return List.of(items);
  }

  @override
  Future<InboxTask> add(String title) async {
    if (failWrite) throw StateError('Write failed');
    final task = InboxTask(
      id: 'saved-id',
      title: title.trim(),
      createdAt: DateTime(2026, 11, 23),
    );
    items.add(task);
    return task;
  }
}

void main() {
  late SupabaseClient client;
  late _Repository repository;
  setUp(() {
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    repository = _Repository(client);
  });
  tearDown(() => client.dispose());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [inboxRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: InboxPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Hộp việc rỗng, thêm thành công mới hiển thị bản ghi', (
    tester,
  ) async {
    await open(tester);
    expect(find.textContaining('Hộp việc đang trống'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '  Học chương mới  ');
    await tester.tap(find.text('Ghi lại'));
    await tester.pumpAndSettle();
    expect(find.text('Học chương mới'), findsOneWidget);
    expect(find.textContaining('Hộp việc đang trống'), findsNothing);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('Lỗi ghi giữ nội dung nhập và không giả vờ thêm thành công', (
    tester,
  ) async {
    repository.failWrite = true;
    await open(tester);
    await tester.enterText(find.byType(TextFormField), 'Giữ lại ý tưởng');
    await tester.tap(find.text('Ghi lại'));
    await tester.pumpAndSettle();
    expect(repository.items, isEmpty);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Giữ lại ý tưởng',
    );
    expect(
      find.textContaining('Chưa xác nhận được việc đã lưu'),
      findsOneWidget,
    );
  });

  testWidgets('Lỗi đọc hiện thử lại, không hiển thị danh sách mẫu', (
    tester,
  ) async {
    repository.failRead = true;
    await open(tester);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('Hộp việc đang trống'), findsNothing);
    repository.failRead = false;
    await tester.ensureVisible(find.text('Thử lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('Hộp việc đang trống'), findsOneWidget);
  });
}
