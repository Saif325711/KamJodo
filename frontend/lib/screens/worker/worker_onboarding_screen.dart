import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/worker_service.dart';

class WorkerOnboardingScreen extends StatefulWidget {
  const WorkerOnboardingScreen({
    super.key,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  State<WorkerOnboardingScreen> createState() => _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState extends State<WorkerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _priceController = TextEditingController();
  final _radiusController = TextEditingController();

  List<dynamic> _categories = [];
  String? _selectedCategoryId;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _aboutController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    _priceController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final categories = await WorkerService.getCategories();
      final profileRes = await WorkerService.getMyWorkerProfile();

      if (!mounted) return;

      final profile = (profileRes['success'] == true)
          ? profileRes['data'] as Map<String, dynamic>?
          : null;

      setState(() {
        _categories = categories;

        if (profile != null) {
          _fullNameController.text = (profile['name'] ?? '').toString();
          _aboutController.text = (profile['about'] ?? '').toString();
          _experienceController.text = (profile['experienceYears'] ?? '').toString();
          _priceController.text = (profile['startingPrice'] ?? '').toString();
          _radiusController.text = (profile['serviceRadiusKm'] ?? '10').toString();

          final skills = profile['skills'] as List<dynamic>?;
          if (skills != null) {
            _skillsController.text = skills.join(', ');
          }

          final catObj = profile['primaryCategoryId'] as Map<String, dynamic>?;
          if (catObj != null) {
            _selectedCategoryId = (catObj['id'] ?? catObj['_id'] ?? '').toString();
          }
        }

        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSaving = true; _error = null; });

    try {
      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final data = {
        'fullName': _fullNameController.text.trim(),
        'about': _aboutController.text.trim(),
        'primaryCategoryId': _selectedCategoryId,
        'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
        'startingPrice': double.tryParse(_priceController.text.trim()) ?? 0,
        'serviceRadiusKm': double.tryParse(_radiusController.text.trim()) ?? 10,
        'skills': skillsList,
      };

      final res = await WorkerService.updateMyWorkerProfile(data);

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Worker profile saved successfully!', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        setState(() => _error = res['message'] as String? ?? 'Failed to save profile.');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: widget.primary,
        foregroundColor: Colors.white,
        title: Text('Setup Worker Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Your Professional Details',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    Text(
                      'This information will be displayed to potential customers',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                    ),

                    const SizedBox(height: 24),

                    // Full Name
                    _FieldLabel('Full Name *'),
                    const SizedBox(height: 6),
                    _InputField(
                      controller: _fullNameController,
                      hint: 'e.g. Ramesh Kumar',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Primary Category
                    _FieldLabel('Primary Category *'),
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

                    // Experience & Starting Price Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Experience (Years)'),
                              const SizedBox(height: 6),
                              _InputField(
                                controller: _experienceController,
                                hint: 'e.g. 5',
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
                              _FieldLabel('Starting Rate (₹)'),
                              const SizedBox(height: 6),
                              _InputField(
                                controller: _priceController,
                                hint: 'e.g. 300',
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Service Radius
                    _FieldLabel('Service Radius (km)'),
                    const SizedBox(height: 6),
                    _InputField(
                      controller: _radiusController,
                      hint: 'e.g. 15',
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    // Skills (comma separated)
                    _FieldLabel('Skills (Comma Separated)'),
                    const SizedBox(height: 6),
                    _InputField(
                      controller: _skillsController,
                      hint: 'e.g. Wiring, Inverter, Plumbing, Leakage Repair',
                    ),

                    const SizedBox(height: 16),

                    // About
                    _FieldLabel('About Yourself / Bio'),
                    const SizedBox(height: 6),
                    _InputField(
                      controller: _aboutController,
                      hint: 'e.g. Certified electrician with 10 years experience in Delhi NCR',
                      maxLines: 3,
                    ),

                    // Error
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 13)),
                    ],

                    const SizedBox(height: 28),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('Save Profile ✅', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF333333)),
    );
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
