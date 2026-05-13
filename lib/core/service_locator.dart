import 'package:get_it/get_it.dart';
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
import '../../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/inventory/presentation/bloc/inventory_bloc.dart';

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
      ));
  sl.registerLazySingleton(() => GetInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => SaveInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => DeleteInvoiceUseCase(sl()));
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

  // ── Inventory ─────────────────────────────────────────────
  sl.registerFactory(() => InventoryBloc(
        inventoryRepository: sl(),
        productRepository: sl(),
      ));
  sl.registerLazySingleton<InventoryRepository>(
      () => InventoryRepositoryImpl());
}
