import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerService {
  static final ScannerService _instance = ScannerService._();
  factory ScannerService() => _instance;
  ScannerService._();

  /// يتم تعيينه عند إتمام عملية بيع للعودة للكاميرا بحالة إيقاف
  static bool saleJustCompleted = false;

  MobileScannerController createController({
    DetectionSpeed detectionSpeed = DetectionSpeed.noDuplicates,
    bool returnImage = false,
    bool autoStart = false,
  }) {
    return MobileScannerController(
      detectionSpeed: detectionSpeed,
      returnImage: returnImage,
      autoStart: autoStart,
    );
  }

  Future<void> startController(MobileScannerController controller) async {
    try {
      await controller.start();
    } catch (_) {}
  }

  void stopController(MobileScannerController controller) {
    try {
      controller.stop();
    } catch (_) {}
  }

  Future<void> disposeController(MobileScannerController controller) async {
    try {
      await controller.stop();
      await controller.dispose();
    } catch (_) {}
  }
}
