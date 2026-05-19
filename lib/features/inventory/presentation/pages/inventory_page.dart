import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../bloc/inventory_bloc.dart';
import '../../domain/entities/stock_movement.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<InventoryBloc>().add(const LoadMovementsEvent());
    _searchController.addListener(
        () => setState(() => _query = _searchController.text.toLowerCase()));
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
          ],
        ),
      ),
      body: BlocListener<InventoryBloc, InventoryState>(
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message!),
              backgroundColor: state.status == InventoryStatus.error
                  ? Colors.red
                  : Colors.green,
            ));
            if (state.status == InventoryStatus.success) {
              // Reload products to reflect stock changes
              context.read<ProductBloc>().add(LoadProducts());
            }
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsTab(),
            _buildMovementsTab(),
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
              final lowStock =
                  state.products.where((p) => p.isLowStock).toList();
              final filtered = state.products
                  .where((p) =>
                      p.name.toLowerCase().contains(_query) ||
                      p.barcode.contains(_query))
                  .toList();

              return Column(
                children: [
                  if (lowStock.isNotEmpty)
                    _buildLowStockBanner(lowStock.length),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('لا توجد منتجات'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) =>
                                _buildProductStockCard(context, filtered[i]),
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

  Widget _buildLowStockBanner(int count) {
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
          Text(
            '$count منتج وصل للحد الأدنى من المخزون',
            style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildProductStockCard(BuildContext context, Product product) {
    final isLow = product.isLowStock;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isLow ? Colors.orange.withOpacity(0.4) : Colors.grey[200]!),
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
              color: isLow
                  ? Colors.orange.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
              color: isLow ? Colors.orange : AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
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
                          color: isLow ? Colors.orange : Colors.black87),
                    ),
                    Flexible(
                      child: Text(' (حد أدنى: ${product.minStock})',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[400]),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
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
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
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
