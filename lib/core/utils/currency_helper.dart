import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';
import '../../features/shop/domain/entities/shop.dart';

/// Helper class to access currency settings from anywhere in the app
class CurrencyHelper {
  static String getCurrencyName(BuildContext context) {
    final state = context.read<ShopBloc>().state;
    if (state is ShopLoaded) {
      return state.shop.currencyName.isNotEmpty
          ? state.shop.currencyName
          : 'ريال';
    }
    return 'ريال';
  }

  static String getCurrencySymbol(BuildContext context) {
    final state = context.read<ShopBloc>().state;
    if (state is ShopLoaded) {
      return state.shop.currencySymbol.isNotEmpty
          ? state.shop.currencySymbol
          : 'ر.س';
    }
    return 'ر.س';
  }

  static String getCurrencyLogo(BuildContext context) {
    final state = context.read<ShopBloc>().state;
    if (state is ShopLoaded) {
      return state.shop.currencyLogo;
    }
    return '';
  }

  /// Format a price with currency symbol
  static String formatPrice(BuildContext context, double price) {
    final symbol = getCurrencySymbol(context);
    final name = getCurrencyName(context);
    return '$price $symbol ($name)';
  }

  /// Format a price with just the symbol
  static String formatPriceSimple(BuildContext context, double price) {
    final symbol = getCurrencySymbol(context);
    return '$price $symbol';
  }

  /// Get the current shop currency settings
  static Shop getShopCurrency(BuildContext context) {
    final state = context.read<ShopBloc>().state;
    if (state is ShopLoaded) {
      return state.shop;
    }
    return const Shop();
  }
}
