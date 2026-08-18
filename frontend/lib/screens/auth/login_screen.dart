import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.role,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final String role; // 'customer' | 'worker'

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }

    if (password.isEmpty) {
      setState(() => _error = 'Please enter any password.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await AuthService.quickLogin(
        name: name,
        password: password,
        role: widget.role,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => AppShell(
              primary: widget.primary,
              secondary: widget.secondary,
              tertiary: widget.tertiary,
            ),
          ),
          (_) => false,
        );
      } else {
        setState(() => _error = result['message'] as String? ?? 'Login failed.');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = widget.role == 'worker';
    final roleLabel = isWorker ? 'Worker Mode' : 'Customer Mode';
    final roleEmoji = isWorker ? '🔧' : '🙋';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: widget.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'KamJodo — Hire Workers 🙋',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // ── Heading ────────────────────────────────────────────────────
            Text(
              'Create Account / Login',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your name and password to find & hire skilled workers',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF777777),
              ),
            ),

            const SizedBox(height: 32),

            // ── Full Name Input ────────────────────────────────────────────
            Text(
              'Full Name',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _nameController,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: isWorker ? 'e.g. Ramesh Kumar' : 'e.g. Amit Sharma',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.person_outline, color: widget.secondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Password Input ─────────────────────────────────────────────
            Text(
              'Password',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Enter any password',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.lock_outline, color: widget.secondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // ── Error ──────────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.poppins(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // ── Login Button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        'Continue to App 🚀',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
