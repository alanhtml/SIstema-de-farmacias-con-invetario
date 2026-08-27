import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:farmacia_app/screens/scanner.dart';
import 'package:farmacia_app/services/auth_service.dart';
import 'package:farmacia_app/services/medicamento_service.dart';
import 'package:farmacia_app/models/lote_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterLoteScreen extends StatefulWidget {
  const RegisterLoteScreen({super.key});

  @override
  State<RegisterLoteScreen> createState() => _RegisterLoteScreenState();
}

class _RegisterLoteScreenState extends State<RegisterLoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();
  final _medicamentoService = MedicamentoService();

  final _codigoLoteController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _vencimientoController = TextEditingController();
  
  // Controladores para desglose de stock (Tabletas/Cápsulas)
  final _cajasController = TextEditingController();
  final _blistersPorCajaController = TextEditingController();
  final _pastillasPorBlisterController = TextEditingController();

  String? _selectedMedicationId;
  List<Map<String, dynamic>> _medications = [];
  bool _isLoadingMedications = true;
  bool _isSaving = false;
  bool _isScanning = false;
  dynamic _farmaciaId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _authService.getUserProfile(user.uid);
        _farmaciaId = profile?['farmacia_id'];
        
        if (_farmaciaId == null) {
           final prefs = await SharedPreferences.getInstance();
           _farmaciaId = prefs.getString('local_farmacia_string_id');
        }

        // Obtener la lista de medicamentos maestros de Firestore
        final snapshot = await _firestore.collection('medicamentos_maestros').get();
        
        if (mounted) {
          setState(() {
            _medications = snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList();
            
            _isLoadingMedications = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMedications = false);
      debugPrint('Error cargando medicamentos: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _vencimientoController.text = picked.toIso8601String().split('T')[0]);
    }
  }

  Future<void> _saveLote() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    if (_farmaciaId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Farmacia no identificada'), backgroundColor: AppTheme.danger));
       return;
    }

    setState(() => _isSaving = true);
    try {
      final cantidad = int.parse(_cantidadController.text.trim());
      
      // 1. Crear el lote
      final lote = Lote(
        medicamentoId: _selectedMedicationId!,
        numeroLote: _codigoLoteController.text.trim(),
        cantidadInicial: cantidad,
        cantidadActual: cantidad,
        fechaVencimiento: _vencimientoController.text,
        farmaciaId: _farmaciaId.toString(),
        estado: 'activo',
      );

      // Usamos un mapa manual para flexibilidad con el ID de farmacia que ahora es String
      // y para incluir el FieldValue.serverTimestamp() que no está en el modelo
      final loteData = {
        ...lote.toJson(),
        'fecha_registro': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('lotes').add(loteData);

      // 2. Actualizar o crear entrada en 'inventarios'
      // Buscamos si ya existe este medicamento en el inventario de la farmacia
      final invSnap = await _firestore.collection('inventarios')
        .where('farmacia_id', isEqualTo: _farmaciaId)
        .where('medicamento_id', isEqualTo: _selectedMedicationId)
        .where('lote', isEqualTo: _codigoLoteController.text.trim())
        .limit(1)
        .get();

      if (invSnap.docs.isNotEmpty) {
        final docId = invSnap.docs.first.id;
        final currentStock = invSnap.docs.first.data()['stock_actual'] ?? 0;
        await _firestore.collection('inventarios').doc(docId).update({
          'stock_actual': currentStock + cantidad,
        });
      } else {
        // Obtener info del medicamento para el denormalizado (opcional pero común en NoSQL)
        final medDoc = await _firestore.collection('medicamentos_maestros').doc(_selectedMedicationId).get();
        final medData = medDoc.data() ?? {};

        await _firestore.collection('inventarios').add({
          'farmacia_id': _farmaciaId,
          'medicamento_id': _selectedMedicationId,
          'nombre': medData['nombre'] ?? 'Desconocido',
          'principio_activo': medData['principio_activo'] ?? '',
          'lote': _codigoLoteController.text.trim(),
          'stock_actual': cantidad,
          'fecha_vencimiento': _vencimientoController.text,
        });
      }

      if (mounted) {
        _clearFields();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lote registrado exitosamente'), backgroundColor: AppTheme.success));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearFields() {
    _codigoLoteController.clear();
    _cantidadController.clear();
    _vencimientoController.clear();
    _cajasController.clear();
    _blistersPorCajaController.clear();
    _pastillasPorBlisterController.clear();
    setState(() => _selectedMedicationId = null);
  }

  void _calculateTotal() {
    final cajas = int.tryParse(_cajasController.text) ?? 0;
    final blisters = int.tryParse(_blistersPorCajaController.text) ?? 0;
    final pastillas = int.tryParse(_pastillasPorBlisterController.text) ?? 0;

    if (cajas > 0 && blisters > 0 && pastillas > 0) {
      final total = cajas * blisters * pastillas;
      setState(() {
        _cantidadController.text = total.toString();
      });
    }
  }

  Map<String, dynamic>? get _selectedMedicationData {
    if (_selectedMedicationId == null) return null;
    return _medications.firstWhere((m) => m['id'].toString() == _selectedMedicationId, orElse: () => {});
  }

  Future<void> _scanMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (result != null && result is String) {
      final gtin = result.trim();
      final found = _medications.firstWhere(
        (m) => m['gtin'] == gtin,
        orElse: () => {},
      );

      if (found.isNotEmpty) {
        setState(() {
          _selectedMedicationId = found['id'].toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Seleccionado: ${found['nombre']}'),
            backgroundColor: AppTheme.brandGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No se encontró el medicamento en el catálogo maestro.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.softGrey,
      appBar: AppBar(
        title: Text('Nuevo Lote', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      ),
      body: _isLoadingMedications 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Detalles de Ingreso', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.brandGreen)),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedMedicationId,
                          isExpanded: true,
                          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                          decoration: _inputDeco('Medicamento', Icons.medication, isDark),
                          items: _medications.map((m) => DropdownMenuItem(
                            value: m['id'].toString(), 
                            child: Text(m['nombre'], overflow: TextOverflow.ellipsis)
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedMedicationId = v),
                          validator: (v) => v == null ? 'Campo requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _scanMedication,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                              foregroundColor: AppTheme.brandGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.brandGreen.withOpacity(0.5)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codigoLoteController,
                    decoration: _inputDeco('Código/Número de Lote', Icons.tag, isDark),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  if (_selectedMedicationData != null && 
                     (_selectedMedicationData!['unidad_id'] == 1 || _selectedMedicationData!['unidad_id'] == 2)) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface.withOpacity(0.5) : AppTheme.softGrey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.brandGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calculadora de Stock (Unidades)', 
                            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.brandGreen)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cajasController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoSimple('Cajas', isDark),
                                  onChanged: (_) => _calculateTotal(),
                                ),
                              ),
                              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('x')),
                              Expanded(
                                child: TextFormField(
                                  controller: _blistersPorCajaController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoSimple('Blísters/Caja', isDark),
                                  onChanged: (_) => _calculateTotal(),
                                ),
                              ),
                              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('x')),
                              Expanded(
                                child: TextFormField(
                                  controller: _pastillasPorBlisterController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoSimple('Pastillas/Blíster', isDark),
                                  onChanged: (_) => _calculateTotal(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('Cantidad Total (Unidades)', Icons.inventory, isDark),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vencimientoController,
                    readOnly: true,
                    onTap: _selectDate,
                    decoration: _inputDeco('Fecha de Vencimiento', Icons.calendar_today, isDark),
                    validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveLote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('REGISTRAR LOTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.brandGreen),
      filled: true,
      fillColor: isDark ? AppTheme.darkSurface : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  InputDecoration _inputDecoSimple(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      filled: true,
      fillColor: isDark ? AppTheme.darkBackground : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}
