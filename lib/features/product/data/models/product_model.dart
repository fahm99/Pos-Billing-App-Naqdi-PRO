import 'package:hive/hive.dart';
import '../../domain/entities/product.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String barcode;
  @HiveField(3)
  final double price;
  @HiveField(4)
  final int stock;
  @HiveField(5)
  final double costPrice;
  @HiveField(6)
  final int minStock;
  @HiveField(7)
  final String unit;
  @HiveField(8)
  final String category;

  ProductModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.stock = 0,
    this.costPrice = 0.0,
    this.minStock = 5,
    this.unit = 'قطعة',
    this.category = 'عام',
  });

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      barcode: product.barcode,
      price: product.price,
      stock: product.stock,
      costPrice: product.costPrice,
      minStock: product.minStock,
      unit: product.unit,
      category: product.category,
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      barcode: barcode,
      price: price,
      stock: stock,
      costPrice: costPrice,
      minStock: minStock,
      unit: unit,
      category: category,
    );
  }
}
