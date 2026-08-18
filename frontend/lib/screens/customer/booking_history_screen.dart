import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/booking_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({
    super.key,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<dynamic>> _bookingsByTab = {
    'active': [],
    'completed': [],
    'cancelled': [],
  };
  final Map<String, bool> _loading = {
    'active': true,
    'completed': true,
    'cancelled': true,
  };

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
    await Future.wait([
      _loadTab('active'),
      _loadTab('completed'),
      _loadTab('cancelled'),
    ]);
  }

  Future<void> _loadTab(String tab) async {
    final statusMap = {
      'active': null,
      'completed': 'paid',
      'cancelled': 'cancelled_by_customer',
    };

    try {
      final bookings = await BookingService.getMyBookings(status: statusMap[tab]);
      if (!mounted) return;

      setState(() {
        if (tab == 'active') {
          const activeStatuses = [
            'requested', 'accepted', 'worker_on_the_way', 'arrived',
            'service_started', 'service_completed', 'payment_pending', 'rated',
          ];
          _bookingsByTab['active'] = bookings
              .where((b) => activeStatuses.contains(b['status']))
              .toList();
        } else {
          _bookingsByTab[tab] = bookings;
        }
        _loading[tab] = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading[tab] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: widget.primary,
        foregroundColor: Colors.white,
        title: Text('My Bookings', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'Active (${_bookingsByTab['active']?.length ?? 0})'),
            const Tab(text: 'Completed'),
            const Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BookingList(
            bookings: _bookingsByTab['active'] ?? [],
            isLoading: _loading['active'] ?? true,
            onRefresh: () => _loadTab('active'),
            primary: widget.primary,
            secondary: widget.secondary,
            tertiary: widget.tertiary,
          ),
          _BookingList(
            bookings: _bookingsByTab['completed'] ?? [],
            isLoading: _loading['completed'] ?? true,
            onRefresh: () => _loadTab('completed'),
            primary: widget.primary,
            secondary: widget.secondary,
            tertiary: widget.tertiary,
          ),
          _BookingList(
            bookings: _bookingsByTab['cancelled'] ?? [],
            isLoading: _loading['cancelled'] ?? true,
            onRefresh: () => _loadTab('cancelled'),
            primary: widget.primary,
            secondary: widget.secondary,
            tertiary: widget.tertiary,
          ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.isLoading,
    required this.onRefresh,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });
  final List<dynamic> bookings;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No bookings found', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: secondary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (_, i) => _BookingCard(
          booking: bookings[i] as Map<String, dynamic>,
          secondary: secondary,
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.secondary});
  final Map<String, dynamic> booking;
  final Color secondary;

  String get _statusLabel {
    const labels = {
      'requested': '🕐 Pending',
      'accepted': '✅ Accepted',
      'worker_on_the_way': '🚗 Worker on the Way',
      'arrived': '📍 Worker Arrived',
      'service_started': '🔧 Work in Progress',
      'service_completed': '🎉 Work Completed',
      'payment_pending': '💳 Payment Pending',
      'paid': '✅ Paid',
      'rated': '⭐ Rated',
      'rejected': '❌ Rejected',
      'cancelled_by_customer': '🚫 Cancelled by You',
      'cancelled_by_worker': '🚫 Cancelled by Worker',
    };
    return labels[booking['status'] as String? ?? ''] ?? booking['status'] as String? ?? '';
  }

  Color get _statusColor {
    final s = booking['status'] as String? ?? '';
    if (['accepted', 'paid', 'rated', 'service_completed'].contains(s)) return Colors.green;
    if (['rejected', 'cancelled_by_customer', 'cancelled_by_worker'].contains(s)) return Colors.red;
    if (['service_started', 'worker_on_the_way', 'arrived'].contains(s)) return Colors.blue;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final desc = booking['description'] as String? ?? 'Booking';
    final workerName = (booking['worker'] as Map<String, dynamic>?)?['name'] as String? ?? 'Worker';
    final createdAt = booking['createdAt'] as String?;
    final price = (booking['estimatedPrice'] as num?)?.toInt() ?? 0;

    DateTime? date;
    if (createdAt != null) {
      try { date = DateTime.parse(createdAt).toLocal(); } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel,
                      style: GoogleFonts.poppins(fontSize: 12, color: _statusColor, fontWeight: FontWeight.w600)),
                ),
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.engineering_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(workerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              desc.isNotEmpty ? desc : 'No description',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (price > 0) ...[
              const SizedBox(height: 8),
              Text('Estimated Rate: ₹$price',
                  style: GoogleFonts.poppins(fontSize: 12, color: secondary, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
