import '../../../../core/data/hive_database.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../domain/repositories/printer_repository.dart';

class PrinterRepositoryImpl implements PrinterRepository {
  final PrinterHelper _helper = PrinterHelper();

  @override
  Future<List<BluetoothDevice>> scanDevices() async {
    if (await _helper.checkPermission()) {
      return await _helper.getBondedDevices();
    }
    throw Exception('Bluetooth permission denied');
  }

  @override
  Future<bool> connect(String macAddress, String name) =>
      _helper.connect(macAddress);

  @override
  Future<bool> disconnect() => _helper.disconnect();

  @override
  String? getSavedPrinterMac() => HiveDatabase.settingsBox.get('printer_mac');

  @override
  String? getSavedPrinterName() => HiveDatabase.settingsBox.get('printer_name');

  @override
  Future<void> savePrinterData(String mac, String name) async {
    await HiveDatabase.settingsBox.put('printer_mac', mac);
    await HiveDatabase.settingsBox.put('printer_name', name);
  }

  @override
  Future<void> clearPrinterData() async {
    await HiveDatabase.settingsBox.delete('printer_mac');
    await HiveDatabase.settingsBox.delete('printer_name');
  }

  @override
  Future<void> testPrint(String shopName) =>
      _helper.printText("Test Print\n\n$shopName\n\n----------------\n\n");
}
