import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/login_screen.dart';

/// First screen shown to new users — choose "Hire a Worker" (Customer)
/// or "Work & Earn" (Worker).
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({
    super.key,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  void _goToAuth(BuildContext context, String role) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          primary: primary,
          secondary: secondary,
          tertiary: tertiary,
          role: role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              secondary,
              tertiary.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 2),
                      ),
                      child: const Icon(Icons.handshake_outlined, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'KamJodo',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect with skilled workers or find local jobs',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // ── Role Cards ──────────────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Select your mode to continue',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Hire a Worker (Customer) ─────────────────────────
                      _RoleCard(
                        icon: Icons.person_search_outlined,
                        title: 'Hire a Worker',
                        subtitle: 'Find & book nearby skilled professionals',
                        emoji: '🙋',
                        onTap: () => _goToAuth(context, 'customer'),
                      ),

                      const SizedBox(height: 16),

                      // ── Work & Earn (Worker) ───────────────────────────
                      _RoleCard(
                        icon: Icons.engineering_outlined,
                        title: 'Work & Earn',
                        subtitle: 'Offer your services & get customer leads',
                        emoji: '🔧',
                        onTap: () => _goToAuth(context, 'worker'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'By continuing, you agree to our Terms of Service & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Role Card Widget ─────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Emoji badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF999999)),
            ],
          ),
        ),
      ),
    );
  }
}
