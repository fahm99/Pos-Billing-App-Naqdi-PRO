class AppDataSnapshot {
  final double todaySales;
  final double todayProfit;
  final int todayInvoices;
  final double todayExpenses;
  final double monthSales;
  final double monthProfit;
  final int monthInvoices;
  final double monthExpenses;
  final double totalRevenue;
  final double totalProfit;
  final int totalInvoices;
  final double totalExpenses;
  final int productCount;
  final int lowStockCount;
  final int expiredCount;
  final int customerCount;
  final int supplierCount;
  final int activeDebts;
  final double totalDebts;
  final double overdueDebts;
  final double totalOutstanding;
  final String topProduct;
  final String topCustomer;
  final int invoiceCountToday;
  final double avgInvoiceValue;
  final String bestDay;
  final String bestHour;

  const AppDataSnapshot({
    required this.todaySales,
    required this.todayProfit,
    required this.todayInvoices,
    required this.todayExpenses,
    required this.monthSales,
    required this.monthProfit,
    required this.monthInvoices,
    required this.monthExpenses,
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalInvoices,
    required this.totalExpenses,
    required this.productCount,
    required this.lowStockCount,
    required this.expiredCount,
    required this.customerCount,
    required this.supplierCount,
    required this.activeDebts,
    required this.totalDebts,
    required this.overdueDebts,
    required this.totalOutstanding,
    required this.topProduct,
    required this.topCustomer,
    required this.invoiceCountToday,
    required this.avgInvoiceValue,
    required this.bestDay,
    required this.bestHour,
  });
}
