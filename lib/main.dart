import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/main_scaffold.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await MofuchiTheme.load();

  runApp(const MofuchiGardenApp());
}

/// Shared theme state for the entire application.
/// A future Home Screen update can call MofuchiTheme.toggle() from the
/// moon/sun button without needing to change the authentication flow.
class MofuchiTheme {
  MofuchiTheme._();

  static const String _storageKey = 'mofuchi_dark_mode';
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDark => mode.value == ThemeMode.dark;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = (prefs.getBool(_storageKey) ?? false)
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static Future<void> setDark(bool enabled) async {
    mode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, enabled);
  }

  static Future<void> toggle() => setDark(!isDark);
}

class MofuchiGardenApp extends StatelessWidget {
  const MofuchiGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MofuchiTheme.mode,
      builder: (context, selectedMode, _) => MaterialApp(
      title: 'Mofuchi Garden',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F4FB),
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          primary: const Color(0xFF6E7F68),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF151321),
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          primary: const Color(0xFFB9A2EA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: selectedMode,
      // Firebase Auth persists the signed-in user on Android/iOS.
      // Route returning users straight to the main app; show onboarding
      // to users who are signed out.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8060C6),
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            return const MainScaffold();
          }

          return const OnboardingScreen();
        },
      ),
      ),
    );
  }
}
