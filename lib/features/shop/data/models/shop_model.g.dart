// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShopModelAdapter extends TypeAdapter<ShopModel> {
  @override
  final int typeId = 1;

  @override
  ShopModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopModel(
      name: fields[0] as String? ?? '',
      addressLine1: fields[1] as String? ?? '',
      addressLine2: fields[2] as String? ?? '',
      phoneNumber: fields[3] as String? ?? '',
      upiId: fields[4] as String? ?? '',
      footerText: fields[5] as String? ?? '',
      currencyName: fields[6] as String? ?? 'ريال',
      currencySymbol: fields[7] as String? ?? 'ر.س',
      currencyLogo: fields[8] as String? ?? '',
      shopLogo: fields[9] as String? ?? '',
      defaultTaxPercent: (fields[10] as double?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, ShopModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.addressLine1)
      ..writeByte(2)
      ..write(obj.addressLine2)
      ..writeByte(3)
      ..write(obj.phoneNumber)
      ..writeByte(4)
      ..write(obj.upiId)
      ..writeByte(5)
      ..write(obj.footerText)
      ..writeByte(6)
      ..write(obj.currencyName)
      ..writeByte(7)
      ..write(obj.currencySymbol)
      ..writeByte(8)
      ..write(obj.currencyLogo)
      ..writeByte(9)
      ..write(obj.shopLogo)
      ..writeByte(10)
      ..write(obj.defaultTaxPercent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
