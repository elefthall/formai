import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/workout/presentation/workout_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FormAiApp()));
}

class FormAiApp extends StatelessWidget {
  const FormAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FormAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2D2D),
          onPrimary: Colors.white,
          secondary: Color(0xFFFF2D2D),
          onSecondary: Colors.white,
          surface: Colors.black,
          onSurface: Colors.white,
          error: Color(0xFFFF5252),
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF2D2D),
            foregroundColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: const WorkoutScreen(),
    );
  }
}
