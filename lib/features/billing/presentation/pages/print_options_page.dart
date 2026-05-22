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
import '../../../../core/utils/notification_helper.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../shop/domain/entities/shop.dart';
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
  bool _isSharingImage = false;
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
      body: BlocConsumer<BillingBloc, BillingState>(
        listener: (context, state) {
          if (state.printSuccess) {
            _saveInvoice(context, state);
            NotificationHelper.show(context, 'تم حفظ الفاتورة بنجاح');
            context.go('/scan');
          }
          if (state.error != null) {
            NotificationHelper.show(context, state.error!);
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
              String currencySymbol = _currencySymbol;
              if (shopState is ShopLoaded) {
                shopName = shopState.shop.name;
                upiId = shopState.shop.upiId;
                currencySymbol = shopState.shop.currencySymbol.isNotEmpty
                    ? shopState.shop.currencySymbol
                    : 'ر.س';
              }

              final taxAmount = (subtotal - _discountAmount) * (_taxPercent / 100);
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
                    _buildPrintOptions(billingState, shopState, shopName, upiId,
                        subtotal, total, change, taxAmount, currencySymbol),
                    const SizedBox(height: 24),
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

  Widget _buildPrintOptions(
      BillingState billingState, ShopState shopState,
      String shopName, String upiId, double subtotal, double total,
      double change, double taxAmount, String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('خيارات الإرسال', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isSavingPdf ? null : () {
            if (shopState is ShopLoaded) {
              _savePdfToDevice(
                shopName: shopName,
                shop: shopState.shop,
                billingState: billingState,
                subtotal: subtotal,
                total: total,
                change: change,
                taxAmount: taxAmount,
              );
            }
          },
          child: _buildOptionCard(
            icon: Icons.save_alt,
            color: const Color(0xFF2196F3),
            title: 'حفظ كملف PDF',
            subtitle: 'حفظ الفاتورة على جهازك',
            isLoading: _isSavingPdf,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isSavingPdf ? null : () {
            if (shopState is ShopLoaded) {
              _sharePdf(
                shopName: shopName,
                shop: shopState.shop,
                billingState: billingState,
                subtotal: subtotal,
                total: total,
                change: change,
                taxAmount: taxAmount,
              );
            }
          },
          child: _buildOptionCard(
            icon: Icons.share,
            color: const Color(0xFFE74C3C),
            title: 'مشاركة PDF',
            subtitle: 'مشاركة الفاتورة عبر التطبيقات',
          ),
        ),
        const SizedBox(height: 12),
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
          child: _buildOptionCard(
            icon: Icons.print,
            color: AppTheme.primaryColor,
            title: 'طباعة عبر الطابعة',
            subtitle: 'طباعة الفاتورة على طابعة بلوتوث',
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isSharingImage ? null : () => _shareAsImage(),
          child: _buildOptionCard(
            icon: Icons.image_outlined,
            color: Colors.amber[700]!,
            title: 'مشاركة كصورة',
            subtitle: 'مشاركة الفاتورة كصورة',
            isLoading: _isSharingImage,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    bool isLoading = false,
  }) {
    return Container(
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isLoading
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                : Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSellWithoutInvoiceButton(BillingState billingState, ShopState shopState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: billingState.cartItems.isEmpty ? null : () {
          _saveInvoice(context, billingState);
          NotificationHelper.show(context, 'تم تسجيل البيع بنجاح');
          context.read<BillingBloc>().add(ClearCartEvent());
          context.go('/scan');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('بيع بدون فاتورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Future<Uint8List> _generateInvoicePdf({
    required String shopName,
    required Shop shop,
    required BillingState billingState,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double total,
    required double change,
    required String invoiceNumber,
  }) async {
    final doc = pw.Document();

    pw.Font? arabicFont;
    pw.Font? arabicBold;
    try {
      arabicFont = await PdfGoogleFonts.cairoRegular();
      arabicBold = await PdfGoogleFonts.cairoBold();
    } catch (_) {
      try {
        arabicFont = await PdfGoogleFonts.tajawalRegular();
        arabicBold = await PdfGoogleFonts.tajawalBold();
      } catch (_) {
        try {
          arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
          arabicBold = await PdfGoogleFonts.notoNaskhArabicBold();
        } catch (_) {}
      }
    }

    final theme = pw.ThemeData.withFont(
      base: arabicFont ?? pw.Font.helvetica(),
      bold: arabicBold ?? pw.Font.helveticaBold(),
    );

    final items = billingState.cartItems;
    final currencySymbol = shop.currencySymbol.isNotEmpty ? shop.currencySymbol : 'ر.س';

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          // Header - Logo & Shop name on right, Invoice # & Date on left
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(shopName,
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, font: arabicBold)),
                  if (shop.addressLine1.isNotEmpty)
                    pw.Text(shop.addressLine1, style: pw.TextStyle(fontSize: 10, font: arabicFont)),
                  if (shop.addressLine2.isNotEmpty)
                    pw.Text(shop.addressLine2, style: pw.TextStyle(fontSize: 10, font: arabicFont)),
                  if (shop.phoneNumber.isNotEmpty)
                    pw.Text('الهاتف: ${shop.phoneNumber}', style: pw.TextStyle(fontSize: 10, font: arabicFont)),
                  if (shop.taxNumber.isNotEmpty)
                    pw.Text('الرقم الضريبي: ${shop.taxNumber}', style: pw.TextStyle(fontSize: 10, font: arabicFont)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('رقم الفاتورة: $invoiceNumber',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: arabicBold)),
                  pw.Text('التاريخ: ${_formatDate(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 10, font: arabicFont)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // Products table with RTL support
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
                      '$currencySymbol${items[i].product.price.toStringAsFixed(2)}',
                      items[i].product.name,
                      '$currencySymbol${items[i].total.toStringAsFixed(2)}',
                    ]),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // Totals aligned to the right
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildPdfTotalRow('المجموع الفرعي', '$currencySymbol${subtotal.toStringAsFixed(2)}', arabicFont),
              if (discountAmount > 0)
                _buildPdfTotalRow('الخصم', '-$currencySymbol${discountAmount.toStringAsFixed(2)}', arabicFont),
              if (taxAmount > 0)
                _buildPdfTotalRow('الضريبة', '$currencySymbol${taxAmount.toStringAsFixed(2)}', arabicFont),
              _buildPdfTotalRow('الإجمالي', '$currencySymbol${total.toStringAsFixed(2)}', arabicFont,
                  isBold: true, boldFont: arabicBold),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // Payment info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('طريقة الدفع: ${_paymentLabel(_paymentMethod)}',
                  style: pw.TextStyle(fontSize: 11, font: arabicFont)),
              if (_paymentMethod == PaymentMethod.cash || _paymentMethod == PaymentMethod.mixed)
                pw.Text('المبلغ النقدي: $currencySymbol${_cashPaid.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 11, font: arabicFont)),
              if (_paymentMethod == PaymentMethod.mixed) ...[
                if (_upiPaid > 0)
                  pw.Text('مبلغ UPI: $currencySymbol${_upiPaid.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 11, font: arabicFont)),
                if (_cardPaid > 0)
                  pw.Text('مبلغ البطاقة: $currencySymbol${_cardPaid.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 11, font: arabicFont)),
              ],
              if (change > 0)
                pw.Text('الباقي: $currencySymbol${change.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 11, font: arabicFont)),
            ],
          ),

          // Footer
          if (shop.footerText.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Paragraph(
                text: shop.footerText,
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
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                  fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  font: isBold ? boldFont ?? font : font,
                  fontSize: isBold ? 13 : 11)),
          pw.SizedBox(width: 20),
          pw.Text(label,
              textDirection: pw.TextDirection.rtl,
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

  Future<void> _savePdfToDevice({
    required String shopName,
    required Shop shop,
    required BillingState billingState,
    required double subtotal,
    required double total,
    required double change,
    required double taxAmount,
  }) async {
    setState(() => _isSavingPdf = true);
    try {
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final bytes = await _generateInvoicePdf(
        shopName: shopName,
        shop: shop,
        billingState: billingState,
        subtotal: subtotal,
        discountAmount: _discountAmount,
        taxAmount: taxAmount,
        total: total,
        change: change,
        invoiceNumber: invoiceNumber,
      );

      final directory = await getApplicationDocumentsDirectory();
      final invoicesDir = Directory('${directory.path}/فواتير_نقدي');
      if (!await invoicesDir.exists()) {
        await invoicesDir.create(recursive: true);
      }

      final fileName = '${invoiceNumber}_$dateStr.pdf';
      final file = File('${invoicesDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        _saveInvoice(context, billingState);
        NotificationHelper.show(context, 'تم حفظ الفاتورة بنجاح');
        if (mounted) {
          Share.shareXFiles([XFile(file.path)], text: 'فاتورة رقم $invoiceNumber');
        }
        context.read<BillingBloc>().add(ClearCartEvent());
        context.go('/scan');
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.show(context, 'فشل حفظ PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _isSavingPdf = false);
    }
  }

  Future<void> _sharePdf({
    required String shopName,
    required Shop shop,
    required BillingState billingState,
    required double subtotal,
    required double total,
    required double change,
    required double taxAmount,
  }) async {
    setState(() => _isSavingPdf = true);
    try {
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final bytes = await _generateInvoicePdf(
        shopName: shopName,
        shop: shop,
        billingState: billingState,
        subtotal: subtotal,
        discountAmount: _discountAmount,
        taxAmount: taxAmount,
        total: total,
        change: change,
        invoiceNumber: invoiceNumber,
      );

      await Printing.sharePdf(bytes: bytes, filename: '${invoiceNumber}_$dateStr.pdf');

      if (mounted) {
        _saveInvoice(context, billingState);
        context.read<BillingBloc>().add(ClearCartEvent());
        context.go('/scan');
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.show(context, 'فشل مشاركة PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _isSavingPdf = false);
    }
  }

  Future<void> _shareAsImage() async {
    setState(() => _isSharingImage = true);
    try {
      final billingState = context.read<BillingBloc>().state;
      if (billingState.cartItems.isEmpty) return;

      _saveInvoice(context, billingState);
      NotificationHelper.show(context, 'تم تسجيل البيع بنجاح');
      context.read<BillingBloc>().add(ClearCartEvent());
      context.go('/scan');
    } catch (e) {
      if (mounted) {
        NotificationHelper.show(context, 'فشل: $e');
      }
    } finally {
      if (mounted) setState(() => _isSharingImage = false);
    }
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
