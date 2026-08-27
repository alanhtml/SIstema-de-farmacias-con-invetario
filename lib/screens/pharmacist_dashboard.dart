import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';
import '../theme/theme.dart';
import 'movements_screen.dart';
import '../services/auth_service.dart';

class PharmacistDashboard extends StatefulWidget {
  const PharmacistDashboard({super.key});

  @override
  State<PharmacistDashboard> createState() => _PharmacistDashboardState();
}

class _PharmacistDashboardState extends State<PharmacistDashboard> {
  bool _loading = true;
  String? _error;
  int _totalStock = 0;
  int _alertas = 0;
  int _movimientosHoy = 0;
  int _ventasHoy = 0;
  double _ingresosHoy = 0.0;
  String _userName = 'Farmacéutico';
  dynamic _farmaciaId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final profile = await AuthService().getUserProfile(user.uid).timeout(const Duration(seconds: 10));
        
        if (mounted) {
          setState(() {
            _userName = profile?['nombre'] ?? user.displayName ?? 'Farmacéutico';
            _farmaciaId = profile?['farmacia_id'];
          });
        }
      }

      if (_farmaciaId != null) {
        final stats = await AuthService().getDashboardStats(_farmaciaId.toString());
        if (mounted) {
          final data = stats['data'] ?? {};
          setState(() {
            _totalStock = data['total_stock'] ?? 0;
            _alertas = data['alerts'] ?? 0;
            _movimientosHoy = data['scans_today'] ?? 0;
            _ventasHoy = data['ventas_hoy'] ?? 0;
            _ingresosHoy = (data['ingresos_hoy'] ?? 0.0).toDouble();
            _loading = false;
          });
          if (_alertas > 0) _showAutoAlert();
        }
      } else {
        if (mounted) {
          setState(() {
            _error = "No se encontró información de la farmacia vinculada.";
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error de inicialización: $e';
          _loading = false;
        });
      }
    }
  }

  void _showAutoAlert() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 28),
              const SizedBox(width: 12),
              Text('¡Atención de Stock!', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text('Existen medicamentos próximos a vencer o con stock crítico. Revisa los reportes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ENTENDIDO', style: TextStyle(color: AppTheme.brandGreen, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/report');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandGreen),
              child: const Text('VER REPORTES', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    });
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
            onPressed: () => AppTheme.themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
          : _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildContent(isDark),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.danger),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text('¡Hola, $_userName!', style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Panel de Control Farmacéutico', style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : AppTheme.neutralGrey)),
        const SizedBox(height: 28),
        
        Text('Servicios y Soporte', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        
        _ActionButton(
          icon: Icons.edit_location_alt_rounded,
          label: 'Gestionar Farmacia',
          subtitle: 'Cambiar nombre, foto o teléfono',
          color: AppTheme.brandGreen,
          onTap: () async {
            if (_farmaciaId != null) {
              final result = await Navigator.pushNamed(
                context, 
                '/edit-pharmacy', 
                arguments: _farmaciaId.toString()
              );
              if (result == true) _loadData();
            }
          },
        ),

        const SizedBox(height: 12),
        
        _ActionButton(
          icon: Icons.support_agent_rounded,
          label: 'Servicio al Cliente',
          subtitle: 'Ayuda técnica y reportes oficiales',
          color: AppTheme.danger,
          onTap: () => Navigator.pushNamed(context, '/support-center'),
        ),

        const SizedBox(height: 100),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : AppTheme.neutralGrey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

class _StatCardSmall extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCardSmall({required this.icon, required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppTheme.neutralGrey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppTheme.neutralGrey)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
