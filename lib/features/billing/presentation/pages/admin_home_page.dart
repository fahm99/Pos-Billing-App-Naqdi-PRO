import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/domain/entities/product.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../sales/domain/entities/invoice.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  bool _isCameraOn = true;
  bool _isFlashOn = false;
  bool _isControllerReady = false;
  bool _isDisposed = false;
  final Map<String, DateTime> _lastScanTimes = {};
  String _currencySymbol = 'ر.س';
  bool _navigatingToCheckout = false;

  @override
  void initState() {
    super.initState();
    _navigatingToCheckout = false;
    WidgetsBinding.instance.addObserver(this);
    _loadCurrencySymbol();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initScannerController());
  }

  void _loadCurrencySymbol() {
    final shopState = context.read<ShopBloc>().state;
    if (shopState is ShopLoaded && shopState.shop.currencySymbol.isNotEmpty) {
      setState(() => _currencySymbol = shopState.shop.currencySymbol);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeScannerController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopScanner();
    } else if (state == AppLifecycleState.resumed && _isCameraOn) {
      _startScanner();
    }
  }

  Future<void> _initScannerController() async {
    if (_isDisposed) return;
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        returnImage: false,
      );
      await _scannerController!.start();
      if (mounted && !_isDisposed) setState(() => _isControllerReady = true);
    } catch (_) {
      if (mounted && !_isDisposed) setState(() => _isControllerReady = false);
    }
  }

  Future<void> _disposeScannerController() async {
    _isControllerReady = false;
    try {
      await _scannerController?.stop();
      await _scannerController?.dispose();
    } catch (_) {}
    _scannerController = null;
  }

  void _stopScanner() {
    try {
      _scannerController?.stop();
    } catch (_) {}
  }

  void _startScanner() async {
    if (_isDisposed) return;
    try {
      if (_scannerController == null) {
        await _initScannerController();
      } else {
        await _scannerController!.start();
      }
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isControllerReady || !mounted || _isDisposed) return;
    final now = DateTime.now();
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      if (_lastScanTimes.containsKey(raw) &&
          now.difference(_lastScanTimes[raw]!).inSeconds < 2) continue;
      _lastScanTimes[raw] = now;
      HapticFeedback.mediumImpact();
      if (mounted) {
        context.read<BillingBloc>().add(ScanBarcodeEvent(raw));
      }
      break;
    }
  }

  void _goToAdminBilling() {
    if (_navigatingToCheckout) return;
    _navigatingToCheckout = true;
    _stopScanner();
    context.push('/admin-billing').then((_) {
      _navigatingToCheckout = false;
      if (mounted && !_isDisposed && _isCameraOn) _startScanner();
    });
  }

  void _goToCheckout() {
    if (_navigatingToCheckout) return;
    _navigatingToCheckout = true;
    _stopScanner();
    context.push('/checkout').then((_) {
      _navigatingToCheckout = false;
      if (mounted && !_isDisposed && _isCameraOn) _startScanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BillingBloc, BillingState>(
          listenWhen: (previous, current) =>
              previous.cartItems.length < current.cartItems.length &&
              current.cartItems.length == 1,
          listener: (context, state) {
            if (mounted) _goToAdminBilling();
          },
        ),
        BlocListener<BillingBloc, BillingState>(
          listenWhen: (previous, current) =>
              previous.error != current.error && current.error != null,
          listener: (context, state) {
            if (state.error != null) {
              NotificationHelper.show(context, state.error!);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: RefreshIndicator(
          onRefresh: () async {
            if (mounted) {
              context.read<ProductBloc>().add(LoadProducts());
              context.read<SalesBloc>().add(LoadInvoicesEvent());
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scanner section
                _buildScannerSection(),
                const SizedBox(height: 20),
                // Today Summary - Horizontal row
                _buildTodaySummary(),
                const SizedBox(height: 20),
                // Stock Alerts Section
                _buildStockAlertsSection(),
                const SizedBox(height: 20),
                // Recent Invoices
                _buildRecentInvoices(),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 220,
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Stack(
          children: [
            if (_isCameraOn && _isControllerReady && _scannerController != null)
              MobileScanner(
                controller: _scannerController!,
                onDetect: _onDetect,
              )
            else if (!_isCameraOn)
              Container(
                color: const Color(0xFF1E293B),
                child: const Center(
                  child:
                      Icon(Icons.videocam_off, color: Colors.white, size: 48),
                ),
              )
            else
              Container(
                color: const Color(0xFF1E293B),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
              ),
            // Scan frame
            Center(
              child: Container(
                width: 160,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(children: [
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                ]),
              ),
            ),
            // Flash and camera toggle
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  _buildIconButton(
                    icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    onPressed: () {
                      setState(() => _isFlashOn = !_isFlashOn);
                      _scannerController?.toggleTorch();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                    onPressed: () {
                      setState(() => _isCameraOn = !_isCameraOn);
                      if (_isCameraOn) {
                        _startScanner();
                      } else {
                        _stopScanner();
                      }
                    },
                  ),
                ],
              ),
            ),
            // Go to checkout button when items in cart
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: BlocBuilder<BillingBloc, BillingState>(
                builder: (context, state) {
                  if (state.cartItems.isEmpty) return const SizedBox.shrink();
                  return ElevatedButton(
                    onPressed: () => _goToCheckout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'مراجعة الطلب (${state.cartItems.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight)
                ? const BorderSide(color: AppTheme.primaryColor, width: 3)
                : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight)
                ? const BorderSide(color: AppTheme.primaryColor, width: 3)
                : BorderSide.none,
            left: (alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft)
                ? const BorderSide(color: AppTheme.primaryColor, width: 3)
                : BorderSide.none,
            right: (alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight)
                ? const BorderSide(color: AppTheme.primaryColor, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildTodaySummary() {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        final today = DateTime.now();
        final todayInvoices = state.invoices
            .where((inv) =>
                inv.date.year == today.year &&
                inv.date.month == today.month &&
                inv.date.day == today.day)
            .toList();

        final todayRevenue =
            todayInvoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);
        final todayProfit =
            todayInvoices.fold(0.0, (sum, inv) => sum + inv.totalProfit);
        final todayCount = todayInvoices.length;
        final todayAvg = todayCount > 0 ? todayRevenue / todayCount : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص اليوم',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1E)),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatCard(
                      'المبيعات', '$todayCount', Icons.receipt_long_rounded),
                  const SizedBox(width: 10),
                  _buildStatCard('الإيرادات', '$todayRevenue$_currencySymbol',
                      Icons.trending_up_rounded),
                  const SizedBox(width: 10),
                  _buildStatCard('الأرباح', '$todayProfit$_currencySymbol',
                      Icons.account_balance_wallet_rounded),
                  const SizedBox(width: 10),
                  _buildStatCard('المتوسط', '$todayAvg$_currencySymbol',
                      Icons.bar_chart_rounded),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      width: 115,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// قسم تنبيهات المخزون
  Widget _buildStockAlertsSection() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        // تصفية المنتجات ذات المخزون المنخفض أو القريبة من انتهاء الصلاحية
        final lowStockProducts = state.products
            .where((p) =>
                p.isAtOrBelowReorderPoint ||
                (p.daysUntilExpiry != null && p.daysUntilExpiry! <= 30))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_outlined,
                          color: Colors.red, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'تنبيهات المخزون',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1E)),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/stock-alerts'),
                  child: Text(
                    'عرض الكل',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Products List
            if (lowStockProducts.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 40, color: Colors.green[300]),
                      const SizedBox(height: 8),
                      Text('لا توجد تنبيهات',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: lowStockProducts.length > 10
                      ? 10
                      : lowStockProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final product = lowStockProducts[index];
                    return _buildStockAlertCard(product);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStockAlertCard(Product product) {
    final daysUntilExpiry = product.daysUntilExpiry;
    final isExpiringSoon = daysUntilExpiry != null && daysUntilExpiry <= 30;

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpiringSoon
              ? Colors.red.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20), // Space for badge
                // Product Image
                Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(product.imageUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildDefaultImage(),
                                ),
                              )
                            : _buildDefaultImage(),
                  ),
                ),
                const SizedBox(height: 8),
                // Product Name
                Text(
                  product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Stock
                Text(
                  '${product.stock} ${product.unit}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                // Expiry
                if (daysUntilExpiry != null)
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 12,
                        color: isExpiringSoon ? Colors.red : Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$daysUntilExpiry يوم',
                        style: TextStyle(
                            fontSize: 10,
                            color:
                                isExpiringSoon ? Colors.red : Colors.grey[500]),
                      ),
                    ],
                  )
                else
                  Text(
                    'لا يوجد',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
              ],
            ),
          ),
          // Stock Badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${product.stock}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Center(
      child: Image.asset(
        'assets/naqdilogo.jpg',
        width: 36,
        height: 36,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.inventory_2_outlined,
          color: AppTheme.primaryColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildRecentInvoices() {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        final recentInvoices = state.invoices.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'آخر الفواتير',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1E)),
                ),
                GestureDetector(
                  onTap: () => context.push('/sales'),
                  child: const Text(
                    'عرض الكل',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recentInvoices.map((inv) => _buildInvoiceCard(inv)),
            if (recentInvoices.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 40, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text('لا توجد فواتير بعد',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final dateStr =
        '${invoice.date.year}/${invoice.date.month.toString().padLeft(2, '0')}/${invoice.date.day.toString().padLeft(2, '0')} ${invoice.date.hour.toString().padLeft(2, '0')}:${invoice.date.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_rounded,
              color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(invoice.invoiceNumber,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(dateStr,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        trailing: Text(
          '$_currencySymbol${invoice.totalAmount.toStringAsFixed(0)}',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1A1C1E)),
        ),
        onTap: () => context.push('/sales/${invoice.id}', extra: invoice),
      ),
    );
  }
}
