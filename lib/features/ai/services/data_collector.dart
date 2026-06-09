import 'package:billing_app/features/sales/domain/entities/invoice.dart';
import 'package:billing_app/features/expenses/domain/entities/expense.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/customers/domain/entities/customer.dart';
import 'package:billing_app/features/suppliers/domain/entities/supplier.dart';
import 'package:billing_app/features/debts/domain/entities/debt.dart';
import 'app_data_snapshot.dart';

class DataCollector {
  AppDataSnapshot collect({
    required List<Invoice> invoices,
    required List<Expense> expenses,
    required List<Product> products,
    required List<Customer> customers,
    required List<Supplier> suppliers,
    required List<Debt> debts,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    final todayInvoices = invoices.where((i) => i.date.isAfter(todayStart)).toList();
    final monthInvoices = invoices.where((i) => i.date.isAfter(monthStart)).toList();

    final todaySales = todayInvoices.fold(0.0, (s, i) => s + i.totalAmount);
    final todayProfit = todayInvoices.fold(0.0, (s, i) => s + i.totalProfit);
    final monthSales = monthInvoices.fold(0.0, (s, i) => s + i.totalAmount);
    final monthProfit = monthInvoices.fold(0.0, (s, i) => s + i.totalProfit);
    final totalRevenue = invoices.fold(0.0, (s, i) => s + i.totalAmount);
    final totalProfit = invoices.fold(0.0, (s, i) => s + i.totalProfit);

    final todayExp = expenses.where((e) => e.date.isAfter(todayStart)).fold<double>(0, (s, e) => s + e.amount);
    final monthExp = expenses.where((e) => e.date.isAfter(monthStart)).fold<double>(0, (s, e) => s + e.amount);
    final totalExp = expenses.fold<double>(0, (s, e) => s + e.amount);

    final lowStock = products.where((p) => p.isAtOrBelowReorderPoint).length;
    final expired = products.where((p) => p.expiryDate != null && p.expiryDate!.isBefore(now)).length;

    final activeDebts = debts.where((d) => d.status == DebtStatus.active).length;
    final overdueDebts = debts.where((d) => d.isOverdue).length;
    final totalOutstanding = debts.fold(0.0, (s, d) => s + d.remainingAmount);

    final productSales = <String, double>{};
    for (final inv in invoices) {
      for (final item in inv.items) {
        productSales[item.productName] = (productSales[item.productName] ?? 0) + item.subtotal;
      }
    }
    final topProduct = productSales.entries.isEmpty
        ? '—'
        : productSales.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final customerSales = <String, double>{};
    for (final inv in invoices) {
      final name = inv.customerName ?? 'عميل نقدي';
      customerSales[name] = (customerSales[name] ?? 0) + inv.totalAmount;
    }
    final topCustomer = customerSales.entries.isEmpty
        ? '—'
        : customerSales.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final avgInvoiceValue = todayInvoices.isNotEmpty ? todaySales / todayInvoices.length : 0.0;

    final daySales = <int, double>{};
    for (final inv in monthInvoices) {
      daySales[inv.date.day] = (daySales[inv.date.day] ?? 0) + inv.totalAmount;
    }
    final bestDay = daySales.entries.isEmpty
        ? '—'
        : daySales.entries.reduce((a, b) => a.value > b.value ? a : b).key.toString();

    final hourSales = <int, double>{};
    for (final inv in invoices) {
      hourSales[inv.date.hour] = (hourSales[inv.date.hour] ?? 0) + inv.totalAmount;
    }
    final bestHour = hourSales.entries.isEmpty
        ? '—'
        : '${hourSales.entries.reduce((a, b) => a.value > b.value ? a : b).key}:00';

    return AppDataSnapshot(
      todaySales: todaySales,
      todayProfit: todayProfit,
      todayInvoices: todayInvoices.length,
      todayExpenses: todayExp,
      monthSales: monthSales,
      monthProfit: monthProfit,
      monthInvoices: monthInvoices.length,
      monthExpenses: monthExp,
      totalRevenue: totalRevenue,
      totalProfit: totalProfit,
      totalInvoices: invoices.length,
      totalExpenses: totalExp,
      productCount: products.length,
      lowStockCount: lowStock,
      expiredCount: expired,
      customerCount: customers.length,
      supplierCount: suppliers.length,
      activeDebts: activeDebts,
      totalDebts: totalOutstanding,
      overdueDebts: overdueDebts.toDouble(),
      totalOutstanding: totalOutstanding,
      topProduct: topProduct,
      topCustomer: topCustomer,
      invoiceCountToday: todayInvoices.length,
      avgInvoiceValue: avgInvoiceValue,
      bestDay: bestDay,
      bestHour: bestHour,
    );
  }
}
