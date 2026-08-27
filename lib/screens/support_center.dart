import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:farmacia_app/services/auth_service.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  final AuthService _authService = AuthService();
  String _userRole = 'cliente';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  void _loadRole() async {
    final role = await _authService.getSavedRole();
    if (mounted) setState(() => _userRole = role ?? 'cliente');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final questions = _userRole == 'farmaceutico' ? _pharmacistFAQ : _clientFAQ;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.softGrey,
      appBar: AppBar(
        title: Text('Centro de Ayuda', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/my-reports'),
            icon: const Icon(Icons.history_rounded, color: AppTheme.brandGreen),
            tooltip: 'Mis Consultas',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿En qué podemos ayudarte?',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Consulta nuestras preguntas frecuentes o contacta a un operador.',
              style: TextStyle(color: isDark ? Colors.white60 : AppTheme.neutralGrey),
            ),
            const SizedBox(height: 24),
            ...questions.map((faq) => _buildFAQItem(faq, isDark)).toList(),
            const SizedBox(height: 40),
            _buildSupportCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, String> faq, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(
          faq['q']!,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : AppTheme.darkText,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq['a']!,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [AppTheme.darkSurface, Colors.black] 
            : [AppTheme.brandGreen, const Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            '¿No encontraste lo que buscabas?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Un operador del Administrador Maestro está disponible para ayudarte.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/report-problem'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.brandGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('CONTACTAR OPERADOR', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, String>> _clientFAQ = [
    {
      'q': '¿Cómo verifico si un medicamento es auténtico?',
      'a': 'Usa el botón de cámara en la pantalla principal para escanear el código QR o GTIN del empaque. El sistema te dirá instantáneamente si es original o sospechoso.'
    },
    {
      'q': '¿Qué hago si encuentro un producto falso?',
      'a': 'Debes reportarlo inmediatamente usando el botón "Reportar Problema". Toma una foto de la evidencia y describe dónde lo adquiriste para que el Administrador Maestro tome medidas.'
    },
    {
      'q': '¿La aplicación muestra precios reales?',
      'a': 'Sí, los precios son actualizados por las propias farmacias en tiempo real. Puedes comparar precios entre diferentes sucursales cercanas.'
    },
  ];

  final List<Map<String, String>> _pharmacistFAQ = [
    {
      'q': '¿Cómo cargo mi inventario masivamente?',
      'a': 'Puedes usar el escáner para registrar productos uno por uno o solicitar al Administrador Maestro la carga mediante un archivo CSV desde el panel web.'
    },
    {
      'q': 'Mi farmacia aparece como suspendida.',
      'a': 'Si tu farmacia está inactiva, contacta con el soporte técnico. Esto puede deberse a falta de actualización de documentos sanitarios o reportes de usuarios pendientes.'
    },
    {
      'q': '¿Cómo genero reportes de vencimiento?',
      'a': 'En la pestaña "Reportes", el sistema resalta automáticamente los lotes que vencerán en los próximos 3 meses para que puedas gestionarlos.'
    },
  ];
}
