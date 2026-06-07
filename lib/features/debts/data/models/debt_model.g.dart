part of 'debt_model.dart';

class DebtModelAdapter extends TypeAdapter<DebtModel> {
  @override
  final int typeId = 10;

  @override
  DebtModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return DebtModel(
      id: fields[0] as String,
      customerId: fields[1] as String?,
      customerName: fields[2] as String,
      originalAmount: fields[3] as double,
      remainingAmount: fields[4] as double,
      description: fields[5] as String,
      date: fields[6] as DateTime,
      dueDate: fields[7] as DateTime?,
      status: fields[8] as String? ?? 'active',
    );
  }

  @override
  void write(BinaryWriter writer, DebtModel obj) {
    writer.writeByte(9);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.customerId);
    writer.writeByte(2);
    writer.write(obj.customerName);
    writer.writeByte(3);
    writer.write(obj.originalAmount);
    writer.writeByte(4);
    writer.write(obj.remainingAmount);
    writer.writeByte(5);
    writer.write(obj.description);
    writer.writeByte(6);
    writer.write(obj.date);
    writer.writeByte(7);
    writer.write(obj.dueDate);
    writer.writeByte(8);
    writer.write(obj.status);
  }
}
