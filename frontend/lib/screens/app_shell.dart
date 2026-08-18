import 'package:flutter/material.dart';

import 'feed_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.dynamic_feed_outlined), activeIcon: Icon(Icons.dynamic_feed), label: 'Feed'),
    BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Message'),
    BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Search'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(
        primary: widget.primary,
        secondary: widget.secondary,
        tertiary: widget.tertiary,
      ),
      const FeedScreen(),
      const MessagesScreen(),
      SearchScreen(
        primary: widget.primary,
        secondary: widget.secondary,
        tertiary: widget.tertiary,
      ),
      ProfileScreen(
        primary: widget.primary,
        secondary: widget.secondary,
        tertiary: widget.tertiary,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.primary, widget.secondary, widget.tertiary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: _navItems,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white60,
            showUnselectedLabels: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
