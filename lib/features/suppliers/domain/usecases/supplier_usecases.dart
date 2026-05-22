import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetSuppliersUseCase implements UseCase<List<Supplier>, NoParams> {
  final SupplierRepository repository;
  GetSuppliersUseCase(this.repository);

  @override
  Future<Either<Failure, List<Supplier>>> call(NoParams params) =>
      repository.getSuppliers();
}

class AddSupplierUseCase implements UseCase<void, Supplier> {
  final SupplierRepository repository;
  AddSupplierUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Supplier params) =>
      repository.addSupplier(params);
}

class UpdateSupplierUseCase implements UseCase<void, Supplier> {
  final SupplierRepository repository;
  UpdateSupplierUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Supplier params) =>
      repository.updateSupplier(params);
}

class DeleteSupplierUseCase implements UseCase<void, String> {
  final SupplierRepository repository;
  DeleteSupplierUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) =>
      repository.deleteSupplier(params);
}
