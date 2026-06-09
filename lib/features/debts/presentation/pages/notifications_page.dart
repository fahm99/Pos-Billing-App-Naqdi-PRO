import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../domain/entities/debt.dart';
import '../bloc/debt_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<DebtBloc>().add(const LoadDebtsEvent());
    context.read<ProductBloc>().add(LoadProducts());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'الديون'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'المخزون'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDebtsTab(),
          _buildStockTab(),
        ],
      ),
    );
  }

  Widget _buildDebtsTab() {
    return BlocBuilder<DebtBloc, DebtState>(
      builder: (context, state) {
        if (state.status == DebtStatusType.loading && state.debts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final overdueDebts = state.debts.where((d) => d.isOverdue).toList();
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
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('لا توجد ديون',
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildStockTab() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.status == ProductStatus.loading && state.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final alerts = <_StockAlertItem>[];

        for (final product in state.products) {
          if (product.isBelowReorderPoint) {
            alerts.add(_StockAlertItem(
              product: product,
              priority: _AlertPriority.critical,
              message: 'نفاد المخزون',
              subtitle: 'المتبقي: ${product.stock} ${product.unit} (الحد الأدنى: ${product.minStock})',
            ));
          } else if (product.isAtOrBelowReorderPoint) {
            alerts.add(_StockAlertItem(
              product: product,
              priority: _AlertPriority.warning,
              message: 'اقترب من النفاد',
              subtitle: 'المتبقي: ${product.stock} ${product.unit}',
            ));
          }
          if (product.expiryDate != null) {
            final days = product.expiryDate!.difference(now).inDays;
            if (days <= 0) {
              alerts.add(_StockAlertItem(
                product: product,
                priority: _AlertPriority.critical,
                message: 'منتهي الصلاحية',
                subtitle: 'انتهى في ${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
              ));
            } else if (days <= 30) {
              alerts.add(_StockAlertItem(
                product: product,
                priority: _AlertPriority.warning,
                message: 'صلاحية وشيكة',
                subtitle: 'متبقي $days يوم - ينتهي في ${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
              ));
            }
          }
        }

        alerts.sort((a, b) => a.priority.index.compareTo(b.priority.index));

        if (alerts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('المخزون سليم، لا توجد تنبيهات',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        final criticalCount = alerts.where((a) => a.priority == _AlertPriority.critical).length;
        final warningCount = alerts.where((a) => a.priority == _AlertPriority.warning).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlertSummary(criticalCount, warningCount),
              const SizedBox(height: 16),
              _buildSectionHeader('جميع التنبيهات', alerts.length, AppTheme.primaryColor),
              const SizedBox(height: 8),
              ...alerts.map((a) => _buildAlertCard(a)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertSummary(int criticalCount, int warningCount) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Text('$criticalCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 4),
                const Text('حرجة', style: TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Text('$warningCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 4),
                const Text('تحذيرية', style: TextStyle(fontSize: 12, color: Colors.orange)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(_StockAlertItem alert) {
    final color = alert.priority == _AlertPriority.critical ? Colors.red : Colors.orange;
    final borderColor = alert.priority == _AlertPriority.critical
        ? Colors.red.withOpacity(0.3)
        : Colors.orange.withOpacity(0.3);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: alert.product.imageUrl != null && alert.product.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(alert.product.imageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_outlined, color: color, size: 24),
                  ),
                )
              : Icon(Icons.inventory_2_outlined, color: color, size: 24),
        ),
        title: Text(alert.product.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            Text(alert.subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        onTap: () => context.push('/stock-alerts'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}

enum _AlertPriority { critical, warning }

class _StockAlertItem {
  final Product product;
  final _AlertPriority priority;
  final String message;
  final String subtitle;

  const _StockAlertItem({
    required this.product,
    required this.priority,
    required this.message,
    required this.subtitle,
  });
}
