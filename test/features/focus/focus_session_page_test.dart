import 'package:chang_app/features/focus/application/focus_controller.dart';
import 'package:chang_app/features/focus/data/audio/audio_library.dart';
import 'package:chang_app/features/focus/data/audio/local_sound.dart';
import 'package:chang_app/features/focus/domain/focus_session.dart';
import 'package:chang_app/features/focus/presentation/focus_host.dart';
import 'package:chang_app/features/focus/presentation/focus_session_page.dart';
import 'package:chang_app/features/home/data/dashboard_provider.dart';
import 'package:chang_app/features/tasks/data/task_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

DashboardData _sampleDashboard() => const DashboardData(
  name: 'Chiến',
  tasks: [],
  todayCount: 2,
  todayDone: 1,
  inboxCount: 1,
  overdueCount: 0,
  nextEvent: null,
  weekSeconds: 4500,
  weekTargetMinutes: 420,
  completedSessions: 3,
);

Map<String, dynamic> _sampleSessionRaw({
  String status = 'IN_PROGRESS',
  String sound = 'SILENT',
  int elapsedMs = 22000,
  int targetSeconds = 1500,
}) => {
  'id': 'session-28',
  'task_id': 'task-13',
  'subtask_id': 'step-3',
  'task_title': 'Phác thảo luồng đăng ký',
  'step_title': 'Vẽ luồng đăng ký',
  'step_order': 3,
  'project_name': 'UI/UX',
  'status': status,
  'target_duration_seconds': targetSeconds,
  'elapsed_milliseconds': elapsedMs,
  'revision': 1,
  'ambient_sound': sound,
  'running_since': status == 'IN_PROGRESS' ? '2026-11-26T10:00:00Z' : null,
  'server_now': '2026-11-26T10:00:00Z',
};

class _FakeFocusController extends FocusController {
  _FakeFocusController({required this.initialState});

  final FocusState initialState;
  final int fakeElapsedMs = 22000;
  final List<String> commands = [];
  String? lastSound;

  @override
  FocusState build() => initialState;

  @override
  int get elapsedMs => fakeElapsedMs;

  @override
  int get elapsedSeconds => fakeElapsedMs ~/ 1000;

  @override
  int get remainingSeconds =>
      ((state.session?.targetSeconds ?? 0) - elapsedSeconds).clamp(0, 10800);

  @override
  Future<void> restore() async {}

  @override
  Future<void> reconcile() async {
    commands.add('RECONCILE');
  }

  @override
  Future<bool> command(
    String action, {
    String? sound,
    bool? complete,
    String? note,
  }) async {
    commands.add(action);
    final current = state.session;
    if (current == null) return false;
    final nextRaw = Map<String, dynamic>.from(current.raw);
    switch (action) {
      case 'PAUSE':
        nextRaw['status'] = 'PAUSED';
        nextRaw['running_since'] = null;
      case 'RESUME':
        nextRaw['status'] = 'IN_PROGRESS';
        nextRaw['running_since'] = '2026-11-26T10:00:00Z';
      case 'FINISH':
        nextRaw['status'] = 'AWAITING_REVIEW';
        nextRaw['running_since'] = null;
      case 'SOUND':
        lastSound = sound;
        nextRaw['ambient_sound'] = sound ?? 'SILENT';
    }
    state = state.copy(session: FocusSession(nextRaw));
    return true;
  }
}

class _FakeAudioLibrary extends AudioLibrary {
  @override
  Future<List<LocalSound>> build() async => const [];
}

