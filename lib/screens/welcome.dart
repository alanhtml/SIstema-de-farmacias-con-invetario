import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:farmacia_app/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:farmacia_app/screens/register.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      
      if (!mounted) return;

      if (result == 'NEW_USER') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RegisterScreen(isSocialRegister: true),
          ),
        );
      } else if (result != null) {
        _processLoginResult(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error con Google: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processLoginResult(String? role) {
    debugPrint('🚀 WelcomeScreen: Procesando resultado de login. Rol recibido: "$role"');
    
    if (!mounted) return;

    if (role == null) {
      debugPrint('❌ Error: El rol es null');
      return;
    }

    final cleanRole = role.trim().toLowerCase();

    if (cleanRole == 'farmaceutico') {
      debugPrint('✅ Redirigiendo a Dashboard de Farmacéutico');
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    } else if (cleanRole == 'cliente' || cleanRole == 'usuario') {
      debugPrint('✅ Redirigiendo a Home de Cliente');
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      debugPrint('⚠️ Rol no reconocido: "$cleanRole"');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perfil incompleto: $cleanRole'), backgroundColor: AppTheme.warning),
      );
    }
  }

  Future<void> _handleEmailLogin() async {
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/logo_completo.png',
                width: 280,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.medical_services, size: 100, color: AppTheme.brandGreen),
              ),
              const SizedBox(height: 40),
              Text(
                'Seguridad en cada dosis',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Verifica la autenticidad de tus medicamentos y gestiona tu inventario con Google.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              
              // BOTÓN PRINCIPAL: GOOGLE
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 18),
                  label: Text(
                    'CONTINUAR CON GOOGLE',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4), // Google Blue
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // OPCIÓN SECUNDARIA: CORREO
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleEmailLogin,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'INGRESAR CON CORREO',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                      letterSpacing: 0.5
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text.rich(
                  TextSpan(
                    text: '¿Eres nuevo? ',
                    style: TextStyle(color: Colors.grey.shade600),
                    children: const [
                      TextSpan(
                        text: 'Crea una cuenta manual',
                        style: TextStyle(color: AppTheme.brandGreen, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
