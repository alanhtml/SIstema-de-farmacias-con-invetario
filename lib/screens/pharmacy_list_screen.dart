import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/medicamento_service.dart';
import '../theme/theme.dart';
import 'map_screen.dart';
import 'pharmacy_details_screen.dart';

class PharmacyListScreen extends StatefulWidget {
  const PharmacyListScreen({super.key});

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> {
  final MedicamentoService _medService = MedicamentoService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allFarmacias = [];
  List<Map<String, dynamic>> _filteredFarmacias = [];

  @override
  void initState() {
    super.initState();
    _fetchFarmacias();
  }

  Future<void> _fetchFarmacias() async {
    setState(() => _isLoading = true);
    try {
      final data = await _medService.getFarmacias();
      setState(() {
        _allFarmacias = data;
        _filteredFarmacias = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar farmacias: $e')),
      );
    }
  }

  void _filterFarmacias(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFarmacias = _allFarmacias;
      } else {
        _filteredFarmacias = _allFarmacias.where((f) {
          final nombre = (f['nombre'] ?? '').toString().toLowerCase();
          return nombre.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Widget _buildPharmacyImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.brandGreen.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.local_pharmacy, color: AppTheme.brandGreen, size: 30),
      );
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.memory(
          base64Decode(base64String),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.brandGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.broken_image, color: AppTheme.brandGreen),
          ),
        ),
      );
    } catch (e) {
      return const Icon(Icons.local_pharmacy, color: AppTheme.brandGreen, size: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmacias Registradas', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.brandGreen,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterFarmacias,
              decoration: InputDecoration(
                hintText: 'Buscar farmacia por nombre...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.brandGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppTheme.brandGreen),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
                : _filteredFarmacias.isEmpty
                    ? const Center(child: Text('No se encontraron farmacias.'))
                    : RefreshIndicator(
                        onRefresh: _fetchFarmacias,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredFarmacias.length,
                          itemBuilder: (context, index) {
                            final farmacia = _filteredFarmacias[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 4,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: _buildPharmacyImage(farmacia['foto_fachada_base64']),
                                title: Text(farmacia['nombre'] ?? 'Sin nombre',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(farmacia['direccion'] ?? 'Sin dirección'),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(farmacia['rating']?.toString() ?? '4.5', 
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PharmacyDetailsScreen(farmacia: farmacia),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        },
        label: const Text('Ver en Mapa', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.map_rounded, color: Colors.white),
        backgroundColor: AppTheme.brandGreen,
      ),
    );
  }
}
