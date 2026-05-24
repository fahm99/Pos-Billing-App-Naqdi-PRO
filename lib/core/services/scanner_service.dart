import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerService {
  static final ScannerService _instance = ScannerService._();
  factory ScannerService() => _instance;
  ScannerService._();

  /// يتم تعيينه عند إتمام عملية بيع للعودة للكاميرا بحالة إيقاف
  static bool saleJustCompleted = false;

  MobileScannerController? _controller;
  int _referenceCount = 0;

  MobileScannerController controller(String widgetKey) {
    _referenceCount++;
    _controller ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
      autoStart: false,
    );
    return _controller!;
  }

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
      dispose();
    }
  }

  void dispose() {
    _referenceCount = 0;
    try {
      _controller?.stop();
      _controller?.dispose();
    } catch (_) {}
    _controller = null;
  }
}
