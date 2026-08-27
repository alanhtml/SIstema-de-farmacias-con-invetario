import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';

class EditPharmacyScreen extends StatefulWidget {
  final String farmaciaId;

  const EditPharmacyScreen({super.key, required this.farmaciaId});

  @override
  State<EditPharmacyScreen> createState() => _EditPharmacyScreenState();
}

class _EditPharmacyScreenState extends State<EditPharmacyScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _horarioController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _photoBase64;
  File? _newPhotoFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _horarioController = TextEditingController();
    _loadPharmacyData();
  }

  Future<void> _loadPharmacyData() async {
    try {
      final data = await _authService.getFarmaciaData(widget.farmaciaId);
      if (data != null) {
        setState(() {
          _nameController.text = data['nombre'] ?? '';
          _addressController.text = data['direccion'] ?? '';
          _phoneController.text = data['telefono'] ?? '';
          _horarioController.text = data['horario_atencion'] ?? '';
          _photoBase64 = data['foto_fachada_base64'];
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _newPhotoFile = File(image.path);
        _photoBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _authService.updateFarmacia(
        farmaciaId: widget.farmaciaId,
        nombre: _nameController.text.trim(),
        direccion: _addressController.text.trim(),
        telefono: _phoneController.text.trim(),
        horario: _horarioController.text.trim(),
        isActive: true,
        fotoBase64: _photoBase64,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos actualizados correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _horarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Farmacia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.brandGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FOTO DE LA FACHADA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brandGreen, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.softGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _photoBase64 != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _newPhotoFile != null 
                                  ? Image.file(_newPhotoFile!, fit: BoxFit.cover)
                                  : Image.memory(base64Decode(_photoBase64!), fit: BoxFit.cover),
                              )
                            : const Center(child: Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(_nameController, 'Nombre de la Farmacia', Icons.local_pharmacy),
                    const SizedBox(height: 16),
                    _buildTextField(_addressController, 'Dirección', Icons.location_on),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, 'Teléfono / Referencia', Icons.phone, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField(_horarioController, 'Horario de Atención', Icons.access_time),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('GUARDAR CAMBIOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brandGreen, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade400),
            filled: true,
            fillColor: AppTheme.softGrey,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.brandGreen, width: 1.5)),
          ),
          validator: (value) => (value == null || value.isEmpty) ? 'Este campo es requerido' : null,
        ),
      ],
    );
  }
}
