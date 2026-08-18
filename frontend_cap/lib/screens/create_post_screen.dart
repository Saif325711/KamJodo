import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/worker_service.dart';
import '../theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategoryId;
  List<dynamic> _categories = [];
  bool _isLoading = false;
  bool _isCatLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final rawCats = await WorkerService.getCategories();
    if (!mounted) return;

    final seenIds = <String>{};
    final validCats = <dynamic>[];
    for (final cat in rawCats) {
      final name = (cat['name'] ?? '').toString().trim();
      final id = (cat['_id'] ?? cat['id'] ?? (name.isNotEmpty ? 'cat_${name.toLowerCase()}' : '')).toString().trim();
      if (id.isNotEmpty && !seenIds.contains(id)) {
        seenIds.add(id);
        validCats.add({'id': id, 'name': name.isNotEmpty ? name : 'Category'});
      }
    }

    setState(() {
      _categories = validCats;
      _isCatLoading = false;
    });
  }

  Future<void> _createPost() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a post title')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final price = double.tryParse(_priceController.text) ?? 0;
    final res = await WorkerService.createPost(
      title: title,
      categoryId: _selectedCategoryId,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      startingPrice: price,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Post published successfully!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to create post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: kCapPrimary,
        foregroundColor: Colors.white,
        title: Text('Create Service Post', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Post Title ────────────────────────────────────────────────
            _label('Post Title *'),
            const SizedBox(height: 6),
            _field(
              controller: _titleController,
              hint: 'e.g. Professional Home Plumbing Service',
              icon: Icons.title,
            ),
            const SizedBox(height: 18),

            // ── Category ──────────────────────────────────────────────────
            _label('Category'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
              ),
              child: _isCatLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categories.any((c) => c['id'] == _selectedCategoryId) ? _selectedCategoryId : null,
                        isExpanded: true,
                        hint: Text('Select a category', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                        items: _categories.map((cat) {
                          final id = cat['id'].toString();
                          final name = cat['name'].toString();
                          return DropdownMenuItem<String>(value: id, child: Text(name));
                        }).toList(),
                        onChanged: (id) {
                          setState(() {
                            _selectedCategoryId = id;
                          });
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 18),

            // ── Description ───────────────────────────────────────────────
            _label('Description'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
              ),
              child: TextField(
                controller: _descController,
                maxLines: 4,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe your service in detail...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Starting Price ────────────────────────────────────────────
            _label('Starting Price (₹)'),
            const SizedBox(height: 6),
            _field(
              controller: _priceController,
              hint: 'e.g. 300',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),

            // ── Submit ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kCapSecondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text('Publish Post 🚀', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF333333)));
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(icon, color: kCapSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
