import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/widgets/admin_login_dialog.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';

/// CustomAppBar - شريط علوي مخصص محسّن
/// يدعم وضعين:
/// 1. الوضع المبسط (showDonationButton) - للشاشات الداخلية
/// 2. الوضع الكامل مع الترحيب والتاريخ والإشعارات - للشاشات الرئيسية
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showDonationButton;
  final bool showGreeting; // عرض الترحيب والتاريخ
  final VoidCallback? onDonationPressed;
  final VoidCallback? onNotificationPressed; // عند الضغط على الإشعارات
  final int? notificationCount;

  const CustomAppBar({
    super.key,
    this.showDonationButton = true,
    this.showGreeting = false,
    this.onDonationPressed,
    this.onNotificationPressed,
    this.notificationCount,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) {
        String shopName = 'نقدي';
        String shopLogo = '';

        if (state is ShopLoaded) {
          shopName = state.shop.name.isNotEmpty ? state.shop.name : 'نقدي';
          shopLogo = state.shop.shopLogo;
        }

        return Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
          ),
          child: SafeArea(
            bottom: false,
            child: showGreeting
                ? _buildFullLayout(context, shopName, shopLogo)
                : _buildSimpleLayout(context, shopName, shopLogo),
          ),
        );
      },
    );
  }

  // ===================== الوضع المبسط (للشاشات الداخلية) =====================
  Widget _buildSimpleLayout(BuildContext context, String shopName, String shopLogo) {
    return Row(
      children: [
        // الشعار واسم المتجر
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildShopLogo(shopLogo, shopName),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // زر تبديل الوضع
        _buildModeSwitch(context),
        const SizedBox(width: 8),
        // زر التبرع
        if (showDonationButton) _buildDonationButton(context),
      ],
    );
  }

  // ===================== الوضع الكامل (للشاشات الرئيسية) =====================
  Widget _buildFullLayout(BuildContext context, String shopName, String shopLogo) {
    return Row(
      children: [
        // اليمين: الإشعارات والترحيب
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // صف الترحيب والإشعارات
              Row(
                children: [
                  // أيقونة الإشعارات مع Badge
                  GestureDetector(
                    onTap: onNotificationPressed ?? () {},
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined,
                            color: Color(0xFF4B5563), size: 24),
                        if ((notificationCount ?? 0) > 0)
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 16, minHeight: 16),
                              child: Text(
                                '${notificationCount!}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // نص الترحيب
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      final userName = authState is AdminMode
                          ? authState.user.name
                          : 'كاشير';
                      return Text(
                        'مرحباً، $userName',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // التاريخ هجري + ميلادي
              _buildDateRow(),
            ],
          ),
        ),
        // اليسار: الشعار + وضع + تبرع
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, productState) {
            final lowStockCount = productState.products
                .where((p) => p.isAtOrBelowReorderPoint)
                .length;
            final nearExpiryCount = productState.products
                .where((p) => p.daysUntilExpiry != null && p.daysUntilExpiry! <= 30)
                .length;
            // نجمع الإشعارات من المخزون المنخفض والصلاحية القريبة
            if (notificationCount == null && (lowStockCount > 0 || nearExpiryCount > 0)) {
              // لا نعيد بناء لأننا داخل build
            }
            return const SizedBox.shrink();
          },
        ),
        // صورة المتجر + الوضع + التبرع
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShopLogo(shopLogo, shopName),
            const SizedBox(width: 8),
            _buildModeSwitch(context),
            const SizedBox(width: 4),
            if (showDonationButton) _buildDonationButton(context),
          ],
        ),
      ],
    );
  }

  // عرض التاريخ هجري + ميلادي
  Widget _buildDateRow() {
    final now = DateTime.now();
    final gregorian = DateFormat('EEEE, d MMMM yyyy', 'ar').format(now);
    return Text(
      gregorian,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF9CA3AF),
      ),
    );
  }

  // ===================== الأزرار المشتركة =====================

  Widget _buildModeSwitch(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isAdmin = authState is AdminMode;
        return GestureDetector(
          onTap: () => _onModeToggle(context, authState),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isAdmin
                  ? const Color(0xFF00A77E).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAdmin
                    ? const Color(0xFF00A77E).withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAdmin ? Icons.shield : Icons.person,
                  color: isAdmin ? const Color(0xFF00A77E) : Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  isAdmin ? 'أدمن' : 'عامل',
                  style: TextStyle(
                    color: isAdmin ? const Color(0xFF00A77E) : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDonationButton(BuildContext context) {
    return GestureDetector(
      onTap: onDonationPressed ?? () => context.push('/donation'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFC9A84C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFC9A84C).withOpacity(0.3),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volunteer_activism,
                color: Color(0xFFC9A84C), size: 18),
            SizedBox(width: 6),
            Text(
              'تبرع',
              style: TextStyle(
                color: Color(0xFFC9A84C),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== الشعار =====================
  Widget _buildShopLogo(String shopLogo, String shopName) {
    if (shopLogo.isNotEmpty) {
      if (!shopLogo.startsWith('http')) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[100],
          ),
          child: ClipOval(
            child: Image.file(
              File(shopLogo),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildDefaultLogo(shopName),
            ),
          ),
        );
      } else {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(shopLogo),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }
    return _buildDefaultLogo(shopName);
  }

  Widget _buildDefaultLogo(String shopName) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFF00A77E),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          shopName.isNotEmpty ? shopName.substring(0, 1).toUpperCase() : 'ن',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // ===================== أحداث =====================
  void _onModeToggle(BuildContext context, AuthState authState) {
    if (authState is AdminMode) {
      _showSwitchToCashierConfirmation(context);
    } else {
      _showAdminLoginDialog(context);
    }
  }

  Future<void> _showAdminLoginDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const AdminLoginDialog(),
    );
    if (result == true && context.mounted) {
      context.go('/admin-home');
    }
  }

  Future<void> _showSwitchToCashierConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('التبديل لوضع العامل'),
        content: const Text('هل تريد التبديل إلى وضع العامل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthCubit>().disableAdminMode();
              Navigator.of(ctx).pop(true);
            },
            child: const Text('تبديل'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      context.go('/scan');
    }
  }
}