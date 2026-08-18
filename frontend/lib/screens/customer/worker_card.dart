import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'worker_profile_screen.dart';

/// Reusable card shown in search results and home screen
class WorkerCard extends StatelessWidget {
  const WorkerCard({
    super.key,
    required this.worker,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Map<String, dynamic> worker;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  Widget build(BuildContext context) {
    final name = worker['name'] as String? ?? 'Worker';
    final photo = worker['profilePhoto'] as String? ?? '';
    final category = (worker['category'] as Map<String, dynamic>?)?['name'] as String? ?? '';
    final rating = (worker['ratingAverage'] as num?)?.toDouble() ?? 0.0;
    final reviews = (worker['ratingCount'] as num?)?.toInt() ?? 0;
    final jobs = (worker['completedJobs'] as num?)?.toInt() ?? 0;
    final price = (worker['startingPrice'] as num?)?.toInt() ?? 0;
    final isOnline = worker['isOnline'] == true;
    final isVerified = worker['identityVerified'] == true;
    final workerId = (worker['id'] ?? worker['_id'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        if (workerId.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkerProfileScreen(
              workerId: workerId,
              primary: primary,
              secondary: secondary,
              tertiary: tertiary,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Avatar ────────────────────────────────────────────────
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'W',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: secondary,
                            ),
                          )
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // ── Info ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + verified
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF111111),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified, size: 15, color: secondary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Category
                    Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Rating + jobs
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                        const SizedBox(width: 2),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(1) : 'New',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        if (reviews > 0) ...[
                          Text(
                            ' ($reviews)',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                        if (jobs > 0) ...[
                          const SizedBox(width: 8),
                          Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                            '$jobs jobs',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Price + Arrow ─────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (price > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹$price+',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: secondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
