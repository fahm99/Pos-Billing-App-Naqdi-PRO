import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/app_settings.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../bloc/inventory_bloc.dart';
import '../../domain/entities/stock_movement.dart';

/// InventoryPage - صفحة إدارة المخزون
/// التعديل: تحسين منطق نقطة إعادة الطلب
/// - ترتيب المنتجات الأقل من نقطة الطلب أولاً
/// - إضافة أيقونة ⚠️ للمنتجات المنخفضة
/// - عرض تنبيهات دقيقة حسب الحالة (مساوٍ أو أقل)
/// - الاستماع لأحداث البيع والإرجاع لتحديث المخزون لحظياً
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    context.read<InventoryBloc>().add(const LoadMovementsEvent());
    _searchController.addListener(
        () => setState(() => _query = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// إعادة تحميل المنتجات عند العودة للشاشة
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ProductBloc>().add(LoadProducts());
      context.read<InventoryBloc>().add(const LoadMovementsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزون'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'المنتجات'),
            Tab(text: 'حركة المخزون'),
            Tab(text: 'تاريخ الصلاحية'),
          ],
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          // الاستماع لحركات المخزون
          BlocListener<InventoryBloc, InventoryState>(
            listener: (context, state) {
              if (state.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message!),
                  backgroundColor: state.status == InventoryStatus.error
                      ? Colors.red
                      : Colors.green,
                ));
                if (state.status == InventoryStatus.success) {
                  context.read<ProductBloc>().add(LoadProducts());
                }
              }
            },
          ),
          // الاستماع للبيع والإرجاع لتحديث المخزون لحظياً
          BlocListener<SalesBloc, SalesState>(
            listenWhen: (previous, current) =>
                current.status == SalesStatus.success &&
                previous.status != current.status,
            listener: (context, state) {
              // تحديث لحظي للمخزون بعد البيع أو الإرجاع
              context.read<ProductBloc>().add(LoadProducts());
              context.read<InventoryBloc>().add(const LoadMovementsEvent());
            },
          ),
        ],
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsTab(),
            _buildMovementsTab(),
            _buildExpiryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث عن منتج',
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              // تصفية المنتجات حسب البحث
              final filtered = state.products
                  .where((p) =>
                      p.name.toLowerCase().contains(_query) ||
                      p.barcode.contains(_query))
                  .toList();

              // ترتيب: المنتجات الأقل من نقطة الطلب أولاً
              final sorted = List<Product>.from(filtered);
              sorted.sort((a, b) {
                // المنتجات عند أو أقل من نقطة إعادة الطلب أولاً
                final aAtReorder = a.stock <= a.minStock;
                final bAtReorder = b.stock <= b.minStock;
                if (aAtReorder && !bAtReorder) return -1;
                if (!aAtReorder && bAtReorder) return 1;
                // ثم ترتيب تصاعدي حسب الكمية
                return a.stock.compareTo(b.stock);
              });

              // المنتجات التي تحتاج تنبيه
              final reorderProducts = state.products
                  .where((p) => p.stock <= p.minStock)
                  .toList();

              return Column(
                children: [
                  if (reorderProducts.isNotEmpty)
                    _buildReorderBanner(reorderProducts),
                  Expanded(
                    child: sorted.isEmpty
                        ? const Center(child: Text('لا توجد منتجات'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: sorted.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) =>
                                _buildProductStockCard(context, sorted[i]),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// شريط تنبيه نقطة إعادة الطلب المحسّن
  /// التعديل: عرض التنبيه مرة واحدة فقط لكل منتج
  Widget _buildReorderBanner(List<Product> reorderProducts) {
    // تصفية المنتجات التي لم يتم تنبيهها بعد
    final dismissed = AppSettings.getDismissedReorderAlerts();
    final newAlerts = reorderProducts
        .where((p) => !dismissed.contains(p.id))
        .toList();

    // إذا لم توجد تنبيهات جديدة، لا تعرض الشريط
    if (newAlerts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${newAlerts.length} منتج يحتاج إعادة طلب',
              style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              // تجاهل جميع التنبيهات الحالية
              for (final p in newAlerts) {
                AppSettings.dismissReorderAlert(p.id);
              }
              setState(() {});
            },
            child: const Text(
              'تجاهل',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// رسالة التنبيه الدقيقة حسب حالة المخزون
  String _getReorderMessage(Product product) {
    if (product.stock == product.minStock) {
      return '⚠️ تنبيه: منتج ${product.name} وصل لنقطة إعادة الطلب. الكمية المتبقية: ${product.stock}';
    } else {
      return '⚠️ تنبيه: منتج ${product.name} أقل من نقطة إعادة الطلب. الكمية المتبقية: ${product.stock}';
    }
  }

  Widget _buildProductStockCard(BuildContext context, Product product) {
    final isAtReorder = product.stock <= product.minStock;
    final isBelowReorder = product.stock < product.minStock;
    final isAtExactReorder = product.stock == product.minStock;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isAtReorder
                ? Colors.orange.withOpacity(0.4)
                : Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isAtReorder
                  ? Colors.orange.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isBelowReorder
                  ? Icons.warning_rounded
                  : isAtExactReorder
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
              color: isAtReorder ? Colors.orange : AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isAtReorder)
                      const Text(
                        '⚠️',
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('المخزون: ',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                    Text(
                      '${product.stock} ${product.unit}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAtReorder ? Colors.orange : Colors.black87),
                    ),
                    Flexible(
                      child: Text(' (حد أدنى: ${product.minStock})',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[400]),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (isAtExactReorder)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'وصل لنقطة إعادة الطلب',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                if (isBelowReorder)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'أقل من نقطة إعادة الطلب!',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(
                icon: Icons.add_circle_outline,
                color: AppTheme.primaryColor,
                tooltip: 'إضافة مخزون',
                onTap: () => _showAddStockDialog(context, product),
              ),
              _iconBtn(
                icon: Icons.tune,
                color: Colors.blue,
                tooltip: 'تعديل',
                onTap: () => _showAdjustDialog(context, product),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(icon, color: color, size: 20),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildMovementsTab() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state.status == InventoryStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.movements.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('لا توجد حركات مخزون',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.movements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _buildMovementCard(state.movements[i]),
        );
      },
    );
  }

  Widget _buildMovementCard(StockMovement m) {
    final isIn = m.type == MovementType.stockIn ||
        (m.type == MovementType.adjustment && m.stockAfter > m.stockBefore) ||
        m.type == MovementType.returned;
    final color = isIn ? Colors.green : Colors.red;
    final sign = isIn ? '+' : '-';
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(m.date);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIn ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${m.typeLabel} • $dateStr',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                if (m.note != null && m.note!.isNotEmpty)
                  Text(m.note!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${m.quantity}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: color),
              ),
              Text(
                '${m.stockBefore} ← ${m.stockAfter}',
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, Product product) {
    final ctrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة مخزون - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المخزون الحالي: ${product.stock} ${product.unit}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'الكمية المضافة', hintText: '0'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(ctrl.text);
              if (qty != null && qty > 0) {
                context.read<InventoryBloc>().add(AddStockEvent(
                      product: product,
                      quantity: qty,
                      note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                    ));
                // مسح التنبيه إذا ارتفع المخزون فوق نقطة الطلب
                final newStock = product.stock + qty;
                if (newStock > product.minStock) {
                  AppSettings.clearReorderAlert(product.id);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryTab() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final now = DateTime.now();
        final products = state.products;

        final expired = products.where((p) => p.expiryDate != null && p.expiryDate!.isBefore(now)).toList();
        final critical = products.where((p) {
          if (p.expiryDate == null) return false;
          final days = p.expiryDate!.difference(now).inDays;
          return days >= 0 && days <= 30;
        }).toList();
        final warning = products.where((p) {
          if (p.expiryDate == null) return false;
          final days = p.expiryDate!.difference(now).inDays;
          return days > 30 && days <= 60;
        }).toList();
        final valid = products.where((p) {
          if (p.expiryDate == null) return false;
          final days = p.expiryDate!.difference(now).inDays;
          return days > 60;
        }).toList();
        final noExpiry = products.where((p) => p.expiryDate == null).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildExpirySection('منتهي الصلاحية', expired, Colors.red, Icons.error_outline),
            const SizedBox(height: 12),
            _buildExpirySection('ينتهي خلال 30 يوم', critical, Colors.orange, Icons.warning_amber_rounded),
            const SizedBox(height: 12),
            _buildExpirySection('ينتهي خلال 60 يوم', warning, Colors.yellow[700]!, Icons.info_outline),
            const SizedBox(height: 12),
            _buildExpirySection('صلاحية جيدة', valid, Colors.green, Icons.check_circle_outline),
            const SizedBox(height: 12),
            _buildExpirySection('بدون تاريخ صلاحية', noExpiry, Colors.grey, Icons.help_outline),
          ],
        );
      },
    );
  }

  Widget _buildExpirySection(String title, List<Product> products, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${products.length}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text('لا يوجد', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          )
        else
          ...products.map((p) => _buildExpiryProductCard(p, color)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildExpiryProductCard(Product product, Color color) {
    final now = DateTime.now();
    String statusText;
    if (product.expiryDate == null) {
      statusText = 'غير محدد';
    } else if (product.expiryDate!.isBefore(now)) {
      statusText = 'منتهي';
    } else {
      final days = product.expiryDate!.difference(now).inDays;
      statusText = 'متبقي $days يوم';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6, right: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${product.stock} ${product.unit}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.expiryDate != null
                    ? DateFormat('yyyy/MM/dd').format(product.expiryDate!)
                    : '--',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(statusText, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, Product product) {
    final ctrl = TextEditingController(text: '${product.stock}');
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل مخزون - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'الكمية الجديدة'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration:
                  const InputDecoration(labelText: 'سبب التعديل (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(ctrl.text);
              if (qty != null && qty >= 0) {
                context.read<InventoryBloc>().add(AdjustStockEvent(
                      product: product,
                      newStock: qty,
                      note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                    ));
                // مسح التنبيه إذا ارتفع المخزون فوق نقطة الطلب
                if (qty > product.minStock) {
                  AppSettings.clearReorderAlert(product.id);
                } else {
                  // إعادة التنبيه إذا انخفض المخزون
                  AppSettings.dismissReorderAlert(product.id);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
