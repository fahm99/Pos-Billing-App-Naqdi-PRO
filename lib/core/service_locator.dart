import 'package:get_it/get_it.dart';
import '../../features/ai/data/datasources/ai_local_datasource.dart';
import '../../features/ai/data/datasources/ai_remote_datasource.dart';
import '../../features/ai/data/repositories/ai_repository_impl.dart';
import '../../features/ai/presentation/bloc/ai_bloc.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/usecases/product_usecases.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../../features/shop/data/repositories/shop_repository_impl.dart';
import '../../features/shop/domain/repositories/shop_repository.dart';
import '../../features/shop/domain/usecases/shop_usecases.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';
import '../../features/settings/data/repositories/printer_repository_impl.dart';
import '../../features/settings/domain/repositories/printer_repository.dart';
import '../../features/settings/presentation/bloc/printer_bloc.dart';
import '../../features/sales/data/repositories/sales_repository_impl.dart';
import '../../features/sales/domain/repositories/sales_repository.dart';
import '../../features/sales/domain/usecases/sales_usecases.dart';
import '../../features/sales/presentation/bloc/sales_bloc.dart';
import '../../features/customers/data/repositories/customer_repository_impl.dart';
import '../../features/customers/domain/repositories/customer_repository.dart';
import '../../features/customers/domain/usecases/customer_usecases.dart';
import '../../features/customers/presentation/bloc/customer_bloc.dart';
import '../../features/suppliers/data/repositories/supplier_repository_impl.dart';
import '../../features/suppliers/domain/repositories/supplier_repository.dart';
import '../../features/suppliers/domain/usecases/supplier_usecases.dart';
import '../../features/suppliers/presentation/bloc/supplier_bloc.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/inventory/presentation/bloc/inventory_bloc.dart';
import '../../features/expenses/data/repositories/expense_repository_impl.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/expenses/domain/usecases/expense_usecases.dart';
import '../../features/expenses/presentation/bloc/expense_bloc.dart';
import '../../features/zakat/data/repositories/zakat_repository_impl.dart';
import '../../features/zakat/domain/repositories/zakat_repository.dart';
import '../../features/zakat/domain/usecases/zakat_usecases.dart';
import '../../features/zakat/presentation/bloc/zakat_bloc.dart';
import '../../features/debts/data/repositories/debt_repository_impl.dart';
import '../../features/debts/domain/repositories/debt_repository.dart';
import '../../features/debts/domain/usecases/debt_usecases.dart';
import '../../features/debts/presentation/bloc/debt_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Product ──────────────────────────────────────────────
  sl.registerFactory(() => ProductBloc(
        getProductsUseCase: sl(),
        addProductUseCase: sl(),
        updateProductUseCase: sl(),
        deleteProductUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByBarcodeUseCase(sl()));
  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl());

  // ── Shop ─────────────────────────────────────────────────
  sl.registerFactory(() => ShopBloc(
        getShopUseCase: sl(),
        updateShopUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopUseCase(sl()));
  sl.registerLazySingleton<ShopRepository>(() => ShopRepositoryImpl());

  // ── Printer ───────────────────────────────────────────────
  sl.registerFactory(() => PrinterBloc(repository: sl()));
  sl.registerLazySingleton<PrinterRepository>(() => PrinterRepositoryImpl());

  // ── Sales ─────────────────────────────────────────────────
  sl.registerFactory(() => SalesBloc(
        getInvoicesUseCase: sl(),
        saveInvoiceUseCase: sl(),
        deleteInvoiceUseCase: sl(),
        completeSaleUseCase: sl(),
        returnInvoiceUseCase: sl(),
        getProductsUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoiceByIdUseCase(sl()));
  sl.registerLazySingleton(() => SaveInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => DeleteInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => CompleteSaleUseCase(
        salesRepository: sl(),
        productRepository: sl(),
        inventoryRepository: sl(),
      ));
  sl.registerLazySingleton(() => ReturnInvoiceUseCase(
        salesRepository: sl(),
        productRepository: sl(),
        inventoryRepository: sl(),
      ));
  sl.registerLazySingleton<SalesRepository>(() => SalesRepositoryImpl());

  // ── Customers ─────────────────────────────────────────────
  sl.registerFactory(() => CustomerBloc(
        getCustomersUseCase: sl(),
        addCustomerUseCase: sl(),
        updateCustomerUseCase: sl(),
        deleteCustomerUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetCustomersUseCase(sl()));
  sl.registerLazySingleton(() => AddCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCustomerUseCase(sl()));
  sl.registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl());

  // ── Suppliers ─────────────────────────────────────────────
  sl.registerFactory(() => SupplierBloc(
        getSuppliersUseCase: sl(),
        addSupplierUseCase: sl(),
        updateSupplierUseCase: sl(),
        deleteSupplierUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetSuppliersUseCase(sl()));
  sl.registerLazySingleton(() => AddSupplierUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSupplierUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSupplierUseCase(sl()));
  sl.registerLazySingleton<SupplierRepository>(() => SupplierRepositoryImpl());

  // ── Auth ──────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerFactory(() => AuthCubit(sl()));

  // ── Inventory ─────────────────────────────────────────────
  sl.registerFactory(() => InventoryBloc(
        inventoryRepository: sl(),
        productRepository: sl(),
      ));
  sl.registerLazySingleton<InventoryRepository>(
      () => InventoryRepositoryImpl());

  // ── Expenses ─────────────────────────────────────────────
  sl.registerFactory(() => ExpenseBloc(
        getExpensesUseCase: sl(),
        addExpenseUseCase: sl(),
        updateExpenseUseCase: sl(),
        deleteExpenseUseCase: sl(),
        getExpenseSummaryUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetExpensesUseCase(sl()));
  sl.registerLazySingleton(() => AddExpenseUseCase(sl()));
  sl.registerLazySingleton(() => UpdateExpenseUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExpenseUseCase(sl()));
  sl.registerLazySingleton(() => GetExpenseSummaryUseCase(sl()));
  sl.registerLazySingleton<ExpenseRepository>(
      () => ExpenseRepositoryImpl());

  // ── Zakat ──────────────────────────────────────────────
  sl.registerFactory(() => ZakatBloc(
        calculateZakatUseCase: sl(),
        getPaymentsUseCase: sl(),
        addPaymentUseCase: sl(),
        deletePaymentUseCase: sl(),
        getTotalPaidUseCase: sl(),
      ));
  sl.registerLazySingleton(() => CalculateZakatUseCase(
        salesRepository: sl(),
        expenseRepository: sl(),
      ));
  sl.registerLazySingleton(() => GetZakatPaymentsUseCase(sl()));
  sl.registerLazySingleton(() => AddZakatPaymentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteZakatPaymentUseCase(sl()));
  sl.registerLazySingleton(() => GetZakatTotalPaidUseCase(sl()));
  sl.registerLazySingleton<ZakatRepository>(() => ZakatRepositoryImpl());

  // ── Debts ──────────────────────────────────────────────
  sl.registerFactory(() => DebtBloc(
        getDebtsUseCase: sl(),
        addDebtUseCase: sl(),
        updateDebtUseCase: sl(),
        deleteDebtUseCase: sl(),
        getDebtByIdUseCase: sl(),
        getPaymentsUseCase: sl(),
        addPaymentUseCase: sl(),
        deletePaymentUseCase: sl(),
        getTotalOutstandingUseCase: sl(),
      ));
  sl.registerLazySingleton(() => GetDebtsUseCase(sl()));
  sl.registerLazySingleton(() => GetDebtByIdUseCase(sl()));
  sl.registerLazySingleton(() => AddDebtUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDebtUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDebtUseCase(sl()));
  sl.registerLazySingleton(() => GetDebtsByCustomerUseCase(sl()));
  sl.registerLazySingleton(() => GetDebtPaymentsUseCase(sl()));
  sl.registerLazySingleton(() => AddDebtPaymentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDebtPaymentUseCase(sl()));
  sl.registerLazySingleton(() => GetTotalOutstandingUseCase(sl()));
  sl.registerLazySingleton<DebtRepository>(() => DebtRepositoryImpl());

  // ── AI Assistant ──────────────────────────────────────────
  sl.registerLazySingleton(() => AiLocalDataSource());
  sl.registerLazySingleton(() => AiRemoteDataSource());
  sl.registerLazySingleton(() => AiRepositoryImpl(sl(), sl()));
  sl.registerFactory(() => AiBloc(sl()));
}
