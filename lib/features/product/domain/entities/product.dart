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
  final DateTime? expiryDate; // تاريخ انتهاء الصلاحية
  final String? imageUrl; // مسار صورة المنتج

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
    this.expiryDate,
    this.imageUrl,
  });

  double get profitMargin =>
      costPrice > 0 ? ((price - costPrice) / costPrice) * 100 : 0;

  bool get isLowStock => stock <= minStock;
  bool get isAtOrBelowReorderPoint => stock <= minStock;
  bool get isBelowReorderPoint => stock < minStock;

  /// الأيام المتبقية قبل انتهاء الصلاحية (null إذا لم يكن هناك تاريخ)
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// حالة الصلاحية
  ExpiryStatus get expiryStatus {
    if (expiryDate == null) return ExpiryStatus.unknown;
    final days = daysUntilExpiry!;
    if (days <= 0) return ExpiryStatus.expired;
    if (days <= 30) return ExpiryStatus.critical;
    if (days <= 60) return ExpiryStatus.warning;
    return ExpiryStatus.valid;
  }

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
    DateTime? expiryDate,
    String? imageUrl,
    bool clearExpiryDate = false,
    bool clearImageUrl = false,
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
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        barcode,
        price,
        costPrice,
        stock,
        minStock,
        unit,
        category,
        expiryDate,
        imageUrl
      ];
}

/// حالة صلاحية المنتج
enum ExpiryStatus {
  expired, // منتهي
  critical, // أقل من 30 يوم
  warning, // 31-60 يوم
  valid, // أكثر من 60 يوم
  unknown, // لا يوجد تاريخ
}
