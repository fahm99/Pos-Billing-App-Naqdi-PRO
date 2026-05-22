import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';
import '../../features/shop/domain/entities/shop.dart';

class CurrencyHelper {
  static String _cachedSymbol = 'ر.س';
  static String _cachedName = 'ريال';

  static void updateCache(ShopState state) {
    if (state is ShopLoaded) {
      _cachedSymbol = state.shop.currencySymbol.isNotEmpty
          ? state.shop.currencySymbol
          : 'ر.س';
      _cachedName = state.shop.currencyName.isNotEmpty
          ? state.shop.currencyName
          : 'ريال';
    }
  }

  static String getCurrencySymbol([BuildContext? context]) {
    if (context != null) {
      final state = context.read<ShopBloc>().state;
      updateCache(state);
    }
    return _cachedSymbol;
  }

  static String getCurrencyName([BuildContext? context]) {
    if (context != null) {
      final state = context.read<ShopBloc>().state;
      updateCache(state);
    }
    return _cachedName;
  }

  static String formatPrice(BuildContext context, double price) {
    final symbol = getCurrencySymbol(context);
    return '$price $symbol';
  }

  static String formatPriceSimple(BuildContext context, double price) {
    final symbol = getCurrencySymbol(context);
    return '$price $symbol';
  }

  static Shop getShopCurrency(BuildContext context) {
    final state = context.read<ShopBloc>().state;
    if (state is ShopLoaded) {
      return state.shop;
    }
    return const Shop();
  }
}
