import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../domain/entities/invoice.dart';
import '../bloc/sales_bloc.dart';

class InvoiceDetailPage extends StatefulWidget {
  final Invoice invoice;
  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharing = false;

  Invoice get invoice => widget.invoice;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);
    final dateStr = DateFormat('dd/MM/yyyy – HH:mm').format(invoice.date);
    final cs = CurrencyHelper.getCurrencySymbol(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Share as PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: 'مشاركة كـ PDF',
            onPressed: _isSharing ? null : () => _shareAsPdf(context),
          ),
          // Share as Image
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Colors.amber),
            tooltip: 'مشاركة كصورة',
            onPressed: _isSharing ? null : () => _shareAsImage(context),
          ),
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
      body: RepaintBoundary(
        key: _repaintKey,
        child: SingleChildScrollView(
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
                        '$cs${invoice.cashPaid.toStringAsFixed(2)}'),
                  ],
                  if (invoice.changeAmount > 0) ...[
                    const Divider(height: 20),
                    _buildInfoRow('الباقي للعميل',
                        '$cs${invoice.changeAmount.toStringAsFixed(2)}'),
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
                          _dataCell('$cs${item.subtotal.toStringAsFixed(2)}',
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
                      '$cs${invoice.subtotal.toStringAsFixed(2)}'),
                  if (invoice.discountAmount > 0) ...[
                    const Divider(height: 16),
                    _buildInfoRow('الخصم',
                        '- $cs${invoice.discountAmount.toStringAsFixed(2)}',
                        valueColor: Colors.red),
                  ],
                  if (invoice.taxAmount > 0) ...[
                    const Divider(height: 16),
                    _buildInfoRow(
                        'الضريبة', '$cs${invoice.taxAmount.toStringAsFixed(2)}'),
                  ],
                  const Divider(height: 16),
                  _buildInfoRow(
                    'الإجمالي',
                    '$cs${invoice.totalAmount.toStringAsFixed(2)}',
                    bold: true,
                    valueColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
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
      NotificationHelper.show(context, 'لم يتم تحميل بيانات المتجر');
      return;
    }

    final printerHelper = PrinterHelper();
    if (!printerHelper.isConnected) {
      final savedMac = HiveDatabase.settingsBox.get('printer_mac');
      if (savedMac != null) {
        final connected = await printerHelper.connect(savedMac);
        if (!connected) {
          if (context.mounted) {
            NotificationHelper.show(context, 'فشل الاتصال بالطابعة');
          }
          return;
        }
      } else {
        if (context.mounted) {
          NotificationHelper.show(context, 'لا توجد طابعة محفوظة');
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
        NotificationHelper.show(context, 'تمت إعادة الطباعة');
      }
    } catch (e) {
      if (context.mounted) {
        NotificationHelper.show(context, 'فشلت الطباعة: $e');
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

  Future<void> _shareAsPdf(BuildContext context) async {
    setState(() => _isSharing = true);
    try {
      final shopState = context.read<ShopBloc>().state;
      if (shopState is! ShopLoaded) {
        NotificationHelper.show(context, 'لم يتم تحميل بيانات المتجر');
        return;
      }

      final bytes = await _generateInvoicePdf(shopState.shop);
      final dateStr = DateFormat('yyyy-MM-dd').format(invoice.date);
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${invoice.invoiceNumber}_$dateStr.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        NotificationHelper.show(context, 'فشل مشاركة PDF: $e');
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareAsImage(BuildContext context) async {
    setState(() => _isSharing = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${invoice.invoiceNumber}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles([XFile(file.path)], text: 'فاتورة ${invoice.invoiceNumber}');
    } catch (e) {
      if (context.mounted) {
        NotificationHelper.show(context, 'فشل مشاركة الصورة: $e');
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<Uint8List> _generateInvoicePdf(Shop shop) async {
    final arabicFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/cairo-font.ttf'),
    );

    final baseStyle = pw.TextStyle(font: arabicFont, fontSize: 12);
    final boldStyle = pw.TextStyle(
        font: arabicFont, fontSize: 12, fontWeight: pw.FontWeight.bold);
    final titleStyle = pw.TextStyle(
        font: arabicFont,
        fontSize: 22,
        fontWeight: pw.FontWeight.bold,
        decoration: pw.TextDecoration.underline);
    final storeNameStyle = pw.TextStyle(
        font: arabicFont, fontSize: 28, fontWeight: pw.FontWeight.bold);
    final headerCellStyle = pw.TextStyle(
        font: arabicFont,
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black);
    final cellStyle = pw.TextStyle(font: arabicFont, fontSize: 12);

    final cs = shop.currencySymbol.isNotEmpty ? shop.currencySymbol : 'ر.س';

    final subtotal = invoice.subtotal;
    final taxAmount = invoice.taxAmount;
    final taxRate =
        subtotal > 0 && taxAmount > 0 ? taxAmount / subtotal : 0.0;

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.all(20),
            padding: const pw.EdgeInsets.all(25),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
              color: PdfColors.white,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    shop.name.isNotEmpty ? shop.name : 'متجر النخبة التجاري',
                    style: storeNameStyle,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    '${shop.addressLine1.isNotEmpty ? shop.addressLine1 : 'الرياض'}\n'
                    '${shop.phoneNumber.isNotEmpty ? 'هاتف: ${shop.phoneNumber}' : ''}'
                    '${shop.taxNumber.isNotEmpty ? ' | الرقم الضريبي: ${shop.taxNumber}' : ''}',
                    style: baseStyle,
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Center(
                  child: pw.Text('فاتورة ضريبية مبسطة', style: titleStyle),
                ),
                pw.SizedBox(height: 15),
                pw.Divider(color: PdfColors.black, thickness: 2),

                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfInfoLine('رقم الفاتورة: ', invoice.invoiceNumber,
                              boldStyle, baseStyle),
                          _pdfInfoLine(
                              'التاريخ: ',
                              DateFormat('dd/MM/yyyy').format(invoice.date),
                              boldStyle,
                              baseStyle),
                          _pdfInfoLine(
                              'الوقت: ',
                              DateFormat('HH:mm').format(invoice.date),
                              boldStyle,
                              baseStyle),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfInfoLine('العميل: ',
                              invoice.customerName ?? 'عميل نقدي',
                              boldStyle, baseStyle),
                          _pdfInfoLine(
                              'طريقة الدفع: ',
                              _paymentLabel(invoice.paymentMethod),
                              boldStyle,
                              baseStyle),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),

                pw.Table(
                  border: pw.TableBorder.all(
                      color: PdfColors.black, width: 1.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFF0F0F0)),
                      children: [
                        '#',
                        'المنتج / الخدمة',
                        'الكمية',
                        'سعر الوحدة ($cs)',
                        'الإجمالي ($cs)',
                      ].map((e) => pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(e,
                                style: headerCellStyle,
                                textAlign: pw.TextAlign.center),
                          )).toList(),
                    ),
                    ...invoice.items.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final item = entry.value;
                      final lineTotal = item.price * item.quantity;
                      return pw.TableRow(
                        children: [
                          _pdfCell(index.toString(), cellStyle),
                          _pdfCell(item.productName, cellStyle),
                          _pdfCell(item.quantity.toString(), cellStyle),
                          _pdfCell(item.price.toStringAsFixed(2), cellStyle),
                          _pdfCell(lineTotal.toStringAsFixed(2), cellStyle),
                        ],
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 15),

                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 250,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                          color: PdfColors.black, width: 1.5),
                    ),
                    child: pw.Column(
                      children: [
                        _buildTotalRow('الإجمالي قبل الضريبة',
                            '$cs ${subtotal.toStringAsFixed(2)}',
                            boldStyle, baseStyle),
                        _buildTotalRow(
                            'ضريبة القيمة المضافة (${(taxRate * 100).toStringAsFixed(0)}%)',
                            '$cs ${taxAmount.toStringAsFixed(2)}',
                            boldStyle, baseStyle),
                        pw.Divider(
                            height: 1, color: PdfColors.black),
                        _buildTotalRow('المبلغ الإجمالي',
                            '$cs ${invoice.totalAmount.toStringAsFixed(2)}',
                            boldStyle,
                            baseStyle.copyWith(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(height: 25),
                pw.Divider(color: PdfColors.black, thickness: 2),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                          shop.footerText.isNotEmpty
                              ? shop.footerText
                              : 'شكراً لزيارتكم ... نتمنى لكم يوماً سعيداً',
                          style: baseStyle),
                      pw.Text(
                          'يمكنكم استبدال أو إرجاع المنتجات خلال 3 أيام مع إحضار الفاتورة',
                          style: baseStyle),
                      pw.SizedBox(height: 8),
                      pw.Text('تم إصدار هذه الفاتورة بواسطة نظام نقاط البيع (نقدي)',
                          style: baseStyle.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfInfoLine(String label, String value,
      pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    return pw.RichText(
      text: pw.TextSpan(
        style: valueStyle,
        children: [
          pw.TextSpan(text: label, style: labelStyle),
          pw.TextSpan(text: value),
        ],
      ),
    );
  }

  pw.Widget _pdfCell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  pw.Widget _buildTotalRow(String label, String value,
      pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
      ),
      padding:
          const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(label,
                style: labelStyle, textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(width: 16),
          pw.Text(value,
              style: valueStyle, textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }
}
