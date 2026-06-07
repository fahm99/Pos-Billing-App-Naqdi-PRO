import 'package:equatable/equatable.dart';

class ZakatCalculation extends Equatable {
  final DateTime fromDate;
  final DateTime toDate;
  final double totalSalesProfit;
  final double totalExpenses;
  final double netZakatableAmount;
  final double zakatDue;
  final double? nisabThreshold;

  const ZakatCalculation({
    required this.fromDate,
    required this.toDate,
    required this.totalSalesProfit,
    required this.totalExpenses,
    required this.netZakatableAmount,
    required this.zakatDue,
    this.nisabThreshold,
  });

  bool get isZakatDue => zakatDue > 0;

  @override
  List<Object?> get props => [
        fromDate,
        toDate,
        totalSalesProfit,
        totalExpenses,
        netZakatableAmount,
        zakatDue,
        nisabThreshold,
      ];
}
