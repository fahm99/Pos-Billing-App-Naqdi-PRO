import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, List<Expense>>> getExpenses();
  Future<Either<Failure, Expense>> getExpenseById(String id);
  Future<Either<Failure, void>> addExpense(Expense expense);
  Future<Either<Failure, void>> updateExpense(Expense expense);
  Future<Either<Failure, void>> deleteExpense(String id);
  Future<Either<Failure, double>> getTotalForPeriod(DateTime from, DateTime to);
  Future<Either<Failure, Map<ExpenseCategory, double>>> getSummaryByCategory(
      DateTime from, DateTime to);
}
