import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/worker_service.dart';
import 'customer/worker_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.primary = const Color(0xFF7A0000),
    this.secondary = const Color(0xFFB31217),
    this.tertiary = const Color(0xFFFF5F6D),
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<dynamic> _categories = [];
  List<dynamic> _searchResults = [];

  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isCategoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await WorkerService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isCategoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCategoriesLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final query = _searchController.text.trim();
      final response = await WorkerService.searchWorkers(
        search: query.isNotEmpty ? query : null,
        categoryId: _selectedCategoryId,
      );

      if (!mounted) return;

      final workers = (response['data']?['workers'] as List<dynamic>?) ?? [];
      setState(() {
        _searchResults = workers;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      if (_selectedCategoryId == categoryId) {
        _selectedCategoryId = null;
      } else {
        _selectedCategoryId = categoryId;
      }
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: widget.primary,
        title: Text(
          'Worker Search',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Header & Categories Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search workers, skills (e.g. Plumber, AC)',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(Icons.search, color: widget.secondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF3F3F3),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category filter chips
                if (_isCategoriesLoading)
                  const SizedBox(
                    height: 36,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_categories.isNotEmpty)
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index] as Map<String, dynamic>;
                        final catId = (cat['id'] ?? cat['_id'] ?? '').toString();
                        final name = (cat['name'] ?? '').toString();
                        final isSelected = _selectedCategoryId == catId;

                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isSelected ? Colors.white : const Color(0xFF444444),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: widget.secondary,
                            backgroundColor: const Color(0xFFF0F0F0),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (_) => _selectCategory(catId),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Search Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No matching workers found',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try searching for another skill or category',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final worker = _searchResults[index] as Map<String, dynamic>;
                          return WorkerCard(
                            worker: worker,
                            primary: widget.primary,
                            secondary: widget.secondary,
                            tertiary: widget.tertiary,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
