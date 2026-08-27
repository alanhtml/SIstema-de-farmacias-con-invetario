import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmacia_app/theme/theme.dart';

class TraceabilityDetailScreen extends StatelessWidget {
  const TraceabilityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FCEF),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.darkText), onPressed: () => Navigator.pop(context)),
        title: Text('Detalle de Trazabilidad', style: GoogleFonts.manrope(color: AppTheme.darkText, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Identificador de Unidad:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Text('#UID-992834-X', style: TextStyle(color: AppTheme.brandGreen, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 24),
            _buildTechnicalSpecsCard(),
            const SizedBox(height: 20),
            _buildIntegrityAnalysisCard(),
            const SizedBox(height: 24),
            _buildCustodyHistory(),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalSpecsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _statusTag('AUTÉNTICO'),
            const SizedBox(height: 8),
            Text('Amoxicilina 500mg', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
          const Icon(Icons.qr_code_2, color: AppTheme.brandGreen, size: 40),
        ]),
        const SizedBox(height: 24),
        _specRow('GTIN', '07702011001234', 'LOTE', 'LOT-BF2024-01'),
        const SizedBox(height: 20),
        _specRow('EXPIRACIÓN', '12 OCT 2026', 'ID UNIDAD', 'U-29384-8821', isUrgent: true),
      ]),
    );
  }

  Widget _statusTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFBCF0B8), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF245027))),
    );
  }

  Widget _specRow(String l1, String v1, String l2, String v2, {bool isUrgent = false}) {
    return Row(children: [
      Expanded(child: _specItem(l1, v1, isUrgent: isUrgent)),
      Expanded(child: _specItem(l2, v2)),
    ]);
  }

  Widget _specItem(String label, String value, {bool isUrgent = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isUrgent ? const Color(0xFFAB2D57) : AppTheme.darkText)),
    ]);
  }

  Widget _buildIntegrityAnalysisCard() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFEFF6E9), borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
          child: Image.network('https://lh3.googleusercontent.com/aida-public/AB6AXuD3pbhEaSV5r4EpZVEeTWlqRHHkME1ugq5PXhQmoyivAXlrq4s2-1A6wxR3UPf-iHUQqDGWHW7FzSpsPk71fW0wuG6mzdLiRSgj0uDWdsKZxL6P-vrUjwirz643aN3Ecm-GhtnTTfWuulFbIETy-7ELg7HUN_pYkpQB6R9DfxXzQXlzNACjPcTXeTEVmlFhbu46_sOJs9Rxc7DWmmw_b-he1yO6D6E7JaCBo_QFEWXge7Yzm_Dgct8F526h0D7_NZ4SfxhUcbo7WR4', width: 100, height: 120, fit: BoxFit.cover),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Análisis de Integridad', style: TextStyle(fontWeight: FontWeight.w800)),
            const Text('La firma digital coincide. Sin alteraciones de cadena de frío.', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Wrap(spacing: 4, children: [_smallTag('Empaque: OK'), _smallTag('Sello: Verificado')]),
          ]),
        )),
      ]),
    );
  }

  Widget _smallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCustodyHistory() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Historial de Custodia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        _timelineStep(Icons.factory, 'Fabricación', 'Bio-Pharma S.A.', '05 ENE 2024', isFirst: true),
        _timelineStep(Icons.local_shipping, 'Distribución', 'Operador Logístico', '12 FEB 2024'),
        _timelineStep(Icons.local_pharmacy, 'En Farmacia', 'Central San José', '20 MAR 2024', isLast: true, isActive: true),
      ]),
    );
  }

  Widget _timelineStep(IconData icon, String title, String sub, String date, {bool isFirst = false, bool isLast = false, bool isActive = false}) {
    Color color = isActive ? AppTheme.brandGreen : Colors.grey;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
        if (!isLast) Container(width: 2, height: 40, color: Colors.black12),
      ]),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 20),
      ]),
    ]);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(children: [
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandGreen), child: const Text('GENERAR REPORTE PDF'))),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black12)), child: const Text('REPORTAR ANOMALÍA', style: TextStyle(color: AppTheme.darkText)))),
    ]);
  }
}


