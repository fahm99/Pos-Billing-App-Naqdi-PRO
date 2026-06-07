part of 'expense_bloc.dart';

enum ExpenseStatus { initial, loading, loaded, success, error }

class ExpenseState extends Equatable {
  final ExpenseStatus status;
  final List<Expense> expenses;
  final List<Expense> filteredExpenses;
  final Map<ExpenseCategory, double> categorySummary;
  final ExpenseCategory? selectedCategory;
  final String? message;

  const ExpenseState({
    this.status = ExpenseStatus.initial,
    this.expenses = const [],
    this.filteredExpenses = const [],
    this.categorySummary = const {},
    this.selectedCategory,
    this.message,
  });

  double get totalAmount =>
      expenses.fold(0, (sum, e) => sum + e.amount);

  ExpenseState copyWith({
    ExpenseStatus? status,
    List<Expense>? expenses,
    List<Expense>? filteredExpenses,
    Map<ExpenseCategory, double>? categorySummary,
    ExpenseCategory? selectedCategory,
    String? message,
    bool clearCategory = false,
  }) {
    return ExpenseState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      categorySummary: categorySummary ?? this.categorySummary,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        expenses,
        filteredExpenses,
        categorySummary,
        selectedCategory,
        message,
      ];
}
