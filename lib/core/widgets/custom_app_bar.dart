import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
          shopLogo = state.shop.currencyLogo;
        }

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
                      if (shopLogo.isNotEmpty)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(shopLogo),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A77E),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              shopName.isNotEmpty
                                  ? shopName.substring(0, 1).toUpperCase()
                                  : 'ن',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
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
      },
    );
  }
}
