import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../app_shell.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.phone,
    required this.role,
    this.devOtp,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final String phone;
  final String role;
  final String? devOtp;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _autoFillTestOtp();
  }

  void _autoFillTestOtp() {
    // If test number 6003359534, auto pre-fill requested OTP 654321
    final isTestPhone = widget.phone.endsWith('6003359534');
    final otpToFill = isTestPhone ? '654321' : (widget.devOtp ?? '');

    if (otpToFill.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < 6; i++) {
          _controllers[i].text = otpToFill[i];
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _enteredOtp;
    if (otp.length < 6) {
      setState(() => _error = 'Please enter the full 6-digit code.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await AuthService.verifyOtp(
        phone: widget.phone,
        otp: otp,
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
        setState(() => _error = result['message'] as String? ?? 'Invalid verification code.');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() { _error = null; _isLoading = true; });
    try {
      await AuthService.sendOtp(widget.phone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent!')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not resend code.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTestPhone = widget.phone.endsWith('6003359534');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: widget.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Verify OTP',
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
              'Enter Verification Code',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF777777)),
                children: [
                  const TextSpan(text: 'We sent a 6-digit code to '),
                  TextSpan(
                    text: widget.phone,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            // ── Test Credential Banner ─────────────────────────────────────
            if (isTestPhone) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Test Account OTP: 654321 (Auto-filled)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (widget.devOtp != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Dev OTP: ${widget.devOtp}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 36),

            // ── OTP Boxes ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  width: 46,
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _focusNodes[index].hasFocus
                          ? widget.secondary
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      if (_enteredOtp.length == 6) _verifyOtp();
                    },
                  ),
                );
              }),
            ),

            // ── Error ──────────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _error!,
                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── Verify Button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
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
                        'Verify & Continue',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Resend ─────────────────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _resendOtp,
                child: Text(
                  "Didn't receive code? Resend OTP",
                  style: GoogleFonts.poppins(
                    color: widget.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
