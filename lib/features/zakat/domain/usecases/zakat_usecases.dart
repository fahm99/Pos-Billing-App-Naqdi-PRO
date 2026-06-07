import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../sales/domain/entities/invoice.dart';
import '../../../sales/domain/repositories/sales_repository.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../entities/zakat_calculation.dart';
import '../entities/zakat_payment.dart';
import '../repositories/zakat_repository.dart';

class CalculateZakatUseCase {
  final SalesRepository salesRepository;
  final ExpenseRepository expenseRepository;

  CalculateZakatUseCase({
    required this.salesRepository,
    required this.expenseRepository,
  });

  Future<Either<Failure, ZakatCalculation>> call(DateTime from, DateTime to) async {
    try {
      final invoicesResult = await salesRepository.getInvoices();
      final expensesResult = await expenseRepository.getTotalForPeriod(from, to);

      double totalSalesProfit = 0;
      if (invoicesResult.isRight()) {
        final invoices = invoicesResult.getRight().toNullable() ?? [];
        totalSalesProfit = invoices
            .where((inv) =>
                inv.date.isAfter(from) &&
                inv.date.isBefore(to) &&
                inv.status != InvoiceStatus.returned)
            .fold<double>(0, (sum, inv) => sum + inv.totalProfit);
      }

      double totalExpenses = 0;
      if (expensesResult.isRight()) {
        totalExpenses = expensesResult.getRight().toNullable() ?? 0;
      }

      final netAmount = totalSalesProfit - totalExpenses;
      const nisabThreshold = 2000.0;
      final zakatDue = netAmount > nisabThreshold ? netAmount * 0.025 : 0.0;

      return Right(ZakatCalculation(
        fromDate: from,
        toDate: to,
        totalSalesProfit: totalSalesProfit,
        totalExpenses: totalExpenses,
        netZakatableAmount: netAmount,
        zakatDue: zakatDue,
        nisabThreshold: nisabThreshold,
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

class GetZakatPaymentsUseCase implements UseCase<List<ZakatPayment>, NoParams> {
  final ZakatRepository repository;
  GetZakatPaymentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ZakatPayment>>> call(NoParams params) =>
      repository.getPayments();
}

class AddZakatPaymentUseCase implements UseCase<void, ZakatPayment> {
  final ZakatRepository repository;
  AddZakatPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ZakatPayment params) =>
      repository.addPayment(params);
}

class DeleteZakatPaymentUseCase implements UseCase<void, String> {
  final ZakatRepository repository;
  DeleteZakatPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) =>
      repository.deletePayment(params);
}

class GetZakatTotalPaidUseCase implements UseCase<double, NoParams> {
  final ZakatRepository repository;
  GetZakatTotalPaidUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(NoParams params) =>
      repository.getTotalPaid();
}
