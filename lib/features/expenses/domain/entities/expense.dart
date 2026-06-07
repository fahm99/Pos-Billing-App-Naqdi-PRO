import 'package:equatable/equatable.dart';

enum ExpenseCategory {
  rent('إيجار'),
  utilities('فواتير ومرافق'),
  salary('رواتب'),
  supplies('مستلزمات'),
  maintenance('صيانة'),
  transportation('مواصلات'),
  marketing('تسويق'),
  other('أخرى');

  final String label;
  const ExpenseCategory(this.label);
}

enum RecurringPeriod {
  weekly('أسبوعي'),
  monthly('شهري'),
  yearly('سنوي');

  final String label;
  const RecurringPeriod(this.label);
}

class Expense extends Equatable {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String paymentMethod;
  final String? supplierId;
  final String? receiptImagePath;
  final bool isRecurring;
  final RecurringPeriod? recurringPeriod;
  final String? notes;

  const Expense({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.paymentMethod = 'cash',
    this.supplierId,
    this.receiptImagePath,
    this.isRecurring = false,
    this.recurringPeriod,
    this.notes,
  });

  Expense copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? paymentMethod,
    String? supplierId,
    String? receiptImagePath,
    bool? isRecurring,
    RecurringPeriod? recurringPeriod,
    String? notes,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      supplierId: supplierId ?? this.supplierId,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPeriod: recurringPeriod ?? this.recurringPeriod,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        amount,
        date,
        category,
        paymentMethod,
        supplierId,
        receiptImagePath,
        isRecurring,
        recurringPeriod,
        notes,
      ];
}
