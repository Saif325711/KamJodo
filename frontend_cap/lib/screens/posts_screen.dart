import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/worker_service.dart';
import '../theme.dart';
import 'create_post_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    _posts = await WorkerService.getMyPosts();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: kCapPrimary,
        foregroundColor: Colors.white,
        title: Text('My Posts', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
              _loadPosts();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          _loadPosts();
        },
        backgroundColor: kCapSecondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('New Post', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kCapSecondary))
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.post_add, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No posts yet',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first service post\nso customers can find you',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  color: kCapSecondary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (_, i) {
                      final post = _posts[i] as Map<String, dynamic>;
                      final title = post['title'] as String? ?? 'Untitled Post';
                      String category = '';
                      if (post['category'] != null) {
                        category = post['category'].toString();
                      } else if (post['categoryId'] != null) {
                        if (post['categoryId'] is Map) {
                          category = (post['categoryId']['name'] ?? '').toString();
                        } else {
                          category = post['categoryId'].toString();
                        }
                      }
                      final price = (post['startingPrice'] as num?)?.toInt() ?? 0;
                      final status = post['status'] as String? ?? 'active';
                      final views = (post['viewCount'] as num?)?.toInt() ?? 0;
                      final bookings = (post['bookingCount'] as num?)?.toInt() ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                          border: status == 'active'
                              ? Border.all(color: Colors.green.shade200, width: 1)
                              : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'active' ? Colors.green.shade50 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: status == 'active' ? Colors.green.shade700 : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (category.isNotEmpty) ...[
                                  Icon(Icons.work_outline, size: 14, color: kCapSecondary),
                                  const SizedBox(width: 4),
                                  Text(category, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                                  const SizedBox(width: 12),
                                ],
                                Icon(Icons.currency_rupee, size: 14, color: Colors.green.shade600),
                                Text('$price+', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green.shade600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text('$views views', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                                const SizedBox(width: 16),
                                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text('$bookings bookings', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
