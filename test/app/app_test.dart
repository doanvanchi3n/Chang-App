import 'package:chang_app/app/app.dart';
import 'package:chang_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Trang chủ hiển thị tiếng Việt độc lập với backend', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ChangApp()));
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.name), findsOneWidget);
    expect(find.text(AppConstants.tagline), findsOneWidget);
    expect(
      Localizations.localeOf(tester.element(find.byType(Scaffold))),
      const Locale('vi'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Trang khởi động không tràn trên màn hình nhỏ khi tăng cỡ chữ', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const ProviderScope(child: ChangApp()));
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.tagline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
