import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/widgets/admin_login_dialog.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showDonationButton;
  final VoidCallback? onDonationPressed;

  const CustomAppBar({
    super.key,
    this.showDonationButton = true,
    this.onDonationPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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

        return _buildAppBarContent(context, shopName, shopLogo);
      },
    );
  }

  Widget _buildAppBarContent(
      BuildContext context, String shopName, String shopLogo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            // Shop Logo and Name (Right side)
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

            // Mode Switch Button
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                final isAdmin = authState is AdminMode;
                return GestureDetector(
                  onTap: () => _onModeToggle(context, authState),
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
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
                          color: isAdmin
                              ? const Color(0xFF00A77E)
                              : Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAdmin ? 'أدمن' : 'عامل',
                          style: TextStyle(
                            color: isAdmin
                                ? const Color(0xFF00A77E)
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Donation Button (Left side)
            if (showDonationButton)
              GestureDetector(
                onTap: onDonationPressed ??
                    () {
                      context.push('/donation');
                    },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
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
                      Icon(
                        Icons.volunteer_activism,
                        color: Color(0xFFC9A84C),
                        size: 18,
                      ),
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

  void _showAdminLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AdminLoginDialog(),
    );
  }

  void _showSwitchToCashierConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('التبديل لوضع العامل'),
          content: const Text('هل تريد التبديل إلى وضع العامل؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<AuthCubit>().disableAdminMode();
              },
              child: const Text('تبديل'),
            ),
          ],
        ),
      ),
    );
  }
}

  Widget _buildShopLogo(String shopLogo, String shopName) {
    // إذا كان هناك شعار
    if (shopLogo.isNotEmpty) {
      // تحقق إذا كان المسار محلي (ملف)
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
        // رابط خارجي
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

    // الشعار الافتراضي
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

