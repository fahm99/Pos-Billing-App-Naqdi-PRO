import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  @override
  Future<Either<Failure, List<Expense>>> getExpenses() async {
    try {
      final expenses = HiveDatabase.expenseBox.values
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return Right(expenses);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Expense>> getExpenseById(String id) async {
    try {
      final model = HiveDatabase.expenseBox.get(id);
      if (model == null) {
        return const Left(CacheFailure('المصروف غير موجود'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      await HiveDatabase.expenseBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      await HiveDatabase.expenseBox.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    try {
      await HiveDatabase.expenseBox.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalForPeriod(
      DateTime from, DateTime to) async {
    try {
      final total = HiveDatabase.expenseBox.values
          .map((m) => m.toEntity())
          .where((e) => e.date.isAfter(from) && e.date.isBefore(to))
          .fold<double>(0, (sum, e) => sum + e.amount);
      return Right(total);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<ExpenseCategory, double>>> getSummaryByCategory(
      DateTime from, DateTime to) async {
    try {
      final summary = <ExpenseCategory, double>{};
      for (final model in HiveDatabase.expenseBox.values) {
        final e = model.toEntity();
        if (e.date.isAfter(from) && e.date.isBefore(to)) {
          summary[e.category] = (summary[e.category] ?? 0) + e.amount;
        }
      }
      return Right(summary);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
