import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('${AuthService.baseUrl}/api/v1/worker-posts'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _posts = (body['data'] as List<dynamic>?) ?? [];
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text('Worker Service Feed 🧢', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeed,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.dynamic_feed_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No worker posts yet',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Posts published by workers in KamJodo Cap\nwill appear here for you to hire',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFeed,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final post = _posts[index] as Map<String, dynamic>;
                      final title = post['title'] as String? ?? 'Service Post';
                      final desc = post['description'] as String? ?? '';
                      final price = (post['startingPrice'] as num?)?.toInt() ?? 0;
                      final workerName = (post['worker'] as Map<String, dynamic>?)?['name'] as String? ?? 'Skilled Worker';

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                child: Text(
                                  workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Theme.of(context).primaryColor),
                                ),
                              ),
                              title: Text(workerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                              subtitle: Text('Available for Hire ⚡', style: GoogleFonts.poppins(fontSize: 12, color: Colors.green.shade700)),
                              trailing: price > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                                      child: Text('₹$price+', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.green.shade800)),
                                    )
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF222222)),
                              ),
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  desc,
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Booking request sent for: $title'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.handshake_outlined),
                                  label: Text('Hire Worker 🤝', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
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
