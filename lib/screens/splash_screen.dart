import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Pequeño delay para que se vea la animación
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final authService = AuthService();
    // Re-inicializamos para estar seguros de tener el rol más actual
    final role = await authService.initializeAuth();

    if (!mounted) return;

    if (role == null) {
      debugPrint('🚫 Splash: Sin sesión activa, yendo a Welcome');
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    final cleanRole = role.trim().toLowerCase();
    debugPrint('🚀 Splash: Sesión detectada para rol: $cleanRole');

    if (cleanRole == 'farmaceutico') {
      Navigator.pushReplacementNamed(context, '/main_farmer');
    } else if (cleanRole == 'cliente' || cleanRole == 'usuario') {
      Navigator.pushReplacementNamed(context, '/main_client');
    } else {
      debugPrint('⚠️ Splash: Rol desconocido "$cleanRole", yendo a Welcome');
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: Image.asset(
                      'assets/images/logo_completo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.local_pharmacy_rounded,
                        size: 72,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(height: 8),
                  Text('SEGURIDAD FARMACÉUTICA', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), letterSpacing: 1.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 60),
                  const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
