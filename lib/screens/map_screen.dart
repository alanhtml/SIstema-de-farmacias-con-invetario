import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:farmacia_app/services/medicamento_service.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'pharmacy_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  final MedicamentoService _medService = MedicamentoService();
  List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    await _getUserLocation();
    await _loadFarmacias();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadFarmacias() async {
    try {
      final farmacias = await _medService.getFarmacias();
      
      final List<Marker> newMarkers = farmacias.map((f) {
        final double lat = double.tryParse(f['latitud']?.toString() ?? '') ?? -16.5000;
        final double lng = double.tryParse(f['longitud']?.toString() ?? '') ?? -68.1500;
        
        return Marker(
          point: LatLng(lat, lng),
          width: 60,
          height: 60,
          child: GestureDetector(
            onTap: () => _showFarmaciaDetails(f),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sombra del pin
                const Positioned(
                  bottom: 5,
                  child: Icon(Icons.location_on, color: Colors.black26, size: 54),
                ),
                // Pin principal
                const Icon(Icons.location_on, color: AppTheme.brandGreen, size: 50),
                // Icono de casita blanca dentro del pin
                const Positioned(
                  top: 8,
                  child: Icon(
                    Icons.home_rounded, // Icono de casita
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList();

      if (mounted) {
        setState(() => _markers = newMarkers);
      }
    } catch (e) {
      debugPrint('Error cargando farmacias: $e');
    }
  }

  Widget _buildPharmacyImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.brandGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.local_pharmacy, color: AppTheme.brandGreen, size: 30),
      );
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          base64Decode(base64String),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.brandGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.broken_image, color: AppTheme.brandGreen),
      );
    }
  }

  void _showFarmaciaDetails(Map<String, dynamic> f) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPharmacyImage(f['foto_fachada_base64']),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f['nombre'] ?? 'Farmacia', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.brandGreen)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(f['direccion'] ?? 'Dirección no disponible', 
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PharmacyDetailsScreen(farmacia: f),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Ver Inventario", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Cerrar"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() => _currentPosition = position);
          _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
        }
      }
    } catch (e) {
      debugPrint('Error GPS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Red de Farmacias", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.brandGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(-16.5000, -68.1500),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.farmacia_app',
              ),
              MarkerLayer(markers: _markers),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.my_location, color: Colors.blue, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
            
          if (_markers.isEmpty && !_isLoading)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.black87),
                    SizedBox(width: 10),
                    Expanded(child: Text("No hay farmacias registradas en el mapa.", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'refresh',
            onPressed: _initializeMapData,
            backgroundColor: Colors.white,
            mini: true,
            child: const Icon(Icons.refresh, color: AppTheme.brandGreen),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'location',
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(
                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  16.0,
                );
              } else {
                _getUserLocation();
              }
            },
            backgroundColor: AppTheme.brandGreen,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
