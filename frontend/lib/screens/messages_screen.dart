import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.edit_square))],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          _MessageTile(name: 'Aarav', subtitle: 'Let us post this tonight.', unread: true),
          _MessageTile(name: 'Maya', subtitle: 'The feed design looks great.', unread: false),
          _MessageTile(name: 'KamJodo Team', subtitle: 'New admin request waiting.', unread: true),
          _MessageTile(name: 'Riya', subtitle: 'I shared the profile mockups.', unread: false),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.name, required this.subtitle, required this.unread});

  final String name;
  final String subtitle;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Row(
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          if (unread)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFFE94A3F), shape: BoxShape.circle),
            ),
        ],
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
