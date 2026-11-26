import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/focus/presentation/focus_session_page.dart';
import '../../features/onboarding/presentation/pages/startup_page.dart';
import '../../features/tasks/presentation/task_detail_page.dart';
import '../../features/tasks/presentation/task_list_page.dart';
import '../navigation.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StartupPage()),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TaskListPage(),
      ),
      GoRoute(
        path: '/tasks/:taskId',
        builder: (context, state) =>
            TaskDetailPage(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: '/focus',
        builder: (context, state) => const FocusSessionPage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
