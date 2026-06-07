part of 'zakat_bloc.dart';

sealed class ZakatEvent extends Equatable {
  const ZakatEvent();

  @override
  List<Object?> get props => [];
}

class LoadZakatEvent extends ZakatEvent {
  final DateTime from;
  final DateTime to;

  const LoadZakatEvent({required this.from, required this.to});

  @override
  List<Object?> get props => [from, to];
}

class PayZakatEvent extends ZakatEvent {
  final double amount;
  final DateTime from;
  final DateTime to;
  final double totalSalesProfit;
  final double totalExpenses;

  const PayZakatEvent({
    required this.amount,
    required this.from,
    required this.to,
    required this.totalSalesProfit,
    required this.totalExpenses,
  });

  @override
  List<Object?> get props =>
      [amount, from, to, totalSalesProfit, totalExpenses];
}

class DeleteZakatPaymentEvent extends ZakatEvent {
  final String paymentId;

  const DeleteZakatPaymentEvent(this.paymentId);

  @override
  List<Object?> get props => [paymentId];
}
