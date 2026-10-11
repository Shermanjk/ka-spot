import 'package:flutter/material.dart';
import '../widgets/interactive_nav_bar.dart';
import 'connections_screen.dart';
import 'map_screen.dart';
import 'places_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const MapScreen(key: ValueKey('tab_map')),
      const ConnectionsScreen(key: ValueKey('tab_connections')),
      const PlacesScreen(key: ValueKey('tab_places')),
      const ProfileScreen(key: ValueKey('tab_profile')),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selected,
        children: screens,
      ),
      bottomNavigationBar: InteractiveNavBar(
        selectedIndex: _selected,
        onTap: (index) => setState(() => _selected = index),
        items: const [
          InteractiveNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore_rounded,
            label: 'Map',
          ),
          InteractiveNavItem(
            icon: Icons.people_outline_rounded,
            selectedIcon: Icons.people_rounded,
            label: 'Circle',
          ),
          InteractiveNavItem(
            icon: Icons.place_outlined,
            selectedIcon: Icons.place_rounded,
            label: 'Places',
          ),
          InteractiveNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'You',
          ),
        ],
      ),
    );
  }
}
