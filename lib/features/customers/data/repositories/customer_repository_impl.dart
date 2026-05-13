import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  @override
  Future<Either<Failure, List<Customer>>> getCustomers() async {
    try {
      final customers = HiveDatabase.customerBox.values
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Right(customers);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCustomer(Customer customer) async {
    try {
      final model = CustomerModel.fromEntity(customer);
      await HiveDatabase.customerBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) async {
    try {
      final model = CustomerModel.fromEntity(customer);
      await HiveDatabase.customerBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await HiveDatabase.customerBox.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
