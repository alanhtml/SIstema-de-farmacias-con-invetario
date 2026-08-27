import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  static final ValueNotifier<String?> roleNotifier = ValueNotifier<String?>(null);

  String? get currentRole => roleNotifier.value;

  // --- SESIÓN ---
  Future<void> _saveSession(String rol, String nombre, {dynamic localId, dynamic farmaciaId}) async {
    final prefs = await SharedPreferences.getInstance();
    
    final cleanRol = rol.replaceAll(RegExp(r"['" '"' r"]"), "").trim().toLowerCase();
    final cleanNombre = nombre.replaceAll(RegExp(r"['" '"' r"]"), "").trim();

    await prefs.setString('user_role', cleanRol);
    await prefs.setString('user_name', cleanNombre);
    
    if (localId != null) {
      await prefs.setString('local_user_id_str', localId.toString());
    }
    
    if (farmaciaId != null) {
      await prefs.setString('local_farmacia_id_str', farmaciaId.toString());
    }
    
    roleNotifier.value = cleanRol;
    debugPrint('💾 Sesión local establecida: Rol=$cleanRol, ID=$localId');
  }

  Future<String?> getLocalFarmaciaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('local_farmacia_id_str');
  }

  Future<String?> getLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('local_user_id_str');
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    roleNotifier.value = null;
  }

  // --- REGISTRO ---
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String nombre,
    required String rol,
    String? farmaciaNombre,
    String? farmaciaDireccion,
    String? farmaciaTelefono,
    String? farmaciaHorario,
    String? farmaciaFotoBase64,
    double? latitud,
    double? longitud,
  }) async {
    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) throw Exception("Error al crear cuenta en Firebase");

    await credential.user!.updateDisplayName(nombre);

    String? farmaciaId;
    if (rol == 'farmaceutico' && farmaciaNombre != null) {
      // Crear documento de farmacia en Firestore
      final farmaciaDoc = await _firestore.collection('farmacias').add({
        'nombre': farmaciaNombre,
        'direccion': farmaciaDireccion ?? '',
        'telefono': farmaciaTelefono ?? '',
        'horario_atencion': farmaciaHorario ?? '',
        'foto_fachada_base64': farmaciaFotoBase64,
        'latitud': latitud ?? 0.0,
        'longitud': longitud ?? 0.0,
        'estado_activo': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      farmaciaId = farmaciaDoc.id;
    }

    // Guardar perfil de usuario en Firestore
    await _firestore.collection('usuarios').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'farmacia_id': farmaciaId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // --- LOGIN ---
  Future<String?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (credential.user != null) return await initializeAuth();
    return null;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<String?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    if (userCredential.user != null) {
      // Verificar si el usuario ya existe en Firestore
      final profile = await getUserProfile(userCredential.user!.uid);
      
      if (profile == null || profile['rol'] == null) {
        // Usuario nuevo o sin rol definido: Marcar como pendiente
        return 'NEW_USER';
      }

      return await initializeAuth();
    }
    return null;
  }

  Future<String?> initializeAuth() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        final profile = doc.data()!;

        // --- VERIFICACIÓN DE SUSPENSIÓN ---
        if (profile['suspendido'] == true) {
          debugPrint('🚫 Usuario suspendido detectado: ${user.email}');
          await signOut();
          return 'suspendido';
        }

        final String role = profile['rol']?.toString() ?? 'cliente';
        
        // Manejo de farmacia_id (puede ser String o int si viene de migración previa)
        dynamic fId = profile['farmacia_id'];
        
        await _saveSession(
          role, 
          profile['nombre'] ?? "Usuario", 
          localId: user.uid,
          farmaciaId: profile['farmacia_id']
        );

        return roleNotifier.value;
      }
    } catch (e) {
      debugPrint('⚠️ Error sync perfil Firestore: $e');
    }
    return await getSavedRole();
  }

  User? get currentUser => _auth.currentUser;

  Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<String?> getSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _clearSession();
  }

  // --- PERFIL ---
  Future<void> completeSocialProfile({
    required String uid,
    required String nombre,
    required String email,
    required String rol,
    String? farmaciaNombre,
    String? farmaciaDireccion,
    String? farmaciaTelefono,
    String? farmaciaHorario,
    String? farmaciaFotoBase64,
    double? latitud,
    double? longitud,
  }) async {
    String? farmaciaId;
    if (rol == 'farmaceutico' && farmaciaNombre != null) {
      final farmaciaDoc = await _firestore.collection('farmacias').add({
        'nombre': farmaciaNombre,
        'direccion': farmaciaDireccion ?? '',
        'telefono': farmaciaTelefono ?? '',
        'horario_atencion': farmaciaHorario ?? '',
        'foto_fachada_base64': farmaciaFotoBase64,
        'latitud': latitud ?? 0.0,
        'longitud': longitud ?? 0.0,
        'estado_activo': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      farmaciaId = farmaciaDoc.id;
    }

    await _firestore.collection('usuarios').doc(uid).set({
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'farmacia_id': farmaciaId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await initializeAuth();
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error en getUserProfile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required String nombre,
    String? password,
    String? fotoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(nombre);
      if (fotoUrl != null) await user.updatePhotoURL(fotoUrl);
      if (password != null && password.isNotEmpty) await user.updatePassword(password);
    }
    
    await _firestore.collection('usuarios').doc(userId).update({
      'nombre': nombre,
      if (fotoUrl != null) 'foto_url': fotoUrl,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', nombre);
  }

  Future<void> updateFarmacia({
    required String farmaciaId,
    required String nombre,
    required String direccion,
    required String telefono,
    required String horario,
    required bool isActive,
    String? fotoBase64,
  }) async {
    await _firestore.collection('farmacias').doc(farmaciaId).update({
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'horario_atencion': horario,
      'estado_activo': isActive,
      if (fotoBase64 != null) 'foto_fachada_base64': fotoBase64,
    });
  }

  Future<Map<String, dynamic>?> getFarmaciaData(String farmaciaId) async {
    try {
      final doc = await _firestore.collection('farmacias').doc(farmaciaId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      debugPrint('Error en getFarmaciaData: $e');
      return null;
    }
  }

  // --- DASHBOARD Y REPORTES REALES ---
  Future<Map<String, dynamic>> getDashboardStats(String farmaciaId) async {
    try {
      final now = DateTime.now();
      final nextMonth = now.add(const Duration(days: 30));

      // 1. Obtener inventario para stock total
      final inventorySnap = await _firestore.collection('inventarios')
          .where('farmacia_id', isEqualTo: farmaciaId)
          .get();
      
      int totalStock = 0;
      for (var doc in inventorySnap.docs) {
        totalStock += (doc.data()['stock_actual'] as num?)?.toInt() ?? 0;
      }

      // 2. Contar alertas (vencimientos próximos < 30 días)
      final lotesSnap = await _firestore.collection('lotes')
          .where('farmacia_id', isEqualTo: farmaciaId)
          .where('estado', isEqualTo: 'activo')
          .get();
      
      int alerts = 0;
      for (var doc in lotesSnap.docs) {
        final expiryStr = doc.data()['fecha_vencimiento'];
        if (expiryStr != null) {
          final expiryDate = DateTime.tryParse(expiryStr);
          if (expiryDate != null && expiryDate.isBefore(nextMonth)) {
            alerts++;
          }
        }
      }

      // 3. Obtener escaneos de hoy (RF-30/31)
      final startOfDay = DateTime(now.year, now.month, now.day);
      final scansSnap = await _firestore.collection('historial_verificaciones')
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      return {
        'data': {
          'total_stock': totalStock,
          'alerts': alerts,
          'scans_today': scansSnap.docs.length,
        }
      };
    } catch (e) {
      debugPrint('Error getDashboardStats: $e');
      return {'data': {'total_stock': 0, 'alerts': 0, 'scans_today': 0}};
    }
  }
}