void main() {
  Future<void> setViewport(
    WidgetTester tester,
    Size size, {
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> pumpFocusPage(
    WidgetTester tester, {
    required Size size,
    required _FakeFocusController controller,
    double textScale = 1.0,
  }) async {
    await setViewport(tester, size, textScale: textScale);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          focusControllerProvider.overrideWith(() => controller),
          audioLibraryProvider.overrideWith(_FakeAudioLibrary.new),
          dashboardProvider.overrideWith((ref) async => _sampleDashboard()),
          taskDetailProvider.overrideWith((ref, taskId) async => null),
        ],
        child: const MaterialApp(home: FocusSessionPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'W28 (Desktop 1280px) hiển thị full-width desktop layout, nút nằm ngang và đúng thiết kế',
    (tester) async {
      final controller = _FakeFocusController(
        initialState: FocusState(
          session: FocusSession(_sampleSessionRaw()),
          expanded: true,
        ),
      );
      await pumpFocusPage(
        tester,
        size: const Size(1280, 900),
        controller: controller,
      );

      // Không bị bó cứng về 560dp mobile trên màn hình desktop.
      expect(tester.getSize(find.byType(Scaffold)).width, 1280);
      expect(find.text('chặng'), findsOneWidget);
      expect(find.text('Chế độ tập trung'), findsOneWidget);
      expect(find.text('Thu gọn phiên'), findsOneWidget);
      expect(find.text('UI/UX'), findsOneWidget);
      expect(find.text('Phác thảo luồng đăng ký'), findsOneWidget);
      expect(find.text('Bước 3 · Vẽ luồng đăng ký'), findsOneWidget);
      expect(find.text('Phiên học · 25 phút'), findsOneWidget);
      expect(find.text('24:38'), findsOneWidget);
      expect(
        find.text('Đã trôi qua 22 giây · Còn lại 24:38'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('mascot-active')), findsOneWidget);
      expect(find.text('Cứ làm từng bước thôi.'), findsOneWidget);

      // Trên desktop, 2 nút hành động đặt ngang hàng.
      expect(
        find.byKey(const ValueKey('focus-desktop-actions-row')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('focus-mobile-actions-column')),
        findsNothing,
      );
      expect(find.text('Âm thanh'), findsOneWidget);
      expect(find.text('Tắt'), findsOneWidget);
      expect(
        find.text('Kết thúc phiên không tự đánh dấu công việc hoàn thành.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'M28 (Mobile 390px) hiển thị header mobile và nút xếp dọc theo thiết kế',
    (tester) async {
      final controller = _FakeFocusController(
        initialState: FocusState(
          session: FocusSession(_sampleSessionRaw()),
          expanded: true,
        ),
      );
      await pumpFocusPage(
        tester,
        size: const Size(390, 844),
        controller: controller,
      );

      expect(find.text('Thu gọn'), findsOneWidget);
      expect(find.text('Tập trung'), findsOneWidget);
      expect(find.text('Chế độ tập trung'), findsNothing);
      expect(find.text('24:38'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('focus-mobile-actions-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('focus-desktop-actions-row')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tạm dừng đổi linh vật sang nghỉ ngơi, hiển thị badge và cho phép tiếp tục học',
    (tester) async {
      final controller = _FakeFocusController(
        initialState: FocusState(
          session: FocusSession(_sampleSessionRaw()),
          expanded: true,
        ),
      );
      await pumpFocusPage(
        tester,
        size: const Size(1280, 900),
        controller: controller,
      );

      await tester.tap(find.byKey(const ValueKey('focus-pause-resume-button')));
      await tester.pumpAndSettle();

      expect(controller.commands, ['PAUSE']);
      expect(find.text('Đang tạm dừng'), findsOneWidget);
      expect(find.text('Tiếp tục học'), findsOneWidget);
      expect(find.byKey(const ValueKey('mascot-paused')), findsOneWidget);
      expect(
        find.textContaining('Thời gian tạm dừng không được tính.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('focus-pause-resume-button')));
      await tester.pumpAndSettle();

      expect(controller.commands, ['PAUSE', 'RESUME']);
      expect(find.text('Tạm dừng'), findsOneWidget);
      expect(find.byKey(const ValueKey('mascot-active')), findsOneWidget);
    },
  );

  testWidgets(
    'Bật/tắt âm thanh inline gửi lệnh SOUND và nút Kết thúc phiên hỏi xác nhận',
    (tester) async {
      final controller = _FakeFocusController(
        initialState: FocusState(
          session: FocusSession(_sampleSessionRaw()),
          expanded: true,
        ),
      );
      await pumpFocusPage(
        tester,
        size: const Size(1280, 900),
        controller: controller,
      );

      await tester.tap(find.byKey(const ValueKey('focus-sound-switch')));
      await tester.pumpAndSettle();
      expect(controller.lastSound, 'WHITE_NOISE');
      expect(find.text('Nhiễu trắng'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('focus-finish-button')));
      await tester.pumpAndSettle();
      expect(find.text('Kết thúc phiên tại đây?'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục phiên'));
      await tester.pumpAndSettle();
      expect(controller.commands.contains('FINISH'), isFalse);

      await tester.tap(find.byKey(const ValueKey('focus-finish-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kết thúc'));
      await tester.pumpAndSettle();
      expect(controller.commands.contains('FINISH'), isTrue);
    },
  );

  testWidgets(
    'FocusHost hiển thị Floating PiP card trên Desktop (1280px) khi thu gọn',
    (tester) async {
      final desktopController = _FakeFocusController(
        initialState: FocusState(
          session: FocusSession(_sampleSessionRaw()),
          expanded: false,
        ),
      );
      await setViewport(tester, const Size(1280, 900));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            focusControllerProvider.overrideWith(() => desktopController),
          ],
          child: MaterialApp(
            builder: (context, child) => FocusHost(child: child!),
            home: const Scaffold(body: Center(child: Text('Màn hình chính'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('focus-desktop-pip')), findsOneWidget);
      expect(find.byKey(const ValueKey('focus-mobile-mini-bar')), findsNothing);
      expect(find.text('24:38'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('focus-pip-toggle-button')));
      await tester.pumpAndSettle();
      expect(desktopController.commands, ['PAUSE']);
    },
  );

  testWidgets(
    'FocusHost hiển thị Mini bar gọn ở đáy màn hình trên Mobile (390px) khi thu gọn',
    (tester) async {
      final mobileController = _FakeFocusController(
        initialState: FocusState(
          session: FocusSession(_sampleSessionRaw()),
          expanded: false,
        ),
      );
      await setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            focusControllerProvider.overrideWith(() => mobileController),
          ],
          child: MaterialApp(
            builder: (context, child) => FocusHost(child: child!),
            home: const Scaffold(body: Center(child: Text('Màn hình chính'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('focus-mobile-mini-bar')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('focus-desktop-pip')), findsNothing);
      expect(find.text('Đang học · 24:38'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('focus-mini-toggle-button')));
      await tester.pumpAndSettle();
      expect(mobileController.commands, ['PAUSE']);
    },
  );

  testWidgets('Màn hình nhỏ 320px với cỡ chữ 2.0x không bị tràn giao diện', (
    tester,
  ) async {
    final controller = _FakeFocusController(
      initialState: FocusState(
        session: FocusSession(_sampleSessionRaw()),
        expanded: true,
      ),
    );
    await pumpFocusPage(
      tester,
      size: const Size(320, 568),
      controller: controller,
      textScale: 2.0,
    );

    expect(find.text('24:38'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'W30 (Desktop 1920x1080) hiển thị bố cục tổng kết desktop, radio ngang, nút ngang và linh vật PNG',
    (tester) async {
      final controller = _FakeFocusController(
        initialState: FocusState(
          session: FocusSession(
            _sampleSessionRaw(
              status: 'AWAITING_REVIEW',
              elapsedMs: 1500000,
              targetSeconds: 1500,
            ),
          ),
          expanded: true,
        ),
      );
      await pumpFocusPage(
        tester,
        size: const Size(1920, 1080),
        controller: controller,
      );

      expect(tester.getSize(find.byType(Scaffold)).width, 1920);
      expect(find.text('Tổng kết phiên học'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(
        find.byKey(const ValueKey('focus-summary-desktop-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('focus-summary-mobile-layout')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('summary-desktop-radios')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('summary-mobile-radios')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('summary-desktop-actions-row')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('summary-mobile-actions-column')),
        findsNothing,
      );

      final mascot = tester.widget<Image>(
        find.byKey(const ValueKey('mascot-summary')),
      );
      expect(mascot.gaplessPlayback, isTrue);

      await tester.tap(find.text('Đã hoàn thành bước 3'));
      await tester.pumpAndSettle();
      expect(controller.reviewComplete, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'M30 (Mobile 390x844) hiển thị bố cục tổng kết mobile xếp dọc và linh vật PNG',
    (tester) async {
      final controller = _FakeFocusController(
        initialState: FocusState(
          session: FocusSession(
            _sampleSessionRaw(
              status: 'AWAITING_REVIEW',
              elapsedMs: 120000,
              targetSeconds: 1500,
            ),
          ),
          expanded: true,
        ),
      );
      await pumpFocusPage(
        tester,
        size: const Size(390, 844),
        controller: controller,
      );

      expect(
        find.byKey(const ValueKey('focus-summary-mobile-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('focus-summary-desktop-layout')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('summary-mobile-radios')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('summary-desktop-radios')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('summary-mobile-actions-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('summary-desktop-actions-row')),
        findsNothing,
      );
      expect(
        tester.widget<Image>(find.byKey(const ValueKey('mascot-summary'))),
        isA<Image>(),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
