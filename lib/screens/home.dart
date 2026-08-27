import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../services/auth_service.dart';

/// ClienteScannerDashboard — Pantalla principal del cliente/usuario.
/// Muestra un botón prominente para escanear medicamentos y opciones de navegación.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Usuario';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final auth = AuthService();
      final user = auth.currentUser;
      
      // Intentar SharedPreferences primero
      final savedName = await auth.getSavedName();
      if (savedName != null && mounted) {
        setState(() => _userName = savedName);
      }

      if (user != null) {
        final profile = await auth.getUserProfile(user.uid);
        if (mounted) {
          setState(() {
            _userName = profile?['nombre'] ?? user.displayName ?? savedName ?? 'Usuario';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_icono.png',
              height: 28,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.local_pharmacy_rounded, color: AppTheme.brandGreen, size: 28),
            ),
            const SizedBox(width: 10),
            Text('Medivida', style: GoogleFonts.manrope(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              AppTheme.themeNotifier.value =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserName,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo dinámico
              Text('¡Hola, $_userName!',
                  style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Verifica tus medicamentos fácilmente',
                  style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white60 : AppTheme.neutralGrey)),
              const SizedBox(height: 36),

              // Botón principal de escaneo
              _ScanHeroButton(
                onTap: () => Navigator.pushNamed(context, '/scanner'),
                isDark: isDark,
              ),
              const SizedBox(height: 32),

              // Información
              const Text('¿Cómo funciona?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              _StepTile(
                number: '1',
                title: 'Escanea el código',
                description:
                    'Apunta la cámara al código de barras del medicamento.',
                icon: Icons.qr_code_scanner_rounded,
                color: AppTheme.brandGreen,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _StepTile(
                number: '2',
                title: 'Verificación instantánea',
                description:
                    'El sistema verifica el código contra la base de datos de Medivida.',
                icon: Icons.verified_rounded,
                color: const Color(0xFF6366F1),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _StepTile(
                number: '3',
                title: 'Resultado claro',
                description:
                    'Recibes un indicador de color: verde (válido), amarillo (sospechoso), rojo (no encontrado).',
                icon: Icons.palette_rounded,
                color: AppTheme.warning,
                isDark: isDark,
              ),
              const SizedBox(height: 32),

              // Acciones secundarias
              const Text('Más opciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),

              _OptionTile(
                icon: Icons.search_rounded,
                label: 'Buscar medicamento',
                onTap: () => Navigator.pushNamed(context, '/medication-search'),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _OptionTile(
                icon: Icons.local_pharmacy_rounded,
                label: 'Farmacias registradas',
                onTap: () => Navigator.pushNamed(context, '/pharmacy-list'),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _OptionTile(
                icon: Icons.map_rounded,
                label: 'Red de Farmacias (Mapa)',
                onTap: () => Navigator.pushNamed(context, '/maps'),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _OptionTile(
                icon: Icons.help_outline_rounded,
                label: 'Centro de Ayuda y Soporte',
                onTap: () => Navigator.pushNamed(context, '/support-center'),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _OptionTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Mis Consultas',
                onTap: () => Navigator.pushNamed(context, '/my-reports'),
                isDark: isDark,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Widgets auxiliares ----------

class _ScanHeroButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _ScanHeroButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandGreen.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  size: 52, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              'Escanear Medicamento',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Toca para abrir la cámara',
              style: TextStyle(
                  fontSize: 14, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StepTile({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(number,
                  style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.manrope(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description,
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white54 : AppTheme.neutralGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.brandGreen, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.manrope(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: isDark ? Colors.white30 : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
