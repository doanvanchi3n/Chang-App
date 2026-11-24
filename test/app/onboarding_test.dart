import 'dart:async';

import 'package:chang_app/app/app.dart';
import 'package:chang_app/features/home/presentation/pages/home_page.dart';
import 'package:chang_app/features/onboarding/data/onboarding_store.dart';
import 'package:chang_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('M06 tự vào Home sau intro và không hiển thị lại khi mở app', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ChangApp()));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(await OnboardingStore().isCompleted(), isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const ProviderScope(child: ChangApp()));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('M06 có nội dung mới và chỉ tự lưu sau animation 1,2 giây', (
    tester,
  ) async {
    final store = _ControlledStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: OnboardingPage()),
      ),
    );
    await tester.pump();
    expect(find.text('Chặng nhỏ,\ntiến bộ mỗi ngày.'), findsOneWidget);
    expect(find.text('Lên kế hoạch tự học theo nhịp của bạn.'), findsOneWidget);
    expect(find.text('Lên kế hoạch'), findsOneWidget);
    expect(find.text('Tập trung'), findsOneWidget);
    expect(find.text('Nhìn lại'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);
    expect(find.text('Đang kiểm tra đăng nhập...'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1199));
    expect(store.calls, 0);
    await tester.pump(const Duration(milliseconds: 17));
    expect(store.calls, 1);
    store.pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final label in ['Bắt đầu', 'Bỏ qua']) {
    testWidgets('$label lưu một lần dù animation kết thúc khi đang lưu', (
      tester,
    ) async {
      final store = _ControlledStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [onboardingStoreProvider.overrideWithValue(store)],
          child: const MaterialApp(home: OnboardingPage()),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.text(label));
      await tester.pump();
      await tester.tap(find.text(label));
      await tester.pump();
      expect(store.calls, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.pump(const Duration(milliseconds: 1300));
      expect(store.calls, 1);
      store.pending.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Lỗi lưu giữ M06, chỉ thử lại khi người dùng yêu cầu', (
    tester,
  ) async {
    final store = _FailOnceStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingStoreProvider.overrideWithValue(store)],
        child: const ChangApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(await store.isCompleted(), isFalse);
    await tester.ensureVisible(find.text('Thử lại'));
    await tester.pump();
    expect(
      find.text('Chưa lưu được thiết lập. Vui lòng thử lại.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(await store.isCompleted(), isTrue);
  });

  testWidgets('Xem lại M06 giữ màn hình và nút Bắt đầu quay về trang trước', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OnboardingPage(autoForward: false),
                  ),
                ),
                child: const Text('Xem lại'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Xem lại'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(await OnboardingStore().isCompleted(), isFalse);
    await tester.ensureVisible(find.text('Bắt đầu'));
    await tester.pump();
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(find.text('Xem lại'), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(await OnboardingStore().isCompleted(), isFalse);
  });

  testWidgets('M06 cuộn được ở 320px khi tăng chữ gấp đôi', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingPage(autoForward: false)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Giảm chuyển động hoàn tất intro mà không chờ 1,2 giây', (
    tester,
  ) async {
    final store = _ControlledStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: OnboardingPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(store.calls, 1);
    store.pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _ControlledStore extends OnboardingStore {
  final pending = Completer<void>();
  int calls = 0;

  @override
  Future<void> complete() {
    calls++;
    return pending.future;
  }
}

class _FailOnceStore extends OnboardingStore {
  bool fail = true;

  @override
  Future<void> complete() async {
    if (fail) {
      fail = false;
      throw StateError('Disk unavailable');
    }
    return super.complete();
  }
}
