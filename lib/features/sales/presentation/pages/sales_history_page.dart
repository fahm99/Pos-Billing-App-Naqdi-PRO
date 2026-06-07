import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';
import '../../domain/entities/invoice.dart';
import '../bloc/sales_bloc.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _filterDate;
  String _currencySymbol = 'ر.س';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SalesBloc>().add(LoadInvoicesEvent());
    _searchController.addListener(() =>
        setState(() => _searchQuery = _searchController.text.toLowerCase()));
    _loadCurrencySymbol();
  }

  void _loadCurrencySymbol() {
    final shopState = context.read<ShopBloc>().state;
    if (shopState is ShopLoaded && shopState.shop.currencySymbol.isNotEmpty) {
      _currencySymbol = shopState.shop.currencySymbol;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'سجل الفواتير'),
            Tab(text: 'التقارير'),
          ],
        ),
      ),
      body: BlocConsumer<SalesBloc, SalesState>(
        listener: (context, state) {
          if (state.status == SalesStatus.error && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildInvoiceList(state),
              _buildReports(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInvoiceList(SalesState state) {
    if (state.status == SalesStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    var invoices = state.invoices;

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      invoices = invoices
          .where((i) =>
              i.invoiceNumber.toLowerCase().contains(_searchQuery) ||
              (i.customerName?.toLowerCase().contains(_searchQuery) ?? false))
          .toList();
    }

    // Filter by date
    if (_filterDate != null) {
      invoices = invoices
          .where((i) =>
              i.date.year == _filterDate!.year &&
              i.date.month == _filterDate!.month &&
              i.date.day == _filterDate!.day)
          .toList();
    }

    return Column(
      children: [
        // Search + date filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث برقم الفاتورة أو العميل',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _filterDate != null
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.calendar_today,
                      color: _filterDate != null
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      size: 20),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _filterDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    setState(() => _filterDate = picked);
                  },
                ),
              ),
              if (_filterDate != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () => setState(() => _filterDate = null),
                ),
            ],
          ),
        ),
        if (invoices.isEmpty)
          const Expanded(
            child: Center(
              child: Text('لا توجد فواتير',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildInvoiceCard(invoices[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final dateStr = DateFormat('dd/MM/yyyy – HH:mm').format(invoice.date);
    return InkWell(
      onTap: () => context.push('/sales/${invoice.id}', extra: invoice),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.invoiceNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(dateStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  if (invoice.customerName != null) ...[
                    const SizedBox(height: 2),
                    Text(invoice.customerName!,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_currencySymbol${invoice.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 4),
                _buildStatusChip(invoice.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(InvoiceStatus status) {
    Color color;
    String label;
    switch (status) {
      case InvoiceStatus.completed:
        color = Colors.green;
        label = 'مكتملة';
        break;
      case InvoiceStatus.returned:
        color = Colors.red;
        label = 'مرتجعة';
        break;
      case InvoiceStatus.partial:
        color = Colors.orange;
        label = 'جزئية';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildReports(SalesState state) {
    final now = DateTime.now();
    final todayInvoices = state.invoices
        .where((i) =>
            i.date.year == now.year &&
            i.date.month == now.month &&
            i.date.day == now.day)
        .toList();
    final monthInvoices = state.invoices
        .where((i) => i.date.year == now.year && i.date.month == now.month)
        .toList();

    final todayRevenue = todayInvoices.fold(0.0, (s, i) => s + i.totalAmount);
    final monthRevenue = monthInvoices.fold(0.0, (s, i) => s + i.totalAmount);
    final todayProfit = todayInvoices.fold(0.0, (s, i) => s + i.totalProfit);
    final monthProfit = monthInvoices.fold(0.0, (s, i) => s + i.totalProfit);

    final expenseState = context.read<ExpenseBloc>().state;
    final allExpenses = expenseState.expenses;
    final todayExpenses = allExpenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold<double>(0, (s, e) => s + e.amount);
    final monthExpenses = allExpenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (s, e) => s + e.amount);
    final totalExpenses = allExpenses.fold<double>(0, (s, e) => s + e.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReportSection('اليوم', todayInvoices.length, todayRevenue,
              todayProfit, todayExpenses),
          const SizedBox(height: 16),
          _buildReportSection('هذا الشهر', monthInvoices.length, monthRevenue,
              monthProfit, monthExpenses),
          const SizedBox(height: 16),
          _buildReportSection('الإجمالي', state.invoiceCount,
              state.totalRevenue, state.totalProfit, totalExpenses),
          const SizedBox(height: 24),
          if (state.invoices.isNotEmpty) _buildTopProducts(state.invoices),
        ],
      ),
    );
  }

  Widget _buildReportSection(String title, int count, double revenue,
      double profit, double expenses) {
    final currency = CurrencyHelper.getCurrencySymbol(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'الفواتير', '$count', Icons.receipt_long, Colors.blue)),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildStatCard(
                      'الإيرادات',
                      '$currency${revenue.toStringAsFixed(0)}',
                      Icons.attach_money,
                      AppTheme.primaryColor)),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildStatCard(
                      'الأرباح',
                      '$currency${profit.toStringAsFixed(0)}',
                      Icons.trending_up,
                      Colors.orange)),
              const SizedBox(width: 6),
              Expanded(
                  child: _buildStatCard(
                      'المصروفات',
                      '$currency${expenses.toStringAsFixed(0)}',
                      Icons.money_off,
                      Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTopProducts(List<Invoice> invoices) {
    final Map<String, double> productSales = {};
    for (final inv in invoices) {
      for (final item in inv.items) {
        productSales[item.productName] =
            (productSales[item.productName] ?? 0) + item.subtotal;
      }
    }
    final sorted = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('أكثر المنتجات مبيعاً',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...top.asMap().entries.map((e) {
            final rank = e.key + 1;
            final entry = e.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? Colors.amber
                          : rank == 2
                              ? Colors.grey[400]
                              : Colors.brown[300],
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('$rank',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(entry.key,
                          style: const TextStyle(fontSize: 13))),
                  Text('$_currencySymbol${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
