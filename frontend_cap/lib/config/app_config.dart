// ─── KamJodo Cap — Centralized URL Config ────────────────────────────────────
// Jab backend Vercel pe live ho jaye, sirf liveBaseUrl update karo.
// Baaki saari services automatically us URL ka use karengi.

class AppConfig {
  // 🔴 CHANGE THIS after Vercel deployment ─────────────────────────────────────
  static const String liveBaseUrl = 'https://kamjodo-backend.vercel.app';
  // ─────────────────────────────────────────────────────────────────────────────

  static const String androidEmulatorUrl = 'http://10.0.2.2:5000';
  static const String localhostUrl       = 'http://localhost:5000';
}
