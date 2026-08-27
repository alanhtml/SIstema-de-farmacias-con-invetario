import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'home.dart';
import 'medication_search.dart';
import 'map_screen.dart';
import 'profile.dart';

class MainClientScreen extends StatefulWidget {
  const MainClientScreen({super.key});

  @override
  State<MainClientScreen> createState() => _MainClientScreenState();
}

class _MainClientScreenState extends State<MainClientScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MedicationSearchScreen(),
    const MapScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          indicatorColor: AppTheme.brandGreen.withOpacity(0.15),
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.brandGreen),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.search_rounded, color: AppTheme.brandGreen),
              label: 'Buscar',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: AppTheme.brandGreen),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.brandGreen),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
