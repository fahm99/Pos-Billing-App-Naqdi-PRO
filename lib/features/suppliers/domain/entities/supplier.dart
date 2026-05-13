import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String address;
  final double balance; // موجب = مستحق للمورد
  final DateTime createdAt;

  const Supplier({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.balance = 0,
    required this.createdAt,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    double? balance,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, address, balance];
}
