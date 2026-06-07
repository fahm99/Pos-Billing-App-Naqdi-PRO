import 'package:equatable/equatable.dart';

class DebtPayment extends Equatable {
  final String id;
  final String debtId;
  final double amount;
  final DateTime date;
  final String? notes;

  const DebtPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.notes,
  });

  @override
  List<Object?> get props => [id, debtId, amount, date, notes];
}
