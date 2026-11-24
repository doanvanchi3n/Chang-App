import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/pages/startup_page.dart';
import '../navigation.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StartupPage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
