import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/expense_usecases.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final GetExpensesUseCase getExpensesUseCase;
  final AddExpenseUseCase addExpenseUseCase;
  final UpdateExpenseUseCase updateExpenseUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;
  final GetExpenseSummaryUseCase getExpenseSummaryUseCase;

  ExpenseBloc({
    required this.getExpensesUseCase,
    required this.addExpenseUseCase,
    required this.updateExpenseUseCase,
    required this.deleteExpenseUseCase,
    required this.getExpenseSummaryUseCase,
  }) : super(const ExpenseState()) {
    on<LoadExpensesEvent>(_onLoad);
    on<AddExpenseEvent>(_onAdd);
    on<UpdateExpenseEvent>(_onUpdate);
    on<DeleteExpenseEvent>(_onDelete);
    on<LoadExpenseSummaryEvent>(_onLoadSummary);
    on<FilterExpensesByCategoryEvent>(_onFilterByCategory);
  }

  Future<void> _onLoad(
      LoadExpensesEvent event, Emitter<ExpenseState> emit) async {
    emit(state.copyWith(status: ExpenseStatus.loading));
    final result = await getExpensesUseCase(NoParams());
    result.fold(
      (f) => emit(
          state.copyWith(status: ExpenseStatus.error, message: f.message)),
      (expenses) => emit(state.copyWith(
        status: ExpenseStatus.loaded,
        expenses: expenses,
        filteredExpenses: _applyFilter(expenses, state.selectedCategory),
      )),
    );
  }

  Future<void> _onAdd(AddExpenseEvent event, Emitter<ExpenseState> emit) async {
    final result = await addExpenseUseCase(event.expense);
    result.fold(
      (f) => emit(
          state.copyWith(status: ExpenseStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: ExpenseStatus.success, message: 'تمت إضافة المصروف'));
        add(LoadExpensesEvent());
      },
    );
  }

  Future<void> _onUpdate(
      UpdateExpenseEvent event, Emitter<ExpenseState> emit) async {
    final result = await updateExpenseUseCase(event.expense);
    result.fold(
      (f) => emit(
          state.copyWith(status: ExpenseStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: ExpenseStatus.success, message: 'تم تحديث المصروف'));
        add(LoadExpensesEvent());
      },
    );
  }

  Future<void> _onDelete(
      DeleteExpenseEvent event, Emitter<ExpenseState> emit) async {
    final result = await deleteExpenseUseCase(event.id);
    result.fold(
      (f) => emit(
          state.copyWith(status: ExpenseStatus.error, message: f.message)),
      (_) {
        emit(state.copyWith(
            status: ExpenseStatus.success, message: 'تم حذف المصروف'));
        add(LoadExpensesEvent());
      },
    );
  }

  Future<void> _onLoadSummary(
      LoadExpenseSummaryEvent event, Emitter<ExpenseState> emit) async {
    final result =
        await getExpenseSummaryUseCase(event.from, event.to);
    result.fold(
      (f) => emit(
          state.copyWith(status: ExpenseStatus.error, message: f.message)),
      (summary) => emit(state.copyWith(categorySummary: summary)),
    );
  }

  void _onFilterByCategory(
      FilterExpensesByCategoryEvent event, Emitter<ExpenseState> emit) {
    emit(state.copyWith(
      selectedCategory: event.category,
      filteredExpenses: _applyFilter(state.expenses, event.category),
    ));
  }

  List<Expense> _applyFilter(
      List<Expense> expenses, ExpenseCategory? category) {
    if (category == null) return expenses;
    return expenses.where((e) => e.category == category).toList();
  }
}
