import 'package:hive/hive.dart';
import '../../domain/entities/supplier.dart';

part 'supplier_model.g.dart';

@HiveType(typeId: 4)
class SupplierModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String phone;
  @HiveField(3)
  final String address;
  @HiveField(4)
  final double balance;
  @HiveField(5)
  final DateTime createdAt;

  SupplierModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.balance = 0,
    required this.createdAt,
  });

  factory SupplierModel.fromEntity(Supplier s) => SupplierModel(
        id: s.id,
        name: s.name,
        phone: s.phone,
        address: s.address,
        balance: s.balance,
        createdAt: s.createdAt,
      );

  Supplier toEntity() => Supplier(
        id: id,
        name: name,
        phone: phone,
        address: address,
        balance: balance,
        createdAt: createdAt,
      );
}
