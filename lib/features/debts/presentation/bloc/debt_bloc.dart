import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_payment.dart';
import '../../domain/usecases/debt_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'debt_event.dart';
part 'debt_state.dart';

class DebtBloc extends Bloc<DebtEvent, DebtState> {
  final GetDebtsUseCase getDebtsUseCase;
  final AddDebtUseCase addDebtUseCase;
  final UpdateDebtUseCase updateDebtUseCase;
  final DeleteDebtUseCase deleteDebtUseCase;
  final GetDebtByIdUseCase getDebtByIdUseCase;
  final GetDebtPaymentsUseCase getPaymentsUseCase;
  final AddDebtPaymentUseCase addPaymentUseCase;
  final DeleteDebtPaymentUseCase deletePaymentUseCase;
  final GetTotalOutstandingUseCase getTotalOutstandingUseCase;

  DebtBloc({
    required this.getDebtsUseCase,
    required this.addDebtUseCase,
    required this.updateDebtUseCase,
    required this.deleteDebtUseCase,
    required this.getDebtByIdUseCase,
    required this.getPaymentsUseCase,
    required this.addPaymentUseCase,
    required this.deletePaymentUseCase,
    required this.getTotalOutstandingUseCase,
  }) : super(const DebtState()) {
    on<LoadDebtsEvent>(_onLoadDebts);
    on<AddDebtEvent>(_onAddDebt);
    on<UpdateDebtEvent>(_onUpdateDebt);
    on<DeleteDebtEvent>(_onDeleteDebt);
    on<LoadDebtDetailEvent>(_onLoadDetail);
    on<AddDebtPaymentEvent>(_onAddPayment);
    on<DeleteDebtPaymentEvent>(_onDeletePayment);
  }

  Future<void> _onLoadDebts(
      LoadDebtsEvent event, Emitter<DebtState> emit) async {
    emit(state.copyWith(status: DebtStatusType.loading));

    final debtsResult = await getDebtsUseCase(NoParams());
    final totalResult = await getTotalOutstandingUseCase(NoParams());

    List<Debt> debts = [];
    if (debtsResult.isRight()) {
      debts = debtsResult.getRight().toNullable() ?? [];
    }

    double totalOutstanding = 0;
    if (totalResult.isRight()) {
      totalOutstanding = totalResult.getRight().toNullable() ?? 0;
    }

    emit(state.copyWith(
      status: DebtStatusType.loaded,
      debts: debts,
      totalOutstanding: totalOutstanding,
    ));
  }

  Future<void> _onAddDebt(
      AddDebtEvent event, Emitter<DebtState> emit) async {
    final result = await addDebtUseCase(event.debt);
    if (result.isLeft()) {
      emit(state.copyWith(
        status: DebtStatusType.error,
        errorMessage: result.getLeft().toNullable()?.message,
      ));
    } else {
      emit(state.copyWith(status: DebtStatusType.success));
      add(const LoadDebtsEvent());
    }
  }

  Future<void> _onUpdateDebt(
      UpdateDebtEvent event, Emitter<DebtState> emit) async {
    final result = await updateDebtUseCase(event.debt);
    if (result.isLeft()) {
      emit(state.copyWith(
        status: DebtStatusType.error,
        errorMessage: result.getLeft().toNullable()?.message,
      ));
    } else {
      emit(state.copyWith(status: DebtStatusType.success));
      add(const LoadDebtsEvent());
    }
  }

  Future<void> _onDeleteDebt(
      DeleteDebtEvent event, Emitter<DebtState> emit) async {
    final result = await deleteDebtUseCase(event.debtId);
    if (result.isRight()) {
      final debts = List<Debt>.from(state.debts)
        ..removeWhere((d) => d.id == event.debtId);
      emit(state.copyWith(debts: debts));
    }
  }

  Future<void> _onLoadDetail(
      LoadDebtDetailEvent event, Emitter<DebtState> emit) async {
    emit(state.copyWith(status: DebtStatusType.loading));

    final debtResult = await getDebtByIdUseCase(event.debtId);
    final paymentsResult = await getPaymentsUseCase(event.debtId);

    Debt? selectedDebt;
    if (debtResult.isRight()) {
      selectedDebt = debtResult.getRight().toNullable();
    }

    List<DebtPayment> payments = [];
    if (paymentsResult.isRight()) {
      payments = paymentsResult.getRight().toNullable() ?? [];
    }

    emit(state.copyWith(
      status: DebtStatusType.loaded,
      selectedDebt: selectedDebt,
      payments: payments,
    ));
  }

  Future<void> _onAddPayment(
      AddDebtPaymentEvent event, Emitter<DebtState> emit) async {
    final result = await addPaymentUseCase(event.payment);
    if (result.isRight() && state.selectedDebt != null) {
      final debt = state.selectedDebt!;
      final newRemaining = debt.remainingAmount - event.payment.amount;
      final updatedDebt = debt.copyWith(
        remainingAmount: newRemaining,
        status: newRemaining <= 0 ? DebtStatus.paid : debt.status,
      );
      await updateDebtUseCase(updatedDebt);
      emit(state.copyWith(status: DebtStatusType.success));
      add(LoadDebtDetailEvent(debt.id));
    }
  }

  Future<void> _onDeletePayment(
      DeleteDebtPaymentEvent event, Emitter<DebtState> emit) async {
    final result = await deletePaymentUseCase(event.paymentId);
    if (result.isRight() && state.selectedDebt != null) {
      add(LoadDebtDetailEvent(state.selectedDebt!.id));
    }
  }
}
