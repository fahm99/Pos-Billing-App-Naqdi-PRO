import 'package:hive/hive.dart';
import '../../domain/entities/expense.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 9)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final double amount;
  @HiveField(4)
  final DateTime date;
  @HiveField(5)
  final int categoryIndex;
  @HiveField(6)
  final String paymentMethod;
  @HiveField(7)
  final String? supplierId;
  @HiveField(8)
  final String? receiptImagePath;
  @HiveField(9)
  final bool isRecurring;
  @HiveField(10)
  final int? recurringPeriodIndex;
  @HiveField(11)
  final String? notes;

  ExpenseModel({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.date,
    required this.categoryIndex,
    this.paymentMethod = 'cash',
    this.supplierId,
    this.receiptImagePath,
    this.isRecurring = false,
    this.recurringPeriodIndex,
    this.notes,
  });

  factory ExpenseModel.fromEntity(Expense e) => ExpenseModel(
        id: e.id,
        title: e.title,
        description: e.description,
        amount: e.amount,
        date: e.date,
        categoryIndex: e.category.index,
        paymentMethod: e.paymentMethod,
        supplierId: e.supplierId,
        receiptImagePath: e.receiptImagePath,
        isRecurring: e.isRecurring,
        recurringPeriodIndex: e.recurringPeriod?.index,
        notes: e.notes,
      );

  Expense toEntity() => Expense(
        id: id,
        title: title,
        description: description,
        amount: amount,
        date: date,
        category: ExpenseCategory.values[categoryIndex],
        paymentMethod: paymentMethod,
        supplierId: supplierId,
        receiptImagePath: receiptImagePath,
        isRecurring: isRecurring,
        recurringPeriod: recurringPeriodIndex == null
            ? null
            : RecurringPeriod.values[recurringPeriodIndex!],
        notes: notes,
      );
}
