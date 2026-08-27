import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:farmacia_app/models/lote_model.dart';

class MedicamentoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> buscarPorGTIN(String gtin) async {
    try {
      final snapshot = await _firestore.collection('medicamentos_maestros')
          .where('gtin', isEqualTo: gtin).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return {
          'id': snapshot.docs.first.id,
          ...snapshot.docs.first.data()
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error buscarPorGTIN: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> validarMedicamento(String nombre) async {
    try {
      final snapshot = await _firestore.collection('medicamentos_maestros')
          .where('nombre', isEqualTo: nombre).limit(1).get();
      return snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : null;
    } catch (e) { throw Exception('Error validarMedicamento: $e'); }
  }

  Future<bool> reportarIncidencia({
    required String usuarioId,
    required String medicamentoId,
    required String descripcion,
    String? nombreFarmaco,
    String? evidenciaUrl,
    double? latitud,
    double? longitud,
  }) async {
    try {
      await _firestore.collection('reportes_incidencias').add({
        'usuario_id': usuarioId,
        'medicamento_id': medicamentoId,
        'nombre_farmaco': nombreFarmaco,
        'descripcion': descripcion,
        'evidencia_url': evidenciaUrl,
        'ubicacion': latitud != null ? GeoPoint(latitud, longitud!) : null,
        'fecha': FieldValue.serverTimestamp(),
        'estado': 'pendiente',
      });
      return true;
    } catch (e) { return false; }
  }

  Future<bool> postLote(Lote lote) async {
    try {
      await _firestore.collection('lotes').add(lote.toJson());
      return true;
    } catch (e) { return false; }
  }

  Future<bool> deleteInventoryItem(String id) async {
    try {
      await _firestore.collection('inventarios').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleteInventoryItem: $e');
      return false;
    }
  }

  Future<bool> updateInventoryItem(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('inventarios').doc(id).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updateInventoryItem: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> verificarEscanear(String codigo) async {
    try {
      // 1. Primero buscamos en Lotes (Trazabilidad específica)
      final snapshot = await _firestore.collection('lotes')
          .where('codigo_qr', isEqualTo: codigo).limit(1).get();
      
      Map<String, dynamic> result;
      if (snapshot.docs.isNotEmpty) {
        result = {'status': 'success', 'data': snapshot.docs.first.data()};
      } else {
        // 2. Fallback: Buscar en Catálogo Maestro (Información técnica global)
        final maestro = await buscarPorGTIN(codigo);
        if (maestro != null) {
          result = {
            'status': 'warning', 
            'message': 'Producto legítimo reconocido en catálogo, pero sin registro de trazabilidad de lote en esta unidad.',
            'data': {
              ...maestro,
              'numero_lote': 'No verificado',
              'fecha_vencimiento': 'Ver envase físico',
            }
          };
        } else {
          result = {'status': 'error', 'message': 'Medicamento no encontrado en el sistema de seguridad ni en el catálogo maestro.'};
        }
      }

      // RF-30: Registrar el historial de verificación
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('historial_verificaciones').add({
          'usuario_id': user.uid,
          'codigo_escaneado': codigo,
          'resultado': result['status'],
          'fecha': FieldValue.serverTimestamp(),
          'medicamento_nombre': result['data']?['nombre'] ?? 'Desconocido',
        });
      }

      return result;
    } catch (e) { return {'status': 'error', 'message': e.toString()}; }
  }

  // RF-32: Registrar búsquedas realizadas
  Future<void> registrarBusqueda(String query) async {
    final user = _auth.currentUser;
    if (user != null && query.isNotEmpty) {
      await _firestore.collection('historial_busquedas').add({
        'usuario_id': user.uid,
        'query': query,
        'fecha': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<Map<String, dynamic>> getInventory(dynamic farmaciaId) async {
    try {
      final snapshot = await _firestore.collection('inventarios')
          .where('farmacia_id', isEqualTo: farmaciaId.toString()).get();
      return {
        'OK': true,
        'data': snapshot.docs.map((doc) => {'id_firestore': doc.id, ...doc.data()}).toList()
      };
    } catch (e) { throw Exception('Error inventory: $e'); }
  }

  Future<bool> registerMedicamentoMaestro(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('medicamentos_maestros').add({...data, 'createdAt': FieldValue.serverTimestamp()});
      return true;
    } catch (e) { return false; }
  }

  Future<List<Map<String, dynamic>>> buscarGlobal(String query) async {
    try {
      // 1. Obtener todas las farmacias para mapear nombres y ubicación
      final pharmaciesSnap = await _firestore.collection('farmacias').get();
      final Map<String, Map<String, dynamic>> pharmacyMap = {};
      for (var doc in pharmaciesSnap.docs) {
        pharmacyMap[doc.id] = {...doc.data(), 'id': doc.id};
      }

      // 2. Obtener catálogo maestro para detalles técnicos
      final maestroSnap = await _firestore.collection('medicamentos_maestros').get();
      final Map<String, Map<String, dynamic>> maestroMap = {};
      for (var doc in maestroSnap.docs) {
        maestroMap[doc.id] = {...doc.data(), 'id': doc.id};
      }

      // 3. Obtener inventarios
      final snapshot = await _firestore.collection('inventarios').get();
      
      final List<Map<String, dynamic>> results = [];
      for (var doc in snapshot.docs) {
        final invData = doc.data();
        final String? medId = invData['medicamento_id'];
        final String? farmId = invData['farmacia_id'];
        
        final maestroData = medId != null ? maestroMap[medId] : null;
        final farmaciaData = farmId != null ? pharmacyMap[farmId] : null;

        // FILTRO: Solo agregar si la farmacia NO está suspendida
        if (farmaciaData != null && farmaciaData['estado_activo'] == false) {
          continue; 
        }

        results.add({
          ...invData,
          'id': doc.id,
          'maestro': maestroData,
          'farmacia': farmaciaData,
          'nombre': invData['nombre'] ?? maestroData?['nombre'] ?? 'Sin nombre',
          'principio_activo': invData['principio_activo'] ?? maestroData?['principio_activo'] ?? '',
          'precio': invData['precio'] ?? (maestroData?['precio_sugerido'] ?? 0.0),
        });
      }

      if (query.isEmpty) return results;
      final q = query.toLowerCase();
      return results.where((item) {
        final nombre = (item['nombre'] ?? '').toString().toLowerCase();
        final principio = (item['principio_activo'] ?? '').toString().toLowerCase();
        return nombre.contains(q) || principio.contains(q);
      }).toList();
    } catch (e) { 
      debugPrint('Error buscarGlobal: $e');
      return []; 
    }
  }

  Future<List<Map<String, dynamic>>> getFarmacias() async {
    try {
      final snapshot = await _firestore.collection('farmacias').get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getStockAlerts(String farmaciaId) async {
    try {
      final snapshot = await _firestore.collection('inventarios')
          .where('farmacia_id', isEqualTo: farmaciaId)
          .where('stock_actual', isLessThanOrEqualTo: 10).get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getPublicReports() async {
    try {
      final snapshot = await _firestore.collection('reportes_incidencias')
          .orderBy('fecha', descending: true).limit(20).get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) { return []; }
  }
}
