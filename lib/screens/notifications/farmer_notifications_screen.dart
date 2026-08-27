import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme.dart';
import '../../services/auth_service.dart';
import '../../services/medicamento_service.dart';

class FarmerNotificationsScreen extends StatefulWidget {
  const FarmerNotificationsScreen({super.key});

  @override
  State<FarmerNotificationsScreen> createState() => _FarmerNotificationsScreenState();
}

class _FarmerNotificationsScreenState extends State<FarmerNotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _alertasCriticas = [];
  List<dynamic> _alertasVencimiento = [];
  String? _error;
  final MedicamentoService _medService = MedicamentoService();

  @override
  void initState() {
    super.initState();
    _loadAlertas();
  }

  Future<void> _loadAlertas() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = AuthService();
      String? farmaciaId = await authService.getLocalFarmaciaId();

      if (farmaciaId == null) {
        if (mounted) {
          setState(() {
            _error = 'No se encontró farmacia asociada.';
            _isLoading = false;
          });
        }
        return;
      }

      // Obtener alertas desde Firestore
      final alertas = await _medService.getStockAlerts(farmaciaId);

      if (mounted) {
        setState(() {
          _alertasCriticas = alertas;
          // Por ahora, simulamos alertas de vencimiento o las filtramos si el modelo lo permite
          _alertasVencimiento = []; 
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al conectar con Firestore: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAlertas = _alertasCriticas.length + _alertasVencimiento.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Alertas Operativas', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppTheme.danger),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadAlertas, child: const Text('Reintentar'))
                    ],
                  ),
                )
              : totalAlertas == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.success),
                          const SizedBox(height: 16),
                          Text('Todo en orden. No hay alertas.', style: GoogleFonts.manrope(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAlertas,
                      color: AppTheme.brandGreen,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_alertasCriticas.isNotEmpty) ...[
                            Text('STOCK CRÍTICO', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.danger, letterSpacing: 1.2)),
                            const SizedBox(height: 8),
                            ..._alertasCriticas.map((alerta) => _buildAlertCard(alerta, true, isDark)).toList(),
                            const SizedBox(height: 16),
                          ],
                          if (_alertasVencimiento.isNotEmpty) ...[
                            Text('PRÓXIMOS A VENCER', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.warning, letterSpacing: 1.2)),
                            const SizedBox(height: 8),
                            ..._alertasVencimiento.map((alerta) => _buildAlertCard(alerta, false, isDark)).toList(),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildAlertCard(dynamic alerta, bool isCritico, bool isDark) {
    final nombre = alerta['medicamento'] ?? 'Medicamento';
    final lote = alerta['codigo_lote'] ?? 'Lote N/A';
    final stock = alerta['cantidad_actual'] ?? 0;
    
    String subtitle = isCritico 
        ? 'Stock crítico: $stock unidades restantes.'
        : 'Próximo a vencer. (Stock: $stock)';

    if (!isCritico && alerta['fecha_vencimiento'] != null) {
        final fecha = DateTime.tryParse(alerta['fecha_vencimiento'].toString());
        if (fecha != null) {
            final diff = fecha.difference(DateTime.now()).inDays;
            subtitle = 'Vence en $diff días. (Stock: $stock)';
        }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isCritico ? AppTheme.danger.withOpacity(0.5) : AppTheme.warning.withOpacity(0.5))),
      elevation: 0,
      color: isCritico ? AppTheme.danger.withOpacity(0.05) : AppTheme.warning.withOpacity(0.05),
      child: ListTile(
        leading: Icon(
          isCritico ? Icons.warning_rounded : Icons.calendar_today_rounded,
          color: isCritico ? AppTheme.danger : AppTheme.warning,
          size: 32,
        ),
        title: Text('$nombre (Lote: $lote)', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        trailing: IconButton(
          icon: Icon(Icons.arrow_forward_ios, size: 16, color: isCritico ? AppTheme.danger : AppTheme.warning),
          onPressed: () {
            Navigator.pushNamed(context, '/inventory-list');
          },
        ),
      ),
    );
  }
}
