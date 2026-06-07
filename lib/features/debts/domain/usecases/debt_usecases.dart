import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/debt.dart';
import '../entities/debt_payment.dart';
import '../repositories/debt_repository.dart';

class GetDebtsUseCase implements UseCase<List<Debt>, NoParams> {
  final DebtRepository repository;
  GetDebtsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Debt>>> call(NoParams params) =>
      repository.getDebts();
}

class GetDebtByIdUseCase implements UseCase<Debt, String> {
  final DebtRepository repository;
  GetDebtByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Debt>> call(String params) =>
      repository.getDebtById(params);
}

class AddDebtUseCase implements UseCase<void, Debt> {
  final DebtRepository repository;
  AddDebtUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Debt params) =>
      repository.addDebt(params);
}

class UpdateDebtUseCase implements UseCase<void, Debt> {
  final DebtRepository repository;
  UpdateDebtUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Debt params) =>
      repository.updateDebt(params);
}

class DeleteDebtUseCase implements UseCase<void, String> {
  final DebtRepository repository;
  DeleteDebtUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) =>
      repository.deleteDebt(params);
}

class GetDebtsByCustomerUseCase implements UseCase<List<Debt>, String> {
  final DebtRepository repository;
  GetDebtsByCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, List<Debt>>> call(String params) =>
      repository.getDebtsByCustomer(params);
}

class GetDebtPaymentsUseCase implements UseCase<List<DebtPayment>, String> {
  final DebtRepository repository;
  GetDebtPaymentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DebtPayment>>> call(String params) =>
      repository.getPayments(params);
}

class AddDebtPaymentUseCase implements UseCase<void, DebtPayment> {
  final DebtRepository repository;
  AddDebtPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DebtPayment params) =>
      repository.addPayment(params);
}

class GetTotalOutstandingUseCase implements UseCase<double, NoParams> {
  final DebtRepository repository;
  GetTotalOutstandingUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(NoParams params) =>
      repository.getTotalOutstanding();
}

class DeleteDebtPaymentUseCase implements UseCase<void, String> {
  final DebtRepository repository;
  DeleteDebtPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) =>
      repository.deletePayment(params);
}
