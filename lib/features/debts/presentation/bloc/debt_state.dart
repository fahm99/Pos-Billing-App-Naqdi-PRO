part of 'debt_bloc.dart';

enum DebtStatusType { initial, loading, loaded, error, success }

class DebtState extends Equatable {
  final DebtStatusType status;
  final List<Debt> debts;
  final Debt? selectedDebt;
  final List<DebtPayment> payments;
  final double totalOutstanding;
  final String? errorMessage;

  const DebtState({
    this.status = DebtStatusType.initial,
    this.debts = const [],
    this.selectedDebt,
    this.payments = const [],
    this.totalOutstanding = 0,
    this.errorMessage,
  });

  DebtState copyWith({
    DebtStatusType? status,
    List<Debt>? debts,
    Debt? selectedDebt,
    List<DebtPayment>? payments,
    double? totalOutstanding,
    String? errorMessage,
  }) {
    return DebtState(
      status: status ?? this.status,
      debts: debts ?? this.debts,
      selectedDebt: selectedDebt ?? this.selectedDebt,
      payments: payments ?? this.payments,
      totalOutstanding: totalOutstanding ?? this.totalOutstanding,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, debts, selectedDebt, payments, totalOutstanding, errorMessage];
}
