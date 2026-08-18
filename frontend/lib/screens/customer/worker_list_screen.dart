import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/worker_service.dart';
import 'worker_card.dart';

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final String? categoryId;
  final String? categoryName;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  List<dynamic> _workers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _limit = 20;

  bool _onlyAvailable = false;
  bool _onlyVerified = false;
  String _sortBy = 'rating';

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadWorkers({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    setState(() => _isLoading = refresh || _page == 1);

    try {
      final result = await WorkerService.searchWorkers(
        categoryId: widget.categoryId,
        availableNow: _onlyAvailable ? true : null,
        verifiedOnly: _onlyVerified ? true : null,
        page: _page,
        limit: _limit,
      );

      if (!mounted) return;

      final workers = (result['data']?['workers'] as List<dynamic>?) ?? [];
      final pagination = result['data']?['pagination'] as Map<String, dynamic>?;
      final totalPages = (pagination?['pages'] as num?)?.toInt() ?? 1;

      if (_sortBy == 'price') {
        workers.sort((a, b) => ((a['startingPrice'] as num?) ?? 0)
            .compareTo((b['startingPrice'] as num?) ?? 0));
      } else {
        workers.sort((a, b) => ((b['ratingAverage'] as num?) ?? 0)
            .compareTo((a['ratingAverage'] as num?) ?? 0));
      }

      setState(() {
        if (refresh || _page == 1) {
          _workers = workers;
        } else {
          _workers.addAll(workers);
        }
        _hasMore = _page < totalPages;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _isLoadingMore = false; });
    }
  }

  Future<void> _loadMore() async {
    setState(() { _isLoadingMore = true; _page++; });
    await _loadWorkers();
  }

  void _applyFilter({bool? available, bool? verified, String? sort}) {
    setState(() {
      if (available != null) _onlyAvailable = available;
      if (verified != null) _onlyVerified = verified;
      if (sort != null) _sortBy = sort;
    });
    _loadWorkers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: widget.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.categoryName ?? 'Available Workers',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilters(context),
            tooltip: 'Filter Workers',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadWorkers(refresh: true),
        color: widget.secondary,
        child: Column(
          children: [
            // Active filters
            if (_onlyAvailable || _onlyVerified || _sortBy != 'rating')
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_onlyAvailable)
                        _FilterChip(
                          label: '🟢 Available Now',
                          onRemove: () => _applyFilter(available: false),
                          secondary: widget.secondary,
                        ),
                      if (_onlyVerified)
                        _FilterChip(
                          label: '✅ Verified Only',
                          onRemove: () => _applyFilter(verified: false),
                          secondary: widget.secondary,
                        ),
                      if (_sortBy == 'price')
                        _FilterChip(
                          label: '💰 Sort: Price',
                          onRemove: () => _applyFilter(sort: 'rating'),
                          secondary: widget.secondary,
                        ),
                    ],
                  ),
                ),
              ),

            // Results count
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${_workers.length} worker${_workers.length == 1 ? '' : 's'} found',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),

            // Worker List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _workers.isEmpty
                      ? _EmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _workers.length + (_hasMore ? 1 : 0),
                          itemBuilder: (_, index) {
                            if (index >= _workers.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return WorkerCard(
                              worker: _workers[index] as Map<String, dynamic>,
                              primary: widget.primary,
                              secondary: widget.secondary,
                              tertiary: widget.tertiary,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            bool localAvail = _onlyAvailable;
            bool localVerified = _onlyVerified;
            String localSort = _sortBy;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text('Filter Workers', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: localAvail,
                    onChanged: (v) => setModal(() => localAvail = v),
                    activeThumbColor: widget.secondary,
                    title: Text('Available Workers Only', style: GoogleFonts.poppins(fontSize: 14)),
                    subtitle: Text('Show workers who are currently online', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: localVerified,
                    onChanged: (v) => setModal(() => localVerified = v),
                    activeThumbColor: widget.secondary,
                    title: Text('Verified Workers Only', style: GoogleFonts.poppins(fontSize: 14)),
                    subtitle: Text('Show workers with verified identity', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(height: 8),
                  Text('Sort By', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _SortChip(
                        label: '⭐ Highest Rating',
                        selected: localSort == 'rating',
                        onTap: () => setModal(() => localSort = 'rating'),
                        secondary: widget.secondary,
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: '💰 Lowest Price',
                        selected: localSort == 'price',
                        onTap: () => setModal(() => localSort = 'price'),
                        secondary: widget.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _applyFilter(available: localAvail, verified: localVerified, sort: localSort);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Apply Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove, required this.secondary});
  final String label;
  final VoidCallback onRemove;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: secondary, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: secondary),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.selected, required this.onTap, required this.secondary});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? secondary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No matching workers found', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 6),
          Text('Try selecting different search filters', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
