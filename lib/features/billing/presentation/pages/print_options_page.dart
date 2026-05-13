import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../sales/domain/entities/invoice.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../bloc/billing_bloc.dart';

class PrintOptionsPage extends StatefulWidget {
  const PrintOptionsPage({super.key});

  @override
  State<PrintOptionsPage> createState() => _PrintOptionsPageState();
}

class _PrintOptionsPageState extends State<PrintOptionsPage> {
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  double _discountAmount = 0;
  double _taxPercent = 0;
  double _cashPaid = 0;
  double _upiPaid = 0;
  double _cardPaid = 0;

  double _calcTotal(double subtotal) {
    final afterDiscount = subtotal - _discountAmount;
    final tax = afterDiscount * (_taxPercent / 100);
    return afterDiscount + tax;
  }

  double _calcChange(double total) {
    if (_paymentMethod == PaymentMethod.cash) return _cashPaid - total;
    if (_paymentMethod == PaymentMethod.mixed) {
      return (_cashPaid + _upiPaid + _cardPaid) - total;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خيارات الفاتورة'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<BillingBloc, BillingState>(
        listener: (context, state) {
          if (state.printSuccess) {
            _saveInvoice(context, state);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('تم حفظ الفاتورة بنجاح'),
                backgroundColor: Colors.green));
            context.go('/scan');
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.error!), backgroundColor: Colors.red));
          }
        },
        builder: (context, billingState) {
          final subtotal = billingState.totalAmount;
          final total = _calcTotal(subtotal);
          final change = _calcChange(total);

          return BlocBuilder<ShopBloc, ShopState>(
            builder: (context, shopState) {
              String shopName = 'Shop';
              String upiId = '';
              if (shopState is ShopLoaded) {
                shopName = shopState.shop.name;
                upiId = shopState.shop.upiId;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Method Section
                    _buildPaymentSection(total),
                    const SizedBox(height: 16),

                    // Discount & Tax Section
                    _buildDiscountTaxSection(subtotal),
                    const SizedBox(height: 16),

                    // Total Summary
                    _buildTotalSection(total, change),
                    const SizedBox(height: 24),

                    // Print Options
                    _buildPrintOptions(
                        billingState, shopState, shopName, upiId),
                    const SizedBox(height: 24),

                    // Sell Without Invoice Button
                    _buildSellWithoutInvoiceButton(billingState, shopState),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentSection(double total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('طريقة الدفع',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: PaymentMethod.values.map((m) {
              final selected = _paymentMethod == m;
              return ChoiceChip(
                label: Text(_paymentLabel(m)),
                selected: selected,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontSize: 12),
                onSelected: (_) => setState(() {
                  _paymentMethod = m;
                  _cashPaid = 0;
                  _upiPaid = 0;
                  _cardPaid = 0;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (_paymentMethod == PaymentMethod.cash ||
              _paymentMethod == PaymentMethod.mixed) ...[
            _buildAmountField(
              label: 'المبلغ النقدي',
              hint: total.toStringAsFixed(2),
              onChanged: (v) =>
                  setState(() => _cashPaid = double.tryParse(v) ?? 0),
            ),
          ],
          if (_paymentMethod == PaymentMethod.mixed) ...[
            const SizedBox(height: 8),
            _buildAmountField(
              label: 'مبلغ UPI',
              hint: '0.00',
              onChanged: (v) =>
                  setState(() => _upiPaid = double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 8),
            _buildAmountField(
              label: 'مبلغ البطاقة',
              hint: '0.00',
              onChanged: (v) =>
                  setState(() => _cardPaid = double.tryParse(v) ?? 0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountField(
      {required String label,
      required String hint,
      required ValueChanged<String> onChanged}) {
    return TextFormField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDiscountTaxSection(double subtotal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الخصم والضريبة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('خصم',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: _discountAmount == 0
                          ? ''
                          : _discountAmount.toStringAsFixed(0),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          hintText: '0', contentPadding: EdgeInsets.all(10)),
                      onChanged: (v) => setState(
                          () => _discountAmount = double.tryParse(v) ?? 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ضريبة (%)',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: _taxPercent == 0
                          ? ''
                          : _taxPercent.toStringAsFixed(0),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          hintText: '0', contentPadding: EdgeInsets.all(10)),
                      onChanged: (v) =>
                          setState(() => _taxPercent = double.tryParse(v) ?? 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(double total, double change) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF00A77E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00A77E).withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإجمالي',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${total.toStringAsFixed(2)} ر.س',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A77E))),
            ],
          ),
          if (_paymentMethod == PaymentMethod.cash && _cashPaid > total) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الباقي',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                Text('${change.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrintOptions(BillingState billingState, ShopState shopState,
      String shopName, String upiId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('خيارات الإرسال',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Print as PDF
        GestureDetector(
          onTap: () {
            if (shopState is ShopLoaded) {
              context.read<BillingBloc>().add(PrintReceiptEvent(
                  shopName: shopState.shop.name,
                  address1: shopState.shop.addressLine1,
                  address2: shopState.shop.addressLine2,
                  phone: shopState.shop.phoneNumber,
                  footer: shopState.shop.footerText));
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf,
                      color: Color(0xFFE74C3C), size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('طباعة كـ PDF',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_left, color: Colors.grey),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Print via Printer
        GestureDetector(
          onTap: () {
            if (shopState is ShopLoaded) {
              context.read<BillingBloc>().add(PrintReceiptEvent(
                  shopName: shopState.shop.name,
                  address1: shopState.shop.addressLine1,
                  address2: shopState.shop.addressLine2,
                  phone: shopState.shop.phoneNumber,
                  footer: shopState.shop.footerText));
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A77E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.print,
                      color: Color(0xFF00A77E), size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('طباعة عبر الطابعة',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_left, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSellWithoutInvoiceButton(
      BillingState billingState, ShopState shopState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: billingState.cartItems.isEmpty
            ? null
            : () {
                _saveInvoice(context, billingState);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('تم تسجيل البيع بنجاح'),
                    backgroundColor: Colors.green));
                context.read<BillingBloc>().add(ClearCartEvent());
                context.go('/scan');
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'بيع بدون فاتورة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _saveInvoice(BuildContext context, BillingState billingState) {
    final subtotal = billingState.totalAmount;
    final total = _calcTotal(subtotal);
    final taxAmount = (subtotal - _discountAmount) * (_taxPercent / 100);
    final invoiceNumber =
        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final items = billingState.cartItems
        .map((ci) => InvoiceItem(
              productId: ci.product.id,
              productName: ci.product.name,
              price: ci.product.price,
              costPrice: ci.product.costPrice,
              quantity: ci.quantity,
              unit: ci.product.unit,
            ))
        .toList();

    final invoice = Invoice(
      id: const Uuid().v4(),
      invoiceNumber: invoiceNumber,
      date: DateTime.now(),
      items: items,
      subtotal: subtotal,
      discountAmount: _discountAmount,
      taxAmount: taxAmount,
      totalAmount: total,
      paymentMethod: _paymentMethod,
      cashPaid: _cashPaid,
      upiPaid: _upiPaid,
      cardPaid: _cardPaid,
      changeAmount: _calcChange(total),
    );
    // استخدام CompleteSaleEvent بدلاً من SaveInvoiceEvent لخصم المخزون تلقائياً
    context.read<SalesBloc>().add(CompleteSaleEvent(invoice));
  }

  String _paymentLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.card:
        return 'بطاقة';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.mixed:
        return 'مختلط';
    }
  }
}
