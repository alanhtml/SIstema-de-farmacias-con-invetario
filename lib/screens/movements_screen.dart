import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';

class MovementsScreen extends StatelessWidget {
  const MovementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Movimientos', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Historial de Actividad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _buildHistoryItem(Icons.add_task_rounded, 'Lote registrado con éxito', 'Hace 5 minutos', AppTheme.brandGreen, isDark),
          _buildHistoryItem(Icons.verified_user_rounded, 'Medicamento verificado', 'Hace 20 minutos', const Color(0xFF6366F1), isDark),
          _buildHistoryItem(Icons.inventory_2_rounded, 'Actualización de stock', 'Hace 1 hora', const Color(0xFF0EA5E9), isDark),
          _buildHistoryItem(Icons.warning_amber_rounded, 'Alerta de vencimiento revisada', 'Hace 3 horas', AppTheme.warning, isDark),
          _buildHistoryItem(Icons.edit_note_rounded, 'Perfil de farmacia actualizado', 'Hace 5 horas', const Color(0xFF0EA5E9), isDark),
          _buildHistoryItem(Icons.add_task_rounded, 'Nuevo medicamento registrado', 'Ayer', AppTheme.brandGreen, isDark),
          _buildHistoryItem(Icons.verified_user_rounded, 'Medicamento verificado', 'Ayer', const Color(0xFF6366F1), isDark),
          _buildHistoryItem(Icons.inventory_2_rounded, 'Salida de stock (Venta)', 'Ayer', AppTheme.danger, isDark),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(IconData icon, String title, String time, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(time, style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey)),
        dense: true,
      ),
    );
  }
}
