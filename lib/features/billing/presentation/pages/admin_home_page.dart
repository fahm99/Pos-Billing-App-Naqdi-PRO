import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/domain/entities/product.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../sales/domain/entities/invoice.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentNavIndex = 2; // المسح (الافتراضي)

  // عناصر التنقل السفلي (من اليمين لليسار)
  final List<_BottomNavItem> _navItems = [
    _BottomNavItem(icon: Icons.grid_view_rounded, label: 'المزيد', path: '/settings'),
    _BottomNavItem(icon: Icons.trending_up_rounded, label: 'المبيعات', path: '/sales'),
    _BottomNavItem(icon: Icons.inventory_2_rounded, label: 'المخزون', path: '/inventory'),
    _BottomNavItem(icon: Icons.category_rounded, label: 'المنتجات', path: '/products-nav'),
    _BottomNavItem(icon: Icons.home_rounded, label: 'الرئيسية', path: '/admin-home'),
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CustomAppBar(showDonationButton: true),
      body: RefreshIndicator(
        onRefresh: () async {
          if (mounted) {
            context.read<ProductBloc>().add(LoadProducts());
            context.read<SalesBloc>().add(LoadInvoicesEvent());
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== الإجراءات السريعة ====================
              _buildQuickActions(),
              const SizedBox(height: 20),

              // ==================== ملخص اليوم ====================
              _buildTodaySummary(),
              const SizedBox(height: 20),

              // ==================== تنبيهات المخزون ====================
              _buildStockAlerts(),
              const SizedBox(height: 20),

              // ==================== آخر الفواتير ====================
              _buildRecentInvoices(),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(bottomPadding),
    );
  }

  // ==================== الإجراءات السريعة ====================
  Widget _buildQuickActions() {
    return Row(
      children: [
        // بطاقة نقطة البيع (خضراء)
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/scan'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'نقطة البيع',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'مسح الباركود وإتمام البيع',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // بطاقة بحث سريع (بيضاء)
        Expanded(
          child: GestureDetector(
            onTap: _showQuickSearchSheet,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search_rounded, color: Color(0xFF16A34A), size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'بحث سريع',
                    style: TextStyle(
                      color: Color(0xFF1A1C1E),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'بحث عن منتجات',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showQuickSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF16A34A)),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('ابحث عن منتج للبدء', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ملخص اليوم ====================
  Widget _buildTodaySummary() {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        // حساب ملخص اليوم
        final today = DateTime.now();
        final todayInvoices = state.invoices.where((inv) =>
            inv.date.year == today.year &&
            inv.date.month == today.month &&
            inv.date.day == today.day).toList();

        final todayRevenue = todayInvoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);
        final todayProfit = todayInvoices.fold(0.0, (sum, inv) => sum + inv.totalProfit);
        final todayCount = todayInvoices.length;
        final todayAvg = todayCount > 0 ? todayRevenue / todayCount : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص اليوم',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard('المبيعات', '$todayCount', Icons.receipt_long_rounded, const Color(0xFF16A34A), Colors.green[50]!),
                const SizedBox(width: 10),
                _buildStatCard('الإيرادات', '${todayRevenue.toStringAsFixed(0)} ر.س', Icons.trending_up_rounded, const Color(0xFF2563EB), Colors.blue[50]!),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStatCard('الأرباح', '${todayProfit.toStringAsFixed(0)} ر.س', Icons.account_balance_wallet_rounded, const Color(0xFFD97706), Colors.amber[50]!),
                const SizedBox(width: 10),
                _buildStatCard('متوسط الفاتورة', '${todayAvg.toStringAsFixed(0)} ر.س', Icons.bar_chart_rounded, const Color(0xFF7C3AED), Colors.purple[50]!),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: color),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== تنبيهات المخزون ====================
  Widget _buildStockAlerts() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final lowStockProducts = state.products
            .where((p) => p.isAtOrBelowReorderPoint)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تنبيهات المخزون',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                ),
                if (lowStockProducts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${lowStockProducts.length} منتج',
                      style: TextStyle(fontSize: 11, color: Colors.red[700], fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: lowStockProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green[300], size: 28),
                          const SizedBox(height: 4),
                          Text('جميع المنتجات متوفرة', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: lowStockProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => _buildStockAlertCard(lowStockProducts[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStockAlertCard(Product product) {
    final isBelow = product.isBelowReorderPoint;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isBelow ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isBelow ? Colors.red[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isBelow ? Icons.warning_rounded : Icons.info_outline_rounded,
              color: isBelow ? Colors.red : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  isBelow
                      ? 'أقل من نقطة الطلب!'
                      : 'وصل لنقطة الطلب',
                  style: TextStyle(fontSize: 10, color: isBelow ? Colors.red[700] : Colors.orange[700]),
                ),
                Text(
                  'المتبقي: ${product.stock} ${product.unit}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== آخر الفواتير ====================
  Widget _buildRecentInvoices() {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        final recentInvoices = state.invoices.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'آخر الفواتير',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                ),
                GestureDetector(
                  onTap: () => context.push('/sales'),
                  child: Text(
                    'عرض الكل',
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recentInvoices.map((inv) => _buildInvoiceCard(inv)),
            if (recentInvoices.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text('لا توجد فواتير بعد', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final dateStr = DateFormat('yyyy/MM/dd HH:mm', 'ar').format(invoice.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_rounded, color: Color(0xFF16A34A), size: 20),
        ),
        title: Text(invoice.invoiceNumber,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        trailing: Text(
          '${invoice.totalAmount.toStringAsFixed(0)} ر.س',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1C1E)),
        ),
        onTap: () => context.push('/sales/${invoice.id}', extra: invoice),
      ),
    );
  }

  // ==================== التنقل السفلي ====================
  Widget _buildBottomNavBar(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPadding + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _navItems.map((item) {
          final index = _navItems.indexOf(item);
          final isSelected = _currentNavIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _currentNavIndex = index);
              context.push(item.path);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF16A34A).withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon,
                      color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                      size: 24),
                  const SizedBox(height: 2),
                  Text(item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;
  final String path;
  const _BottomNavItem({required this.icon, required this.label, required this.path});
}