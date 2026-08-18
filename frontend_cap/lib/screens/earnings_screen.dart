import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/booking_service.dart';
import '../theme.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  List<dynamic> _completedJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final all = await BookingService.getMyBookings();
      _completedJobs = all.where((b) {
        final s = (b['status'] ?? '').toString();
        return ['service_completed', 'paid', 'rated'].contains(s);
      }).toList();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  int get _totalEarnings => _completedJobs.fold(0, (sum, job) {
    final amount = (job['finalAmount'] ?? job['estimatedPrice'] ?? 0) as num;
    return sum + amount.toInt();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: kCapPrimary,
        foregroundColor: Colors.white,
        title: Text('Earnings', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kCapSecondary))
          : RefreshIndicator(
              onRefresh: _loadJobs,
              color: kCapSecondary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Summary Card ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kCapPrimary, kCapSecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: kCapPrimary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Earnings', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text(
                          '₹ $_totalEarnings',
                          style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _miniStat('${_completedJobs.length}', 'Completed'),
                            const SizedBox(width: 24),
                            _miniStat('--', 'Rating'),
                            const SizedBox(width: 24),
                            _miniStat('--', 'Followers'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Recent Transactions ─────────────────────────────────
                  Text('Recent Jobs', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),

                  if (_completedJobs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'No completed jobs yet.\nComplete jobs to see earnings here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ),

                  ..._completedJobs.map((job) {
                    final desc = job['description'] as String? ?? 'Service';
                    final customerName = (job['customer'] as Map<String, dynamic>?)?['name'] as String? ?? 'Customer';
                    final amount = (job['finalAmount'] ?? job['estimatedPrice'] ?? 0) as num;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Text(
                            '₹ $amount',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),
      ],
    );
  }
}
