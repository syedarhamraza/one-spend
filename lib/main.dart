import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/telemetry/events.dart';
import 'core/telemetry/telemetry.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/updates/presentation/update_controller.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'theme/one_ui_theme.dart';
import 'theme/one_ui_scroll.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _reportUncaughtErrors();
  await configureDependencies();
  final launchRoute = await sl<NotificationService>().launchRoute();
  final showOnboarding = launchRoute == null && await needsOnboarding();

  // Draw behind the system bars on every Android version (it's the default from Android
  // 15), with transparent bars over the pitch-black One UI background.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

/// Sends every error nothing else caught to Crashlytics (see [AppLog]).
void _reportUncaughtErrors() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLog.fatal(details.exception, details.stack, reason: 'Flutter: ${details.context ?? details.library}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.fatal(error, stack, reason: 'Uncaught async error');
    return true;
  };
  Isolate.current.addErrorListener(RawReceivePort((List<dynamic> pair) {
    final stack = pair.last == null ? null : StackTrace.fromString(pair.last as String);
    AppLog.fatal(pair.first ?? 'Unknown isolate error', stack, reason: 'Isolate error');
  }).sendPort);
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
  String? _lastScreen;

  static const _tabRoutes = {AppRoutes.subscriptions, AppRoutes.upcoming, AppRoutes.analytics, AppRoutes.settings};

  @override
  void initState() {
    super.initState();
    HomeChrome.reset();
    _router.routerDelegate.addListener(_reportScreen);
    if (sl.isRegistered<NotificationService>()) {
      _notificationTaps = sl<NotificationService>().taps.listen(_openNotificationRoute);
    }
    final launchRoute = widget.launchRoute;
    if (launchRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openNotificationRoute(launchRoute));
    }
    // Once per launch, quietly (unless turned off in Software update › Auto download):
    // Play needs the activity in the foreground, hence after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(UpdateController.instance.autoCheck()));
  }

  /// Tabs switch in place; pages are pushed above the tabs so back returns to them.
  void _openNotificationRoute(String route) {
    final target = _tabRoutes.contains(route)
        ? 'tab'
        : route.startsWith(AppRoutes.paymentMethods)
            ? 'card'
            : 'subscription';
    AppLog.event(TelemetryEvent.notificationOpened(target));
    if (_tabRoutes.contains(route)) {
      _router.go(route);
    } else {
      _router.push(route);
    }
  }

  /// Screen views for analytics and crash breadcrumbs: the route pattern
  /// (`/subscriptions/:id`), never the ids in it.
  void _reportScreen() {
    final screen = _router.routerDelegate.currentConfiguration.fullPath;
    if (screen.isEmpty || screen == _lastScreen) return;
    _lastScreen = screen;
    AppLog.screen(screen);
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_reportScreen);
    _notificationTaps?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'One Spend',
      debugShowCheckedModeBanner: false,
      theme: OneUITheme.darkTheme,
      scrollBehavior: const OneUIScrollBehavior(),
      routerConfig: _router,
    );
  }
}
