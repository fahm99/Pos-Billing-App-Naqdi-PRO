import 'package:hive/hive.dart';
import '../../domain/entities/debt_payment.dart';

part 'debt_payment_model.g.dart';

@HiveType(typeId: 11)
class DebtPaymentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String debtId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? notes;

  DebtPaymentModel({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.notes,
  });

  factory DebtPaymentModel.fromEntity(DebtPayment entity) {
    return DebtPaymentModel(
      id: entity.id,
      debtId: entity.debtId,
      amount: entity.amount,
      date: entity.date,
      notes: entity.notes,
    );
  }

  DebtPayment toEntity() {
    return DebtPayment(
      id: id,
      debtId: debtId,
      amount: amount,
      date: date,
      notes: notes,
    );
  }
}
