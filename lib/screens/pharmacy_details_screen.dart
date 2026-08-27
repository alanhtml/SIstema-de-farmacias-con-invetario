import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/medicamento_service.dart';
import '../theme/theme.dart';

class PharmacyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> farmacia;

  const PharmacyDetailsScreen({super.key, required this.farmacia});

  @override
  State<PharmacyDetailsScreen> createState() => _PharmacyDetailsScreenState();
}

class _PharmacyDetailsScreenState extends State<PharmacyDetailsScreen> {
  final MedicamentoService _medService = MedicamentoService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _filteredInventory = [];
  String _selectedCategory = 'Todos';

  final List<String> _categories = [
    'Todos',
    'Analgésicos',
    'Antibióticos',
    'Antiinflamatorios',
    'Vitaminas',
    'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      // Fetching all maestro data to enrich inventory items
      final maestroSnapshot = await _medService.buscarPorGTIN(''); // This is not ideal, but let's see how buscarGlobal does it
      // Actually, let's use a more efficient way or just reuse buscarGlobal and filter
      final allEnriched = await _medService.buscarGlobal('');
      final farmaciaId = widget.farmacia['id'].toString();
      
      setState(() {
        _inventory = allEnriched.where((item) => 
          item['farmacia_id']?.toString() == farmaciaId || 
          item['farmacia']?['id']?.toString() == farmaciaId
        ).toList();
        _filteredInventory = _inventory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching inventory: $e');
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'Todos') {
        _filteredInventory = _inventory;
      } else {
        _filteredInventory = _inventory.where((item) {
          final itemCat = item['categoria']?.toString() ?? 'Otros';
          return itemCat.toLowerCase() == category.toLowerCase();
        }).toList();
      }
    });
  }

  Widget _buildPharmacyAvatar() {
    final base64String = widget.farmacia['foto_fachada_base64'];
    if (base64String == null || base64String.isEmpty) {
      return const CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white,
        child: Icon(Icons.local_pharmacy, color: AppTheme.brandGreen, size: 40),
      );
    }

    try {
      return CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white,
        backgroundImage: MemoryImage(base64Decode(base64String)),
      );
    } catch (e) {
      return const CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white,
        child: Icon(Icons.broken_image, color: AppTheme.brandGreen, size: 40),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farmacia['nombre'] ?? 'Detalles', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.brandGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header con info de la farmacia
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.brandGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                _buildPharmacyAvatar(),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.farmacia['latitud'] != null)
                        Text(
                          'GPS: ${widget.farmacia['latitud']}, ${widget.farmacia['longitud']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      Text(widget.farmacia['direccion'] ?? 'Dirección no disponible',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 5),
                      const Text('Abierto ahora', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Selector de categorías
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (bool selected) => _filterByCategory(cat),
                    selectedColor: AppTheme.brandGreen.withOpacity(0.2),
                    checkmarkColor: AppTheme.brandGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.brandGreen : Colors.black54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Listado de Stock
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
                : _filteredInventory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No hay productos en esta categoría', 
                              style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredInventory.length,
                        itemBuilder: (context, index) {
                          final item = _filteredInventory[index];
                          final stock = item['stock_actual'] ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/medication-detail',
                                  arguments: item,
                                );
                              },
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.medication, color: AppTheme.brandGreen),
                              ),
                              title: Text(item['nombre'] ?? 'Medicamento', 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(item['presentacion'] ?? 'Unidad'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Bs. ${item['precio'] ?? '0.00'}', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brandGreen)),
                                  Text('Stock: $stock', 
                                    style: TextStyle(
                                      color: stock < 10 ? Colors.red : Colors.grey,
                                      fontSize: 12,
                                    )),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
