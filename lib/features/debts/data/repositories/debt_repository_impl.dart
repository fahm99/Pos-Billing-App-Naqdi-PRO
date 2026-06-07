import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_payment.dart';
import '../../domain/repositories/debt_repository.dart';
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';

class DebtRepositoryImpl implements DebtRepository {
  @override
  Future<Either<Failure, List<Debt>>> getDebts() async {
    try {
      final debts = HiveDatabase.debtBox.values
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return Right(debts);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Debt>> getDebtById(String id) async {
    try {
      final model = HiveDatabase.debtBox.get(id);
      if (model == null) {
        return const Left(CacheFailure('الديون غير موجود'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addDebt(Debt debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      await HiveDatabase.debtBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDebt(Debt debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      await HiveDatabase.debtBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDebt(String id) async {
    try {
      await HiveDatabase.debtBox.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Debt>>> getDebtsByCustomer(
      String customerId) async {
    try {
      final debts = HiveDatabase.debtBox.values
          .where((m) => m.customerId == customerId)
          .map((m) => m.toEntity())
          .toList();
      return Right(debts);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DebtPayment>>> getPayments(String debtId) async {
    try {
      final payments = HiveDatabase.debtPaymentBox.values
          .where((m) => m.debtId == debtId)
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return Right(payments);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addPayment(DebtPayment payment) async {
    try {
      final model = DebtPaymentModel.fromEntity(payment);
      await HiveDatabase.debtPaymentBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePayment(String paymentId) async {
    try {
      await HiveDatabase.debtPaymentBox.delete(paymentId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalOutstanding() async {
    try {
      final total = HiveDatabase.debtBox.values
          .where((m) => m.status == 'active')
          .fold<double>(0, (sum, m) => sum + m.remainingAmount);
      return Right(total);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
