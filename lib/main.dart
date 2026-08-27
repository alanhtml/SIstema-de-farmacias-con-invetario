import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:farmacia_app/screens/map_screen.dart';
import 'package:farmacia_app/screens/login.dart';
import 'package:farmacia_app/screens/register.dart';
import 'package:farmacia_app/screens/home.dart';
import 'package:farmacia_app/screens/profile.dart';
import 'package:farmacia_app/screens/pharmacist_dashboard.dart';
import 'package:farmacia_app/screens/main_client_screen.dart';
import 'package:farmacia_app/screens/main_farmer_screen.dart';
import 'package:farmacia_app/screens/welcome.dart';
import 'package:farmacia_app/screens/inventory_list.dart';
import 'package:farmacia_app/screens/medication_search.dart';
import 'package:farmacia_app/screens/verification_result.dart';
import 'package:farmacia_app/screens/register_medicine.dart';
import 'package:farmacia_app/screens/scanner.dart';
import 'package:farmacia_app/screens/reports_screen.dart';
import 'package:farmacia_app/screens/trazabilidad_detail.dart';
import 'package:farmacia_app/screens/register_lote.dart';
import 'package:farmacia_app/screens/splash_screen.dart';
import 'package:farmacia_app/screens/movements_screen.dart';
import 'package:farmacia_app/screens/report_problem.dart';
import 'package:farmacia_app/screens/support_center.dart';
import 'package:farmacia_app/screens/my_reports_screen.dart';
import 'package:farmacia_app/screens/pharmacy_list_screen.dart';
import 'package:farmacia_app/screens/pharmacy_details_screen.dart';
 import 'package:farmacia_app/screens/edit_pharmacy_screen.dart';
import 'package:farmacia_app/screens/medication_details_screen.dart';
import 'package:farmacia_app/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Inicializar App Check para evitar bloqueos en el registro (RF-01)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Inicializar Auth y cargar rol si hay sesión
  final authService = AuthService();
  
  final String? initialRole = await authService.initializeAuth();

  runApp(FarmaciaApp(initialRole: initialRole));
}

class FarmaciaApp extends StatelessWidget {
  final String? initialRole;
  const FarmaciaApp({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Medivida',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          initialRoute: _getInitialRoute(),
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/main_client': (context) => const MainClientScreen(),
            '/main_farmer': (context) => const MainFarmerScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/dashboard': (context) => const PharmacistDashboard(),
            '/scanner': (context) => const ScannerScreen(),
            '/maps': (context) => const MapScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/register-medicine': (context) => const RegisterMedicineScreen(),
            '/inventory-list': (context) => const InventoryListScreen(),
            '/medication-search': (context) => const MedicationSearchScreen(),
            '/pharmacy-list': (context) => const PharmacyListScreen(),
            '/verification-result': (context) => const VerificationResultScreen(),
            '/report': (context) => const ReportsScreen(),
            '/movements': (context) => const MovementsScreen(),
            '/traceability-detail': (context) => const TraceabilityDetailScreen(),
            '/registro-lote': (context) => const RegisterLoteScreen(),
            '/report-problem': (context) => const ReportProblemScreen(),
            '/support-center': (context) => const SupportCenterScreen(),
            '/my-reports': (context) => const MyReportsScreen(),
            '/pharmacy-detail': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return PharmacyDetailsScreen(farmacia: args);
            },
            '/edit-pharmacy': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as String;
              return EditPharmacyScreen(farmaciaId: args);
            },
            '/medication-detail': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return MedicationDetailsScreen(medication: args);
            },
          },
        );
      },
    );
  }

  String _getInitialRoute() {
    if (initialRole == null) return '/';
    final role = initialRole!.trim().toLowerCase();
    if (role == 'suspendido') return '/login'; // Si está suspendido, forzar login
    if (role == 'farmaceutico') return '/main_farmer';
    return '/main_client';
  }
}
