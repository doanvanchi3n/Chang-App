import 'package:chang_app/app/app.dart';
import 'package:chang_app/features/onboarding/data/onboarding_store.dart';
import 'package:chang_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Giới thiệu linh vật 1,2 giây rồi mở Home, không hỏi thiết lập', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: ChangApp()));
    await tester.pump();
    await tester.pump();

    expect(find.text('Từng bước nhỏ, tiến xa hơn.'), findsOneWidget);
    expect(find.text('Đang kiểm tra đăng nhập...'), findsOneWidget);
    expect(find.text('Chọn mục tiêu học tập'), findsNothing);
    expect(find.text('Chọn định hướng học tập'), findsNothing);
    expect(find.text('Khung giờ học'), findsNothing);
    expect(find.text('Khung giờ vàng'), findsNothing);
    expect(find.textContaining('phút mỗi ngày'), findsNothing);
    expect(find.textContaining('thời lượng cam kết'), findsNothing);
    expect(find.byType(OnboardingPage), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1199));
    expect(find.byType(OnboardingPage), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 17));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Lên kế hoạch · Tập trung · Nhìn lại'), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lỗi lưu onboarding hiện thử lại và hoàn tất sau đó', (
    tester,
  ) async {
    final store = _FailOnceStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingStoreProvider.overrideWithValue(store)],
        child: const ChangApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1216));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Chưa lưu được thiết lập. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(await store.isCompleted(), isFalse);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Lên kế hoạch · Tập trung · Nhìn lại'), findsOneWidget);
    expect(await store.isCompleted(), isTrue);
    expect(tester.takeException(), isNull);
  });
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
