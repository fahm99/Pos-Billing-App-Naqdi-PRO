import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String address;
  final double creditBalance; // رصيد الدين (موجب = عليه دين)
  final double loyaltyPoints;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.creditBalance = 0,
    this.loyaltyPoints = 0,
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    double? creditBalance,
    double? loyaltyPoints,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      creditBalance: creditBalance ?? this.creditBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, phone, address, creditBalance, loyaltyPoints];
}
