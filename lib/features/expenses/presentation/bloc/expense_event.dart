part of 'expense_bloc.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();
  @override
  List<Object?> get props => [];
}

class LoadExpensesEvent extends ExpenseEvent {}

class AddExpenseEvent extends ExpenseEvent {
  final Expense expense;
  const AddExpenseEvent(this.expense);
  @override
  List<Object?> get props => [expense];
}

class UpdateExpenseEvent extends ExpenseEvent {
  final Expense expense;
  const UpdateExpenseEvent(this.expense);
  @override
  List<Object?> get props => [expense];
}

class DeleteExpenseEvent extends ExpenseEvent {
  final String id;
  const DeleteExpenseEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class LoadExpenseSummaryEvent extends ExpenseEvent {
  final DateTime from;
  final DateTime to;
  const LoadExpenseSummaryEvent({required this.from, required this.to});
  @override
  List<Object?> get props => [from, to];
}

class FilterExpensesByCategoryEvent extends ExpenseEvent {
  final ExpenseCategory? category;
  const FilterExpensesByCategoryEvent(this.category);
  @override
  List<Object?> get props => [category];
}
