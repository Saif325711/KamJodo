import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'customer/booking_history_screen.dart';
import 'role_selection_screen.dart';
import 'worker/worker_dashboard_screen.dart';
import 'worker/worker_onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.primary = const Color(0xFF7A0000),
    this.secondary = const Color(0xFFB31217),
    this.tertiary = const Color(0xFFFF5F6D),
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getMe();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RoleSelectionScreen(
          primary: widget.primary,
          secondary: widget.secondary,
          tertiary: widget.tertiary,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: widget.primary, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = _user?['name'] as String? ?? 'User';
    final phone = _user?['phone'] as String? ?? '';
    final rawRole = (_user?['role'] as String? ?? 'customer').toLowerCase();
    final role = rawRole.toUpperCase();
    final photo = _user?['profilePhoto'] as String? ?? '';
    final isWorker = rawRole == 'worker';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: widget.primary,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: widget.secondary.withOpacity(0.1),
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: widget.secondary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'KamJodo User',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: widget.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Menu Options
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                // Worker specific features
                if (isWorker) ...[
                  _MenuItem(
                    icon: Icons.engineering_outlined,
                    title: 'Worker Dashboard / Job Center',
                    subtitle: 'Accept incoming requests & track active jobs',
                    iconColor: widget.secondary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkerDashboardScreen(
                            primary: widget.primary,
                            secondary: widget.secondary,
                            tertiary: widget.tertiary,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _MenuItem(
                    icon: Icons.badge_outlined,
                    title: 'Worker Profile Setup',
                    subtitle: 'Update rates, skills & service radius',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkerOnboardingScreen(
                            primary: widget.primary,
                            secondary: widget.secondary,
                            tertiary: widget.tertiary,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                ],

                _MenuItem(
                  icon: Icons.calendar_month_outlined,
                  title: 'Meri Bookings',
                  subtitle: 'Active, completed & cancelled bookings',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookingHistoryScreen(
                          primary: widget.primary,
                          secondary: widget.secondary,
                          tertiary: widget.tertiary,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _MenuItem(
                  icon: Icons.swap_horiz_outlined,
                  title: 'Switch Role / Mode',
                  subtitle: 'Kaam Dena / Kaam Lena mode change',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RoleSelectionScreen(
                          primary: widget.primary,
                          secondary: widget.secondary,
                          tertiary: widget.tertiary,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _MenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  titleColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF333333)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: titleColor ?? const Color(0xFF111111),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
            )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
