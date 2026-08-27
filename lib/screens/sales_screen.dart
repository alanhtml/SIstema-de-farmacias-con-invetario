import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmacia_app/services/auth_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String? _farmaciaId;
  bool _isLoading = true;
  String _searchQuery = '';
  final List<Map<String, dynamic>> _cart = [];

  @override
  void initState() {
    super.initState();
    _loadFarmaciaId();
  }

  Future<void> _loadFarmaciaId() async {
    final user = _authService.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      _farmaciaId = profile?['farmacia_id'];
      if (_farmaciaId == null) {
        final prefs = await SharedPreferences.getInstance();
        _farmaciaId = prefs.getString('local_farmacia_string_id');
      }
    }
    setState(() => _isLoading = false);
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final index = _cart.indexWhere((element) => element['id'] == item['id']);
      if (index != -1) {
        if (_cart[index]['cantidad_venta'] < item['stock_actual']) {
          _cart[index]['cantidad_venta']++;
        }
      } else {
        _cart.add({
          ...item,
          'cantidad_venta': 1,
        });
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cart[index]['cantidad_venta'] > 1) {
        _cart[index]['cantidad_venta']--;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  double get _totalSales {
    return _cart.fold(0, (sum, item) {
      // Intentar obtener precio de venta, por defecto 1.0 si no existe
      double precio = 0.0;
      if (item['precios'] != null) {
        precio = double.tryParse(item['precios']['unidad']?.toString() ?? '0') ?? 0.0;
      }
      return sum + (precio * item['cantidad_venta']);
    });
  }

  Future<void> _processSale() async {
    if (_cart.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
    );

    try {
      final batch = _firestore.batch();
      final saleId = _firestore.collection('ventas').doc().id;

      for (var item in _cart) {
        // Actualizar stock en inventario
        final invRef = _firestore.collection('inventarios').doc(item['id']);
        batch.update(invRef, {
          'stock_actual': FieldValue.increment(-item['cantidad_venta']),
        });

        // Registrar movimiento
        final movRef = _firestore.collection('movimientos').doc();
        batch.set(movRef, {
          'farmacia_id': _farmaciaId,
          'medicamento_id': item['medicamento_id'],
          'tipo': 'venta',
          'cantidad': item['cantidad_venta'],
          'fecha': FieldValue.serverTimestamp(),
          'lote': item['lote'],
          'venta_id': saleId,
        });
      }

      // Registrar la venta general
      final saleRef = _firestore.collection('ventas').doc(saleId);
      batch.set(saleRef, {
        'farmacia_id': _farmaciaId,
        'fecha': FieldValue.serverTimestamp(),
        'total': _totalSales,
        'items': _cart.map((e) => {
          'nombre': e['nombre'],
          'cantidad': e['cantidad_venta'],
          'precio_unitario': e['precios']?['unidad'] ?? 0,
        }).toList(),
      });

      await batch.commit();
      
      Navigator.pop(context); // Cerrar loading
      setState(() => _cart.clear());
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta realizada con éxito'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar venta: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.softGrey,
      appBar: AppBar(
        title: Text('Nueva Venta', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildSearchBar(isDark),
              Expanded(
                child: Row(
                  children: [
                    // Lista de productos
                    Expanded(
                      flex: 3,
                      child: _buildInventoryList(isDark),
                    ),
                    // Carrito lateral
                    if (_cart.isNotEmpty)
                    Container(
                      width: 300,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        border: Border(left: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                      ),
                      child: _buildCart(isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o código...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.brandGreen),
          filled: true,
          fillColor: isDark ? AppTheme.darkSurface : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildInventoryList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('inventarios')
          .where('farmacia_id', isEqualTo: _farmaciaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final nombre = (data['nombre'] ?? '').toString().toLowerCase();
          return nombre.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return Center(child: Text('No hay productos disponibles', style: GoogleFonts.manrope(color: Colors.grey)));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            final stock = data['stock_actual'] ?? 0;
            
            return InkWell(
              onTap: stock > 0 ? () => _addToCart({...data, 'id': id}) : null,
              child: Opacity(
                opacity: stock > 0 ? 1 : 0.5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['nombre'] ?? 'Sin nombre', 
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                      Text('Lote: ${data['lote']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Stock: $stock', 
                            style: TextStyle(
                              color: stock < 10 ? AppTheme.danger : AppTheme.brandGreen,
                              fontWeight: FontWeight.bold
                            )),
                          const Icon(Icons.add_circle_outline, color: AppTheme.brandGreen),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCart(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Resumen de Venta', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _cart.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = _cart[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Cant: ${item['cantidad_venta']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger, size: 20),
                  onPressed: () => _removeFromCart(index),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_totalSales.toStringAsFixed(2)} Bs.', 
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppTheme.brandGreen, fontSize: 20)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _processSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('CONFIRMAR VENTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
