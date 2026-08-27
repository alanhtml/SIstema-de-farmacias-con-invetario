import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:farmacia_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();
  
  final _nombreEncargadoController = TextEditingController();
  final _emailController = TextEditingController(); 
  
  final _nombreFarmaciaController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _horarioController = TextEditingController();
  bool _estadoActivo = true;
  
  bool _isLoading = true;
  bool _isEditing = false;
  String? _userRole;
  int? _farmaciaId;
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = _authService.currentUser;
    if (user != null) {
      if (mounted) {
        _emailController.text = user.email ?? '';
        _userRole = AuthService.roleNotifier.value;
        _fotoUrl = user.photoURL;
      }
      
      try {
        // 1. Cargar Perfil del Usuario desde Firestore
        final profile = await _authService.getUserProfile(user.uid);
        
        if (mounted && profile != null) {
          setState(() {
            _nombreEncargadoController.text = profile['nombre'] ?? user.displayName ?? '';
            _farmaciaId = profile['farmacia_id'];
            if (profile['foto_url'] != null) _fotoUrl = profile['foto_url'];
          });
        }

        // 2. Si es farmacéutico, cargar los datos de su farmacia desde Firestore
        if (_userRole == 'farmaceutico' && _farmaciaId != null) {
          final farmaciaDoc = await _firestore
              .collection('farmacias')
              .doc(_farmaciaId.toString())
              .get();
          
          if (mounted && farmaciaDoc.exists) {
            final farmacia = farmaciaDoc.data()!;
            setState(() {
              _nombreFarmaciaController.text = farmacia['nombre'] ?? '';
              _direccionController.text = farmacia['direccion'] ?? '';
              _telefonoController.text = farmacia['telefono'] ?? '';
              _horarioController.text = farmacia['horario_atencion'] ?? '';
              _estadoActivo = farmacia['estado_activo'] ?? true;
            });
          }
        }
      } catch (e) {
        debugPrint('Error cargando datos iniciales: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      await _authService.updateUserProfile(
        userId: user.uid,
        nombre: _nombreEncargadoController.text.trim(),
        fotoUrl: _fotoUrl,
      );

      if (_userRole == 'farmaceutico' && _farmaciaId != null) {
        // En Firebase, actualizamos directamente el documento de la farmacia
        await _firestore.collection('farmacias').doc(_farmaciaId.toString()).update({
          'nombre': _nombreFarmaciaController.text.trim(),
          'direccion': _direccionController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'horario_atencion': _horarioController.text.trim(),
          'estado_activo': _estadoActivo,
        });
      }

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.softGrey,
      appBar: AppBar(
        title: Text('Mi Perfil', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.darkText,
        elevation: 0,
        actions: [
          if (!_isEditing)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('EDITAR'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.brandGreen),
            )
          else
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = false),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('CANCELAR'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.brandGreen, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                          backgroundImage: _fotoUrl != null && _fotoUrl!.isNotEmpty ? NetworkImage(_fotoUrl!) : null,
                          child: (_fotoUrl == null || _fotoUrl!.isEmpty) ? const Icon(Icons.person, size: 50, color: AppTheme.brandGreen) : null,
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: AppTheme.brandGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Información Personal'),
                const SizedBox(height: 16),
                _buildField(
                  controller: _nombreEncargadoController,
                  label: _userRole == 'farmaceutico' ? 'Nombre del Encargado' : 'Nombre Completo',
                  hint: 'Ingresa tu nombre',
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  hint: '',
                  icon: Icons.email_outlined,
                  enabled: false, 
                  isDark: isDark,
                ),
                
                if (_userRole == 'farmaceutico') ...[
                  const SizedBox(height: 32),
                  _buildSectionTitle('Datos de la Farmacia'),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _nombreFarmaciaController,
                    label: 'Nombre de la Farmacia',
                    hint: 'Ej. Farmacia San Juan',
                    icon: Icons.business_outlined,
                    enabled: _isEditing,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _direccionController,
                    label: 'Dirección',
                    hint: 'Ej. Calle 123, Av. Principal',
                    icon: Icons.location_on_outlined,
                    enabled: _isEditing,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _telefonoController,
                    label: 'Teléfono de contacto',
                    hint: 'Ej. +591 ...',
                    icon: Icons.phone_outlined,
                    enabled: _isEditing,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _horarioController,
                    label: 'Horario de Atención',
                    hint: 'Ej. 08:00 - 22:00',
                    icon: Icons.access_time,
                    enabled: _isEditing,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    'Estado de la Farmacia',
                    'Activa / Cerrada temporalmente',
                    _estadoActivo,
                    _isEditing ? (v) => setState(() => _estadoActivo = v) : null,
                    isDark,
                  ),
                ],

                if (_isEditing) ...[
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Guardar Cambios', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile == null) return;
    
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");

      final file = File(pickedFile.path);
      final fileName = 'avatars/${user.uid}.jpg';

      final ref = _storage.ref().child(fileName);
      await ref.putFile(file);
      final publicUrl = await ref.getDownloadURL();

      // Persistencia inmediata de la foto
      await _authService.updateUserProfile(
        userId: user.uid,
        nombre: _nombreEncargadoController.text.trim().isEmpty ? user.displayName ?? 'Usuario' : _nombreEncargadoController.text.trim(),
        fotoUrl: publicUrl,
      );

      setState(() {
        _fotoUrl = publicUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto subida correctamente. Guarda los cambios.'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir foto: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppTheme.brandGreen,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool enabled,
    required bool isDark,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          style: GoogleFonts.manrope(fontSize: 15, color: enabled ? (isDark ? Colors.white : AppTheme.darkText) : Colors.grey),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppTheme.brandGreen.withOpacity(0.5)),
            filled: true,
            fillColor: enabled ? (isDark ? AppTheme.darkSurface : Colors.white) : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.brandGreen, width: 1.5)),
          ),
          validator: (v) {
            if (enabled && !obscure && (v == null || v.trim().isEmpty)) return 'Este campo es obligatorio';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool)? onChanged, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.manrope(fontSize: 12)),
        value: value,
        activeColor: AppTheme.brandGreen,
        onChanged: onChanged,
      ),
    );
  }
}

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.softGrey,
      appBar: AppBar(
        title: Text('Notificaciones', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.darkText,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSwitchTile('Alertas de Stock', 'Recibir avisos cuando un producto se agota', true, isDark),
          const SizedBox(height: 8),
          _buildSwitchTile('Vencimientos', 'Avisar 30 días antes de que un lote venza', true, isDark),
          const SizedBox(height: 8),
          _buildSwitchTile('Nuevos Mensajes', 'Notificaciones de soporte y sistema', false, isDark),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: GoogleFonts.manrope(fontSize: 12)),
        value: value,
        activeColor: AppTheme.brandGreen,
        onChanged: (v) {},
      ),
    );
  }
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una nueva contraseña')),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _authService.updateUserProfile(
          userId: user.uid,
          nombre: (await _authService.getSavedName()) ?? 'Usuario',
          password: _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña actualizada correctamente'), backgroundColor: AppTheme.success),
          );
          _passwordController.clear();
          _confirmPasswordController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.softGrey,
      appBar: AppBar(
        title: Text('Seguridad', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.darkText,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Cambiar Contraseña', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 24),
          _buildPasswordField(_passwordController, 'Nueva Contraseña', isDark),
          const SizedBox(height: 16),
          _buildPasswordField(_confirmPasswordController, 'Confirmar Contraseña', isDark),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Actualizar Contraseña', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const Divider(height: 64),
          ListTile(
            leading: const Icon(Icons.fingerprint, color: AppTheme.brandGreen),
            title: const Text('Autenticación Biométrica'),
            trailing: Switch(value: true, onChanged: (v) {}, activeColor: AppTheme.brandGreen),
          ),
          ListTile(
            leading: const Icon(Icons.phonelink_lock, color: AppTheme.brandGreen),
            title: const Text('Verificación en dos pasos'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool isDark) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.darkText),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.softGrey,
      appBar: AppBar(
        title: Text('Ayuda y Soporte', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.darkText,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHelpItem(Icons.question_answer_outlined, 'Preguntas Frecuentes', 'Encuentra respuestas rápidas', isDark),
          _buildHelpItem(Icons.chat_bubble_outline, 'Chat de Soporte', 'Habla con un asesor en línea', isDark),
          _buildHelpItem(Icons.mail_outline, 'Enviar Correo', 'Contáctanos por email', isDark),
          _buildHelpItem(Icons.description_outlined, 'Términos y Condiciones', 'Información legal', isDark),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String subtitle, bool isDark) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.brandGreen),
        title: Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: GoogleFonts.manrope(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
