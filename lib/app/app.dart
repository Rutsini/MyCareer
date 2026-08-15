import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/notifications/application/notification_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(firebaseAuthProvider).currentUser != null) {
      ref.read(notificationCoordinatorProvider).synchronize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final auth = ref.watch(authStateProvider);
    if (auth.valueOrNull != null) {
      ref.watch(notificationBootstrapProvider);
    }
    ref.listen<String?>(pendingNotificationRouteProvider, (_, route) {
      if (route != null) {
        router.go(route);
        ref.read(pendingNotificationRouteProvider.notifier).state = null;
      }
    });
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
