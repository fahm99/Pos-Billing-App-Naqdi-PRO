import 'package:hive/hive.dart';
import '../../domain/entities/zakat_payment.dart';

part 'zakat_payment_model.g.dart';

@HiveType(typeId: 12)
class ZakatPaymentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final DateTime calculationFrom;

  @HiveField(4)
  final DateTime calculationTo;

  @HiveField(5)
  final double totalSalesProfit;

  @HiveField(6)
  final double totalExpenses;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final String status;

  ZakatPaymentModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.calculationFrom,
    required this.calculationTo,
    required this.totalSalesProfit,
    required this.totalExpenses,
    this.notes,
    this.status = 'paid',
  });

  factory ZakatPaymentModel.fromEntity(ZakatPayment entity) {
    return ZakatPaymentModel(
      id: entity.id,
      amount: entity.amount,
      date: entity.date,
      calculationFrom: entity.calculationFrom,
      calculationTo: entity.calculationTo,
      totalSalesProfit: entity.totalSalesProfit,
      totalExpenses: entity.totalExpenses,
      notes: entity.notes,
      status: entity.status.name,
    );
  }

  ZakatPayment toEntity() {
    return ZakatPayment(
      id: id,
      amount: amount,
      date: date,
      calculationFrom: calculationFrom,
      calculationTo: calculationTo,
      totalSalesProfit: totalSalesProfit,
      totalExpenses: totalExpenses,
      notes: notes,
      status: ZakatPaymentStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => ZakatPaymentStatus.paid,
      ),
    );
  }
}
