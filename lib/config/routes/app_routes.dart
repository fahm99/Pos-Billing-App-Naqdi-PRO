import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/presentation/splash_page.dart';
import '../../core/presentation/main_shell.dart';
import '../../features/billing/presentation/pages/admin_home_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
import '../../features/billing/presentation/pages/scanner_screen.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/security_settings_page.dart';
import '../../features/settings/presentation/pages/backup_page.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/product/domain/entities/product.dart';
import '../../features/sales/presentation/pages/sales_history_page.dart';
import '../../features/sales/presentation/pages/invoice_detail_page.dart';
import '../../features/sales/domain/entities/invoice.dart';
import '../../features/suppliers/presentation/pages/suppliers_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/inventory/presentation/pages/stock_alerts_page.dart';
import '../../features/donation/presentation/pages/donation_page.dart';
import '../../features/billing/presentation/pages/print_options_page.dart';
import '../../features/billing/presentation/pages/admin_billing_page.dart';
import '../../features/setup/presentation/pages/setup_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/expenses/presentation/pages/expenses_page.dart';
import '../../features/zakat/presentation/pages/zakat_dashboard_page.dart';
import '../../features/debts/presentation/pages/debts_page.dart';
import '../../features/debts/presentation/pages/debt_detail_page.dart';
import '../../features/debts/presentation/pages/notifications_page.dart';
import '../../features/ai/presentation/pages/ai_chat_page.dart';
import '../../features/ai/presentation/pages/ai_settings_page.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const SetupPage(),
    ),
    // Scanner screen for cashier (no bottom nav)
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScannerScreen(),
    ),
    // Simple Barcode Scanner (returns result only)
    GoRoute(
      path: '/barcode-scanner',
      builder: (context, state) => const ScannerPage(),
    ),
    // Checkout (full screen)
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutPage(),
    ),
    // Admin Billing (after scan in admin mode)
    GoRoute(
      path: '/admin-billing',
      builder: (context, state) => const AdminBillingPage(),
    ),
    // Stock Alerts
    GoRoute(
      path: '/stock-alerts',
      builder: (context, state) => const StockAlertsPage(),
    ),
    // Security Settings
    GoRoute(
      path: '/security-settings',
      builder: (context, state) => const SecuritySettingsPage(),
    ),
    // Suppliers
    GoRoute(
      path: '/suppliers',
      builder: (context, state) => const SuppliersPage(),
    ),
    // Shop Details
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopDetailsPage(),
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
    // Backup Management
    GoRoute(
      path: '/backup',
      builder: (context, state) => const BackupPage(),
    ),
    // Customers Management
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomersPage(),
    ),
    // Expenses Management (Phase 2)
    GoRoute(
      path: '/expenses',
      builder: (context, state) => const ExpensesPage(),
    ),
    // Zakat Dashboard (Phase 3)
    GoRoute(
      path: '/zakat',
      builder: (context, state) => const ZakatDashboardPage(),
    ),
    // Debts Management (Phase 4)
    GoRoute(
      path: '/debts',
      builder: (context, state) => const DebtsPage(),
    ),
    GoRoute(
      path: '/debt-detail',
      builder: (context, state) {
        final debt = state.extra as dynamic;
        return DebtDetailPage(debt: debt);
      },
    ),
    // Unified Notifications Page (Phase 5)
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    // AI Assistant (Phase 7)
    GoRoute(
      path: '/ai-chat',
      builder: (context, state) => const AiChatPage(),
    ),
    GoRoute(
      path: '/ai-settings',
      builder: (context, state) => const AiSettingsPage(),
    ),
    // Main shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        // Admin Home
        GoRoute(
          path: '/admin-home',
          builder: (context, state) => const AdminHomePage(),
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
        // Inventory Tab
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryPage(),
        ),
        // Settings Tab
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);

/// صفحة مؤقتة تُستبدل في المراحل اللاحقة
class _PhasePlaceholderPage extends StatelessWidget {
  const _PhasePlaceholderPage({required this.title, required this.phase});
  final String title;
  final int phase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.handyman_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'سيتم تنفيذ هذه الميزة في المرحلة $phase',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
