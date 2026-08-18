import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/worker_service.dart';
import '../theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final me = await AuthService.getMe();
      final workerRes = await WorkerService.getMyWorkerProfile();
      if (!mounted) return;
      setState(() {
        _profile = {
          ...?me,
          ...?((workerRes['data'] as Map<String, dynamic>?)),
        };
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name'] as String? ?? 'Worker';
    final category = _profile?['category'] as String? ?? 'Service Worker';
    final rating = _profile?['rating'];
    final completedJobs = _profile?['completedJobs'] ?? 0;
    final isOnline = _profile?['isOnline'] == true;
    final verificationStatus = _profile?['verificationStatus'] as String? ?? 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kCapSecondary))
          : CustomScrollView(
              slivers: [
                // ── Profile Header ─────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: kCapPrimary,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kCapPrimary, kCapSecondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'W',
                                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: kCapPrimary),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: isOnline ? Colors.green : Colors.grey,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text(category, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ── Stats Row ─────────────────────────────────────
                        Row(
                          children: [
                            _statCard('${rating ?? '--'}', '⭐ Rating'),
                            const SizedBox(width: 10),
                            _statCard('$completedJobs', '✅ Jobs Done'),
                            const SizedBox(width: 10),
                            _statCard(
                              verificationStatus == 'verified' ? '✓' : '⏳',
                              'Verified',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Info Tiles ────────────────────────────────────
                        _sectionCard(
                          children: [
                            _infoTile(Icons.work_outline, 'Profession', category),
                            _infoTile(Icons.star_outline, 'Rating', rating != null ? '$rating ⭐' : 'Not rated yet'),
                            _infoTile(Icons.verified_user_outlined, 'Verification', verificationStatus.toUpperCase()),
                            _infoTile(Icons.circle, 'Status', isOnline ? 'Online 🟢' : 'Offline ⚫'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Actions ───────────────────────────────────────
                        _sectionCard(
                          children: [
                            _actionTile(Icons.person_outline, 'Edit Profile', () {}),
                            _actionTile(Icons.add_circle_outline, 'Create Post', () {}),
                            _actionTile(Icons.bar_chart_outlined, 'My Earnings', () {}),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Logout ────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: Text('Log Out', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18, color: kCapPrimary)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: kCapSecondary, size: 22),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
      dense: true,
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: kCapSecondary, size: 22),
      title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      dense: true,
    );
  }
}
