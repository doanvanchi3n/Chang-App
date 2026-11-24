import 'package:chang_app/app/widgets/choice_sheet.dart';
import 'package:chang_app/app/widgets/deadline_picker.dart';
import 'package:chang_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(Widget child, {double scale = 1}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('vi'),
  supportedLocales: const [Locale('vi')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void main() {
  for (final width in [320.0, 800.0]) {
    testWidgets('calendar keeps a complete header at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showChangDeadline(context, now: DateTime(2026, 11, 24)),
              child: const Text('Lịch'),
            ),
          ),
          scale: width == 320 ? 1.5 : 1,
        ),
      );
      await tester.tap(find.text('Lịch'));
      await tester.pumpAndSettle();
      expect(find.text('NGÀY ĐÃ CHỌN'), findsOneWidget);
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      await tester.ensureVisible(find.text('Tiếp tục · Chọn giờ'));
      await tester.tap(find.text('Tiếp tục · Chọn giờ'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Hủy').last);
      await tester.pumpAndSettle();
    });
  }

  testWidgets('choice sheet handles long names and returns the chosen step', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? result;
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showChangChoices(
                context,
                title: 'Chọn bước',
                subtitle: 'Tập trung vào một bước nhỏ.',
                selected: '',
                choices: const [
                  ChangChoice('', 'Toàn bộ công việc'),
                  ChangChoice(
                    'step-1',
                    'Bước 1 · Đọc tài liệu rất dài và ghi lại những ý chính cần nhớ',
                    subtitle: '25 phút dự kiến',
                  ),
                ],
              );
            },
            child: const Text('Chọn'),
          ),
        ),
        scale: 1.5,
      ),
    );
    await tester.tap(find.text('Chọn'));
    await tester.pumpAndSettle();
    final label = find.text(
      'Bước 1 · Đọc tài liệu rất dài và ghi lại những ý chính cần nhớ',
    );
    await tester.ensureVisible(label);
    await tester.pumpAndSettle();
    await tester.tap(label);
    await tester.pumpAndSettle();
    expect(result, 'step-1');
    expect(tester.takeException(), isNull);
  });
}
