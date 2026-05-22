import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  MobileScannerController? _controller;
  bool _isReady = false;
  bool _scanned = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initController());
  }

  Future<void> _initController() async {
    if (_isDisposed) return;
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        returnImage: false,
      );
      await _controller!.start();
      if (mounted && !_isDisposed) setState(() => _isReady = true);
    } catch (_) {
      if (mounted && !_isDisposed) setState(() => _isReady = false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller?.stop();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned || !_isReady || _isDisposed) return;
    final barcode = capture.barcodes.firstWhere(
      (b) => b.rawValue != null,
      orElse: () => const Barcode(),
    );
    if (barcode.rawValue == null) return;
    _scanned = true;
    HapticFeedback.mediumImpact();
    _controller?.stop();
    if (mounted) context.pop(barcode.rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('مسح الباركود',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Stack(
        children: [
          if (_isReady && _controller != null)
            MobileScanner(controller: _controller!, onDetect: _onDetect)
          else
            const Center(child: CircularProgressIndicator()),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'ضع الباركود داخل الإطار',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
