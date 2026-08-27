import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:farmacia_app/services/medicamento_service.dart';
import 'package:farmacia_app/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

class ReportProblemScreen extends StatefulWidget {
  final Map<String, dynamic>? productData;
  const ReportProblemScreen({super.key, this.productData});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _medService = MedicamentoService();
  final _authService = AuthService();
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.productData != null) {
      _nameController.text = widget.productData?['nombre'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _sendReport() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa el nombre del fármaco')));
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, describe el problema')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('ID de usuario no encontrado');

      // 1. Obtener ubicación (RF-27)
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        debugPrint('Error obteniendo ubicación para reporte: $e');
      }

      // 2. Subir imagen si existe (RF-28)
      String? evidenceUrl;
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child('reportes/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_imageFile!);
        evidenceUrl = await storageRef.getDownloadURL();
      }

      final localId = await _authService.getLocalUserId() ?? user.uid;

      final success = await _medService.reportarIncidencia(
        usuarioId: localId.toString(),
        medicamentoId: widget.productData?['medicamento_id']?.toString() ?? '0',
        nombreFarmaco: _nameController.text.trim(),
        descripcion: _descriptionController.text.trim(),
        evidenciaUrl: evidenceUrl,
        latitud: position?.latitude,
        longitud: position?.longitude,
      );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte enviado con éxito'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.softGrey,
      appBar: AppBar(
        title: Text('Reportar Problema', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre del Fármaco:', 
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              enabled: widget.productData == null,
              decoration: InputDecoration(
                hintText: 'Ej: Paracetamol 500mg',
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Text('Lote o Descripción del problema:', 
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe el problema, lote, fecha de vencimiento sospechosa, etc.',
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Text('Evidencia Fotográfica (RF-28):', 
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: _imageFile != null 
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('Tocar para tomar foto', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _sendReport,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text('ENVIAR REPORTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
