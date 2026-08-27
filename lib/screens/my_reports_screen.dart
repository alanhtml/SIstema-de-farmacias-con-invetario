import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:farmacia_app/services/auth_service.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Inicia sesión para ver tus reportes')));
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.softGrey,
      appBar: AppBar(
        title: Text('Mis Consultas', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('reportes_incidencias')
            .where('usuario_id', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speaker_notes_off_outlined, size: 80, color: isDark ? Colors.white12 : Colors.grey.shade300),
                  const SizedBox(height: 20),
                  Text(
                    'No se encontraron consultas',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tu ID: ${user.uid.substring(0, 8)}...',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white10 : Colors.grey.shade300),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/report-problem'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandGreen),
                    child: const Text('CREAR NUEVA CONSULTA', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            );
          }

          // Ordenar manualmente en la app mientras se crea el índice en Firebase
          final sortedDocs = docs.toList()
            ..sort((a, b) {
              final aFecha = (a.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
              final bFecha = (b.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
              if (aFecha == null || bFecha == null) return 0;
              return bFecha.compareTo(aFecha); // Descendente
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final estado = data['estado'] ?? 'pendiente';
              final fecha = (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
              final respuestas = data['respuestas'] as List<dynamic>? ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if(!isDark) BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ExpansionTile(
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: _getStatusIcon(estado),
                  title: Text(
                    data['nombre_farmaco'] ?? data['descripcion'] ?? 'Consulta sin título',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.darkText,
                    ),
                  ),
                  subtitle: Text(
                    'Enviado el ${fecha.day}/${fecha.month}/${fecha.year}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 10),
                          _buildChatBubble(
                            message: data['descripcion'] ?? '',
                            isMe: true,
                            isDark: isDark,
                          ),
                          ...respuestas.map((res) => _buildChatBubble(
                                message: res['mensaje'] ?? '',
                                isMe: false,
                                isDark: isDark,
                                sender: res['remitente'],
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getStatusIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'resuelto': return const Icon(Icons.check_circle, color: AppTheme.success);
      case 'en proceso': return const Icon(Icons.timelapse, color: Colors.blue);
      default: return const Icon(Icons.info_outline, color: Colors.orange);
    }
  }

  Widget _buildChatBubble({required String message, required bool isMe, required bool isDark, String? sender}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe 
              ? (isDark ? AppTheme.brightGreen.withOpacity(0.1) : AppTheme.brandGreen.withOpacity(0.1))
              : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && sender != null)
              Text(sender, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.brandGreen)),
            Text(message, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppTheme.darkText)),
          ],
        ),
      ),
    );
  }
}
