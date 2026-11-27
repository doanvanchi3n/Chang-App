import 'package:chang_app/features/home/data/dashboard_provider.dart';
import 'package:chang_app/features/home/presentation/pages/home_page.dart';
import 'package:chang_app/features/notifications/data/notification_repository.dart';
import 'package:chang_app/features/notifications/domain/app_notification.dart';
import 'package:chang_app/features/notifications/presentation/notification_bell.dart';
import 'package:chang_app/features/notifications/presentation/notifications_page.dart';
import 'package:chang_app/features/tasks/data/inbox_repository.dart';
import 'package:chang_app/features/tasks/presentation/task_detail_page.dart';
import 'package:chang_app/features/tasks/presentation/task_detail_provider.dart';
import 'package:chang_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AppNotification item(
  String id,
  String title, {
  bool read = false,
  NotificationKind kind = NotificationKind.system,
  bool earlier = false,
}) => AppNotification(
  id: id,
  title: title,
  body: 'Nội dung thông báo đầy đủ để bạn xem lại và tiếp tục chặng học của mình.',
  kind: kind,
  referenceId: kind == NotificationKind.task ? 'task-1' : null,
  isRead: read,
  createdAt: DateTime.now().subtract(Duration(days: earlier ? 2 : 0)),
);

class _Repository extends NotificationRepository {
  _Repository(super.client, super.inbox);
  List<AppNotification> items = [
    item('n1', 'Đến giờ ôn tập', kind: NotificationKind.task),
    item('n2', 'Một chặng học mới'),
    item(
      'n3',
      'Cột mốc đầu tiên',
      kind: NotificationKind.milestone,
      read: true,
      earlier: true,
    ),
  ];
  bool failRead = false, failWrite = false;
  final readIds = <String>[];
  int markAllCalls = 0;
  AppNotification _read(AppNotification n) => AppNotification(
    id: n.id,
    title: n.title,
    body: n.body,
    kind: n.kind,
    isRead: true,
    createdAt: n.createdAt,
    scheduledAt: n.scheduledAt,
    referenceId: n.referenceId,
  );
  @override
  Future<List<AppNotification>> list() async {
    if (failRead) throw StateError('offline');
    return [...items];
  }

  @override
  Future<void> markRead(String id) async {
    if (failWrite) throw StateError('offline');
    readIds.add(id);
    items = items.map((n) => n.id == id ? _read(n) : n).toList();
  }

  @override
  Future<void> markAllRead() async {
    if (failWrite) throw StateError('offline');
    markAllCalls++;
    items = items.map(_read).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final text = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([text.load(), icons.load()]);
  });
  late SupabaseClient client;
  late _Repository repository;
  setUp(() {
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    repository = _Repository(client, InboxRepository(client));
  });
  tearDown(() async => client.dispose());
  Future<void> pump(
    WidgetTester tester, {
    bool home = false,
    double width = 390,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
          dashboardProvider.overrideWith(
            (ref) async => throw StateError('independent dashboard error'),
          ),
          taskDetailProvider.overrideWith((ref, id) async => null),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(width == 320 ? 1.5 : 1)),
            child: child!,
          ),
          home: home ? const HomePage() : const NotificationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Home bell opens notifications, task target and read count update independently of dashboard',
    (tester) async {
      await pump(tester, home: true);
      expect(find.byType(NotificationBell), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      await tap(tester, find.byTooltip('Thông báo'));
      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.text('Hôm nay'), findsWidgets);
      expect(find.text('Trước đó'), findsOneWidget);
      if (const bool.fromEnvironment('CAPTURE_DIALOG_UI')) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(Uri.file('/tmp/chang-notifications.png')),
        );
      }
      await tap(tester, find.text('Đến giờ ôn tập'));
      expect(repository.readIds, ['n1']);
      expect(
        tester.widget<TaskDetailPage>(find.byType(TaskDetailPage)).taskId,
        'task-1',
      );
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.text('Chưa đọc 1'), findsOneWidget);
      await tap(tester, find.text('Đánh dấu tất cả đã đọc'));
      expect(repository.markAllCalls, 1);
      expect(find.text('Chưa đọc 0'), findsOneWidget);
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.text('2'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'unread/type filters, full body and write errors preserve state',
    (tester) async {
      await pump(tester);
      await tap(tester, find.text('Chưa đọc 2'));
      expect(find.text('Cột mốc đầu tiên'), findsNothing);
      await tap(tester, find.text('Tất cả loại'));
      await tap(tester, find.text('Cột mốc'));
      expect(find.text('Không có thông báo phù hợp'), findsOneWidget);
      await tap(tester, find.text('Tất cả'));
      expect(find.text('Cột mốc đầu tiên'), findsOneWidget);
      await tap(tester, find.text('Cột mốc đầu tiên'));
      expect(find.text(repository.items.last.body), findsWidgets);
      expect(repository.readIds, isEmpty);
      await tap(tester, find.byTooltip('Đóng thông báo'));
      repository.failWrite = true;
      await tap(tester, find.text('Đánh dấu tất cả đã đọc'));
      expect(
        find.textContaining('Chưa xác nhận được trạng thái đã đọc.'),
        findsOneWidget,
      );
      expect(repository.items.where((n) => !n.isRead).length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('failure, retry and empty notifications are distinct states', (
    tester,
  ) async {
    repository.failRead = true;
    await pump(tester);
    expect(find.textContaining('Chưa tải được thông báo.'), findsOneWidget);
    expect(find.text('Chưa có thông báo'), findsNothing);
    repository.failRead = false;
    repository.items = [];
    await tap(tester, find.text('Thử lại'));
    expect(find.text('Chưa có thông báo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final width in [320.0, 800.0]) {
    testWidgets('notification list and details wrap at $width', (tester) async {
      repository.items = [
        item(
          'n1',
          'Thông báo có tiêu đề rất dài về tiến độ học tập và kế hoạch ôn tập cuối kỳ',
        ),
      ];
      await pump(tester, width: width);
      await tap(tester, find.text(repository.items.single.title));
      expect(tester.takeException(), isNull);
      await tap(tester, find.byTooltip('Đóng thông báo'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
