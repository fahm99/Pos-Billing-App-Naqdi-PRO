import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../models/supplier_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  @override
  Future<Either<Failure, List<Supplier>>> getSuppliers() async {
    try {
      final suppliers = HiveDatabase.supplierBox.values
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Right(suppliers);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addSupplier(Supplier supplier) async {
    try {
      final model = SupplierModel.fromEntity(supplier);
      await HiveDatabase.supplierBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSupplier(Supplier supplier) async {
    try {
      final model = SupplierModel.fromEntity(supplier);
      await HiveDatabase.supplierBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSupplier(String id) async {
    try {
      await HiveDatabase.supplierBox.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
