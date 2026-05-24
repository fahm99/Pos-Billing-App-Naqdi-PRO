import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import 'package:go_router/go_router.dart';

enum AlertPriority { critical, warning, info }

class _AlertItem {
  final Product product;
  final AlertPriority priority;
  final String message;
  final String subtitle;

  const _AlertItem({
    required this.product,
    required this.priority,
    required this.message,
    required this.subtitle,
  });
}

class StockAlertsPage extends StatefulWidget {
  const StockAlertsPage({super.key});

  @override
  State<StockAlertsPage> createState() => _StockAlertsPageState();
}

class _StockAlertsPageState extends State<StockAlertsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('تنبيهات المخزون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          final alerts = _buildAlerts(state.products);
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  Text('لا توجد تنبيهات', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('جميع المنتجات في حالة جيدة', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildAlertCard(alerts[index]),
          );
        },
      ),
    );
  }

  List<_AlertItem> _buildAlerts(List<Product> products) {
    final List<_AlertItem> alerts = [];
    final now = DateTime.now();

    for (final product in products) {
      // Low stock - highest priority
      if (product.isBelowReorderPoint) {
        alerts.add(_AlertItem(
          product: product,
          priority: AlertPriority.critical,
          message: 'نفاد المخزون',
          subtitle: 'المتبقي: ${product.stock} ${product.unit} (الحد الأدنى: ${product.minStock})',
        ));
      } else if (product.isAtOrBelowReorderPoint) {
        alerts.add(_AlertItem(
          product: product,
          priority: AlertPriority.warning,
          message: 'اقترب من النفاد',
          subtitle: 'المتبقي: ${product.stock} ${product.unit}',
        ));
      }

      // Expiry alerts
      if (product.expiryDate != null) {
        final days = product.expiryDate!.difference(now).inDays;
        if (days <= 0) {
          alerts.add(_AlertItem(
            product: product,
            priority: AlertPriority.critical,
            message: 'منتهي الصلاحية',
            subtitle: 'انتهى في ${DateFormat('yyyy/MM/dd').format(product.expiryDate!)}',
          ));
        } else if (days <= 30) {
          alerts.add(_AlertItem(
            product: product,
            priority: AlertPriority.warning,
            message: 'صلاحية وشيكة',
            subtitle: 'متبقي $days يوم - ينتهي في ${DateFormat('yyyy/MM/dd').format(product.expiryDate!)}',
          ));
        }
      }
    }

    // Sort by priority
    alerts.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return alerts;
  }

  Widget _buildAlertCard(_AlertItem alert) {
    final Color color;
    switch (alert.priority) {
      case AlertPriority.critical:
        color = Colors.red;
        break;
      case AlertPriority.warning:
        color = Colors.orange;
        break;
      case AlertPriority.info:
        color = Colors.blue;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: alert.product.imageUrl != null && alert.product.imageUrl!.isNotEmpty
                  ? Image.file(
                      File(alert.product.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultImage(),
                    )
                  : _buildDefaultImage(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.message,
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Center(
      child: Image.asset(
        'assets/naqdilogo.jpg',
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.inventory_2_outlined,
          color: AppTheme.primaryColor,
          size: 22,
        ),
      ),
    );
  }
}
