import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../product/domain/entities/product.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';
import '../../domain/entities/cart_item.dart';

class AdminBillingPage extends StatelessWidget {
  const AdminBillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currencySymbol = 'ر.س';
    final shopState = context.read<ShopBloc>().state;
    if (shopState is ShopLoaded && shopState.shop.currencySymbol.isNotEmpty) {
      currencySymbol = shopState.shop.currencySymbol;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتج الممسوح',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28,
              color: Theme.of(context).primaryColor),
          onPressed: () => context.go('/admin-home'),
        ),
      ),
      body: BlocBuilder<BillingBloc, BillingState>(
        builder: (context, state) {
          if (state.cartItems.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/admin-home');
            });
            return const Center(child: CircularProgressIndicator());
          }

          final cartItem = state.cartItems.last;
          final product = cartItem.product;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProductCard(product, currencySymbol),
                const SizedBox(height: 24),
                _buildQuantitySection(context, cartItem, product),
                const SizedBox(height: 24),
                _buildTotalSection(state, currencySymbol),
                const SizedBox(height: 32),
                _buildActionButtons(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, String currencySymbol) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.file(
                      File(product.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultImage(),
                    )
                  : _buildDefaultImage(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C1E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'المخزون: ${product.stock} ${product.unit}',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Center(
      child: Image.asset(
        'assets/naqdilogo.jpg',
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.inventory_2_outlined,
          color: AppTheme.primaryColor,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildQuantitySection(BuildContext context, CartItem cartItem, Product product) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الكمية',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1E))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQtyButton(Icons.remove_rounded, () {
                if (cartItem.quantity > 1) {
                  context.read<BillingBloc>().add(UpdateQuantityEvent(
                      product.id, cartItem.quantity - 1));
                } else {
                  context.read<BillingBloc>()
                      .add(RemoveProductFromCartEvent(product.id));
                }
              }),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '${cartItem.quantity}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
              ),
              _buildQtyButton(Icons.add_rounded, () {
                context.read<BillingBloc>().add(
                    UpdateQuantityEvent(product.id, cartItem.quantity + 1));
              }, isAdd: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed,
      {bool isAdd = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isAdd
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              size: 24,
              color: isAdd ? AppTheme.primaryColor : Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildTotalSection(BillingState state, String currencySymbol) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00A77E).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00A77E).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('إجمالي الطلب',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '$currencySymbol${state.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A77E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, BillingState state) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/checkout'),
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('مراجعة الطلب',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/admin-home'),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('مسح منتج آخر',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}
