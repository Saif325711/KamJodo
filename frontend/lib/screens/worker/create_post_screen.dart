import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/worker_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _radiusController = TextEditingController();

  List<dynamic> _categories = [];
  String? _selectedCategoryId;

  bool _isLoadingCategories = true;
  bool _isPublishing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await WorkerService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _publishPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isPublishing = true; _error = null; });

    try {
      final res = await WorkerService.createPost(
        title: _titleController.text.trim(),
        categoryId: _selectedCategoryId,
        description: _descriptionController.text.trim(),
        startingPrice: double.tryParse(_priceController.text.trim()) ?? 0,
        serviceRadiusKm: double.tryParse(_radiusController.text.trim()) ?? 10,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service Post Published! 🚀', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        setState(() => _error = res['message'] as String? ?? 'Failed to publish post.');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: widget.primary,
        foregroundColor: Colors.white,
        title: Text('Create Service Post', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Service Advertisement',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Your post will be visible in search & feed to customers',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    // Post Title
                    _Label('Post Title *'),
                    const SizedBox(height: 6),
                    _InputField(
                      controller: _titleController,
                      hint: 'e.g. Expert Plumbing & Pipe Repairing Service',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Category
                    _Label('Category (Optional)'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategoryId,
                          hint: Text('Select Category', style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14)),
                          isExpanded: true,
                          items: _categories.map<DropdownMenuItem<String>>((c) {
                            final id = (c['id'] ?? c['_id'] ?? '').toString();
                            final name = (c['name'] ?? '').toString();
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(name, style: GoogleFonts.poppins(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    _Label('Description Details'),
                    const SizedBox(height: 6),
                    _InputField(
                      controller: _descriptionController,
                      hint: 'e.g. 24x7 emergency plumbing, leakage fixing, bathroom fitting etc.',
                      maxLines: 4,
                    ),

                    const SizedBox(height: 16),

                    // Price & Radius Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Starting Price (₹)'),
                              const SizedBox(height: 6),
                              _InputField(
                                controller: _priceController,
                                hint: 'e.g. 250',
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Service Radius (km)'),
                              const SizedBox(height: 6),
                              _InputField(
                                controller: _radiusController,
                                hint: 'e.g. 10',
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 13)),
                    ],

                    const SizedBox(height: 28),

                    // Publish CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isPublishing ? null : _publishPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isPublishing
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('Publish Post 🚀', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF333333)));
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}
