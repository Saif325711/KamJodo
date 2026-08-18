import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/worker_service.dart';
import '../../services/storage_service.dart';
import 'booking_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({
    super.key,
    required this.workerId,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final String workerId;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  List<dynamic> _reviews = [];
  List<dynamic> _posts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      _userRole = await StorageService.getRole();
      final results = await Future.wait([
        WorkerService.getWorkerProfile(widget.workerId),
        WorkerService.getWorkerPosts(widget.workerId),
        WorkerService.getWorkerReviews(widget.workerId),
        if (_userRole == 'customer') WorkerService.isFollowing(widget.workerId),
      ]);

      if (!mounted) return;
      final profileResult = results[0] as Map<String, dynamic>;
      setState(() {
        _profile = profileResult['data'] as Map<String, dynamic>?;
        _posts = results[1] as List<dynamic>;
        final reviewResult = results[2] as Map<String, dynamic>;
        _reviews = (reviewResult['data']?['reviews'] as List<dynamic>?) ?? [];
        if (_userRole == 'customer' && results.length > 3) {
          _isFollowing = results[3] as bool;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final wasFollowing = _isFollowing;
    setState(() => _isFollowing = !wasFollowing);
    final success = wasFollowing
        ? await WorkerService.unfollowWorker(widget.workerId)
        : await WorkerService.followWorker(widget.workerId);
    if (!success && mounted) setState(() => _isFollowing = wasFollowing);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: widget.primary, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: widget.primary, foregroundColor: Colors.white),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Worker not found', style: GoogleFonts.poppins(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final p = _profile!;
    final name = p['name'] as String? ?? 'Worker';
    final photo = p['profilePhoto'] as String? ?? '';
    final category = (p['category'] as Map<String, dynamic>?)?['name'] ?? '';
    final rating = (p['ratingAverage'] as num?)?.toDouble() ?? 0.0;
    final reviews = (p['ratingCount'] as num?)?.toInt() ?? 0;
    final jobs = (p['completedJobs'] as num?)?.toInt() ?? 0;
    final price = (p['startingPrice'] as num?)?.toInt() ?? 0;
    final skills = (p['skills'] as List<dynamic>?) ?? [];
    final identityVerified = p['identityVerified'] == true;
    final isOnline = p['isOnline'] == true;
    final about = p['about'] as String? ?? '';
    final followers = (p['followersCount'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: widget.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.primary, widget.secondary, widget.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      // Avatar
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.white24,
                            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                            child: photo.isEmpty
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'W',
                                    style: GoogleFonts.poppins(
                                      fontSize: 36,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          if (isOnline)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            category,
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                          ),
                          if (identityVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Colors.white, size: 16),
                            const SizedBox(width: 2),
                            Text(
                              'Verified',
                              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Stats Row ──────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(label: 'Rating', value: rating.toStringAsFixed(1), icon: Icons.star, iconColor: Colors.amber),
                  _divider(),
                  _StatItem(label: 'Reviews', value: reviews.toString()),
                  _divider(),
                  _StatItem(label: 'Jobs Done', value: jobs.toString()),
                  _divider(),
                  _StatItem(label: 'Followers', value: followers.toString()),
                ],
              ),
            ),

            // ── Action Buttons ─────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  // Follow
                  if (_userRole == 'customer') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleFollow,
                        icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add, size: 18),
                        label: Text(_isFollowing ? 'Following' : 'Follow',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.secondary,
                          side: BorderSide(color: widget.secondary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  // Book Now
                  if (_userRole == 'customer')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              workerId: widget.workerId,
                              workerName: name,
                              categoryId: (p['category'] as Map<String, dynamic>?)?['id'] as String?,
                              primary: widget.primary,
                              secondary: widget.secondary,
                              tertiary: widget.tertiary,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Book Now',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  // Starting price badge
                  if (price > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '₹$price+',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: widget.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Tabs ──────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: widget.secondary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: widget.secondary,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'About'),
                  Tab(text: 'Posts'),
                  Tab(text: 'Reviews'),
                ],
              ),
            ),

            // ── Tab Views ─────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // About Tab
                  _AboutTab(about: about, skills: skills, price: price, profile: p),
                  // Posts Tab
                  _PostsTab(posts: _posts, secondary: widget.secondary),
                  // Reviews Tab
                  _ReviewsTab(reviews: _reviews, rating: rating),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.grey.shade200);
}

// ─── Stat Item ────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, this.icon, this.iconColor});
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (icon != null) Icon(icon, size: 16, color: iconColor ?? Colors.grey),
            if (icon != null) const SizedBox(width: 2),
            Text(value, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF111111))),
          ],
        ),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ─── About Tab ────────────────────────────────────────────────────────────────
class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.about, required this.skills, required this.price, required this.profile});
  final String about;
  final List<dynamic> skills;
  final int price;
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final experience = (profile['experienceYears'] as num?)?.toInt();
    final serviceRadius = (profile['serviceRadiusKm'] as num?)?.toInt();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (about.isNotEmpty) ...[
          Text('About', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Text(about, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555555), height: 1.5)),
          const SizedBox(height: 16),
        ],
        // Info cards
        Row(
          children: [
            if (experience != null)
              _InfoChip(icon: Icons.work_outline, label: '$experience yrs exp'),
            if (serviceRadius != null) ...[
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.location_on_outlined, label: '${serviceRadius}km area'),
            ],
            if (price > 0) ...[
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.currency_rupee, label: '₹$price+ starting'),
            ],
          ],
        ),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Skills', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((s) => _SkillChip(label: s.toString())).toList(),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF555555))),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFB31217), fontWeight: FontWeight.w500)),
    );
  }
}

// ─── Posts Tab ────────────────────────────────────────────────────────────────
class _PostsTab extends StatelessWidget {
  const _PostsTab({required this.posts, required this.secondary});
  final List<dynamic> posts;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.post_add, size: 60, color: Colors.grey),
            const SizedBox(height: 8),
            Text('No posts yet', style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final post = posts[i] as Map<String, dynamic>;
        final price = (post['startingPrice'] as num?)?.toInt() ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post['title'] as String? ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
              if ((post['description'] as String? ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(post['description'] as String, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (price > 0) ...[
                const SizedBox(height: 8),
                Text('Starting ₹$price', style: GoogleFonts.poppins(color: secondary, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Reviews Tab ──────────────────────────────────────────────────────────────
class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.reviews, required this.rating});
  final List<dynamic> reviews;
  final double rating;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_border, size: 60, color: Colors.grey),
            const SizedBox(height: 8),
            Text('No reviews yet', style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (_, i) {
        final r = reviews[i] as Map<String, dynamic>;
        final customerName = (r['customer'] as Map<String, dynamic>?)?['name'] as String? ?? 'Customer';
        final stars = (r['rating'] as num?)?.toInt() ?? 5;
        final comment = r['comment'] as String? ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 16, backgroundColor: Colors.grey.shade200,
                    child: Text(customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(customerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13))),
                  Row(children: List.generate(5, (j) => Icon(j < stars ? Icons.star : Icons.star_border, size: 14, color: Colors.amber))),
                ],
              ),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(comment, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ],
          ),
        );
      },
    );
  }
}
