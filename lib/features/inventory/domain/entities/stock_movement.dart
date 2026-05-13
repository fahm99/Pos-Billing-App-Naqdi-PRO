import 'package:equatable/equatable.dart';

enum MovementType { stockIn, stockOut, adjustment, returned }

class StockMovement extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final MovementType type;
  final int quantity;
  final int stockBefore;
  final int stockAfter;
  final String? note;
  final DateTime date;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    this.note,
    required this.date,
  });

  String get typeLabel {
    switch (type) {
      case MovementType.stockIn:
        return 'وارد';
      case MovementType.stockOut:
        return 'صادر';
      case MovementType.adjustment:
        return 'تعديل';
      case MovementType.returned:
        return 'مرتجع';
    }
  }

  @override
  List<Object?> get props =>
      [id, productId, type, quantity, stockBefore, stockAfter, date];
}
