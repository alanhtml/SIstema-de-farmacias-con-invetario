import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmacia_app/services/auth_service.dart';
import 'package:farmacia_app/services/farmacia_service.dart';
import 'package:farmacia_app/screens/error_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'movements_screen.dart';

class ReportsScreen extends StatefulWidget {
  final String? farmaciaId;
  const ReportsScreen({super.key, this.farmaciaId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final AuthService _authService = AuthService();
  final FarmaciaService _farmaciaService = FarmaciaService();
  Future<List<Map<String, dynamic>>>? _reportsFuture;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _initReports();
  }

  Future<void> _initReports() async {
    if (!mounted) return;
    String? fId = widget.farmaciaId;
    
    try {
      if (fId == null) {
        final user = _authService.currentUser;
        if (user != null) {
          final profile = await _authService.getUserProfile(user.uid);
          fId = profile?['farmacia_id'];
          
          if (fId == null) {
            final prefs = await SharedPreferences.getInstance();
            fId = prefs.getString('local_farmacia_string_id');
          }
        }
      }

      if (mounted) {
        if (fId != null) {
          setState(() {
            _reportsFuture = _farmaciaService.getInventoryReports(fId!);
            _isInitialLoading = false;
          });
        } else {
          setState(() {
            _isInitialLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  void _loadReports() {
    _initReports();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.softGrey,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppTheme.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Centro de Reportes',
          style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.darkText,
              fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/images/logo_icono.png',
              width: 32,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.medical_services, color: AppTheme.brandGreen),
            ),
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen));
                }
                if (snapshot.hasError || _reportsFuture == null) {
                  return ErrorView(
                    message: snapshot.error?.toString() ??
                        'No se pudo obtener la información del servidor local.',
                    onRetry: _loadReports,
                    isDark: isDark,
                  );
                }

                final rawData = snapshot.data ?? [];
                final data = rawData.map((item) => {
                  ...item,
                  'stock_actual': int.tryParse(item['stock_actual']?.toString() ?? '0') ?? 0,
                }).toList();

                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 64, color: AppTheme.brandGreen.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No hay alertas críticas de stock en este momento',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final criticalStock = data.where((item) => (item['stock_actual'] ?? 0) < 5).toList();

                final threshold = DateTime.now().add(const Duration(days: 30));
                final upcomingExpiry = data.where((item) {
                  final expiryDate = DateTime.tryParse(item['fecha_vencimiento'] ?? '');
                  return expiryDate != null && expiryDate.isBefore(threshold);
                }).toList();

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          'Stock Crítico (< 5 unidades)', Icons.inventory_2_outlined, isDark),
                      const SizedBox(height: 12),
                      _buildListContainer(
                        isDark: isDark,
                        child: criticalStock.isEmpty
                            ? _buildEmptyState('No hay productos con stock crítico', isDark)
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: criticalStock.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, color: isDark ? Colors.white10 : null),
                                itemBuilder: (context, index) {
                                  final item = criticalStock[index];
                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    title: Text(item['nombre'] ?? 'Sin nombre',
                                        style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: isDark ? Colors.white : AppTheme.darkText)),
                                    subtitle: Text('ID: ${item['id']}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white38 : Colors.grey.shade500)),
                                    trailing: Text('${item['stock_actual']} u.',
                                        style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.danger,
                                            fontSize: 15)),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle(
                          'Historial de Movimientos', Icons.history_rounded, isDark),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const MovementsScreen()));
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('VER TODOS LOS MOVIMIENTOS', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.brandGreen,
                            side: const BorderSide(color: AppTheme.brandGreen),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle(
                          'Próximos Vencimientos (30 días)', Icons.timer_outlined, isDark),
                      const SizedBox(height: 12),
                      _buildListContainer(
                        isDark: isDark,
                        child: upcomingExpiry.isEmpty
                            ? _buildEmptyState('No hay lotes próximos a vencer', isDark)
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: upcomingExpiry.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, color: isDark ? Colors.white10 : null),
                                itemBuilder: (context, index) {
                                  final item = upcomingExpiry[index];
                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    title: Text(item['nombre'] ?? 'Sin nombre',
                                        style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: isDark ? Colors.white : AppTheme.darkText)),
                                    subtitle: Text('Lote: ${item['lote'] ?? 'N/A'}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white38 : Colors.grey.shade500)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                          color: AppTheme.danger.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8)),
                                      child: Text(item['fecha_vencimiento'] ?? 'N/A',
                                          style: GoogleFonts.manrope(
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.danger,
                                              fontSize: 12)),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 40),
                      _buildGenerateButton(isDark),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: isDark ? AppTheme.brightGreen : AppTheme.brandGreen, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.darkText)),
      ],
    );
  }

  Widget _buildListContainer({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(message,
            style: GoogleFonts.manrope(
                color: isDark ? Colors.white38 : Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildGenerateButton(bool isDark) {
    final gradient = isDark
        ? const LinearGradient(
            colors: [AppTheme.brightGreen, Color(0xFF00BFA5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : AppTheme.primaryGradient;

    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: (isDark ? AppTheme.brightGreen : AppTheme.brandGreen).withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 6))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Generando reporte PDF...'), behavior: SnackBarBehavior.floating));
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf_rounded,
                    color: isDark ? Colors.black : Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('GENERAR REPORTE PDF',
                    style: GoogleFonts.manrope(
                        color: isDark ? Colors.black : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState({Object? error, required bool isDark}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.danger),
            const SizedBox(height: 16),
            Text('Error de Conexión',
                style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.darkText)),
            const SizedBox(height: 8),
            Text(
                error != null
                    ? 'Detalle: $error'
                    : 'No se pudo obtener la información del servidor local.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(color: isDark ? Colors.white70 : Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadReports,
              style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.brightGreen : AppTheme.brandGreen,
                  foregroundColor: isDark ? Colors.black : Colors.white),
              child: const Text('REINTENTAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

