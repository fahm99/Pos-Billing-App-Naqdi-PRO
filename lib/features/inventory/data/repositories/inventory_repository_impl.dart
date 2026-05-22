import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/stock_movement_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  @override
  Future<Either<Failure, List<StockMovement>>> getMovements(
      {String? productId}) async {
    try {
      var movements = HiveDatabase.stockMovementBox.values
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (productId != null) {
        movements = movements.where((m) => m.productId == productId).toList();
      }
      return Right(movements);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addMovement(StockMovement movement) async {
    try {
      final model = StockMovementModel.fromEntity(movement);
      await HiveDatabase.stockMovementBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
