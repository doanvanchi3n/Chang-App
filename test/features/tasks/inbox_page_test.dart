import 'package:chang_app/app/app.dart';
import 'package:chang_app/features/home/presentation/providers/home_tasks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'onboarding_profile_v1': '{"has_completed_onboarding":true}',
    }),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: ChangApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('Tab Công việc mở Hộp việc M01 với quick add và mascot', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Hộp việc'), findsNothing);

    await tester.tap(find.text('Công việc'));
    await tester.pumpAndSettle();

    expect(find.text('Hộp việc'), findsOneWidget);
    expect(find.text('Ghi lại trước, chọn lúc làm sau.'), findsOneWidget);
    expect(
      find.text('Bạn quyết định việc nào cần làm hôm nay.'),
      findsOneWidget,
    );
    expect(find.text('Chưa lên kế hoạch · 3 việc'), findsOneWidget);
    expect(find.text('Đọc chương 3 cơ sở dữ liệu'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ghi lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ghi lại việc mới rồi lên kế hoạch hôm nay đưa việc sang Home', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Công việc'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('inbox-quick-add')),
      'Làm đề thi thử',
    );
    await tester.tap(find.byKey(const Key('inbox-quick-add-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Làm đề thi thử'), findsOneWidget);
    expect(find.text('Chưa lên kế hoạch · 4 việc'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inbox-schedule-today')));
    await tester.pumpAndSettle();

    expect(find.text('Việc ưu tiên'), findsOneWidget);
    expect(find.text('Đọc chương 3 cơ sở dữ liệu'), findsOneWidget);
    expect(find.text('Chuẩn bị câu hỏi cho buổi review'), findsOneWidget);
    expect(find.text('Làm đề thi thử'), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.text('Việc ưu tiên')),
    );
    final homeTitles = container
        .read(homeTasksProvider)
        .map((t) => t.title)
        .toList();
    expect(homeTitles, contains('Đọc chương 3 cơ sở dữ liệu'));
    expect(homeTitles, contains('Chuẩn bị câu hỏi cho buổi review'));
  });
}
