part of 'debt_bloc.dart';

sealed class DebtEvent extends Equatable {
  const DebtEvent();

  @override
  List<Object?> get props => [];
}

class LoadDebtsEvent extends DebtEvent {
  const LoadDebtsEvent();

  @override
  List<Object?> get props => [];
}

class AddDebtEvent extends DebtEvent {
  final Debt debt;

  const AddDebtEvent(this.debt);

  @override
  List<Object?> get props => [debt];
}

class UpdateDebtEvent extends DebtEvent {
  final Debt debt;

  const UpdateDebtEvent(this.debt);

  @override
  List<Object?> get props => [debt];
}

class DeleteDebtEvent extends DebtEvent {
  final String debtId;

  const DeleteDebtEvent(this.debtId);

  @override
  List<Object?> get props => [debtId];
}

class AddDebtPaymentEvent extends DebtEvent {
  final DebtPayment payment;

  const AddDebtPaymentEvent(this.payment);

  @override
  List<Object?> get props => [payment];
}

class DeleteDebtPaymentEvent extends DebtEvent {
  final String paymentId;

  const DeleteDebtPaymentEvent(this.paymentId);

  @override
  List<Object?> get props => [paymentId];
}

class LoadDebtDetailEvent extends DebtEvent {
  final String debtId;

  const LoadDebtDetailEvent(this.debtId);

  @override
  List<Object?> get props => [debtId];
}
