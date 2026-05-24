import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final products =
          HiveDatabase.productBox.values.map((m) => m.toEntity()).toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final model = HiveDatabase.productBox.values.firstWhere(
        (m) => m.barcode == barcode,
        orElse: () => throw Exception('المنتج غير موجود'),
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      // You can use add() or put()
      final model = ProductModel.fromEntity(product);
      await box.put(model.id, model); // Using ID as key
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      final model = ProductModel.fromEntity(product);
      await box.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      final box = HiveDatabase.productBox;
      await box.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> adjustStock(
      String productId, int newStock) async {
    try {
      final box = HiveDatabase.productBox;
      final model = box.get(productId);
      if (model == null) return const Left(CacheFailure('المنتج غير موجود'));
      final updated = ProductModel(
        id: model.id,
        name: model.name,
        barcode: model.barcode,
        price: model.price,
        stock: newStock,
        costPrice: model.costPrice,
        minStock: model.minStock,
        unit: model.unit,
        category: model.category,
        expiryDate: model.expiryDate,
        imageUrl: model.imageUrl,
      );
      await box.put(productId, updated);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
