import 'package:hive/hive.dart';
import '../../domain/entities/stock_movement.dart';

part 'stock_movement_model.g.dart';

@HiveType(typeId: 7)
class StockMovementModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String productId;
  @HiveField(2)
  final String productName;
  @HiveField(3)
  final int type; // index of MovementType
  @HiveField(4)
  final int quantity;
  @HiveField(5)
  final int stockBefore;
  @HiveField(6)
  final int stockAfter;
  @HiveField(7)
  final String? note;
  @HiveField(8)
  final DateTime date;

  StockMovementModel({
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

  factory StockMovementModel.fromEntity(StockMovement m) => StockMovementModel(
        id: m.id,
        productId: m.productId,
        productName: m.productName,
        type: m.type.index,
        quantity: m.quantity,
        stockBefore: m.stockBefore,
        stockAfter: m.stockAfter,
        note: m.note,
        date: m.date,
      );

  StockMovement toEntity() => StockMovement(
        id: id,
        productId: productId,
        productName: productName,
        type: MovementType.values[type],
        quantity: quantity,
        stockBefore: stockBefore,
        stockAfter: stockAfter,
        note: note,
        date: date,
      );
}
