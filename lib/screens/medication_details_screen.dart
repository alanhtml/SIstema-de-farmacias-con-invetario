import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> medication;

  const MedicationDetailsScreen({super.key, required this.medication});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final farmacia = medication['farmacia'] as Map<String, dynamic>?;
    final maestro = medication['maestro'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        title: Text(medication['nombre'] ?? 'Detalles del Medicamento', 
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.darkText),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(maestro?['imagen_base64'] ?? medication['imagen_base64']),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(isDark),
                  const Divider(height: 40),
                  _buildPharmacySection(farmacia, isDark, context),
                  const SizedBox(height: 24),
                  _buildTechnicalDetails(maestro, medication, isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(farmacia, context),
    );
  }

  Widget _buildImageHeader(String? base64Image) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: base64Image != null
          ? Image.memory(base64Decode(base64Image), fit: BoxFit.contain)
          : const Icon(Icons.medication, size: 100, color: AppTheme.brandGreen),
    );
  }

  Widget _buildHeaderInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                medication['nombre'] ?? 'Sin nombre',
                style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.darkText),
              ),
            ),
            Text(
              'Bs. ${medication['precio'] ?? '0.00'}',
              style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.brandGreen),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          medication['principio_activo'] ?? 'Sin principio activo',
          style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : AppTheme.neutralGrey, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        _Badge(
          label: (int.tryParse(medication['stock_actual']?.toString() ?? '0') ?? 0) > 0 ? 'EN STOCK' : 'SIN STOCK',
          color: (int.tryParse(medication['stock_actual']?.toString() ?? '0') ?? 0) > 0 ? AppTheme.success : AppTheme.danger,
        ),
      ],
    );
  }

  Widget _buildPharmacySection(Map<String, dynamic>? farmacia, bool isDark, BuildContext context) {
    if (farmacia == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DISPONIBLE EN', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neutralGrey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPharmacyLogo(farmacia['foto_fachada_base64']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farmacia['nombre'] ?? 'Farmacia', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(farmacia['direccion'] ?? 'Dirección no disponible', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : AppTheme.neutralGrey)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.directions_rounded, color: AppTheme.brandGreen),
                onPressed: () => _openMap(farmacia['latitud'], farmacia['longitud']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyLogo(String? base64) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(color: AppTheme.softGrey, borderRadius: BorderRadius.circular(10)),
      child: base64 != null
          ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(base64Decode(base64), fit: BoxFit.cover))
          : const Icon(Icons.local_pharmacy, color: AppTheme.brandGreen),
    );
  }

  Widget _buildTechnicalDetails(Map<String, dynamic>? maestro, Map<String, dynamic> inventory, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INFORMACIÓN TÉCNICA', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neutralGrey, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        _buildInfoRow('Presentación', maestro?['presentacion'] ?? 'No especificada', Icons.inventory_2_outlined, isDark),
        _buildInfoRow('Laboratorio', maestro?['laboratorio'] ?? 'No especificado', Icons.factory_outlined, isDark),
        _buildInfoRow('Registro Sanitario', maestro?['registro_sanitario'] ?? 'No disponible', Icons.verified_user_outlined, isDark),
        _buildInfoRow('Categoría', maestro?['categoria'] ?? 'General', Icons.category_outlined, isDark),
        if (maestro?['descripcion'] != null) ...[
          const SizedBox(height: 16),
          Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.darkText)),
          const SizedBox(height: 4),
          Text(maestro!['descripcion'], style: TextStyle(color: isDark ? Colors.white60 : AppTheme.neutralGrey, height: 1.5)),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.brandGreen.withOpacity(0.7)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.neutralGrey, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppTheme.darkText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Map<String, dynamic>? farmacia, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: farmacia?['telefono'] != null ? () => launchUrl(Uri.parse('tel:${farmacia!['telefono']}')) : null,
              icon: const Icon(Icons.phone),
              label: const Text('LLAMAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(color: AppTheme.brandGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.share, color: AppTheme.brandGreen),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
    );
  }
}
