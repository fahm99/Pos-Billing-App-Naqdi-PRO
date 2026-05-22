import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/stock_movement.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<StockMovement>>> getMovements(
      {String? productId});
  Future<Either<Failure, void>> addMovement(StockMovement movement);
}
