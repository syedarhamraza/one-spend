import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme/one_ui_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

class OneSpendApp extends StatelessWidget {
  const OneSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'OneSpend',
          debugShowCheckedModeBanner: false,
          theme: OneUITheme.darkTheme,
          home: const HomeScreen(),
        );
      },
    );
  }
}
