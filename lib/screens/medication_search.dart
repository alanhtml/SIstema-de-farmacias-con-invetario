import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmacia_app/screens/error_view.dart';
import 'package:farmacia_app/services/medicamento_service.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:geolocator/geolocator.dart';

class MedicationSearchScreen extends StatefulWidget {
  const MedicationSearchScreen({super.key});

  @override
  State<MedicationSearchScreen> createState() => _MedicationSearchScreenState();
}

class _MedicationSearchScreenState extends State<MedicationSearchScreen> {
  final MedicamentoService _medicamentoService = MedicamentoService();
  String _searchQuery = '';
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All Medications';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition().then((pos) {
      setState(() => _currentPosition = pos);
      _performSearch();
    }).catchError((e) {
      _performSearch();
    });
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      var results = await _medicamentoService.buscarGlobal(_searchQuery);
      
      if (_currentPosition != null) {
        for (var item in results) {
          final farmacia = item['farmacia'];
          if (farmacia != null && farmacia['latitud'] != null && farmacia['longitud'] != null) {
            double distanceInMeters = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              double.tryParse(farmacia['latitud'].toString()) ?? 0.0,
              double.tryParse(farmacia['longitud'].toString()) ?? 0.0,
            );
            item['distancia_m'] = distanceInMeters;
            item['distancia_km'] = distanceInMeters / 1000;
          }
        }
        // Sort by distance if available
        results.sort((a, b) {
          double distA = a['distancia_m'] ?? double.infinity;
          double distB = b['distancia_m'] ?? double.infinity;
          return distA.compareTo(distB);
        });
      }

      if (mounted) {
        setState(() {
          _results = results;
          
          if (_selectedCategory != 'All Medications') {
            _results = _results.where((item) => 
              (item['categoria'] ?? '').toString().toLowerCase() == _selectedCategory.toLowerCase()
            ).toList();
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Icon(Icons.assignment, color: isDark ? AppTheme.brightGreen : AppTheme.brandGreen, size: 28),
            const SizedBox(width: 10),
            Text(
              'Búsqueda Medivida',
              style: GoogleFonts.manrope(
                color: isDark ? Colors.white : AppTheme.brandGreen,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Medication Search',
                  style: GoogleFonts.manrope(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.darkText,
                  ),
                ),
                Text(
                  'Verify inventory and dosage across the clinical network.',
                  style: TextStyle(color: isDark ? Colors.white60 : AppTheme.neutralGrey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildSearchBar(isDark),
                const SizedBox(height: 24),
                _buildFilterRow(isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: isDark ? AppTheme.brightGreen : AppTheme.brandGreen))
              : _error != null
                ? ErrorView(
                    message: _error!,
                    isDark: isDark,
                    onRetry: _performSearch,
                  )
                : _results.isEmpty 
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        final int stock = int.tryParse(item['stock_actual']?.toString() ?? '0') ?? 0;
                        final statusColor = stock > 10 ? (isDark ? AppTheme.brightGreen : AppTheme.brandGreen) : (stock > 0 ? Colors.orange : AppTheme.danger);
                        final double? distance = item['distancia_km'];

                        return InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/medication-detail',
                              arguments: item,
                            );
                          },
                          child: _buildMedicationCard(
                            title: item['nombre'] ?? 'Unknown',
                            subtitle: '${item['principio_activo'] ?? 'No principle'} • ${item['presentacion'] ?? ''}',
                            tag: stock > 0 ? 'In Stock' : 'Out of Stock',
                            stock: '$stock units available',
                            statusColor: statusColor,
                            icon: Icons.medication,
                            isDark: isDark,
                            price: item['precio']?.toString(),
                            pharmacyName: item['farmacia']?['nombre'],
                            distance: distance != null ? '${distance.toStringAsFixed(1)} km' : null,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/scanner'),
        backgroundColor: isDark ? AppTheme.brightGreen : AppTheme.brandGreen,
        shape: const CircleBorder(),
        child: Icon(Icons.photo_camera, color: isDark ? Colors.black : Colors.white, size: 30),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.softGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _performSearch();
        },
        style: TextStyle(color: isDark ? Colors.white : AppTheme.darkText),
        decoration: InputDecoration(
          hintText: 'Search by name or molecule...',
          hintStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.neutralGrey),
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.white38 : AppTheme.neutralGrey),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildFilterRow(bool isDark) {
    final categories = ['All Medications', 'Antibiotics', 'Cardiovascular', 'Neurology'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) => _filterChip(cat, _selectedCategory == cat, isDark)).toList(),
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = label);
        _performSearch();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
            ? (isDark ? AppTheme.brightGreen : AppTheme.brandGreen) 
            : (isDark ? AppTheme.darkSurface : AppTheme.softGrey),
          borderRadius: BorderRadius.circular(99),
          boxShadow: isSelected 
            ? [BoxShadow(color: (isDark ? AppTheme.brightGreen : AppTheme.brandGreen).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
            : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
              ? (isDark ? Colors.black : Colors.white) 
              : (isDark ? Colors.white38 : AppTheme.neutralGrey),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: isDark ? Colors.white10 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No medications found',
            style: GoogleFonts.manrope(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard({
    required String title,
    required String subtitle,
    required String tag,
    required String stock,
    required Color statusColor,
    required IconData icon,
    required bool isDark,
    String? price,
    String? pharmacyName,
    String? distance,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: statusColor),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (price != null)
                    Text(
                      'Bs. $price',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.brandGreen,
                        fontSize: 16,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: isDark ? AppTheme.darkBackground : AppTheme.softGrey, borderRadius: BorderRadius.circular(6)),
                    child: Text(tag.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.darkText)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.darkText)),
          Text(subtitle, style: TextStyle(color: isDark ? Colors.white60 : AppTheme.neutralGrey, fontSize: 14)),
          if (pharmacyName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.store, size: 14, color: isDark ? Colors.white38 : AppTheme.neutralGrey),
                const SizedBox(width: 4),
                Text(
                  pharmacyName,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : AppTheme.neutralGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (distance != null) ...[
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: isDark ? Colors.white38 : AppTheme.neutralGrey)),
                  const SizedBox(width: 8),
                  Icon(Icons.location_on, size: 14, color: AppTheme.brandGreen),
                  const SizedBox(width: 2),
                  Text(
                    distance,
                    style: TextStyle(
                      color: AppTheme.brandGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: statusColor),
                  const SizedBox(width: 8),
                  Text(stock, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? AppTheme.brightGreen : AppTheme.brandGreen),
            ],
          )
        ],
      ),
    );
  }
}


