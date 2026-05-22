import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/widgets/admin_login_dialog.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showModeSwitch;
  final bool showDonation;

  const CustomAppBar({
    super.key,
    this.showModeSwitch = true,
    this.showDonation = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

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
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Left: Shop logo + name (moved from right)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildShopLogo(shopLogo, shopName),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Right: Mode switch + Donation (moved from left)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showModeSwitch) _buildModeSwitch(context),
                    if (showModeSwitch && showDonation)
                      const SizedBox(width: 6),
                    if (showDonation) _buildDonationButton(context),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopLogo(String shopLogo, String shopName) {
    if (shopLogo.isNotEmpty) {
      if (!shopLogo.startsWith('http')) {
        return Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: Colors.grey[100]),
          child: ClipOval(
            child: Image.file(
              File(shopLogo),
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildDefaultLogo(shopName),
            ),
          ),
        );
      } else {
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
                image: NetworkImage(shopLogo), fit: BoxFit.cover),
          ),
        );
      }
    }
    return _buildDefaultLogo(shopName);
  }

  Widget _buildDefaultLogo(String shopName) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
          color: AppTheme.primaryColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          shopName.isNotEmpty ? shopName.substring(0, 1) : 'ن',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }

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
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAdmin
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAdmin ? Icons.shield : Icons.person,
                  color: isAdmin ? AppTheme.primaryColor : Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  isAdmin ? 'أدمن' : 'عامل',
                  style: TextStyle(
                    color: isAdmin ? AppTheme.primaryColor : Colors.grey[600],
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
      onTap: () => context.push('/donation'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volunteer_activism,
                color: AppTheme.secondaryColor, size: 16),
            SizedBox(width: 4),
            Text(
              'تبرع',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
