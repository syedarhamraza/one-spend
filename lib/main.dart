import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'features/notifications/data/notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'theme/one_ui_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  final launchRoute = await sl<NotificationService>().launchRoute();
  final showOnboarding = launchRoute == null && await needsOnboarding();

  // Set system UI to immersive One UI pitch-black dark mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(OneSpendApp(launchRoute: launchRoute, showOnboarding: showOnboarding));
}

class OneSpendApp extends StatefulWidget {
  /// Route of the notification that cold-started the app, opened after the first frame.
  final String? launchRoute;

  /// Open the first-run welcome instead of the tabs.
  final bool showOnboarding;

  const OneSpendApp({super.key, this.launchRoute, this.showOnboarding = false});

  @override
  State<OneSpendApp> createState() => _OneSpendAppState();
}

class _OneSpendAppState extends State<OneSpendApp> {
  // Owned per app instance so navigation state never leaks between app (or test) instances.
  late final GoRouter _router =
      createAppRouter(initialLocation: widget.showOnboarding ? AppRoutes.welcome : AppRoutes.subscriptions);
  StreamSubscription<String>? _notificationTaps;

  static const _tabRoutes = {AppRoutes.subscriptions, AppRoutes.upcoming, AppRoutes.analytics, AppRoutes.settings};

  @override
  void initState() {
    super.initState();
    HomeChrome.reset();
    if (sl.isRegistered<NotificationService>()) {
      _notificationTaps = sl<NotificationService>().taps.listen(_openNotificationRoute);
    }
    final launchRoute = widget.launchRoute;
    if (launchRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openNotificationRoute(launchRoute));
    }
  }

  /// Tabs switch in place; pages are pushed above the tabs so back returns to them.
  void _openNotificationRoute(String route) {
    if (_tabRoutes.contains(route)) {
      _router.go(route);
    } else {
      _router.push(route);
    }
  }

  @override
  void dispose() {
    _notificationTaps?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OneSpend',
      debugShowCheckedModeBanner: false,
      theme: OneUITheme.darkTheme,
      routerConfig: _router,
    );
  }
}
