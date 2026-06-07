import 'package:hive/hive.dart';
import '../../domain/entities/debt.dart';

part 'debt_model.g.dart';

@HiveType(typeId: 10)
class DebtModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? customerId;

  @HiveField(2)
  final String customerName;

  @HiveField(3)
  final double originalAmount;

  @HiveField(4)
  final double remainingAmount;

  @HiveField(5)
  final String description;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final DateTime? dueDate;

  @HiveField(8)
  final String status;

  DebtModel({
    required this.id,
    this.customerId,
    required this.customerName,
    required this.originalAmount,
    required this.remainingAmount,
    required this.description,
    required this.date,
    this.dueDate,
    this.status = 'active',
  });

  factory DebtModel.fromEntity(Debt entity) {
    return DebtModel(
      id: entity.id,
      customerId: entity.customerId,
      customerName: entity.customerName,
      originalAmount: entity.originalAmount,
      remainingAmount: entity.remainingAmount,
      description: entity.description,
      date: entity.date,
      dueDate: entity.dueDate,
      status: entity.status.name,
    );
  }

  Debt toEntity() {
    return Debt(
      id: id,
      customerId: customerId,
      customerName: customerName,
      originalAmount: originalAmount,
      remainingAmount: remainingAmount,
      description: description,
      date: date,
      dueDate: dueDate,
      status: DebtStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => DebtStatus.active,
      ),
    );
  }
}
