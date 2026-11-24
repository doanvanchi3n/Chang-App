import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/pages/startup_page.dart';
import '../../features/tasks/presentation/task_detail_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StartupPage()),
      GoRoute(
        path: '/tasks/:taskId',
        builder: (context, state) =>
            TaskDetailPage(taskId: state.pathParameters['taskId']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
