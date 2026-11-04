import 'package:flutter/material.dart';

import 'package:motora/core/components/glass_bottom_nav.dart';

import 'package:motora/features/home/presentation/pages/home_page.dart';
import 'package:motora/features/favorites/presentation/pages/favorites_page.dart';
import 'package:motora/features/inquiries/presentation/pages/inquiries_page.dart';
import 'package:motora/features/dealership/presentation/pages/dealerships_page.dart';
import 'package:motora/features/profile/presentation/pages/profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<GlassNavItem> _navItems = [
    GlassNavItem(
      icon: Icons.home_rounded,
      label: 'Home',
    ),
    GlassNavItem(
      icon: Icons.favorite_rounded,
      label: 'Favorites',
    ),
    GlassNavItem(
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Inquiries',
    ),
    GlassNavItem(
      icon: Icons.storefront_rounded,
      label: 'Dealerships',
    ),
    GlassNavItem(
      icon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  late final List<Widget> _pages = [
    const HomePage(),
    const FavoritesPage(),
    const InquiriesPage(),
    const DealershipsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101114),
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}