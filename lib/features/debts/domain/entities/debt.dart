import 'package:equatable/equatable.dart';

enum DebtStatus { active, paid, overdue }

class Debt extends Equatable {
  final String id;
  final String? customerId;
  final String customerName;
  final double originalAmount;
  final double remainingAmount;
  final String description;
  final DateTime date;
  final DateTime? dueDate;
  final DebtStatus status;

  const Debt({
    required this.id,
    this.customerId,
    required this.customerName,
    required this.originalAmount,
    required this.remainingAmount,
    required this.description,
    required this.date,
    this.dueDate,
    this.status = DebtStatus.active,
  });

  double get paidAmount => originalAmount - remainingAmount;
  bool get isOverdue =>
      status == DebtStatus.active &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  Debt copyWith({
    String? id,
    String? customerId,
    String? customerName,
    double? originalAmount,
    double? remainingAmount,
    String? description,
    DateTime? date,
    DateTime? dueDate,
    DebtStatus? status,
  }) {
    return Debt(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      originalAmount: originalAmount ?? this.originalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      description: description ?? this.description,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        originalAmount,
        remainingAmount,
        description,
        date,
        dueDate,
        status,
      ];
}
