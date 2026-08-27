import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FarmaciaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> obtenerFarmacias() async {
    try {
      final snapshot = await _firestore.collection('farmacias').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint("Error obteniendo farmacias: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getDashboardStats(String farmaciaId) async {
    try {
      final inventorySnap = await _firestore.collection('inventarios')
          .where('farmacia_id', isEqualTo: farmaciaId)
          .get();
      
      int totalStock = 0;
      int alerts = 0;
      
      for (var doc in inventorySnap.docs) {
        final data = doc.data();
        totalStock += (data['stock_actual'] as num).toInt();
        
        final expiry = DateTime.tryParse(data['fecha_vencimiento'] ?? '');
        if (expiry != null && expiry.difference(DateTime.now()).inDays < 30) {
          alerts++;
        }
      }

      return {
        'data': {
          'total_stock': totalStock,
          'alerts': alerts,
          'scans_today': 0, 
        }
      };
    } catch (e) {
      debugPrint('Error getDashboardStats: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getInventoryReports(String farmaciaId) async {
    try {
      final snapshot = await _firestore.collection('inventarios')
          .where('farmacia_id', isEqualTo: farmaciaId)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getInventoryReports: $e');
      rethrow;
    }
  }
}
