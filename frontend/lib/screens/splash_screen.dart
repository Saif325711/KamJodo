import 'dart:async';
import 'package:flutter/material.dart';
import 'app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    this.onSplashComplete,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  /// Optional: if provided, called after splash to determine the next screen.
  /// If null, navigates to AppShell directly (legacy behaviour).
  final Widget Function()? onSplashComplete;


  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 1-second animation controller duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    // Automatically navigate to main app after 1 second
    _timer = Timer(const Duration(milliseconds: 1000), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    // Use the auth-aware resolver if provided, otherwise fall back to AppShell
    final nextScreen = widget.onSplashComplete?.call() ??
        AppShell(
          primary: widget.primary,
          secondary: widget.secondary,
          tertiary: widget.tertiary,
        );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }


  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0A1A),
      body: GestureDetector(
        onTap: _navigateToHome,
        child: Stack(
          children: [
            // Generated Dark Background with Worker Collage Glow
            Positioned.fill(
              child: Image.asset(
                'assets/images/kamjodo_splash_screen_vertical.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0B0A1A), Color(0xFF1D0F38)],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Animated Center Logo using kamjodo1.png with 1-Second Scale & Fade Animation
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B00).withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFFE02575).withOpacity(0.25),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/images/kamjodo1.png',
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'frontend/assets/images/kamjodo1.png',
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
