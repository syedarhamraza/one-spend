import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onespend/core/router/app_router.dart';

/// Hosts [home] at `/` inside a [MaterialApp.router] that knows every app page
/// route, so `context.push(...)` navigation works in widget tests.
Widget routedTestApp(Widget home, {ThemeData? theme}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      ...buildPageRoutes(),
    ],
  );
  return MaterialApp.router(theme: theme, routerConfig: router);
}
