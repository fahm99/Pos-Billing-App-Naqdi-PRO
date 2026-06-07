import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/zakat_payment.dart';
import '../../domain/repositories/zakat_repository.dart';
import '../models/zakat_payment_model.dart';

class ZakatRepositoryImpl implements ZakatRepository {
  @override
  Future<Either<Failure, List<ZakatPayment>>> getPayments() async {
    try {
      final payments = HiveDatabase.zakatPaymentBox.values
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return Right(payments);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addPayment(ZakatPayment payment) async {
    try {
      final model = ZakatPaymentModel.fromEntity(payment);
      await HiveDatabase.zakatPaymentBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePayment(String id) async {
    try {
      await HiveDatabase.zakatPaymentBox.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalPaid() async {
    try {
      final total = HiveDatabase.zakatPaymentBox.values
          .fold<double>(0, (sum, m) => sum + m.amount);
      return Right(total);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
