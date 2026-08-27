import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmacia_app/services/medicamento_service.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'scanner.dart'; // Importamos tu pantalla de escáner

class RegisterMedicineScreen extends StatefulWidget {
  const RegisterMedicineScreen({super.key});

  @override
  State<RegisterMedicineScreen> createState() => _RegisterMedicineScreenState();
}

class _RegisterMedicineScreenState extends State<RegisterMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicamentoService = MedicamentoService();

  final _nombreController = TextEditingController();
  final _gtinController = TextEditingController();
  final _principioActivoController = TextEditingController();
  final _laboratorioController = TextEditingController();
  final _registroSanitarioController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioCajaController = TextEditingController();
  final _precioBlisterController = TextEditingController();
  final _precioUnidadController = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedUnitId;

  File? _imageFile;
  final _picker = ImagePicker();

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'nombre': 'Analgésicos'},
    {'id': 2, 'nombre': 'Antipiréticos'},
    {'id': 3, 'nombre': 'Antiinflamatorios'},
    {'id': 4, 'nombre': 'Antibióticos'},
    {'id': 5, 'nombre': 'Antivirales'},
    {'id': 6, 'nombre': 'Antifúngicos'},
    {'id': 7, 'nombre': 'Antidepresivos'},
    {'id': 8, 'nombre': 'Ansiolíticos'},
    {'id': 9, 'nombre': 'Antihistamínicos'},
    {'id': 10, 'nombre': 'Suplementos'},
  ];

  final List<Map<String, dynamic>> _units = [
    {'id': 1, 'nombre': 'Tabletas'},
    {'id': 2, 'nombre': 'Cápsulas'},
    {'id': 3, 'nombre': 'Jarabes'},
    {'id': 4, 'nombre': 'Inyectables'},
    {'id': 5, 'nombre': 'Cremas'},
  ];

  bool _isSaving = false;
  bool _isSearching = false;

  // Función para buscar en la API de Open Product Facts
  Future<void> _autocompleteWithAPI(String barcode) async {
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          
          setState(() {
            _nombreController.text = product['product_name'] ?? '';
            _laboratorioController.text = product['brands'] ?? '';
            _descripcionController.text = product['generic_name'] ?? product['ingredients_text'] ?? '';
            
            // Intentar mapear categoría si existe
            if (product['categories_tags'] != null && product['categories_tags'].isNotEmpty) {
               // Aquí podrías hacer un mapeo más complejo, por ahora dejamos una pista
               _descripcionController.text += "\nCategoría sugerida: ${product['categories_tags'][0]}";
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✨ Datos autocompletados con éxito'), backgroundColor: AppTheme.brandGreen),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ℹ️ Producto no encontrado en la base global, rellene manualmente.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error API: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // Función para abrir el escáner y recibir el código
  Future<void> _scanBarcode() async {
    // Navegamos al escáner y esperamos el resultado (suponiendo que ScannerScreen devuelve el string)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (result != null && result is String) {
      _gtinController.text = result;
      _autocompleteWithAPI(result);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _registerMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 1. Verificar si el GTIN ya existe para evitar duplicados
      final existing = await _medicamentoService.buscarPorGTIN(_gtinController.text.trim());
      
      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ℹ️ Este código de barras ya está registrado en el catálogo global.'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      String? imageBase64;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final success = await _medicamentoService.registerMedicamentoMaestro({
        'nombre': _nombreController.text.trim(),
        'gtin': _gtinController.text.trim(),
        'principio_actvo': _principioActivoController.text.trim(),
        'laboratorio': _laboratorioController.text.trim(),
        'registro_sanitario': _registroSanitarioController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'categoria_id': _selectedCategoryId,
        'unidad_id': _selectedUnitId,
        'imagen_base64': imageBase64, // La imagen ayuda a identificar el producto globalmente
        // Los precios se han eliminado de aquí para que no sean públicos
      });

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Medicamento registrado en el catálogo maestro'),
              backgroundColor: AppTheme.brandGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _clearForm();
        } else {
          throw Exception('No se pudo registrar. Verifica los logs del servidor.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _nombreController.clear();
    _gtinController.clear();
    _principioActivoController.clear();
    _laboratorioController.clear();
    _registroSanitarioController.clear();
    _descripcionController.clear();
    _precioCajaController.clear();
    _precioBlisterController.clear();
    _precioUnidadController.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedUnitId = null;
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
      appBar: AppBar(
        title: Text('Catálogo Maestro',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.darkText)),
        elevation: 0,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.darkText),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: AppTheme.danger),
            onPressed: () => Navigator.pushNamed(context, '/report-problem'),
            tooltip: 'Reportar datos erróneos',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nuevo Registro Técnico',
                  style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.brightGreen : AppTheme.brandGreen)),
              const SizedBox(height: 8),
              Text('Cumple con los requisitos de AGEMED para la trazabilidad nacional.',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600)),
              const SizedBox(height: 24),
              
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.softGrey,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      image: _imageFile != null
                          ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, 
                                color: isDark ? AppTheme.brightGreen : AppTheme.brandGreen,
                                size: 32),
                              const SizedBox(height: 8),
                              Text('Foto', 
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.brightGreen : AppTheme.brandGreen
                                )),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              _buildTextField('Nombre Comercial', _nombreController, Icons.medication, isDark),
              const SizedBox(height: 16),
              
              _buildTextField('Código GTIN / Barra', _gtinController, Icons.qr_code_scanner_rounded, isDark, 
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_gtinController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () => setState(() => _gtinController.clear()),
                        color: Colors.grey,
                      ),
                    IconButton(
                      icon: _isSearching 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.camera_alt_rounded),
                      onPressed: _isSearching ? null : _scanBarcode,
                      color: isDark ? AppTheme.brightGreen : AppTheme.brandGreen,
                      tooltip: 'Escanear nuevo medicamento',
                    ),
                  ],
                )
              ),
              const SizedBox(height: 16),
              
              _buildTextField('Principio Activo', _principioActivoController, Icons.science, isDark),
              const SizedBox(height: 16),
              
              _buildTextField('Laboratorio Fabricante', _laboratorioController, Icons.factory_outlined, isDark),
              const SizedBox(height: 16),

              _buildTextField('Registro Sanitario AGEMED', _registroSanitarioController, Icons.verified_user_outlined, isDark),
              const SizedBox(height: 16),

              _buildDropdownField(
                'Categoría Farmacéutica', 
                _selectedCategoryId, 
                _categories, 
                Icons.category_rounded, 
                isDark,
                (val) => setState(() => _selectedCategoryId = val)
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                'Unidad de Presentación', 
                _selectedUnitId, 
                _units, 
                Icons.inventory_2_rounded, 
                isDark,
                (val) => setState(() => _selectedUnitId = val)
              ),
              const SizedBox(height: 24),

              Text('Configuración de Precios Sugeridos',
                  style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.darkText)),
              const SizedBox(height: 12),
              
              if (_selectedUnitId == 1 || _selectedUnitId == 2) ...[
                Row(
                  children: [
                    Expanded(child: _buildPriceField('Precio Caja', _precioCajaController, isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPriceField('Precio Blister/Tira', _precioBlisterController, isDark)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPriceField('Precio por Unidad (Individual)', _precioUnidadController, isDark),
              ] else ...[
                _buildPriceField('Precio de Venta (Unidad/Frasco)', _precioUnidadController, isDark),
              ],
              
              const SizedBox(height: 24),

              _buildTextField('Descripción Detallada', _descripcionController, Icons.description, isDark, maxLines: 3),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _registerMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.brightGreen : AppTheme.brandGreen,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? CircularProgressIndicator(color: isDark ? Colors.black : Colors.white)
                      : const Text('REGISTRAR PRODUCTO',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon, bool isDark,
      {int maxLines = 1, Widget? suffixIcon}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.darkText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
        prefixIcon: Icon(icon, color: isDark ? AppTheme.brightGreen : AppTheme.brandGreen),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : AppTheme.softGrey,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        alignLabelWithHint: true,
      ),
      validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
    );
  }

  Widget _buildPriceField(String label, TextEditingController controller, bool isDark) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: isDark ? Colors.white : AppTheme.darkText),
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Bs ',
        prefixStyle: TextStyle(color: isDark ? AppTheme.brightGreen : AppTheme.brandGreen, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : AppTheme.softGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownField(String label, int? value, List<Map<String, dynamic>> items, IconData icon, bool isDark, Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      value: value,
      items: items.map((item) => DropdownMenuItem<int>(
        value: item['id'],
        child: Text(item['nombre'], style: TextStyle(color: isDark ? Colors.white : AppTheme.darkText)),
      )).toList(),
      onChanged: onChanged,
      dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
        prefixIcon: Icon(icon, color: isDark ? AppTheme.brightGreen : AppTheme.brandGreen),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : AppTheme.softGrey,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (value) => value == null ? 'Selección requerida' : null,
    );
  }
}
