import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerService {
  static final ScannerService _instance = ScannerService._();
  factory ScannerService() => _instance;
  ScannerService._();

  MobileScannerController? _controller;
  int _referenceCount = 0;
  bool _wasDisposed = false;

  MobileScannerController controller(String widgetKey) {
    _referenceCount++;
    if (_controller == null) {
      _wasDisposed = false;
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        returnImage: false,
        autoStart: false,
      );
    }
    return _controller!;
  }

  bool get isReused => _wasDisposed;

  Future<void> start() async {
    try {
      await _controller?.start();
    } catch (_) {}
  }

  void stop() {
    try {
      _controller?.stop();
    } catch (_) {}
  }

  void release(String widgetKey) {
    _referenceCount--;
    if (_referenceCount <= 0) {
      _referenceCount = 0;
      _wasDisposed = true;
      stop();
    }
  }

  void dispose() {
    _referenceCount = 0;
    _wasDisposed = true;
    try {
      _controller?.stop();
      _controller?.dispose();
    } catch (_) {}
    _controller = null;
  }
}
