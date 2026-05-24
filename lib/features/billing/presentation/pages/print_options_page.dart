import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/scanner_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
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
  bool _isProcessing = false;
  String _currencySymbol = 'ر.س';

  @override
  void initState() {
    super.initState();
    final shopState = context.read<ShopBloc>().state;
    if (shopState is ShopLoaded) {
      _currencySymbol = shopState.shop.currencySymbol.isNotEmpty
          ? shopState.shop.currencySymbol
          : 'ر.س';
    }
  }

  void _goHomeBasedOnMode() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AdminMode) {
      context.go('/admin-home');
    } else {
      context.go('/scan');
    }
  }

  void _finishSale() {
    context.read<BillingBloc>().add(ClearCartEvent());
    ScannerService.saleJustCompleted = true;
    _goHomeBasedOnMode();
  }

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
          icon: Icon(Icons.chevron_left, size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<SalesBloc, SalesState>(
        listenWhen: (previous, current) =>
            previous.status != current.status && _isProcessing,
        listener: (context, state) {
          if (state.status == SalesStatus.success) {
            context.read<ProductBloc>().add(LoadProducts());
            NotificationHelper.show(context, 'تم إتمام البيع بنجاح');
            _finishSale();
          } else if (state.status == SalesStatus.error) {
            if (mounted) setState(() => _isProcessing = false);
            NotificationHelper.show(context,
                state.message ?? 'حدث خطأ أثناء حفظ الفاتورة');
          }
        },
        child: BlocBuilder<BillingBloc, BillingState>(
          builder: (context, billingState) {
          final subtotal = billingState.totalAmount;
          final total = _calcTotal(subtotal);
          final change = _calcChange(total);

          return BlocBuilder<ShopBloc, ShopState>(
            builder: (context, shopState) {
              String currencySymbol = _currencySymbol;
              if (shopState is ShopLoaded) {
                currencySymbol = shopState.shop.currencySymbol.isNotEmpty
                    ? shopState.shop.currencySymbol
                    : 'ر.س';
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPaymentSection(total),
                    const SizedBox(height: 16),
                    _buildDiscountTaxSection(subtotal),
                    const SizedBox(height: 16),
                    _buildTotalSection(total, change, currencySymbol),
                    const SizedBox(height: 24),
                    _buildSellButton(billingState, total, currencySymbol),
                  ],
                ),
              );
            },
          );
        },
      ),
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
          const Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: PaymentMethod.values.map((m) {
              final selected = _paymentMethod == m;
              return ChoiceChip(
                label: Text(_paymentLabel(m)),
                selected: selected,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 12),
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
          if (_paymentMethod == PaymentMethod.cash || _paymentMethod == PaymentMethod.mixed) ...[
            _buildAmountField(
              label: 'المبلغ النقدي',
              hint: total.toStringAsFixed(2),
              onChanged: (v) => setState(() => _cashPaid = double.tryParse(v) ?? 0),
            ),
          ],
          if (_paymentMethod == PaymentMethod.mixed) ...[
            const SizedBox(height: 8),
            _buildAmountField(
              label: 'مبلغ UPI',
              hint: '0.00',
              onChanged: (v) => setState(() => _upiPaid = double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 8),
            _buildAmountField(
              label: 'مبلغ البطاقة',
              hint: '0.00',
              onChanged: (v) => setState(() => _cardPaid = double.tryParse(v) ?? 0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountField({
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          const Text('الخصم والضريبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('خصم', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: _discountAmount == 0 ? '' : _discountAmount.toStringAsFixed(0),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '0', contentPadding: EdgeInsets.all(10)),
                      onChanged: (v) => setState(() => _discountAmount = double.tryParse(v) ?? 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ضريبة (%)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: _taxPercent == 0 ? '' : _taxPercent.toStringAsFixed(0),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '0', contentPadding: EdgeInsets.all(10)),
                      onChanged: (v) => setState(() => _taxPercent = double.tryParse(v) ?? 0),
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

  Widget _buildTotalSection(double total, double change, String currencySymbol) {
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
              const Text('الإجمالي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('$currencySymbol${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00A77E))),
            ],
          ),
          if (_paymentMethod == PaymentMethod.cash && _cashPaid > total) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الباقي', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                Text('$currencySymbol${change.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSellButton(BillingState billingState, double total, String currencySymbol) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (billingState.cartItems.isEmpty || _isProcessing) ? null : () {
          setState(() => _isProcessing = true);
          _saveInvoice(context, billingState);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_checkout, size: 22),
            const SizedBox(width: 10),
            Text(
              'بيع  |  $currencySymbol${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _saveInvoice(BuildContext context, BillingState billingState) {
    final subtotal = billingState.totalAmount;
    final total = _calcTotal(subtotal);
    final taxAmount = (subtotal - _discountAmount) * (_taxPercent / 100);
    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

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
    context.read<SalesBloc>().add(CompleteSaleEvent(invoice));
  }

  String _paymentLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash: return 'نقدي';
      case PaymentMethod.card: return 'بطاقة';
      case PaymentMethod.upi: return 'UPI';
      case PaymentMethod.mixed: return 'مختلط';
    }
  }
}
