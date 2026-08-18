import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({
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
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill requested test phone number for instant user testing
    _phoneController.text = '6003359534';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _error = 'Please enter a valid 10-digit phone number.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final fullPhone = phone.startsWith('+') ? phone : '+91$phone';
      final result = await AuthService.sendOtp(fullPhone);

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              primary: widget.primary,
              secondary: widget.secondary,
              tertiary: widget.tertiary,
              phone: fullPhone,
              role: widget.role,
              devOtp: result['devOtp'] as String?,
            ),
          ),
        );
      } else {
        setState(() => _error = result['message'] as String? ?? 'Failed to send verification code.');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Please check your connection.');
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
          '$roleEmoji $roleLabel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),

            // ── Heading ────────────────────────────────────────────────────
            Text(
              'Enter your\nphone number',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We will send a 6-digit verification code to confirm your number',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF777777),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Test Number Shortcut
            GestureDetector(
              onTap: () {
                setState(() {
                  _phoneController.text = '6003359534';
                  _error = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: widget.secondary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Test Number: 6003359534 (OTP: 654321)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: widget.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Phone Input ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Country code
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Text(
                      '🇮🇳 +91',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
                      onSubmitted: (_) => _sendOtp(),
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: '6003359534',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        counterText: '',
                      ),
                    ),
                  ),
                ],
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

            // ── Send OTP Button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.secondary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
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
                        'Send Verification Code',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
