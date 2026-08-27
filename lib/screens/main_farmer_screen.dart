import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'pharmacist_dashboard.dart';
import 'inventory_list.dart';
import 'sales_screen.dart';
import 'reports_screen.dart';

class MainFarmerScreen extends StatefulWidget {
  const MainFarmerScreen({super.key});

  @override
  State<MainFarmerScreen> createState() => _MainFarmerScreenState();
}

class _MainFarmerScreenState extends State<MainFarmerScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PharmacistDashboard(),
    const InventoryListScreen(),
    const SalesScreen(),
    const ReportsScreen(),
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
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
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
                icon: Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(Icons.grid_view_rounded, color: AppTheme.brandGreen),
                label: 'Panel',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded, color: AppTheme.brandGreen),
                label: 'Stock',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart_rounded, color: AppTheme.brandGreen),
                label: 'Ventas',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded, color: AppTheme.brandGreen),
                label: 'Reportes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
