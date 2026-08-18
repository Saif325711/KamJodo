import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'screens/app_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const KamJodoApp());
}

class KamJodoApp extends StatefulWidget {
  const KamJodoApp({super.key});

  @override
  State<KamJodoApp> createState() => _KamJodoAppState();
}

class _KamJodoAppState extends State<KamJodoApp> {
  // Legacy theme endpoint — still uses port 4000 (existing backend port in dev)
  static const String _baseUrl = 'http://localhost:5000';

  _AppThemeConfig _theme = const _AppThemeConfig(
    appTitle: 'KamJodo',
    primary: Color(0xFF7A0000),
    secondary: Color(0xFFB31217),
    tertiary: Color(0xFFFF5F6D),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadTheme());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Called by SplashScreen after animation completes.
  /// Checks if user is already logged in → AppShell, otherwise → RoleSelection
  Widget _resolveHome() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _checkAuthAndGetUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: _theme.primary,
            body: const Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        final user = snapshot.data;
        if (user != null) {
          return AppShell(
            primary: _theme.primary,
            secondary: _theme.secondary,
            tertiary: _theme.tertiary,
          );
        }
        return LoginScreen(
          primary: _theme.primary,
          secondary: _theme.secondary,
          tertiary: _theme.tertiary,
          role: 'customer',
        );
      },
    );
  }

  /// Verifies the stored token is still valid.
  /// Returns user data if valid, null if not logged in or session expired.
  Future<Map<String, dynamic>?> _checkAuthAndGetUser() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) return null;
    // getMe() internally clears token on 401 (stale local dev ID)
    final user = await AuthService.getMe();
    // Re-check if token was cleared by getMe()
    final stillLoggedIn = await AuthService.isLoggedIn();
    return (stillLoggedIn && user != null) ? user : null;
  }



  Future<void> _loadTheme() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/theme'));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final next = _AppThemeConfig.fromJson(decoded);
      if (mounted) setState(() => _theme = next);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _theme.appTitle,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _theme.primary,
          primary: _theme.primary,
          secondary: _theme.secondary,
          tertiary: _theme.tertiary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        appBarTheme: AppBarTheme(
          backgroundColor: _theme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _theme.secondary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _theme.secondary,
            foregroundColor: Colors.white,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _theme.secondary,
            foregroundColor: Colors.white,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? _theme.secondary : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? _theme.secondary.withOpacity(0.4) : null,
          ),
        ),
        iconTheme: IconThemeData(color: _theme.primary),
      ),
      home: SplashScreen(
        primary: _theme.primary,
        secondary: _theme.secondary,
        tertiary: _theme.tertiary,
        onSplashComplete: _resolveHome,
      ),
    );
  }
}

class _AppThemeConfig {
  const _AppThemeConfig({
    required this.appTitle,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final String appTitle;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  factory _AppThemeConfig.fromJson(Map<String, dynamic> json) {
    return _AppThemeConfig(
      appTitle: (json['appTitle'] ?? 'KamJodo').toString(),
      primary: _colorFromHex((json['primary'] ?? '#7A0000').toString()),
      secondary: _colorFromHex((json['secondary'] ?? '#B31217').toString()),
      tertiary: _colorFromHex((json['tertiary'] ?? '#FF5F6D').toString()),
    );
  }
}

Color _colorFromHex(String value) {
  final hex = value.replaceFirst('#', '');
  final normalized = hex.length == 6 ? 'FF$hex' : hex.padLeft(8, 'F');
  return Color(int.parse(normalized, radix: 16));
}
