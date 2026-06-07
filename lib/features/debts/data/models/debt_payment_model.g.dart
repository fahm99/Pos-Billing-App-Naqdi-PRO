part of 'debt_payment_model.dart';

class DebtPaymentModelAdapter extends TypeAdapter<DebtPaymentModel> {
  @override
  final int typeId = 11;

  @override
  DebtPaymentModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return DebtPaymentModel(
      id: fields[0] as String,
      debtId: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DebtPaymentModel obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.debtId);
    writer.writeByte(2);
    writer.write(obj.amount);
    writer.writeByte(3);
    writer.write(obj.date);
    writer.writeByte(4);
    writer.write(obj.notes);
  }
}
