import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:farmacia_app/theme/theme.dart';
import 'package:farmacia_app/services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  final bool isSocialRegister;
  const RegisterScreen({super.key, this.isSocialRegister = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

enum UserRole { cliente, farmaceutico }

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pharmacyNameController = TextEditingController();
  final _pharmacyAddressController = TextEditingController();
  final _txtTelefonoFarmacia = TextEditingController();
  final _txtHorarioAtencion = TextEditingController();

  final AuthService _authService = AuthService();

  double? _latitude;
  double? _longitude;
  File? _pharmacyPhoto;
  final _picker = ImagePicker();
  bool _gettingLocation = false;
  bool _isRegistering = false;
  bool _waitingVerification = false;

  UserRole _selectedRole = UserRole.cliente;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  StreamSubscription<User?>? _authSubscription;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    if (widget.isSocialRegister) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
      }
    } else {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null && user.emailVerified) {
          _handleSuccessfulEntry();
        }
      });
    }
  }

  Future<void> _handleSuccessfulEntry() async {
    if (!mounted) return;
    _authSubscription?.cancel();
    setState(() => _isRegistering = true);
    
    // Inicializar y obtener el rol real del usuario
    final String? role = await _authService.initializeAuth();
    
    if (mounted) {
      if (role == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
        return;
      }

      final cleanRole = role.trim().toLowerCase();
      if (cleanRole == 'farmaceutico') {
        Navigator.pushNamedAndRemoveUntil(context, '/main_farmer', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pharmacyNameController.dispose();
    _pharmacyAddressController.dispose();
    _txtTelefonoFarmacia.dispose();
    _txtHorarioAtencion.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _setRole(UserRole role) {
    setState(() => _selectedRole = role);
    if (role == UserRole.farmaceutico) { _animController.forward(); } else { _animController.reverse(); }
  }

  Future<void> _register() async {
    if (_isRegistering) return;
    if (!_formKey.currentState!.validate()) return;

    if (!widget.isSocialRegister) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: AppTheme.danger));
        return;
      }
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes aceptar los términos'), backgroundColor: AppTheme.danger));
      return;
    }

    setState(() => _isRegistering = true);

    try {
      String? photoBase64;
      if (_pharmacyPhoto != null) {
        final bytes = await _pharmacyPhoto!.readAsBytes();
        photoBase64 = base64Encode(bytes);
      }

      if (widget.isSocialRegister) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("Sesión de Google no encontrada");

        await _authService.completeSocialProfile(
          uid: user.uid,
          nombre: _nameController.text.trim(),
          email: _emailController.text.trim(),
          rol: _selectedRole == UserRole.farmaceutico ? 'farmaceutico' : 'cliente',
          farmaciaNombre: _selectedRole == UserRole.farmaceutico ? _pharmacyNameController.text.trim() : null,
          farmaciaDireccion: _selectedRole == UserRole.farmaceutico ? _pharmacyAddressController.text.trim() : null,
          farmaciaTelefono: _selectedRole == UserRole.farmaceutico ? _txtTelefonoFarmacia.text.trim() : null,
          farmaciaHorario: _selectedRole == UserRole.farmaceutico ? _txtHorarioAtencion.text.trim() : null,
          farmaciaFotoBase64: photoBase64,
          latitud: _latitude,
          longitud: _longitude,
        );
        
        if (mounted) {
          final targetRoute = _selectedRole == UserRole.farmaceutico ? '/main_farmer' : '/main_client';
          Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
        }
      } else {
        final credential = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          nombre: _nameController.text.trim(),
          rol: _selectedRole == UserRole.farmaceutico ? 'farmaceutico' : 'cliente',
          farmaciaNombre: _selectedRole == UserRole.farmaceutico ? _pharmacyNameController.text.trim() : null,
          farmaciaDireccion: _selectedRole == UserRole.farmaceutico ? _pharmacyAddressController.text.trim() : null,
          farmaciaTelefono: _selectedRole == UserRole.farmaceutico ? _txtTelefonoFarmacia.text.trim() : null,
          farmaciaHorario: _selectedRole == UserRole.farmaceutico ? _txtHorarioAtencion.text.trim() : null,
          farmaciaFotoBase64: photoBase64,
          latitud: _latitude,
          longitud: _longitude,
        );

        // Enviar correo de verificación
        await credential.user?.sendEmailVerification();

        if (mounted) {
          setState(() {
            _isRegistering = false;
            _waitingVerification = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  Future<void> _selectTimeRange() async {
    final TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'HORA DE APERTURA',
    );
    if (start == null) return;

    final TimeOfDay? end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
      helpText: 'HORA DE CIERRE',
    );
    if (end == null) return;

    if (mounted) {
      final String startStr = start.hour.toString().padLeft(2, '0') + ":" + start.minute.toString().padLeft(2, '0');
      final String endStr = end.hour.toString().padLeft(2, '0') + ":" + end.minute.toString().padLeft(2, '0');
      setState(() {
        _txtHorarioAtencion.text = "$startStr - $endStr";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: SafeArea(
        child: _waitingVerification ? _buildWaitingStep() : _buildRegisterForm(),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
            const SizedBox(height: 16),
            const Center(child: Column(children: [Icon(Icons.medical_services, size: 60, color: AppTheme.brandGreen), SizedBox(height: 10), Text('Únete a Medivida', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))])),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))]),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildRoleSelectorImproved(),
                    const SizedBox(height: 24),
                    _buildTextField(controller: _nameController, label: 'Nombre Completo', hint: 'Ej. Guido Mendoza', icon: Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _emailController, label: 'Correo', hint: 'ejemplo@mail.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, readOnly: widget.isSocialRegister),
                    if (!widget.isSocialRegister) ...[
                      const SizedBox(height: 16),
                      _buildTextField(controller: _passwordController, label: 'Contraseña', hint: '••••••••', icon: Icons.lock_outline, obscure: _obscurePassword, suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _confirmPasswordController, label: 'Confirmar', hint: '••••••••', icon: Icons.lock_outline, obscure: _obscureConfirmPassword, suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword))),
                    ],

                    SizeTransition(
                      sizeFactor: _fadeAnimation,
                      child: Column(children: [
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _pharmacyNameController, 
                          label: 'Farmacia', 
                          hint: 'Nombre de la Farmacia', 
                          icon: Icons.local_pharmacy_outlined,
                          isRequired: _selectedRole == UserRole.farmaceutico,
                        ),
                        const SizedBox(height: 16),
                        _buildPharmacyPhotoPicker(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _pharmacyAddressController, 
                          label: 'Dirección', 
                          hint: 'Ubicación', 
                          icon: Icons.location_on_outlined,
                          isRequired: _selectedRole == UserRole.farmaceutico,
                          suffixIcon: IconButton(icon: _gettingLocation ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, color: AppTheme.brandGreen), onPressed: _getCurrentLocation)
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: _buildTextField(
                            controller: _txtTelefonoFarmacia, 
                            label: 'Teléfono', 
                            hint: '70000000', 
                            icon: Icons.phone_android, 
                            keyboardType: TextInputType.phone,
                            prefixText: '🇧🇴 +591 ',
                            isRequired: _selectedRole == UserRole.farmaceutico,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(
                            controller: _txtHorarioAtencion, 
                            label: 'Horario', 
                            hint: '08:00-20:00', 
                            icon: Icons.access_time,
                            readOnly: true,
                            onTap: _selectTimeRange,
                            isRequired: _selectedRole == UserRole.farmaceutico,
                          )),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    _buildTermsCheckbox(),
                    const SizedBox(height: 24),
                    _buildRegisterButton(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(child: TextButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: const Text('¿Ya tienes cuenta? Inicia Sesión', style: TextStyle(color: AppTheme.brandGreen, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelectorImproved() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppTheme.softGrey, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        _roleButton(UserRole.cliente, 'Cliente', Icons.person_rounded),
        const SizedBox(width: 8),
        _roleButton(UserRole.farmaceutico, 'Farmacéutico', Icons.local_pharmacy_rounded),
      ]),
    );
  }

  Widget _roleButton(UserRole role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setRole(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: AppTheme.brandGreen.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey.shade500),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.manrope(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: AppTheme.brandGreen.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.mark_email_unread_rounded, size: 80, color: AppTheme.brandGreen)),
            const SizedBox(height: 32),
            const Text('¡Verifica tu correo!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Hemos enviado un enlace a ${_emailController.text}.\nPulsa el link en tu correo para activar tu cuenta Medivida.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            if (_isRegistering) const CircularProgressIndicator(color: AppTheme.brandGreen)
            else SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: () async {
              setState(() => _isRegistering = true);
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await user.reload();
                if (user.emailVerified) {
                  _handleSuccessfulEntry();
                } else {
                  setState(() => _isRegistering = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aún no detectamos la verificación. Revisa tu mail.')));
                }
              } else {
                setState(() => _isRegistering = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No se encontró sesión activa.')));
              }
            }, child: const Text('YA HE VERIFICADO MI CORREO', style: TextStyle(fontWeight: FontWeight.bold)))),
            TextButton(onPressed: () => setState(() => _waitingVerification = false), child: const Text('Volver al formulario', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required String hint, 
    required IconData icon, 
    TextInputType keyboardType = TextInputType.text, 
    bool obscure = false, 
    Widget? suffixIcon,
    String? prefixText,
    bool readOnly = false,
    VoidCallback? onTap,
    bool isRequired = true,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brandGreen, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller, 
        obscureText: obscure, 
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint, 
          prefixIcon: prefixText != null 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 12),
                  Icon(icon, size: 20, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(prefixText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 4),
                ],
              )
            : Icon(icon, size: 20, color: Colors.grey.shade400),
          suffixIcon: suffixIcon,
          filled: true, fillColor: AppTheme.softGrey,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.brandGreen, width: 1.5)),
        ),
        validator: (v) {
          if (!isRequired) return null;
          return (v == null || v.isEmpty) ? 'Requerido' : null;
        },
      ),
    ]);
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _isRegistering ? null : _register,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
        child: _isRegistering ? const CircularProgressIndicator(color: Colors.white) : const Text('CREAR CUENTA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPharmacyPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FOTO DE LA FACHADA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brandGreen, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickPharmacyPhoto,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.softGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              image: _pharmacyPhoto != null
                  ? DecorationImage(image: FileImage(_pharmacyPhoto!), fit: BoxFit.cover)
                  : null,
            ),
            child: _pharmacyPhoto == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded, color: Colors.grey.shade400, size: 40),
                      const SizedBox(height: 8),
                      Text('Toca para tomar foto de la fachada', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Future<void> _pickPharmacyPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _pharmacyPhoto = File(pickedFile.path));
    }
  }

  Widget _buildTermsCheckbox() {
    return Row(children: [
      Checkbox(
        value: _acceptedTerms, 
        onChanged: (v) => setState(() => _acceptedTerms = v ?? false), 
        activeColor: AppTheme.brandGreen
      ),
      Expanded(
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.manrope(fontSize: 12, color: Colors.black87),
            children: [
              const TextSpan(text: 'Acepto los '),
              TextSpan(
                text: 'Términos de Servicio y Privacidad',
                style: const TextStyle(
                  color: AppTheme.brandGreen, 
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline
                ),
                recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Términos y Privacidad', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _termSection('1. Uso de la Aplicación', 'Medivida es una plataforma para la verificación de autenticidad de medicamentos. El usuario se compromete a usar la app de manera responsable.'),
                _termSection('2. Privacidad de Datos', 'Sus datos personales y de ubicación se utilizan exclusivamente para mejorar la experiencia de búsqueda y registro de farmacias. No compartimos información con terceros sin consentimiento.'),
                _termSection('3. Responsabilidad', 'La información proporcionada por los escaneos es referencial. Ante cualquier duda sobre un medicamento, consulte siempre a un profesional de la salud.'),
                _termSection('4. Registro de Farmacias', 'Los farmacéuticos registrados garantizan la veracidad de la información técnica y de stock proporcionada en sus inventarios.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR', style: TextStyle(color: AppTheme.brandGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _termSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // 1. Verificar si el servicio de ubicación está activo
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Los servicios de ubicación están desactivados.';
      }

      // 2. Verificar permisos actuales
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Solicitar permisos por primera vez
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permiso de ubicación denegado.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permisos denegados permanentemente. Actívalos en Ajustes.';
      }

      // 3. Obtener posición una vez otorgados los permisos
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _latitude = pos.latitude; 
        _longitude = pos.longitude;
        _pharmacyAddressController.text = "GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}";
      });
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error GPS: $e'), backgroundColor: AppTheme.danger)
       );
    } finally { 
      setState(() => _gettingLocation = false); 
    }
  }
}
