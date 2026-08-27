import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:farmacia_app/services/medicamento_service.dart';
import 'package:farmacia_app/theme/theme.dart';
import 'package:farmacia_app/screens/verification_result.dart';
import 'package:farmacia_app/services/auth_service.dart';
import 'package:farmacia_app/config/constants.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acceso a cámara denegado')));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processScan(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final result = await MedicamentoService().verificarEscanear(code);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationResultScreen(
            status: result['status'] ?? 'error',
            data: result['data'] ?? {},
            message: result['message'],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final String? code = barcodes.first.rawValue;
                if (code != null) _processScan(code);
              }
            },
          ),
          // HUD de escaneo
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.srcOut),
            child: Stack(children: [
              Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
              Align(alignment: Alignment.center, child: Container(width: 280, height: 280, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)))),
            ]),
          ),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  Text('Verificador Medivida', style: GoogleFonts.manrope(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ]),
              ),
              const Spacer(),
              SizedBox(
                width: 280, height: 280,
                child: Stack(children: [
                  _buildCorners(),
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) => Positioned(
                      top: _scanAnimation.value * 270, left: 0, right: 0,
                      child: Container(height: 2, decoration: BoxDecoration(color: AppTheme.brandGreen, boxShadow: [BoxShadow(color: AppTheme.brandGreen.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)])),
                    ),
                  ),
                ]),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Text('Apunta al código de barras del producto', style: GoogleFonts.manrope(color: Colors.white70)),
              ),
            ]),
          ),
          if (_isProcessing) Container(color: Colors.black87, child: const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))),
        ],
      ),
    );
  }

  Widget _buildCorners() {
    const double len = 30.0;
    const double sw = 4.0;
    return Stack(children: [
      Positioned(top: 0, left: 0, child: Container(width: len, height: len, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: sw), left: BorderSide(color: Colors.white, width: sw)), borderRadius: BorderRadius.only(topLeft: Radius.circular(24))))),
      Positioned(top: 0, right: 0, child: Container(width: len, height: len, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: sw), right: BorderSide(color: Colors.white, width: sw)), borderRadius: BorderRadius.only(topRight: Radius.circular(24))))),
      Positioned(bottom: 0, left: 0, child: Container(width: len, height: len, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: sw), left: BorderSide(color: Colors.white, width: sw)), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24))))),
      Positioned(bottom: 0, right: 0, child: Container(width: len, height: len, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: sw), right: BorderSide(color: Colors.white, width: sw)), borderRadius: BorderRadius.only(bottomRight: Radius.circular(24))))),
    ]);
  }
}
