import 'package:hive/hive.dart';
import '../../domain/entities/invoice.dart';

part 'invoice_model.g.dart';

@HiveType(typeId: 6)
class InvoiceItemModel extends HiveObject {
  @HiveField(0)
  final String productId;
  @HiveField(1)
  final String productName;
  @HiveField(2)
  final double price;
  @HiveField(3)
  final double costPrice;
  @HiveField(4)
  final int quantity;
  @HiveField(5)
  final String unit;
  @HiveField(6)
  final double discount;

  InvoiceItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    this.costPrice = 0,
    required this.quantity,
    this.unit = 'قطعة',
    this.discount = 0,
  });

  factory InvoiceItemModel.fromEntity(InvoiceItem item) => InvoiceItemModel(
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        costPrice: item.costPrice,
        quantity: item.quantity,
        unit: item.unit,
        discount: item.discount,
      );

  InvoiceItem toEntity() => InvoiceItem(
        productId: productId,
        productName: productName,
        price: price,
        costPrice: costPrice,
        quantity: quantity,
        unit: unit,
        discount: discount,
      );
}

@HiveType(typeId: 2)
class InvoiceModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String invoiceNumber;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final List<InvoiceItemModel> items;
  @HiveField(4)
  final double subtotal;
  @HiveField(5)
  final double discountAmount;
  @HiveField(6)
  final double taxAmount;
  @HiveField(7)
  final double totalAmount;
  @HiveField(8)
  final int paymentMethod; // index of PaymentMethod enum
  @HiveField(9)
  final double cashPaid;
  @HiveField(10)
  final double upiPaid;
  @HiveField(11)
  final double cardPaid;
  @HiveField(12)
  final double changeAmount;
  @HiveField(13)
  final String? customerId;
  @HiveField(14)
  final String? customerName;
  @HiveField(15)
  final int status; // index of InvoiceStatus enum
  @HiveField(16)
  final String? notes;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    required this.totalAmount,
    this.paymentMethod = 0,
    this.cashPaid = 0,
    this.upiPaid = 0,
    this.cardPaid = 0,
    this.changeAmount = 0,
    this.customerId,
    this.customerName,
    this.status = 0,
    this.notes,
  });

  factory InvoiceModel.fromEntity(Invoice invoice) => InvoiceModel(
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        date: invoice.date,
        items: invoice.items.map(InvoiceItemModel.fromEntity).toList(),
        subtotal: invoice.subtotal,
        discountAmount: invoice.discountAmount,
        taxAmount: invoice.taxAmount,
        totalAmount: invoice.totalAmount,
        paymentMethod: invoice.paymentMethod.index,
        cashPaid: invoice.cashPaid,
        upiPaid: invoice.upiPaid,
        cardPaid: invoice.cardPaid,
        changeAmount: invoice.changeAmount,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        status: invoice.status.index,
        notes: invoice.notes,
      );

  Invoice toEntity() => Invoice(
        id: id,
        invoiceNumber: invoiceNumber,
        date: date,
        items: items.map((i) => i.toEntity()).toList(),
        subtotal: subtotal,
        discountAmount: discountAmount,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        paymentMethod: PaymentMethod.values[paymentMethod],
        cashPaid: cashPaid,
        upiPaid: upiPaid,
        cardPaid: cardPaid,
        changeAmount: changeAmount,
        customerId: customerId,
        customerName: customerName,
        status: InvoiceStatus.values[status],
        notes: notes,
      );
}
