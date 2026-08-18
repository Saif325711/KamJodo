import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    this.categoryId,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final String workerId;
  final String workerName;
  final String? categoryId;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _scheduledAt;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: widget.secondary),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: widget.secondary),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    });
  }

  Future<void> _submitBooking() async {
    if (_descController.text.trim().isEmpty) {
      setState(() => _error = 'Please describe the required work.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await BookingService.createBooking(
        workerId: widget.workerId,
        categoryId: widget.categoryId,
        description: _descController.text.trim(),
        notes: _notesController.text.trim(),
        scheduledAt: _scheduledAt,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking request sent! The worker will review it shortly.', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        setState(() => _error = result['message'] as String? ?? 'Booking failed.');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: widget.primary,
        foregroundColor: Colors.white,
        title: Text('Book ${widget.workerName}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [widget.primary, widget.secondary]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.engineering_outlined, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.workerName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Service Booking Request', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Description ───────────────────────────────────────────────
            _SectionLabel('Describe the required work *'),
            const SizedBox(height: 8),
            _InputBox(
              controller: _descController,
              hint: 'e.g. Bathroom pipe blockage repair needed urgently',
              maxLines: 4,
            ),

            const SizedBox(height: 20),

            // ── Scheduled Date ────────────────────────────────────────────
            _SectionLabel('Select Date & Time (Optional)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: widget.secondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _scheduledAt != null
                            ? '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year}  ${_scheduledAt!.hour.toString().padLeft(2,'0')}:${_scheduledAt!.minute.toString().padLeft(2,'0')}'
                            : 'Tap to select preferred date & time',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _scheduledAt != null ? const Color(0xFF111111) : Colors.grey,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Notes ─────────────────────────────────────────────────────
            _SectionLabel('Additional Instructions / Notes (Optional)'),
            const SizedBox(height: 8),
            _InputBox(
              controller: _notesController,
              hint: 'e.g. Call 10 minutes before arrival',
              maxLines: 2,
            ),

            // ── Error ─────────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 13))),
              ]),
            ],

            const SizedBox(height: 32),

            // ── Submit ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('Send Booking Request 🚀', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'The worker will review and accept your request shortly.',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF333333)));
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.controller, required this.hint, this.maxLines = 1});
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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
