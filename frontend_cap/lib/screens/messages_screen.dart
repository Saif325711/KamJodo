import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: kCapPrimary,
        foregroundColor: Colors.white,
        title: Text('Messages', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Messages',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Chat with customers here\nComing soon in Phase 5 (Realtime)',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
