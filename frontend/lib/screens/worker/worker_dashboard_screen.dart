import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/booking_service.dart';
import '../../services/worker_service.dart';
import 'create_post_screen.dart';
import 'worker_onboarding_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({
    super.key,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isOnline = false;
  List<dynamic> _incomingRequests = [];
  List<dynamic> _activeJobs = [];
  List<dynamic> _completedJobs = [];
  bool _isLoadingBookings = true;

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
      _loadWorkerProfile(),
      _loadBookings(),
    ]);
  }

  Future<void> _loadWorkerProfile() async {
    try {
      final res = await WorkerService.getMyWorkerProfile();
      if (!mounted) return;
      if (res['success'] == true) {
        final profile = res['data'] as Map<String, dynamic>?;
        setState(() {
          _isOnline = profile?['isOnline'] == true;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoadingBookings = true);
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
        } else if (['accepted', 'worker_on_the_way', 'arrived', 'service_started', 'payment_pending'].contains(status)) {
          active.add(b);
        } else if (['service_completed', 'paid', 'rated'].contains(status)) {
          completed.add(b);
        }
      }

      setState(() {
        _incomingRequests = incoming;
        _activeJobs = active;
        _completedJobs = completed;
        _isLoadingBookings = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingBookings = false);
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
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job request accepted!', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
      _loadBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Could not accept job.')),
      );
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    final res = await BookingService.rejectBooking(bookingId);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job request rejected.', style: GoogleFonts.poppins())),
      );
      _loadBookings();
    }
  }

  Future<void> _updateJobStatus(String bookingId, String nextStatus, String actionLabel) async {
    final res = await BookingService.updateBookingStatus(bookingId, nextStatus);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated: $actionLabel', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
      _loadBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to update status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final secondary = widget.secondary;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: Text('Worker Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Create Post',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreatePostScreen(
                    primary: widget.primary,
                    secondary: widget.secondary,
                    tertiary: widget.tertiary,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Edit Worker Profile',
            onPressed: () {
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
        ],
      ),
      body: Column(
        children: [
          // ── Availability Header Banner ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOnline ? 'Online — Ready for Jobs' : 'Offline — Not receiving jobs',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      Text(
                        _isOnline ? 'Customers can find & book you' : 'Toggle switch to go online',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isOnline,
                  onChanged: _toggleOnline,
                  activeColor: secondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Job Status Tabs ───────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: secondary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: secondary,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: 'Requests (${_incomingRequests.length})'),
                Tab(text: 'Active (${_activeJobs.length})'),
                Tab(text: 'History (${_completedJobs.length})'),
              ],
            ),
          ),

          // ── Tab Contents ──────────────────────────────────────────────
          Expanded(
            child: _isLoadingBookings
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Incoming Requests Tab
                      _IncomingRequestsList(
                        requests: _incomingRequests,
                        onAccept: _acceptBooking,
                        onReject: _rejectBooking,
                        onRefresh: _loadBookings,
                        secondary: secondary,
                      ),
                      // Active Jobs Tab
                      _ActiveJobsList(
                        activeJobs: _activeJobs,
                        onUpdateStatus: _updateJobStatus,
                        onRefresh: _loadBookings,
                        secondary: secondary,
                      ),
                      // Job History Tab
                      _CompletedJobsList(
                        completedJobs: _completedJobs,
                        onRefresh: _loadBookings,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Incoming Requests View ───────────────────────────────────────────────────
class _IncomingRequestsList extends StatelessWidget {
  const _IncomingRequestsList({
    required this.requests,
    required this.onAccept,
    required this.onReject,
    required this.onRefresh,
    required this.secondary,
  });

  final List<dynamic> requests;
  final Function(String) onAccept;
  final Function(String) onReject;
  final Future<void> Function() onRefresh;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 350,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No new job requests', style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index] as Map<String, dynamic>;
          final id = (req['id'] ?? req['_id'] ?? '').toString();
          final desc = req['description'] as String? ?? 'Service request';
          final customer = req['customer'] as Map<String, dynamic>?;
          final customerName = customer?['name'] as String? ?? 'Customer';
          final customerPhone = customer?['phone'] as String? ?? '';
          final price = (req['estimatedPrice'] as num?)?.toInt() ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: secondary.withOpacity(0.1),
                      child: Text(
                        customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: secondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                          if (customerPhone.isNotEmpty)
                            Text(customerPhone, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (price > 0)
                      Text('₹$price', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: secondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Required Service:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF333333))),
                const SizedBox(height: 16),
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
                        child: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onAccept(id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Accept Job', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
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

// ─── Active Jobs View ─────────────────────────────────────────────────────────
class _ActiveJobsList extends StatelessWidget {
  const _ActiveJobsList({
    required this.activeJobs,
    required this.onUpdateStatus,
    required this.onRefresh,
    required this.secondary,
  });

  final List<dynamic> activeJobs;
  final Function(String bookingId, String nextStatus, String label) onUpdateStatus;
  final Future<void> Function() onRefresh;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    if (activeJobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 350,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.engineering_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No active jobs in progress', style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeJobs.length,
        itemBuilder: (context, index) {
          final job = activeJobs[index] as Map<String, dynamic>;
          final id = (job['id'] ?? job['_id'] ?? '').toString();
          final status = (job['status'] ?? '').toString();
          final desc = job['description'] as String? ?? '';
          final customerName = (job['customer'] as Map<String, dynamic>?)?['name'] as String? ?? 'Customer';

          String nextStatus = '';
          String buttonText = '';
          IconData buttonIcon = Icons.arrow_forward;

          if (status == 'accepted') {
            nextStatus = 'worker_on_the_way';
            buttonText = 'I am On The Way 🚗';
            buttonIcon = Icons.directions_car;
          } else if (status == 'worker_on_the_way') {
            nextStatus = 'arrived';
            buttonText = 'I Have Arrived 📍';
            buttonIcon = Icons.location_on;
          } else if (status == 'arrived') {
            nextStatus = 'service_started';
            buttonText = 'Start Work 🔧';
            buttonIcon = Icons.play_arrow;
          } else if (status == 'service_started') {
            nextStatus = 'service_completed';
            buttonText = 'Complete Work ✅';
            buttonIcon = Icons.check_circle;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: secondary.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Job', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: secondary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Customer: $customerName', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 16),

                if (nextStatus.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => onUpdateStatus(id, nextStatus, buttonText),
                      icon: Icon(buttonIcon, size: 18),
                      label: Text(buttonText, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Completed Jobs History ───────────────────────────────────────────────────
class _CompletedJobsList extends StatelessWidget {
  const _CompletedJobsList({required this.completedJobs, required this.onRefresh});
  final List<dynamic> completedJobs;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (completedJobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 350,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No completed job history', style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: completedJobs.length,
        itemBuilder: (context, index) {
          final job = completedJobs[index] as Map<String, dynamic>;
          final desc = job['description'] as String? ?? 'Completed service';
          final customerName = (job['customer'] as Map<String, dynamic>?)?['name'] as String? ?? 'Customer';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
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
              ],
            ),
          );
        },
      ),
    );
  }
}
