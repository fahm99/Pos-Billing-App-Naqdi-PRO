part of 'zakat_payment_model.dart';

class ZakatPaymentModelAdapter extends TypeAdapter<ZakatPaymentModel> {
  @override
  final int typeId = 12;

  @override
  ZakatPaymentModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return ZakatPaymentModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      calculationFrom: fields[3] as DateTime,
      calculationTo: fields[4] as DateTime,
      totalSalesProfit: fields[5] as double,
      totalExpenses: fields[6] as double,
      notes: fields[7] as String?,
      status: fields[8] as String? ?? 'paid',
    );
  }

  @override
  void write(BinaryWriter writer, ZakatPaymentModel obj) {
    writer.writeByte(9);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.amount);
    writer.writeByte(2);
    writer.write(obj.date);
    writer.writeByte(3);
    writer.write(obj.calculationFrom);
    writer.writeByte(4);
    writer.write(obj.calculationTo);
    writer.writeByte(5);
    writer.write(obj.totalSalesProfit);
    writer.writeByte(6);
    writer.write(obj.totalExpenses);
    writer.writeByte(7);
    writer.write(obj.notes);
    writer.writeByte(8);
    writer.write(obj.status);
  }
}
