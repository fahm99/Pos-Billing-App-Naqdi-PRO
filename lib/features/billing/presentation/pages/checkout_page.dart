import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../sales/domain/entities/invoice.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/presentation/bloc/customer_bloc.dart';
import '../bloc/billing_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  double _discountAmount = 0;
  double _taxPercent = 0;
  double _cashPaid = 0;
  double _upiPaid = 0;
  double _cardPaid = 0;
  Customer? _selectedCustomer;

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
    const borderColor = Color(0xFFE5E5EA);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        context.read<BillingBloc>().add(ClearCartEvent());
        context.go('/scan');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدفع',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () {
              context.read<BillingBloc>().add(ClearCartEvent());
              context.go('/scan');
            },
          ),
        ),
        body: BlocConsumer<BillingBloc, BillingState>(
          listener: (context, state) {
            if (state.printSuccess) {
              _saveInvoice(context, state);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('تمت الطباعة وحفظ الفاتورة'),
                  backgroundColor: Colors.green));
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
                String upiId = '';
                String shopName = 'Shop';
                if (shopState is ShopLoaded) {
                  upiId = shopState.shop.upiId;
                  shopName = shopState.shop.name;
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            // Items table
                            _buildItemsTable(billingState, borderColor),
                            const SizedBox(height: 16),

                            // Discount & Tax
                            _buildDiscountTaxSection(subtotal),
                            const SizedBox(height: 16),

                            // Customer selector
                            _buildCustomerSelector(),
                            const SizedBox(height: 16),

                            // Payment method
                            _buildPaymentSection(total),
                            const SizedBox(height: 16),

                            // UPI QR
                            if (upiId.isNotEmpty &&
                                (_paymentMethod == PaymentMethod.upi ||
                                    _paymentMethod == PaymentMethod.mixed))
                              _buildQrSection(upiId, shopName, total),

                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),

                    // Bottom bar
                    _buildBottomBar(context, billingState, shopState, subtotal,
                        total, change),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemsTable(BillingState state, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          border: const TableBorder(
              horizontalInside: BorderSide(color: Color(0xFFE5E5EA)),
              bottom: BorderSide(color: Color(0xFFE5E5EA))),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                _headerCell('المنتج', TextAlign.right),
                _headerCell('السعر', TextAlign.right),
                _headerCell('الإجمالي', TextAlign.right),
              ],
            ),
            ...state.cartItems.map((item) => TableRow(children: [
                  _dataCell('${item.quantity} × ${item.product.name}',
                      TextAlign.right),
                  _dataCell('ر.س${item.product.price.toStringAsFixed(2)}',
                      TextAlign.right,
                      isSubtitle: true),
                  _dataCell(
                      'ر.س${item.total.toStringAsFixed(2)}', TextAlign.right,
                      isBold: true),
                ])),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountTaxSection(double subtotal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(14),
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
                    Text('خصم (ر.س)',
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
          if (_discountAmount > 0 || _taxPercent > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المجموع الفرعي',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                Text('ر.س${subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (_discountAmount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الخصم',
                      style: TextStyle(fontSize: 12, color: Colors.red[400])),
                  Text('- ر.س${_discountAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[400],
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
            if (_taxPercent > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ضريبة $_taxPercent%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text(
                      '+ ر.س${((subtotal - _discountAmount) * _taxPercent / 100).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state.customers.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.person_outline,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Customer?>(
                    value: _selectedCustomer,
                    hint: const Text('اختر عميل (اختياري)',
                        style: TextStyle(fontSize: 13)),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<Customer?>(
                          value: null, child: Text('بدون عميل')),
                      ...state.customers.map((c) => DropdownMenuItem<Customer?>(
                            value: c,
                            child: Text(c.name,
                                style: const TextStyle(fontSize: 13)),
                          )),
                    ],
                    onChanged: (c) => setState(() => _selectedCustomer = c),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentSection(double total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('طريقة الدفع',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          // Payment method chips
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

          // Cash input
          if (_paymentMethod == PaymentMethod.cash ||
              _paymentMethod == PaymentMethod.mixed) ...[
            _buildAmountField(
              label: 'المبلغ النقدي',
              hint: total.toStringAsFixed(2),
              onChanged: (v) =>
                  setState(() => _cashPaid = double.tryParse(v) ?? 0),
            ),
            if (_paymentMethod == PaymentMethod.cash && _cashPaid > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الباقي للعميل',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      'ر.س${(_cashPaid - total).toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color:
                              _cashPaid >= total ? Colors.green : Colors.red),
                    ),
                  ],
                ),
              ),
            ],
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
        prefixText: 'ر.س ',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildQrSection(String upiId, String shopName, double total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          const Text('امسح للدفع',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          SizedBox(
            width: 160,
            height: 160,
            child: PrettyQrView.data(
              data:
                  'upi://pay?pa=$upiId&pn=$shopName&am=${total.toStringAsFixed(2)}&cu=SAR',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BillingState billingState,
      ShopState shopState, double subtotal, double total, double change) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                      letterSpacing: 1.2)),
              Text(
                'ر.س${total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
            ],
          ),
          if (_paymentMethod == PaymentMethod.cash && _cashPaid > total)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الباقي',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text('ر.س${change.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ],
              ),
            ),
          PrimaryButton(
            onPressed: () {
              context.push('/print-options');
            },
            label: 'متابعة للدفع',
            icon: Icons.arrow_forward,
            isLoading: billingState.isPrinting,
          ),
        ],
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
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name,
    );
    // استخدام CompleteSaleEvent بدلاً من SaveInvoiceEvent لخصم المخزون تلقائياً
    context.read<SalesBloc>().add(CompleteSaleEvent(invoice));
  }

  Widget _headerCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text.toUpperCase(),
          textAlign: align,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.grey)),
    );
  }

  Widget _dataCell(String text, TextAlign align,
      {bool isBold = false, bool isSubtitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(text,
          textAlign: align,
          style: TextStyle(
              fontSize: isSubtitle ? 12 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isSubtitle ? Colors.grey[500] : Colors.black87)),
    );
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
