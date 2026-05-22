import 'package:hive/hive.dart';
import '../../domain/entities/customer.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 3)
class CustomerModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String phone;
  @HiveField(3)
  final String address;
  @HiveField(4)
  final double creditBalance;
  @HiveField(5)
  final double loyaltyPoints;
  @HiveField(6)
  final DateTime createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.creditBalance = 0,
    this.loyaltyPoints = 0,
    required this.createdAt,
  });

  factory CustomerModel.fromEntity(Customer c) => CustomerModel(
        id: c.id,
        name: c.name,
        phone: c.phone,
        address: c.address,
        creditBalance: c.creditBalance,
        loyaltyPoints: c.loyaltyPoints,
        createdAt: c.createdAt,
      );

  Customer toEntity() => Customer(
        id: id,
        name: name,
        phone: phone,
        address: address,
        creditBalance: creditBalance,
        loyaltyPoints: loyaltyPoints,
        createdAt: createdAt,
      );
}
