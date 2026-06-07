import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/routes/app_routes.dart';
import 'core/data/hive_database.dart';
import 'core/service_locator.dart' as di;
import 'core/theme/app_theme.dart';
import 'core/utils/currency_helper.dart';
import 'features/billing/presentation/bloc/billing_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/shop/presentation/bloc/shop_bloc.dart';
import 'features/settings/presentation/bloc/printer_bloc.dart';
import 'features/settings/presentation/bloc/printer_event.dart';
import 'features/sales/presentation/bloc/sales_bloc.dart';
import 'features/customers/presentation/bloc/customer_bloc.dart';
import 'features/suppliers/presentation/bloc/supplier_bloc.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/inventory/presentation/bloc/inventory_bloc.dart';
import 'features/expenses/presentation/bloc/expense_bloc.dart';
import 'features/zakat/presentation/bloc/zakat_bloc.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDatabase.init();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductBloc>(
            create: (context) => di.sl<ProductBloc>()..add(LoadProducts())),
        BlocProvider<ShopBloc>(
            create: (context) => di.sl<ShopBloc>()..add(LoadShopEvent())),
        BlocProvider<BillingBloc>(
            create: (context) =>
                BillingBloc(getProductByBarcodeUseCase: di.sl())),
        BlocProvider<PrinterBloc>(
            create: (context) => di.sl<PrinterBloc>()..add(InitPrinterEvent())),
        BlocProvider<SalesBloc>(
            create: (context) => di.sl<SalesBloc>()..add(LoadInvoicesEvent())),
        BlocProvider<CustomerBloc>(
            create: (context) =>
                di.sl<CustomerBloc>()..add(LoadCustomersEvent())),
        BlocProvider<SupplierBloc>(
            create: (context) =>
                di.sl<SupplierBloc>()..add(LoadSuppliersEvent())),
        BlocProvider<AuthCubit>(
            create: (context) => di.sl<AuthCubit>()),
        BlocProvider<InventoryBloc>(
            create: (context) =>
                di.sl<InventoryBloc>()..add(const LoadMovementsEvent())),
        BlocProvider<ExpenseBloc>(
            create: (context) => di.sl<ExpenseBloc>()..add(LoadExpensesEvent())),
        BlocProvider<ZakatBloc>(
            create: (context) => di.sl<ZakatBloc>()),
      ],
      child: BlocListener<ShopBloc, ShopState>(
        listenWhen: (previous, current) => current is ShopLoaded,
        listener: (context, state) {
          CurrencyHelper.updateCache(state);
        },
        child: MaterialApp.router(
          title: 'نقدي',
          theme: AppTheme.lightTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }
}
 