import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _FeedPostCard(index: index),
      ),
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Creator ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('2h ago'),
            trailing: const Icon(Icons.more_horiz),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.primaries[index % Colors.primaries.length].shade400,
                    Colors.black,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'New post preview',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'A clean feed layout for posts, reels, and updates.',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Icon(Icons.favorite_border, size: 20),
                SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline, size: 20),
                SizedBox(width: 16),
                Icon(Icons.send_outlined, size: 20),
                Spacer(),
                Icon(Icons.bookmark_border, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
