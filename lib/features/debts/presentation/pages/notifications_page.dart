import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/debt.dart';
import '../bloc/debt_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<DebtBloc>().add(const LoadDebtsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
      ),
      body: BlocBuilder<DebtBloc, DebtState>(
        builder: (context, state) {
          if (state.status == DebtStatusType.loading && state.debts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final overdueDebts = state.debts
              .where((d) => d.isOverdue)
              .toList();
          final dueSoonDebts = state.debts
              .where((d) =>
                  d.status == DebtStatus.active &&
                  d.dueDate != null &&
                  !d.isOverdue &&
                  d.dueDate!.difference(DateTime.now()).inDays <= 7)
              .toList();
          final recentDebts = state.debts
              .where((d) => d.status == DebtStatus.active && !d.isOverdue)
              .where((d) =>
                  d.dueDate == null ||
                  d.dueDate!.difference(DateTime.now()).inDays > 7)
              .toList();

          if (state.debts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد إشعارات',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalOutstanding(state.totalOutstanding),
                const SizedBox(height: 16),
                if (overdueDebts.isNotEmpty) ...[
                  _buildSectionHeader('ديون متأخرة', overdueDebts.length, Colors.red),
                  const SizedBox(height: 8),
                  ...overdueDebts.map((d) => _buildDebtNotification(d, isOverdue: true)),
                  const SizedBox(height: 16),
                ],
                if (dueSoonDebts.isNotEmpty) ...[
                  _buildSectionHeader('ديون تستحق قريباً', dueSoonDebts.length, Colors.orange),
                  const SizedBox(height: 8),
                  ...dueSoonDebts.map((d) => _buildDebtNotification(d, isOverdue: false)),
                  const SizedBox(height: 16),
                ],
                if (recentDebts.isNotEmpty) ...[
                  _buildSectionHeader('ديون نشطة', recentDebts.length, Colors.blue),
                  const SizedBox(height: 8),
                  ...recentDebts.map((d) => _buildDebtNotification(d, isOverdue: false)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalOutstanding(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('إجمالي الديون المستحقة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(
            CurrencyHelper.formatPrice(context, total),
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildDebtNotification(Debt debt, {required bool isOverdue}) {
    final remainingStr =
        CurrencyHelper.formatPrice(context, debt.remainingAmount);
    final color = isOverdue ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isOverdue ? Colors.red.shade50 : null,
      child: ListTile(
        onTap: () => context.push('/debt-detail', extra: debt),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            isOverdue ? Icons.warning : Icons.schedule,
            color: color,
          ),
        ),
        title: Text(debt.customerName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '$remainingStr - ${debt.description}'
          '${debt.dueDate != null ? '\nتاريخ الاستحقاق: ${debt.dueDate!.day}/${debt.dueDate!.month}/${debt.dueDate!.year}' : ''}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}
