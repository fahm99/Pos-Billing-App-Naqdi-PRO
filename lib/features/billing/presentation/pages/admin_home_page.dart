import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/services/scanner_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../sales/domain/entities/invoice.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';
import '../../domain/entities/cart_item.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  StreamSubscription<Object?>? _barcodeSubscription;
  bool _isCameraOn = true;
  bool _isFlashOn = false;
  bool _isDisposed = false;
  bool _isInitializing = false;
  final Map<String, DateTime> _lastScanTimes = {};
  String _currencySymbol = 'ر.س';
  bool _navigatingToCheckout = false;

  @override
  void initState() {
    super.initState();
    _navigatingToCheckout = false;
    WidgetsBinding.instance.addObserver(this);
    _loadCurrencySymbol();
    if (ScannerService.saleJustCompleted) {
      ScannerService.saleJustCompleted = false;
      _isCameraOn = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        if (_isCameraOn) {
          _initScanner();
        } else {
          setState(() {});
        }
      }
    });
  }

  void _loadCurrencySymbol() {
    final shopState = context.read<ShopBloc>().state;
    if (shopState is ShopLoaded && shopState.shop.currencySymbol.isNotEmpty) {
      setState(() => _currencySymbol = shopState.shop.currencySymbol);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _barcodeSubscription?.cancel();
    _barcodeSubscription = null;
    if (_scannerController != null) {
      ScannerService().disposeController(_scannerController!);
      _scannerController = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || _scannerController == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isCameraOn) {
          _barcodeSubscription?.cancel();
          _barcodeSubscription = _scannerController!.barcodes.listen(_onDetect);
          ScannerService().startController(_scannerController!);
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _barcodeSubscription?.cancel();
        _barcodeSubscription = null;
        ScannerService().stopController(_scannerController!);
    }
  }

  Future<void> _initScanner() async {
    if (_isDisposed || _isInitializing) return;
    _isInitializing = true;
    // انتظار قصير للتأكد من تحرير كاميرا الصفحة السابقة
    await Future.delayed(const Duration(milliseconds: 300));
    if (_isDisposed || !mounted) {
      _isInitializing = false;
      return;
    }
    _scannerController = ScannerService().createController();
    _barcodeSubscription = _scannerController!.barcodes.listen(_onDetect);
    await ScannerService().startController(_scannerController!);
    _isInitializing = false;
    if (mounted && !_isDisposed) setState(() {});
  }

  void _startScanner() {
    if (_isDisposed || _scannerController == null) return;
    _barcodeSubscription?.cancel();
    _barcodeSubscription = _scannerController!.barcodes.listen(_onDetect);
    ScannerService().startController(_scannerController!);
    if (mounted && !_isDisposed) setState(() {});
  }

  void _stopScanner() {
    _barcodeSubscription?.cancel();
    _barcodeSubscription = null;
    if (_scannerController != null) {
      ScannerService().stopController(_scannerController!);
    }
  }

  void _onDetect(Object? event) {
    if (!mounted || _isDisposed) return;
    if (event is! BarcodeCapture) return;
    final now = DateTime.now();
    for (final barcode in event.barcodes) {
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

  void _goToCheckout() {
    if (_navigatingToCheckout) return;
    _navigatingToCheckout = true;
    _stopScanner();
    context.push('/checkout').then((_) {
      _navigatingToCheckout = false;
      if (mounted &&
          !_isDisposed &&
          _isCameraOn &&
          _scannerController != null) {
        _startScanner();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BillingBloc, BillingState>(
          listenWhen: (previous, current) =>
              previous.error != current.error && current.error != null,
          listener: (context, state) {
            if (state.error != null) {
              NotificationHelper.show(context, state.error!);
            }
          },
        ),
        BlocListener<BillingBloc, BillingState>(
          listenWhen: (previous, current) =>
              previous.warning != current.warning && current.warning != null,
          listener: (context, state) {
            if (state.warning != null) {
              NotificationHelper.show(context, state.warning!);
            }
          },
        ),
        BlocListener<SalesBloc, SalesState>(
          listenWhen: (previous, current) =>
              current.status == SalesStatus.success &&
              previous.status != current.status,
          listener: (context, state) {
            context.read<ProductBloc>().add(LoadProducts());
            if (state.message != null) {
              NotificationHelper.show(context, state.message!);
            }
          },
        ),
        BlocListener<SalesBloc, SalesState>(
          listenWhen: (previous, current) =>
              current.status == SalesStatus.error &&
              previous.status != current.status,
          listener: (context, state) {
            NotificationHelper.show(
                context, state.message ?? 'حدث خطأ أثناء إتمام البيع');
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/ai-chat'),
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
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
                const SizedBox(height: 16),
                // مراجعة الطلب button - visible when cart has items
                _buildReviewOrderButton(),
                const SizedBox(height: 16),
                // Today Summary - single card
                _buildTodaySummary(),
                const SizedBox(height: 20),
                // الإدارة السريعة
                _buildQuickManagementSection(),
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

  Widget _buildReviewOrderButton() {
    return BlocBuilder<BillingBloc, BillingState>(
      builder: (context, state) {
        if (state.cartItems.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('السلة',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                      '${state.totalAmount.toStringAsFixed(2)} $_currencySymbol',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: state.cartItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _buildCartItemCard(state.cartItems[index]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _goToCheckout(),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: Text('مراجعة الطلب (${state.cartItems.length})',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F2F5)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.product.imageUrl != null &&
                      item.product.imageUrl!.isNotEmpty
                  ? Image.file(
                      File(item.product.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultImage(),
                    )
                  : _buildDefaultImage(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${item.product.price.toStringAsFixed(2)} $_currencySymbol',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          _buildQtyControl(item),
        ],
      ),
    );
  }

  Widget _buildQtyControl(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQtyBtn(Icons.remove_rounded, () {
            if (item.quantity > 1) {
              context
                  .read<BillingBloc>()
                  .add(UpdateQuantityEvent(item.product.id, item.quantity - 1));
            } else {
              context
                  .read<BillingBloc>()
                  .add(RemoveProductFromCartEvent(item.product.id));
            }
          }),
          SizedBox(
            width: 28,
            child: Text('${item.quantity}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          _buildQtyBtn(Icons.add_rounded, () {
            context
                .read<BillingBloc>()
                .add(UpdateQuantityEvent(item.product.id, item.quantity + 1));
          }, isAdd: true),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onPressed,
      {bool isAdd = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              size: 16,
              color: isAdd ? AppTheme.primaryColor : Colors.grey[600]),
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
            if (_isCameraOn && _scannerController != null)
              MobileScanner(
                key: const ValueKey('admin_scanner'),
                controller: _scannerController!,
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

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart_rounded,
                        color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ملخص اليوم',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1E)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _summaryItem('المبيعات', '$todayCount', Icons.receipt_long_rounded),
                  _summaryItem('الإيرادات', '$todayRevenue$_currencySymbol', Icons.payments_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _summaryItem('الأرباح', '$todayProfit$_currencySymbol', Icons.account_balance_wallet_rounded),
                  _summaryItem('المتوسط', '$todayAvg$_currencySymbol', Icons.bar_chart_rounded),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1E))),
                ),
              ],
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
        errorBuilder: (_, __, ___) => const Icon(
          Icons.inventory_2_outlined,
          color: AppTheme.primaryColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildQuickManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.grid_view_rounded,
                  color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'الإدارة',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1E)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: _managementItems.length,
          itemBuilder: (context, index) =>
              _buildGridItem(_managementItems[index]),
        ),
      ],
    );
  }

  List<_ManagementItem> get _managementItems => [
        _ManagementItem(
          icon: Icons.people_outline,
          title: 'العملاء',
          subtitle: 'إدارة العملاء',
          onTap: () => context.push('/customers'),
        ),
        _ManagementItem(
          icon: Icons.local_shipping_outlined,
          title: 'الموردون',
          subtitle: 'إدارة الموردين',
          onTap: () => context.push('/suppliers'),
        ),
        _ManagementItem(
          icon: Icons.storefront,
          title: 'بيانات المتجر',
          subtitle: 'تعديل معلومات النشاط',
          onTap: () => context.push('/shop'),
        ),
        _ManagementItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'إدارة الديون',
          subtitle: 'إدارة ديون العملاء',
          onTap: () => context.push('/debts'),
        ),
        _ManagementItem(
          icon: Icons.receipt_long_outlined,
          title: 'إدارة المصروفات',
          subtitle: 'تسجيل المصروفات',
          onTap: () => context.push('/expenses'),
        ),
        _ManagementItem(
          icon: Icons.volunteer_activism_outlined,
          title: 'الزكاة والدخل',
          subtitle: 'حساب الزكاة',
          onTap: () => context.push('/zakat'),
        ),
        _ManagementItem(
          icon: Icons.notifications_outlined,
          title: 'الإشعارات',
          subtitle: 'تنبيهات الديون',
          onTap: () => context.push('/notifications'),
        ),
        _ManagementItem(
          icon: Icons.auto_awesome,
          title: 'المساعد الذكي',
          subtitle: 'AI لتحليل البيانات',
          onTap: () => context.push('/ai-chat'),
        ),
      ];

  Widget _buildGridItem(_ManagementItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Text(
              item.subtitle,
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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

class _ManagementItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManagementItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
