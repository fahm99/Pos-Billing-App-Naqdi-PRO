import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/supplier.dart';

abstract class SupplierRepository {
  Future<Either<Failure, List<Supplier>>> getSuppliers();
  Future<Either<Failure, void>> addSupplier(Supplier supplier);
  Future<Either<Failure, void>> updateSupplier(Supplier supplier);
  Future<Either<Failure, void>> deleteSupplier(String id);
}
