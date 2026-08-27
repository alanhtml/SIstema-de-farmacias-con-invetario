import 'dart:async';
import 'package:flutter/material.dart';
import 'package:farmacia_app/services/auth_service.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmacia_app/screens/profile_details.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  String _displayName = 'Cargando...';
  String _userEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _userEmail = user.email ?? '';
          _isLoading = true;
        });
      }
      try {
        final savedName = await _authService.getSavedName();
        if (savedName != null && mounted) {
          setState(() {
            _displayName = savedName;
          });
        }

        final profile = await _authService.getUserProfile(user.uid).timeout(const Duration(seconds: 10));
        
        String nameToShow = profile?['nombre'] ?? user.displayName ?? savedName ?? 'Usuario';
        
        if (mounted) {
          setState(() {
            _displayName = nameToShow;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error cargando datos de usuario: $e');
        if (mounted) {
          setState(() {
            if (_displayName == 'Cargando...') {
              _displayName = user.displayName ?? 'Usuario Medivida';
            }
            _isLoading = false;
          });
        }
      }
    } else {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildAvatar(isDark),
                    const SizedBox(height: 20),
                    Text(
                      _displayName,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _userEmail,
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildProfileOption(
                      icon: Icons.person_outline_rounded,
                      title: 'Ver y Editar Perfil',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                        _loadUserData();
                      },
                    ),
                    _buildProfileOption(
                      icon: Icons.logout_rounded,
                      title: 'Cerrar Sesión',
                      titleColor: AppTheme.danger,
                      iconColor: AppTheme.danger,
                      onTap: () async {
                        try {
                          await _authService.signOut();
                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandGreen.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: isDark ? AppTheme.brightGreen : AppTheme.brandGreen,
        child: Icon(Icons.person, size: 50, color: isDark ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? (isDark ? AppTheme.brightGreen : AppTheme.brandGreen)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? (isDark ? AppTheme.brightGreen : AppTheme.brandGreen),
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: titleColor,
            ),
          ),
          trailing: trailing ?? Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
