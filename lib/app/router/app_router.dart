import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/pages/startup_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/tasks/presentation/task_detail_page.dart';
import '../../features/tasks/presentation/task_list_page.dart';
import '../../features/tasks/presentation/completed_tasks_page.dart';
import '../../features/projects/presentation/project_list_page.dart';
import '../../features/projects/presentation/create_project_page.dart';
import '../../features/projects/presentation/project_detail_page.dart';
import '../navigation.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StartupPage()),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TaskListPage(),
      ),
      GoRoute(
        path: '/tasks/completed',
        builder: (context, state) => CompletedTasksPage(
          initialProjectId: state.uri.queryParameters['project'],
        ),
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectListPage(),
      ),
      GoRoute(
        path: '/projects/new',
        builder: (context, state) => const CreateProjectPage(),
      ),
      GoRoute(
        path: '/projects/:projectId',
        builder: (context, state) =>
            ProjectDetailPage(projectId: state.pathParameters['projectId']!),
      ),
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
