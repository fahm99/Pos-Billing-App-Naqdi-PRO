import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_payment.dart';
import '../bloc/debt_bloc.dart';

class DebtDetailPage extends StatefulWidget {
  final Debt debt;

  const DebtDetailPage({super.key, required this.debt});

  @override
  State<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends State<DebtDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<DebtBloc>().add(LoadDebtDetailEvent(widget.debt.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('دين - ${widget.debt.customerName}'),
      ),
      body: BlocBuilder<DebtBloc, DebtState>(
        builder: (context, state) {
          final debt = state.selectedDebt ?? widget.debt;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDebtSummary(debt),
                const SizedBox(height: 16),
                if (debt.remainingAmount > 0) _buildAddPaymentButton(debt),
                const SizedBox(height: 16),
                _buildPaymentHistory(state.payments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebtSummary(Debt debt) {
    final originalStr = CurrencyHelper.formatPrice(context, debt.originalAmount);
    final remainingStr = CurrencyHelper.formatPrice(context, debt.remainingAmount);
    final paidStr = CurrencyHelper.formatPrice(context, debt.paidAmount);
    final isOverdue = debt.isOverdue;
    final effectiveStatus = isOverdue ? DebtStatus.overdue : debt.status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(debt.customerName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: effectiveStatus == DebtStatus.paid
                        ? Colors.green.shade50
                        : isOverdue
                            ? Colors.red.shade50
                            : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: effectiveStatus == DebtStatus.paid
                          ? Colors.green
                          : isOverdue
                              ? Colors.red
                              : Colors.orange,
                    ),
                  ),
                  child: Text(
                    effectiveStatus == DebtStatus.paid
                        ? 'مدفوع'
                        : isOverdue
                            ? 'متأخر'
                            : 'نشط',
                    style: TextStyle(
                      color: effectiveStatus == DebtStatus.paid
                          ? Colors.green
                          : isOverdue
                              ? Colors.red
                              : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildRow('المبلغ الأصلي', originalStr),
            _buildRow('المبلغ المدفوع', paidStr, valueColor: Colors.green),
            _buildRow('المبلغ المتبقي', remainingStr, valueColor: Colors.red, isBold: true),
            if (debt.dueDate != null)
              _buildRow('تاريخ الاستحقاق',
                  '${debt.dueDate!.day}/${debt.dueDate!.month}/${debt.dueDate!.year}'),
            _buildRow('التاريخ', '${debt.date.day}/${debt.date.month}/${debt.date.year}'),
            if (debt.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(debt.description, style: const TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor,
              )),
        ],
      ),
    );
  }

  Widget _buildAddPaymentButton(Debt debt) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showPaymentDialog(debt),
        icon: const Icon(Icons.payments),
        label: const Text('تسجيل دفع'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  void _showPaymentDialog(Debt debt) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'المبلغ',
                hintText: 'الحد الأقصى: ${debt.remainingAmount}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0 || amount > debt.remainingAmount) return;
              final payment = DebtPayment(
                id: const Uuid().v4(),
                debtId: debt.id,
                amount: amount,
                date: DateTime.now(),
                notes: notesController.text,
              );
              context.read<DebtBloc>().add(AddDebtPaymentEvent(payment));
              Navigator.pop(ctx);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(List<DebtPayment> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('سجل المدفوعات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (payments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('لا توجد مدفوعات', style: TextStyle(color: Colors.grey)),
              ),
            ),
          )
        else
          ...payments.map((payment) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.check, color: Colors.green, size: 20),
                  ),
                  title: Text(CurrencyHelper.formatPrice(context, payment.amount)),
                  subtitle: Text(
                    '${payment.date.day}/${payment.date.month}/${payment.date.year}'
                    '${payment.notes != null ? ' - ${payment.notes}' : ''}',
                  ),
                ),
              )),
      ],
    );
  }
}
