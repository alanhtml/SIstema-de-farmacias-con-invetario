import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme.dart';
import '../../services/medicamento_service.dart';

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({super.key});

  @override
  State<ClientNotificationsScreen> createState() => _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState extends State<ClientNotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _reportes = [];
  String? _error;
  final MedicamentoService _medService = MedicamentoService();

  @override
  void initState() {
    super.initState();
    _loadReportes();
  }

  Future<void> _loadReportes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reportes = await _medService.getPublicReports();
      setState(() {
        _reportes = reportes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar alertas desde Firestore';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Alertas Comunitarias', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 64, color: AppTheme.danger),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadReportes, child: const Text('Reintentar'))
                    ],
                  ),
                )
              : _reportes.isEmpty
                  ? Center(
                      child: Text('No hay alertas recientes.', 
                        style: GoogleFonts.manrope(fontSize: 16, color: Colors.grey)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReportes,
                      color: AppTheme.brandGreen,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reportes.length,
                        itemBuilder: (context, index) {
                          final reporte = _reportes[index];
                          final farmaco = reporte['medicamento_nombre'] ?? 'Medicamento no especificado';
                          final estado = reporte['estado'] ?? 'pendiente';
                          final fecha = reporte['fecha'] != null ? DateTime.tryParse(reporte['fecha'].toString()) : null;
                          final farmaciaNombre = reporte['farmacia_nombre'] ?? 'Farmacia Desconocida';
                          final farmaciaDireccion = reporte['farmacia_direccion'] ?? 'Dirección desconocida';
                          
                          Color iconColor = AppTheme.brandGreen;
                          IconData iconData = Icons.info_outline;

                          if (estado.toLowerCase() == 'pendiente' || estado.toLowerCase() == 'sospechoso') {
                            iconColor = AppTheme.warning;
                            iconData = Icons.report_problem_rounded;
                          } else if (estado.toLowerCase() == 'rechazado' || estado.toLowerCase() == 'critico') {
                            iconColor = AppTheme.danger;
                            iconData = Icons.error_outline_rounded;
                          } else {
                            iconColor = AppTheme.brandGreen;
                            iconData = Icons.verified_user_rounded;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: isDark ? 0 : 2,
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: iconColor.withOpacity(0.1),
                                    child: Icon(iconData, color: iconColor),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(farmaco, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text(reporte['descripcion'] ?? 'Sin detalles adicionales', 
                                          style: GoogleFonts.manrope(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.local_pharmacy_rounded, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '$farmaciaNombre - $farmaciaDireccion',
                                                style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'ESTADO: ${estado.toUpperCase()}', 
                                              style: GoogleFonts.manrope(fontSize: 11, color: iconColor, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                                            ),
                                            if (fecha != null)
                                              Text(
                                                '${fecha.day}/${fecha.month}/${fecha.year}', 
                                                style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey)
                                              ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
