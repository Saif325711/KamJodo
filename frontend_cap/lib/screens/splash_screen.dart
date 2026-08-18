import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'app_shell.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)));
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2400), _navigate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      // Verify the token is still valid with backend (clears stale local tokens on 401)
      final user = await AuthService.getMe();
      if (!mounted) return;
      // If getMe cleared the token (returned null after 401), route to login
      final stillLoggedIn = await AuthService.isLoggedIn();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => (stillLoggedIn && user != null) ? const AppShell() : const LoginScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kCapPrimary, kCapSecondary, kCapTertiary],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20),
                      ],
                    ),
                    child: const Center(
                      child: Text('🧢', style: TextStyle(fontSize: 46)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'KamJodo Cap',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Worker Platform — Earn on your terms',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
