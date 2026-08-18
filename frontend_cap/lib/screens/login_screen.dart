import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
      setState(() => _error = 'Please enter a password.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await AuthService.quickLogin(name: name, password: password);
      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (_) => false,
        );
      } else {
        setState(() => _error = result['message'] as String? ?? 'Login failed.');
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kCapPrimary, Color(0xFF1A1A1A)],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
                          ],
                        ),
                        child: const Center(
                          child: Text('🧢', style: TextStyle(fontSize: 42)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'KamJodo Cap',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Worker Platform — Sign in to start earning',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Login Card ────────────────────────────────────────────────
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, Worker 👷',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your name and any password to continue',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
                        ),
                        const SizedBox(height: 28),

                        // Name
                        _buildLabel('Your Name'),
                        const SizedBox(height: 6),
                        _buildField(
                          controller: _nameController,
                          hint: 'e.g. Ramesh Kumar',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 18),

                        // Password
                        _buildLabel('Password'),
                        const SizedBox(height: 6),
                        _buildField(
                          controller: _passwordController,
                          hint: 'Enter any password',
                          icon: Icons.lock_outline,
                          obscure: true,
                        ),

                        // Error
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 30),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kCapSecondary,
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
                                    'Start Earning 🚀',
                                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white70),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 14),
          prefixIcon: Icon(icon, color: kCapSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
