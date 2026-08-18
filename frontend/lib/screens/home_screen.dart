import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/worker_service.dart';
import 'customer/worker_card.dart';
import 'customer/worker_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _categoriesFuture;
  late Future<List<dynamic>> _featuredWorkersFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _categoriesFuture = WorkerService.getCategories();
    _featuredWorkersFuture = WorkerService.searchWorkers(limit: 5).then(
      (res) => (res['data']?['workers'] as List<dynamic>?) ?? [],
    );
  }

  void _refresh() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final secondary = widget.secondary;
    final tertiary = widget.tertiary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header banner with logo & stories placeholder
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, secondary, tertiary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      'KamJodo',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _stories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final story = _stories[index];
                        return _StoryBubble(label: story.label, isMe: story.isMe);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main scroll area
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refresh(),
              color: secondary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories header
                    Row(
                      children: [
                        Text(
                          'Categories',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111111),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Categories Grid
                    FutureBuilder<List<dynamic>>(
                      future: _categoriesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final categories = snapshot.data ?? [];

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categories.length + 1,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 6,
                            mainAxisExtent: 92,
                          ),
                          itemBuilder: (context, index) {
                            if (index == categories.length) {
                              return _CategoryBubble(
                                label: 'More',
                                icon: Icons.more_horiz,
                                imageUrl: '',
                                primary: primary,
                                secondary: secondary,
                                tertiary: tertiary,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WorkerListScreen(
                                        primary: primary,
                                        secondary: secondary,
                                        tertiary: tertiary,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }

                            final category = categories[index] as Map<String, dynamic>;
                            final name = (category['name'] ?? '').toString();
                            final iconKey = (category['iconKey'] ?? 'more').toString();
                            final imageUrl = (category['imageUrl'] ?? '').toString();
                            final catId = (category['id'] ?? category['_id'] ?? '').toString();

                            return _CategoryBubble(
                              label: name,
                              icon: _iconForCategory(iconKey, name),
                              imageUrl: imageUrl,
                              primary: primary,
                              secondary: secondary,
                              tertiary: tertiary,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => WorkerListScreen(
                                      categoryId: catId.isNotEmpty ? catId : null,
                                      categoryName: name,
                                      primary: primary,
                                      secondary: secondary,
                                      tertiary: tertiary,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Top Workers Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Top Workers Nearby',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111111),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WorkerListScreen(
                                  primary: primary,
                                  secondary: secondary,
                                  tertiary: tertiary,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'See All',
                            style: GoogleFonts.poppins(
                              color: secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Top Workers List
                    FutureBuilder<List<dynamic>>(
                      future: _featuredWorkersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final workers = snapshot.data ?? [];
                        if (workers.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'No workers available in your area yet.',
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: workers.length,
                          itemBuilder: (context, index) {
                            final worker = workers[index] as Map<String, dynamic>;
                            return WorkerCard(
                              worker: worker,
                              primary: primary,
                              secondary: secondary,
                              tertiary: tertiary,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryItem {
  const _StoryItem({required this.label, required this.isMe});
  final String label;
  final bool isMe;
}

const List<_StoryItem> _stories = [
  _StoryItem(label: 'You', isMe: true),
  _StoryItem(label: 'User 1', isMe: false),
  _StoryItem(label: 'User 2', isMe: false),
  _StoryItem(label: 'User 3', isMe: false),
  _StoryItem(label: 'User 4', isMe: false),
];

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({required this.label, required this.isMe});

  final String label;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(1.4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xFF7A0000),
                Color(0xFFFF5F6D),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isMe
                  ? const Icon(Icons.person, color: Color(0xFFB31217), size: 18)
                  : Text(
                      label.replaceAll('User ', ''),
                      style: const TextStyle(
                        color: Color(0xFFB31217),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 1),
        SizedBox(
          width: 50,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

IconData _iconForCategory(String iconKey, String categoryName) {
  switch (iconKey.toLowerCase()) {
    case 'driver':
    case 'taxi':
      return Icons.local_taxi_outlined;
    case 'plumber':
      return Icons.plumbing_outlined;
    case 'electrician':
    case 'electric':
      return Icons.electrical_services_outlined;
    case 'mechanic':
    case 'tools':
      return Icons.build_outlined;
    case 'teacher':
    case 'school':
      return Icons.school_outlined;
    default:
      return categoryName.toLowerCase() == 'more' ? Icons.more_horiz : Icons.category_outlined;
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({
    required this.label,
    required this.icon,
    required this.imageUrl,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String imageUrl;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(1.5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, secondary, tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(1.4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(icon, color: secondary, size: 22),
                          ),
                        )
                      : Center(
                          child: Icon(icon, color: secondary, size: 22),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF444444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
