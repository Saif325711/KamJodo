import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'app_shell.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale, _logoFade, _logoGlow;

  // Text
  late AnimationController _textCtrl;
  late Animation<double> _titleFade, _subFade;
  late Animation<Offset> _titleSlide, _subSlide;

  // Pulse ring
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // Connection scene (background)
  late AnimationController _sceneCtrl;

  // Progress
  late AnimationController _progressCtrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = _logoCtrl
        .drive(CurveTween(curve: Curves.elasticOut))
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoFade = _logoCtrl
        .drive(CurveTween(curve: const Interval(0.0, 0.5)))
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoGlow = _logoCtrl
        .drive(CurveTween(curve: const Interval(0.4, 1.0)))
        .drive(Tween(begin: 0.0, end: 1.0));

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _titleFade = _textCtrl
        .drive(CurveTween(curve: const Interval(0.0, 0.65, curve: Curves.easeOut)))
        .drive(Tween(begin: 0.0, end: 1.0));
    _titleSlide = _textCtrl
        .drive(CurveTween(curve: const Interval(0.0, 0.7, curve: Curves.easeOut)))
        .drive(Tween(begin: const Offset(0, 0.4), end: Offset.zero));
    _subFade = _textCtrl
        .drive(CurveTween(curve: const Interval(0.3, 1.0, curve: Curves.easeOut)))
        .drive(Tween(begin: 0.0, end: 1.0));
    _subSlide = _textCtrl
        .drive(CurveTween(curve: const Interval(0.3, 1.0, curve: Curves.easeOut)))
        .drive(Tween(begin: const Offset(0, 0.5), end: Offset.zero));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulse = _pulseCtrl
        .drive(CurveTween(curve: Curves.easeInOut))
        .drive(Tween(begin: 0.94, end: 1.06));

    // Connection scene loops forever
    _sceneCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));
    _progress = _progressCtrl
        .drive(CurveTween(curve: Curves.easeInOut))
        .drive(Tween(begin: 0.0, end: 1.0));

    _logoCtrl.forward();
    _progressCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400),
        () { if (mounted) _textCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 2800), _navigate);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _sceneCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    if (loggedIn) {
      final user = await AuthService.getMe();
      if (!mounted) return;
      final stillLoggedIn = await AuthService.isLoggedIn();
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            (stillLoggedIn && user != null) ? const AppShell() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ));
    } else {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: dark gradient ───────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.45, 0.80, 1.0],
                colors: [
                  Color(0xFF0D0500),
                  Color(0xFF3D1200),
                  Color(0xFF7A2800),
                  Color(0xFFAF4400),
                ],
              ),
            ),
          ),

          // ── Layer 2: worker-hirer connection scene ───────────────────
          AnimatedBuilder(
            animation: _sceneCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ConnectionScenePainter(_sceneCtrl.value),
            ),
          ),

          // ── Layer 3: centre radial glow ──────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _logoGlow,
              builder: (_, __) => Container(
                width: size.width * 1.4,
                height: size.width * 1.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kCapTertiary.withValues(alpha: 0.22 * _logoGlow.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 4: main foreground content ─────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Icon ─────────────────────────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
                  builder: (_, __) => FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: ScaleTransition(
                        scale: _pulse,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Outer glow halo
                            Container(
                              width: 144,
                              height: 144,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(42),
                                boxShadow: [
                                  BoxShadow(
                                    color: kCapTertiary.withValues(alpha: 0.45),
                                    blurRadius: 60,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            // Outline ring
                            Container(
                              width: 136,
                              height: 136,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // Solid white icon card
                            Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.30),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                  BoxShadow(
                                    color: kCapSecondary.withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text('🧢', style: TextStyle(fontSize: 56)),
                              ),
                            ),
                            // Live indicator dot
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF0D0500), width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50)
                                          .withValues(alpha: 0.7),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 44),

                // ── Title ────────────────────────────────────────────
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'KamJodo ',
                          style: GoogleFonts.poppins(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.5,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.40),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: 'CAP',
                          style: GoogleFonts.poppins(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: kCapTertiary,
                            letterSpacing: -1.5,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: kCapTertiary.withValues(alpha: 0.55),
                                blurRadius: 18,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Accent line + tagline ────────────────────────────
                SlideTransition(
                  position: _subSlide,
                  child: FadeTransition(
                    opacity: _subFade,
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: kCapTertiary.withValues(alpha: 0.70),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'CONNECT  ·  WORK  ·  EARN',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.55),
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 28,
                              height: 2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: kCapTertiary.withValues(alpha: 0.70),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Bridging skilled workers with\nthe right opportunities',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.50),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Progress ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (_, __) => Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: LinearProgressIndicator(
                                value: _progress.value,
                                minHeight: 2.5,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.10),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.lerp(kCapSecondary, kCapTertiary,
                                      _progress.value)!,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Getting things ready…',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.38),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 44),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Connection Scene Painter ────────────────────────────────────────────────
// Draws two person-node clusters (Worker left, Hirer right) connected by
// a pulsing arc with animated flow dots travelling along it.
class _ConnectionScenePainter extends CustomPainter {
  final double t; // 0..1 looping

  const _ConnectionScenePainter(this.t);

  // Draw a stylised person icon at (cx, cy)
  void _drawPerson(Canvas canvas, Offset center, Color color, double scale) {
    final p = Paint()..color = color..style = PaintingStyle.fill;
    final headR = 14.0 * scale;
    final bodyW = 24.0 * scale;
    final bodyH = 18.0 * scale;
    // head
    canvas.drawCircle(center.translate(0, -headR - bodyH * 0.5), headR, p);
    // body (rounded rect)
    final bodyTop = center.dy - bodyH * 0.5 + headR * 0.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(center.dx, bodyTop + bodyH * 0.5),
            width: bodyW,
            height: bodyH),
        const Radius.circular(8),
      ),
      p,
    );
  }

  // Draw a node circle with label tag
  void _drawNode(Canvas canvas, Offset center, Color color, double scale,
      double glowAlpha) {
    // glow
    canvas.drawCircle(
        center,
        28 * scale,
        Paint()
          ..color = color.withValues(alpha: glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    // ring
    canvas.drawCircle(
        center,
        22 * scale,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // filled circle
    canvas.drawCircle(
        center,
        18 * scale,
        Paint()..color = color.withValues(alpha: 0.18));
    // person icon
    _drawPerson(canvas, center, color.withValues(alpha: 0.85), scale * 0.9);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Node positions  (upper portion of screen, behind the logo area)
    final workerPos = Offset(w * 0.18, h * 0.28);
    final hirerPos = Offset(w * 0.82, h * 0.28);
    final midPos = Offset(w * 0.50, h * 0.18); // centre bridge node

    // Satellite nodes
    final workerSat1 = Offset(w * 0.06, h * 0.42);
    final workerSat2 = Offset(w * 0.24, h * 0.44);
    final hirerSat1 = Offset(w * 0.76, h * 0.44);
    final hirerSat2 = Offset(w * 0.94, h * 0.42);

    final workerColor = const Color(0xFFF57C00);
    final hirerColor = const Color(0xFFFFCA28);
    final lineColor = Colors.white;
    final pulseAlpha = 0.25 + 0.15 * math.sin(t * math.pi * 2);

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // ── Draw connecting lines ──────────────────────────────────────────
    // Worker → centre
    canvas.drawLine(workerPos, midPos, linePaint);
    // Hirer → centre
    canvas.drawLine(hirerPos, midPos, linePaint);
    // Worker → Hirer (main arc via bezier)
    final arcPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.16)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final arcPath = Path()
      ..moveTo(workerPos.dx, workerPos.dy)
      ..cubicTo(
        w * 0.30, h * 0.10,
        w * 0.70, h * 0.10,
        hirerPos.dx, hirerPos.dy,
      );
    canvas.drawPath(arcPath, arcPaint);

    // Satellite lines
    final satPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(workerPos, workerSat1, satPaint);
    canvas.drawLine(workerPos, workerSat2, satPaint);
    canvas.drawLine(hirerPos, hirerSat1, satPaint);
    canvas.drawLine(hirerPos, hirerSat2, satPaint);

    // ── Animate flow dots along main arc ────────────────────────────
    // Compute dot position using cubic bezier parametrically
    for (int i = 0; i < 3; i++) {
      final tp = (t + i / 3.0) % 1.0;
      // Cubic bezier formula
      final p0 = workerPos;
      final p1 = Offset(w * 0.30, h * 0.10);
      final p2 = Offset(w * 0.70, h * 0.10);
      final p3 = hirerPos;
      final mt = 1 - tp;
      final dotX = mt * mt * mt * p0.dx +
          3 * mt * mt * tp * p1.dx +
          3 * mt * tp * tp * p2.dx +
          tp * tp * tp * p3.dx;
      final dotY = mt * mt * mt * p0.dy +
          3 * mt * mt * tp * p1.dy +
          3 * mt * tp * tp * p2.dy +
          tp * tp * tp * p3.dy;
      final alpha = 0.6 * math.sin(tp * math.pi).clamp(0.0, 1.0);
      canvas.drawCircle(
          Offset(dotX, dotY),
          3.5,
          Paint()
            ..color = kCapTertiary.withValues(alpha: alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }

    // ── Worker → centre flow dot ──────────────────────────────────────
    final wt = t % 1.0;
    final wDot = Offset.lerp(workerPos, midPos, wt)!;
    canvas.drawCircle(
        wDot,
        2.5,
        Paint()
          ..color = workerColor.withValues(alpha: 0.5 * math.sin(wt * math.pi))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // ── Draw nodes ────────────────────────────────────────────────────
    _drawNode(canvas, midPos, Colors.white, 0.75, pulseAlpha * 0.6);
    _drawNode(canvas, workerPos, workerColor, 1.0, pulseAlpha);
    _drawNode(canvas, hirerPos, hirerColor, 1.0, pulseAlpha);

    // Satellite mini-nodes
    for (final sat in [workerSat1, workerSat2]) {
      _drawNode(canvas, sat, workerColor, 0.65, pulseAlpha * 0.5);
    }
    for (final sat in [hirerSat1, hirerSat2]) {
      _drawNode(canvas, sat, hirerColor, 0.65, pulseAlpha * 0.5);
    }

    // ── Labels: "Worker" / "Hirer" ────────────────────────────────────
    _drawLabel(canvas, workerPos.translate(0, 36), 'WORKER', workerColor);
    _drawLabel(canvas, hirerPos.translate(0, 36), 'HIRER', hirerColor);
    _drawLabel(canvas, midPos.translate(0, 28), 'CONNECT', Colors.white);
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.55),
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos.translate(-tp.width / 2, 0));
  }

  @override
  bool shouldRepaint(_ConnectionScenePainter old) => old.t != t;
}
