import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../../../core/data/hive_database.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../domain/entities/invoice.dart';
import '../bloc/sales_bloc.dart';

class InvoiceDetailPage extends StatelessWidget {
  final Invoice invoice;
  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);
    final dateStr = DateFormat('dd/MM/yyyy – HH:mm').format(invoice.date);

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Reprint button
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'إعادة الطباعة',
            onPressed: () => _reprint(context),
          ),
          // Return/refund button
          if (invoice.status == InvoiceStatus.completed)
            IconButton(
              icon: const Icon(Icons.assignment_return_outlined,
                  color: Colors.orange),
              tooltip: 'استرجاع',
              onPressed: () => _confirmReturn(context),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status banner for returned
            if (invoice.status == InvoiceStatus.returned)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.assignment_return, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('هذه الفاتورة مرتجعة',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            // Header info
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('التاريخ', dateStr),
                  const Divider(height: 20),
                  _buildInfoRow(
                      'طريقة الدفع', _paymentLabel(invoice.paymentMethod)),
                  if (invoice.cashPaid > 0) ...[
                    const Divider(height: 20),
                    _buildInfoRow('المدفوع نقداً',
                        'ر.س${invoice.cashPaid.toStringAsFixed(2)}'),
                  ],
                  if (invoice.changeAmount > 0) ...[
                    const Divider(height: 20),
                    _buildInfoRow('الباقي للعميل',
                        'ر.س${invoice.changeAmount.toStringAsFixed(2)}'),
                  ],
                  if (invoice.customerName != null) ...[
                    const Divider(height: 20),
                    _buildInfoRow('العميل', invoice.customerName!),
                  ],
                  if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                    const Divider(height: 20),
                    _buildInfoRow('ملاحظات', invoice.notes!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Table(
                  border: const TableBorder(
                      horizontalInside: BorderSide(color: borderColor)),
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                      children: [
                        _headerCell('المنتج'),
                        _headerCell('الكمية'),
                        _headerCell('الإجمالي'),
                      ],
                    ),
                    ...invoice.items.map((item) => TableRow(children: [
                          _dataCell(item.productName),
                          _dataCell('${item.quantity}'),
                          _dataCell('ر.س${item.subtotal.toStringAsFixed(2)}',
                              bold: true),
                        ])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Totals
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('المجموع الفرعي',
                      'ر.س${invoice.subtotal.toStringAsFixed(2)}'),
                  if (invoice.discountAmount > 0) ...[
                    const Divider(height: 16),
                    _buildInfoRow('الخصم',
                        '- ر.س${invoice.discountAmount.toStringAsFixed(2)}',
                        valueColor: Colors.red),
                  ],
                  if (invoice.taxAmount > 0) ...[
                    const Divider(height: 16),
                    _buildInfoRow(
                        'الضريبة', 'ر.س${invoice.taxAmount.toStringAsFixed(2)}'),
                  ],
                  const Divider(height: 16),
                  _buildInfoRow(
                    'الإجمالي',
                    'ر.س${invoice.totalAmount.toStringAsFixed(2)}',
                    bold: true,
                    valueColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: valueColor)),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5)),
    );
  }

  Widget _dataCell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    );
  }

  String _paymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'نقداً';
      case PaymentMethod.card:
        return 'بطاقة';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.mixed:
        return 'مختلط';
    }
  }

  Future<void> _reprint(BuildContext context) async {
    final shopState = context.read<ShopBloc>().state;
    if (shopState is! ShopLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('لم يتم تحميل بيانات المتجر'),
          backgroundColor: Colors.red));
      return;
    }

    final printerHelper = PrinterHelper();
    if (!printerHelper.isConnected) {
      final savedMac = HiveDatabase.settingsBox.get('printer_mac');
      if (savedMac != null) {
        final connected = await printerHelper.connect(savedMac);
        if (!connected) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('فشل الاتصال بالطابعة'),
                backgroundColor: Colors.red));
          }
          return;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('لا توجد طابعة محفوظة'),
              backgroundColor: Colors.red));
        }
        return;
      }
    }

    try {
      final items = invoice.items
          .map((item) => {
                'name': item.productName,
                'qty': item.quantity,
                'price': item.price,
                'total': item.subtotal,
              })
          .toList();

      await printerHelper.printReceipt(
        shopName: shopState.shop.name,
        address1: shopState.shop.addressLine1,
        address2: shopState.shop.addressLine2,
        phone: shopState.shop.phoneNumber,
        items: items,
        total: invoice.totalAmount,
        footer: shopState.shop.footerText,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تمت إعادة الطباعة'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('فشلت الطباعة: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _confirmReturn(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استرجاع الفاتورة'),
        content: Text(
            'هل تريد تسجيل استرجاع الفاتورة ${invoice.invoiceNumber}؟\nسيتم تغيير حالتها إلى "مرتجعة".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              context.read<SalesBloc>().add(ReturnInvoiceEvent(invoice.id));
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('تأكيد الاسترجاع',
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفاتورة'),
        content: Text('هل تريد حذف ${invoice.invoiceNumber}؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              context.read<SalesBloc>().add(DeleteInvoiceEvent(invoice.id));
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
