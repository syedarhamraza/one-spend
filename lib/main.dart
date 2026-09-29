import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'screens/home_screen.dart';
import 'theme/one_ui_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

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

  runApp(const OneSpendApp());
}

class OneSpendApp extends StatefulWidget {
  const OneSpendApp({super.key});

  @override
  State<OneSpendApp> createState() => _OneSpendAppState();
}

class _OneSpendAppState extends State<OneSpendApp> {
  // Owned per app instance so navigation state never leaks between app (or test) instances.
  late final GoRouter _router = createAppRouter();

  @override
  void initState() {
    super.initState();
    HomeChrome.reset();
  }

  @override
  void dispose() {
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
