import 'package:go_router/go_router.dart';
import '../../core/presentation/splash_page.dart';
import '../../core/presentation/main_shell.dart';
import '../../features/billing/presentation/pages/scanner_tab_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/product/domain/entities/product.dart';
import '../../features/sales/presentation/pages/sales_history_page.dart';
import '../../features/sales/presentation/pages/invoice_detail_page.dart';
import '../../features/sales/domain/entities/invoice.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/suppliers/presentation/pages/suppliers_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/donation/presentation/pages/donation_page.dart';
import '../../features/billing/presentation/pages/print_options_page.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    // Main shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        // Scanner Tab
        GoRoute(
          path: '/scan',
          builder: (context, state) => const ScannerTabPage(),
        ),
        // Products Tab
        GoRoute(
          path: '/products-nav',
          builder: (context, state) => const ProductListPage(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddProductPage(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) {
                final product = state.extra as Product?;
                if (product == null) return const ProductListPage();
                return EditProductPage(product: product);
              },
            ),
          ],
        ),
        // Sales Tab
        GoRoute(
          path: '/sales',
          builder: (context, state) => const SalesHistoryPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final invoice = state.extra as Invoice;
                return InvoiceDetailPage(invoice: invoice);
              },
            ),
          ],
        ),
        // Customers Tab
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomersPage(),
        ),
        // Settings Tab
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
    // Simple Barcode Scanner (returns result only)
    GoRoute(
      path: '/barcode-scanner',
      builder: (context, state) => const ScannerPage(),
    ),
    // Checkout (outside shell - full screen)
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutPage(),
    ),
    // Inventory (accessible from settings/products)
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryPage(),
    ),
    // Suppliers (accessible from settings)
    GoRoute(
      path: '/suppliers',
      builder: (context, state) => const SuppliersPage(),
    ),
    // Shop Details (accessible from settings)
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopDetailsPage(),
    ),
    // Products without nav (for direct access from other screens)
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductListPage(),
    ),
    // Donation Page
    GoRoute(
      path: '/donation',
      builder: (context, state) => const DonationPage(),
    ),
    // Print Options Page
    GoRoute(
      path: '/print-options',
      builder: (context, state) => const PrintOptionsPage(),
    ),
  ],
);
