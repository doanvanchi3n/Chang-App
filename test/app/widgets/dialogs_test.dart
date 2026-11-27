import 'package:chang_app/app/widgets/confirmation_dialog.dart';
import 'package:chang_app/app/widgets/deadline_picker.dart';
import 'package:chang_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final text = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([text.load(), icons.load()]);
  });
  Future<void> pump(
    WidgetTester tester,
    Widget Function(BuildContext) builder,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(size.width == 320 ? 1.5 : 1),
          ),
          child: child!,
        ),
        home: Scaffold(body: Builder(builder: builder)),
      ),
    );
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(320, 700),
    const Size(800, 360),
    const Size(390, 844),
  ]) {
    testWidgets('date-only picker keeps full title and returns date at $size', (
      tester,
    ) async {
      DateTime? result;
      await pump(
        tester,
        (context) => TextButton(
          onPressed: () async {
            result = await showChangDate(
              context,
              now: DateTime(2026, 11, 27),
              title: 'Hạn hoàn thành dự án',
            );
          },
          child: const Text('Chọn hạn'),
        ),
        size,
      );
      await tap(tester, find.text('Chọn hạn'));
      expect(find.text('Hạn hoàn thành dự án'), findsOneWidget);
      expect(find.text('NGÀY ĐÃ CHỌN'), findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);
      if (const bool.fromEnvironment('CAPTURE_DIALOG_UI')) {
        if (size.width == 390) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(Uri.file('/tmp/chang-date-picker.png')),
          );
        }
      }
      await tap(tester, find.text('Ngày mai'));
      await tap(tester, find.text('Chọn ngày'));
      expect(result, DateTime(2026, 11, 28));
      expect(find.byType(TimePickerDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'confirmation cancels, confirms and wraps long content at $size',
      (tester) async {
        bool? result;
        await pump(
          tester,
          (context) => TextButton(
            onPressed: () async {
              result = await showChangConfirmation(
                context,
                title: 'Rời form tạo việc?',
                message: 'Các thông tin chưa lưu sẽ bị bỏ. Công việc đã lưu trước đó vẫn được giữ nguyên.',
                cancelLabel: 'Ở lại',
                confirmLabel: 'Rời form',
              );
            },
            child: const Text('Mở xác nhận'),
          ),
          size,
        );
        await tap(tester, find.text('Mở xác nhận'));
        if (const bool.fromEnvironment('CAPTURE_DIALOG_UI')) {
          if (size.width == 390) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(Uri.file('/tmp/chang-confirmation.png')),
            );
          }
        }
        await tap(tester, find.text('Ở lại'));
        expect(result, false);
        await tap(tester, find.text('Mở xác nhận'));
        await tap(tester, find.text('Rời form'));
        expect(result, true);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
