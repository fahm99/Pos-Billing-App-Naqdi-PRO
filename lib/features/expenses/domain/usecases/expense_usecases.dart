import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpensesUseCase implements UseCase<List<Expense>, NoParams> {
  final ExpenseRepository repository;
  GetExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Expense>>> call(NoParams params) =>
      repository.getExpenses();
}

class AddExpenseUseCase implements UseCase<void, Expense> {
  final ExpenseRepository repository;
  AddExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Expense params) =>
      repository.addExpense(params);
}

class UpdateExpenseUseCase implements UseCase<void, Expense> {
  final ExpenseRepository repository;
  UpdateExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Expense params) =>
      repository.updateExpense(params);
}

class DeleteExpenseUseCase implements UseCase<void, String> {
  final ExpenseRepository repository;
  DeleteExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) =>
      repository.deleteExpense(params);
}

class GetExpenseSummaryUseCase {
  final ExpenseRepository repository;
  GetExpenseSummaryUseCase(this.repository);

  Future<Either<Failure, Map<ExpenseCategory, double>>> call(
      DateTime from, DateTime to) {
    return repository.getSummaryByCategory(from, to);
  }
}
