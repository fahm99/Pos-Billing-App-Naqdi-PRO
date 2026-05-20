import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
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
  bool _isSavingPdf = false;

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

              final taxAmount =
                  (subtotal - _discountAmount) * (_taxPercent / 100);
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
                    _buildPrintOptions(billingState, shopState, shopName, upiId,
                        subtotal, total, change, taxAmount),
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

  Widget _buildPrintOptions(
      BillingState billingState,
      ShopState shopState,
      String shopName,
      String upiId,
      double subtotal,
      double total,
      double change,
      double taxAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('خيارات الإرسال',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Save as PDF
        GestureDetector(
          onTap: _isSavingPdf
              ? null
              : () {
                  if (shopState is ShopLoaded) {
                    _savePdfToDevice(
                      shopName: shopName,
                      address1: shopState.shop.addressLine1,
                      address2: shopState.shop.addressLine2,
                      phone: shopState.shop.phoneNumber,
                      footer: shopState.shop.footerText,
                      billingState: billingState,
                      subtotal: subtotal,
                      total: total,
                      change: change,
                      taxAmount: taxAmount,
                    );
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
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isSavingPdf
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2196F3),
                          ),
                        )
                      : const Icon(Icons.save_alt,
                          color: Color(0xFF2196F3), size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('حفظ كملف PDF',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('حفظ الفاتورة على جهازك',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left, color: Colors.grey),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Share PDF
        GestureDetector(
          onTap: _isSavingPdf
              ? null
              : () {
                  if (shopState is ShopLoaded) {
                    _sharePdf(
                      shopName: shopName,
                      address1: shopState.shop.addressLine1,
                      address2: shopState.shop.addressLine2,
                      phone: shopState.shop.phoneNumber,
                      footer: shopState.shop.footerText,
                      billingState: billingState,
                      subtotal: subtotal,
                      total: total,
                      change: change,
                      taxAmount: taxAmount,
                    );
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
                  child: const Icon(Icons.share,
                      color: Color(0xFFE74C3C), size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مشاركة PDF',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('مشاركة الفاتورة عبر التطبيقات',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('طباعة عبر الطابعة',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('طباعة الفاتورة على طابعة بلوتوث',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
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
    context.read<SalesBloc>().add(CompleteSaleEvent(invoice));
  }

  Future<Uint8List> _generateInvoicePdf({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required String footer,
    required BillingState billingState,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double total,
    required double change,
    required String invoiceNumber,
  }) async {
    final doc = pw.Document();

    // تحميل خط Cairo لدعم العربية بشكل صحيح
    pw.Font? arabicFont;
    try {
      arabicFont = await PdfGoogleFonts.cairoRegular();
    } catch (_) {}

    // خط عريض للعناوين
    pw.Font? arabicBold;
    try {
      arabicBold = await PdfGoogleFonts.cairoBold();
    } catch (_) {}

    final theme = pw.ThemeData.withFont(
      base: arabicFont ?? pw.Font.helvetica(),
      bold: arabicBold ?? pw.Font.helveticaBold(),
    );

    final items = billingState.cartItems;

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl, // دعم RTL للعربية
        build: (context) => [
          // رأس الفاتورة - الشعار والاسم يمين
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // اليمين: اسم المتجر
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(shopName,
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          font: arabicBold)),
                  if (address1.isNotEmpty)
                    pw.Text(address1,
                        style: pw.TextStyle(fontSize: 10, font: arabicFont)),
                  if (address2.isNotEmpty)
                    pw.Text(address2,
                        style: pw.TextStyle(fontSize: 10, font: arabicFont)),
                  if (phone.isNotEmpty)
                    pw.Text('الهاتف: $phone',
                        style: pw.TextStyle(fontSize: 10, font: arabicFont)),
                ],
              ),
              // اليسار: رقم الفاتورة والتاريخ
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('رقم الفاتورة: $invoiceNumber',
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          font: arabicBold)),
                  pw.Text('التاريخ: ${_formatDate(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 10, font: arabicFont)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // جدول المنتجات - RTL
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                font: arabicBold),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.centerRight,
            cellStyle: pw.TextStyle(font: arabicFont),
            headers: ['الإجمالي', 'الكمية', 'السعر', 'المنتج', '#'],
            data: List.generate(
                items.length,
                (i) => [
                      '${i + 1}',
                      '${items[i].quantity}',
                      items[i].product.price.toStringAsFixed(2),
                      items[i].product.name,
                      items[i].total.toStringAsFixed(2),
                    ]),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // المجاميع - يمين
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildPdfTotalRow('المجموع الفرعي', subtotal.toStringAsFixed(2),
                  arabicFont),
              if (discountAmount > 0)
                _buildPdfTotalRow('الخصم', '-${discountAmount.toStringAsFixed(2)}',
                    arabicFont),
              if (taxAmount > 0)
                _buildPdfTotalRow('الضريبة', taxAmount.toStringAsFixed(2),
                    arabicFont),
              _buildPdfTotalRow('الإجمالي', total.toStringAsFixed(2), arabicFont,
                  isBold: true, boldFont: arabicBold),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // معلومات الدفع
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('طريقة الدفع: ${_paymentLabel(_paymentMethod)}',
                  style: pw.TextStyle(fontSize: 11, font: arabicFont)),
              if (_paymentMethod == PaymentMethod.cash ||
                  _paymentMethod == PaymentMethod.mixed)
                pw.Text('المبلغ النقدي: ${_cashPaid.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 11, font: arabicFont)),
              if (_paymentMethod == PaymentMethod.mixed) ...[
                if (_upiPaid > 0)
                  pw.Text('مبلغ UPI: ${_upiPaid.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 11, font: arabicFont)),
                if (_cardPaid > 0)
                  pw.Text('مبلغ البطاقة: ${_cardPaid.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 11, font: arabicFont)),
              ],
              if (change > 0)
                pw.Text('الباقي: ${change.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 11, font: arabicFont)),
            ],
          ),

          // التذييل
          if (footer.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Paragraph(
                text: footer,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, font: arabicFont)),
          ],
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _buildPdfTotalRow(String label, String value, pw.Font? font,
      {bool isBold = false, pw.Font? boldFont}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  font: isBold ? boldFont ?? font : font,
                  fontSize: isBold ? 13 : 11)),
          pw.SizedBox(width: 20),
          pw.Text(label,
              style: pw.TextStyle(
                  fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  font: isBold ? boldFont ?? font : font,
                  fontSize: isBold ? 13 : 11)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${_twoDigits(date.month)}/${_twoDigits(date.day)} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  /// حفظ ملف PDF على الجهاز
  /// التعديل: حفظ في مجلد فواتير_نقدي مع تسمية موحدة
  Future<void> _savePdfToDevice({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required String footer,
    required BillingState billingState,
    required double subtotal,
    required double total,
    required double change,
    required double taxAmount,
  }) async {
    setState(() => _isSavingPdf = true);
    try {
      final invoiceNumber =
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final bytes = await _generateInvoicePdf(
        shopName: shopName,
        address1: address1,
        address2: address2,
        phone: phone,
        footer: footer,
        billingState: billingState,
        subtotal: subtotal,
        discountAmount: _discountAmount,
        taxAmount: taxAmount,
        total: total,
        change: change,
        invoiceNumber: invoiceNumber,
      );

      // حفظ الملف في مجلد فواتير_نقدي
      final directory = await getApplicationDocumentsDirectory();
      final invoicesDir = Directory('${directory.path}/فواتير_نقدي');

      if (!await invoicesDir.exists()) {
        await invoicesDir.create(recursive: true);
      }

      // تسمية موحدة: INV-رقم_الفاتورة_التاريخ.pdf
      final fileName = '${invoiceNumber}_${dateStr}.pdf';
      final file = File('${invoicesDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        _saveInvoice(context, billingState);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم حفظ الفاتورة في: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'مشاركة',
            textColor: Colors.white,
            onPressed: () {
              Share.shareXFiles([XFile(file.path)],
                  text: 'فاتورة رقم $invoiceNumber');
            },
          ),
        ));
        context.read<BillingBloc>().add(ClearCartEvent());
        context.go('/scan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل حفظ PDF: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSavingPdf = false);
    }
  }

  /// مشاركة ملف PDF
  Future<void> _sharePdf({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required String footer,
    required BillingState billingState,
    required double subtotal,
    required double total,
    required double change,
    required double taxAmount,
  }) async {
    setState(() => _isSavingPdf = true);
    try {
      final invoiceNumber =
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final bytes = await _generateInvoicePdf(
        shopName: shopName,
        address1: address1,
        address2: address2,
        phone: phone,
        footer: footer,
        billingState: billingState,
        subtotal: subtotal,
        discountAmount: _discountAmount,
        taxAmount: taxAmount,
        total: total,
        change: change,
        invoiceNumber: invoiceNumber,
      );

      // مشاركة الملف مع تسمية موحدة
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${invoiceNumber}_${dateStr}.pdf',
      );

      if (mounted) {
        _saveInvoice(context, billingState);
        context.read<BillingBloc>().add(ClearCartEvent());
        context.go('/scan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل مشاركة PDF: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSavingPdf = false);
    }
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
