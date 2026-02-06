import 'package:flutter/material.dart';


import 'app_shell.dart';
import 'app_state.dart';
import 'app_state_scope.dart';
import '../ui/screens/intro_screen.dart';
import 'intro_prefs.dart';

class NetworkDashboardApp extends StatefulWidget {
  const NetworkDashboardApp({super.key});

  @override
  State<NetworkDashboardApp> createState() => _NetworkDashboardAppState();
}

class _NetworkDashboardAppState extends State<NetworkDashboardApp> {
  final AppState _state = AppState();
  bool _showIntro = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkIntro();
  }

  Future<void> _checkIntro() async {
    final completed = await IntroPrefs.isIntroCompleted();
    setState(() {
      _showIntro = !completed;
      _loading = false;
    });
  }

  void _completeIntro() async {
    await IntroPrefs.setIntroCompleted();
    setState(() {
      _showIntro = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return AppStateScope(
      notifier: _state,
      child: MaterialApp(
        title: 'Network Dashboard',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 71, 138, 30),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: Color(0xFFF8FAFC),
            foregroundColor: Color(0xFF0F172A),
          ),
          navigationBarTheme: const NavigationBarThemeData(
            indicatorColor: Color(0xFFE0E7FF),
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 1,
            shadowColor: Color(0x1F1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          chipTheme: const ChipThemeData(
            backgroundColor: Color(0xFFE0E7FF),
            selectedColor: Color(0xFF1E3A8A),
            labelStyle: TextStyle(color: Color(0xFF1E3A8A)),
            secondaryLabelStyle: TextStyle(color: Colors.white),
            secondarySelectedColor: Color(0xFF1E3A8A),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            shape: StadiumBorder(),
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ),
        themeMode: ThemeMode.light,
        home: _showIntro
            ? IntroScreen(onDone: _completeIntro)
            : const AppShell(),
      ),
    );
  }
}
