import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final double costPrice;
  final int stock;
  final int minStock;
  final String unit; // قطعة، كيلو، لتر، علبة...
  final String category;

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.costPrice = 0.0,
    this.stock = 0,
    this.minStock = 5,
    this.unit = 'قطعة',
    this.category = 'عام',
  });

  double get profitMargin =>
      costPrice > 0 ? ((price - costPrice) / costPrice) * 100 : 0;

  bool get isLowStock => stock <= minStock;

  Product copyWith({
    String? id,
    String? name,
    String? barcode,
    double? price,
    double? costPrice,
    int? stock,
    int? minStock,
    String? unit,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, barcode, price, costPrice, stock, minStock, unit, category];
}
