import '../../../../core/utils/printer_helper.dart';

abstract class PrinterRepository {
  Future<List<BluetoothDevice>> scanDevices();
  Future<bool> connect(String macAddress, String name);
  Future<bool> disconnect();
  String? getSavedPrinterMac();
  String? getSavedPrinterName();
  Future<void> savePrinterData(String mac, String name);
  Future<void> clearPrinterData();
  Future<void> testPrint(String shopName);
}
