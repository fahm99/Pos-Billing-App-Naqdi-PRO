// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final int typeId = 9;

  @override
  ExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      amount: fields[3] as double,
      date: fields[4] as DateTime,
      categoryIndex: fields[5] as int,
      paymentMethod: fields[6] as String,
      supplierId: fields[7] as String?,
      receiptImagePath: fields[8] as String?,
      isRecurring: fields[9] as bool,
      recurringPeriodIndex: fields[10] as int?,
      notes: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.categoryIndex)
      ..writeByte(6)
      ..write(obj.paymentMethod)
      ..writeByte(7)
      ..write(obj.supplierId)
      ..writeByte(8)
      ..write(obj.receiptImagePath)
      ..writeByte(9)
      ..write(obj.isRecurring)
      ..writeByte(10)
      ..write(obj.recurringPeriodIndex)
      ..writeByte(11)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
