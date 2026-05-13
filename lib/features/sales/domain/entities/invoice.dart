import 'package:equatable/equatable.dart';

enum PaymentMethod { cash, card, upi, mixed }

enum InvoiceStatus { completed, returned, partial }

class InvoiceItem extends Equatable {
  final String productId;
  final String productName;
  final double price;
  final double costPrice;
  final int quantity;
  final String unit;
  final double discount; // خصم على المنتج

  const InvoiceItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.costPrice = 0,
    required this.quantity,
    this.unit = 'قطعة',
    this.discount = 0,
  });

  double get subtotal => (price * quantity) - discount;
  double get profit => (price - costPrice) * quantity;

  @override
  List<Object?> get props =>
      [productId, productName, price, costPrice, quantity, unit, discount];
}

class Invoice extends Equatable {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final double cashPaid;
  final double upiPaid;
  final double cardPaid;
  final double changeAmount; // الباقي للعميل
  final String? customerId;
  final String? customerName;
  final InvoiceStatus status;
  final String? notes;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    required this.totalAmount,
    this.paymentMethod = PaymentMethod.cash,
    this.cashPaid = 0,
    this.upiPaid = 0,
    this.cardPaid = 0,
    this.changeAmount = 0,
    this.customerId,
    this.customerName,
    this.status = InvoiceStatus.completed,
    this.notes,
  });

  double get totalProfit =>
      items.fold(0.0, (sum, item) => sum + item.profit) - discountAmount;

  @override
  List<Object?> get props => [id, invoiceNumber, date, status];
}
