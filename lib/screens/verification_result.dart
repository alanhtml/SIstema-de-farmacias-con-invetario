import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:farmacia_app/screens/report_problem.dart';

class VerificationResultScreen extends StatelessWidget {
  final String status;
  final Map<String, dynamic> data;
  final String? message;

  const VerificationResultScreen({
    super.key,
    this.status = 'error',
    this.data = const {},
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    switch (status) {
      case 'success':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle_rounded;
        statusTitle = 'Medicamento Válido';
        statusSubtitle = 'La autenticidad del producto ha sido verificada con éxito.';
        break;
      case 'warning':
        statusColor = AppTheme.warning;
        statusIcon = Icons.warning_rounded;
        statusTitle = 'Producto Sospechoso';
        statusSubtitle = 'Este producto tiene alertas de seguridad o está próximo a vencer.';
        break;
      case 'danger':
      case 'error':
      default:
        statusColor = AppTheme.danger;
        statusIcon = Icons.cancel_rounded;
        statusTitle = 'No Encontrado';
        statusSubtitle = message ?? 'Este medicamento no figura en nuestros registros de seguridad.';
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.softGrey,
      appBar: AppBar(
        title: Text('Resultado', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.darkText, size: 20), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(statusIcon, color: statusColor, size: 70),
            ),
            const SizedBox(height: 24),
            Text(statusTitle, style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.darkText)),
            const SizedBox(height: 8),
            Text(statusSubtitle, textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 15, color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            
            // Tarjeta de Detalles
            if (status != 'error' && data.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(left: BorderSide(color: statusColor, width: 6)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PRODUCTO', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(data['nombre'] ?? 'N/A', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: statusColor)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.medical_services_rounded, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text(data['descripcion'] ?? 'Antibiótico', style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey.shade500)),
                    ]),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildDetailCol('LOTE', data['numero_lote'] ?? 'N/A', isDark)),
                        Expanded(child: _buildDetailCol('EXPIRA', data['fecha_vencimiento'] ?? 'N/A', isDark)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetailCol('FABRICANTE', data['laboratorio'] ?? 'N/A', isDark),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            
            // Card de Farmacia Certificada (Solo si es exitoso)
            if (status == 'success')
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.verified_user_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Farmacia Certificada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Punto de venta verificado y oficial.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                        ],
                      ),
                    )
                  ],
                ),
              ),

            const SizedBox(height: 32),
            
            // Botón Reportar Problema
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => ReportProblemScreen(productData: data))
                );
              },
              icon: const Icon(Icons.report_problem_rounded, color: AppTheme.danger),
              label: Text('Reportar Problema', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.danger)),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.danger.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCol(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.darkText)),
      ],
    );
  }
}
