import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/debt.dart';
import '../entities/debt_payment.dart';

abstract class DebtRepository {
  Future<Either<Failure, List<Debt>>> getDebts();
  Future<Either<Failure, Debt>> getDebtById(String id);
  Future<Either<Failure, void>> addDebt(Debt debt);
  Future<Either<Failure, void>> updateDebt(Debt debt);
  Future<Either<Failure, void>> deleteDebt(String id);
  Future<Either<Failure, List<Debt>>> getDebtsByCustomer(String customerId);
  Future<Either<Failure, List<DebtPayment>>> getPayments(String debtId);
  Future<Either<Failure, void>> addPayment(DebtPayment payment);
  Future<Either<Failure, void>> deletePayment(String paymentId);
  Future<Either<Failure, double>> getTotalOutstanding();
}
