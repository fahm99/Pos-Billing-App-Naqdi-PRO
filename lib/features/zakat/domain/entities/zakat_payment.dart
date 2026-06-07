import 'package:equatable/equatable.dart';

enum ZakatPaymentStatus { paid, pending }

class ZakatPayment extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final DateTime calculationFrom;
  final DateTime calculationTo;
  final double totalSalesProfit;
  final double totalExpenses;
  final String? notes;
  final ZakatPaymentStatus status;

  const ZakatPayment({
    required this.id,
    required this.amount,
    required this.date,
    required this.calculationFrom,
    required this.calculationTo,
    required this.totalSalesProfit,
    required this.totalExpenses,
    this.notes,
    this.status = ZakatPaymentStatus.paid,
  });

  ZakatPayment copyWith({
    String? id,
    double? amount,
    DateTime? date,
    DateTime? calculationFrom,
    DateTime? calculationTo,
    double? totalSalesProfit,
    double? totalExpenses,
    String? notes,
    ZakatPaymentStatus? status,
  }) {
    return ZakatPayment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      calculationFrom: calculationFrom ?? this.calculationFrom,
      calculationTo: calculationTo ?? this.calculationTo,
      totalSalesProfit: totalSalesProfit ?? this.totalSalesProfit,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        date,
        calculationFrom,
        calculationTo,
        totalSalesProfit,
        totalExpenses,
        notes,
        status,
      ];
}
