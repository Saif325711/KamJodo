import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/booking_service.dart';
import '../services/worker_service.dart';
import '../theme.dart';
import 'create_post_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isOnline = false;
  List<dynamic> _incomingRequests = [];
  List<dynamic> _activeJobs = [];
  List<dynamic> _completedJobs = [];
  bool _isLoading = true;

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
      final profileRes = await WorkerService.getMyWorkerProfile();
      if (mounted && profileRes['success'] == true) {
        setState(() => _isOnline = profileRes['data']?['isOnline'] == true);
      }
    } catch (_) {}

    try {
      final bookings = await BookingService.getMyBookings();
      if (!mounted) return;

      final incoming = <dynamic>[];
      final active = <dynamic>[];
      final completed = <dynamic>[];

      for (final b in bookings) {
        final status = (b['status'] ?? '').toString();
        if (status == 'requested') {
          incoming.add(b);
        } else if (['accepted', 'worker_on_the_way', 'arrived', 'service_started'].contains(status)) {
          active.add(b);
        } else if (['service_completed', 'paid', 'rated'].contains(status)) {
          completed.add(b);
        }
      }

      setState(() {
        _incomingRequests = incoming;
        _activeJobs = active;
        _completedJobs = completed;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _isOnline = value);
    final res = await WorkerService.setAvailability(isOnline: value);
    if (res['success'] != true && mounted) {
      setState(() => _isOnline = !value);
    }
  }

  Future<void> _acceptBooking(String bookingId) async {
    final res = await BookingService.acceptBooking(bookingId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['success'] == true ? '✅ Job accepted!' : res['message'] ?? 'Failed'),
      backgroundColor: res['success'] == true ? Colors.green : Colors.red,
    ));
    if (res['success'] == true) _loadAll();
  }

  Future<void> _rejectBooking(String bookingId) async {
    final res = await BookingService.rejectBooking(bookingId);
    if (!mounted) return;
    if (res['success'] == true) _loadAll();
  }

  Future<void> _updateStatus(String bookingId, String nextStatus, String label) async {
    final res = await BookingService.updateBookingStatus(bookingId, nextStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['success'] == true ? '✅ $label' : res['message'] ?? 'Failed'),
      backgroundColor: res['success'] == true ? Colors.green : Colors.red,
    ));
    if (res['success'] == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: kCapPrimary,
        foregroundColor: Colors.white,
        title: Text('🧢 KamJodo Cap', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Post',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Online/Offline Banner ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Colors.white,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: _isOnline
                        ? [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 8)]
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOnline ? 'Online — Ready for Jobs' : 'Offline — Not receiving jobs',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        _isOnline ? 'Customers can find & book you now' : 'Toggle to start receiving requests',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isOnline,
                  onChanged: _toggleOnline,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Quick Stats Row ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                _statChip('${_incomingRequests.length}', 'Pending', Colors.orange),
                const SizedBox(width: 12),
                _statChip('${_activeJobs.length}', 'Active', Colors.blue),
                const SizedBox(width: 12),
                _statChip('${_completedJobs.length}', 'Done', Colors.green),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Tabs ─────────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: kCapSecondary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kCapSecondary,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: 'Requests (${_incomingRequests.length})'),
                Tab(text: 'Active (${_activeJobs.length})'),
                Tab(text: 'History'),
              ],
            ),
          ),

          // ── Tab Views ────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kCapSecondary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _RequestsTab(
                        requests: _incomingRequests,
                        onAccept: _acceptBooking,
                        onReject: _rejectBooking,
                        onRefresh: _loadAll,
                      ),
                      _ActiveTab(
                        jobs: _activeJobs,
                        onUpdate: _updateStatus,
                        onRefresh: _loadAll,
                      ),
                      _HistoryTab(
                        jobs: _completedJobs,
                        onRefresh: _loadAll,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

// ─── Requests Tab ─────────────────────────────────────────────────────────────
class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.requests, required this.onAccept, required this.onReject, required this.onRefresh});
  final List<dynamic> requests;
  final Function(String) onAccept;
  final Function(String) onReject;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _emptyState(Icons.inbox_outlined, 'No new job requests', 'Go online to start receiving jobs');
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kCapSecondary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (_, i) {
          final req = requests[i] as Map<String, dynamic>;
          final id = (req['id'] ?? req['_id'] ?? '').toString();
          final desc = req['description'] as String? ?? 'Service request';
          final customerName = (req['customer'] as Map<String, dynamic>?)?['name'] as String? ?? 'Customer';
          final price = (req['estimatedPrice'] as num?)?.toInt() ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: kCapSecondary.withValues(alpha: 0.15),
                      child: Text(
                        customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kCapSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('New Job Request 🔔', style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade700)),
                        ],
                      ),
                    ),
                    if (price > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text('₹$price+', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.green.shade700)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(desc, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onReject(id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Reject ✗', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onAccept(id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Accept ✓', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Active Tab ───────────────────────────────────────────────────────────────
class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.jobs, required this.onUpdate, required this.onRefresh});
  final List<dynamic> jobs;
  final Function(String, String, String) onUpdate;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return _emptyState(Icons.engineering_outlined, 'No active jobs', 'Accept a request to see it here');
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kCapSecondary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (_, i) {
          final job = jobs[i] as Map<String, dynamic>;
          final id = (job['id'] ?? job['_id'] ?? '').toString();
          final status = (job['status'] ?? '').toString();
          final desc = job['description'] as String? ?? '';
          final customerName = (job['customer'] as Map<String, dynamic>?)?['name'] as String? ?? 'Customer';

          String nextStatus = '';
          String buttonText = '';
          IconData buttonIcon = Icons.arrow_forward;

          if (status == 'accepted') {
            nextStatus = 'worker_on_the_way'; buttonText = "I'm On My Way 🚗"; buttonIcon = Icons.directions_car;
          } else if (status == 'worker_on_the_way') {
            nextStatus = 'arrived'; buttonText = "I've Arrived 📍"; buttonIcon = Icons.location_on;
          } else if (status == 'arrived') {
            nextStatus = 'service_started'; buttonText = 'Start Work 🔧'; buttonIcon = Icons.play_arrow;
          } else if (status == 'service_started') {
            nextStatus = 'service_completed'; buttonText = 'Work Complete ✅'; buttonIcon = Icons.check_circle;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kCapSecondary.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Job 🔧', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kCapSecondary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Customer: $customerName', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                ],
                if (nextStatus.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => onUpdate(id, nextStatus, buttonText),
                      icon: Icon(buttonIcon, size: 18),
                      label: Text(buttonText, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCapSecondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.jobs, required this.onRefresh});
  final List<dynamic> jobs;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return _emptyState(Icons.history, 'No completed jobs yet', 'Your job history will appear here');
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kCapSecondary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (_, i) {
          final job = jobs[i] as Map<String, dynamic>;
          final desc = job['description'] as String? ?? 'Completed service';
          final customerName = (job['customer'] as Map<String, dynamic>?)?['name'] as String? ?? 'Customer';
          final amount = (job['finalAmount'] ?? job['estimatedPrice'] ?? 0);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (amount != 0)
                  Text('₹$amount', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.green.shade700)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Shared Empty State ───────────────────────────────────────────────────────
Widget _emptyState(IconData icon, String title, String subtitle) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 15)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400), textAlign: TextAlign.center),
      ],
    ),
  );
}
