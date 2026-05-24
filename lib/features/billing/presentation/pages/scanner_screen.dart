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
import '../../../../core/widgets/custom_app_bar.dart';
import '../bloc/billing_bloc.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../domain/entities/cart_item.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  StreamSubscription<Object?>? _barcodeSubscription;
  bool _isCameraOn = true;
  bool _isFlashOn = false;
  bool _isDisposed = false;
  final Map<String, DateTime> _lastScanTimes = {};
  static const Duration _scanCooldown = Duration(seconds: 2);
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
    ScannerService().release('ScannerScreen');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isCameraOn) {
          _barcodeSubscription?.cancel();
          _barcodeSubscription = _scannerController?.barcodes.listen(_onDetect);
          ScannerService().start();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _barcodeSubscription?.cancel();
        _barcodeSubscription = null;
        ScannerService().stop();
    }
  }

  void _initScanner() {
    if (_isDisposed) return;
    _scannerController = ScannerService().controller('ScannerScreen');
    _barcodeSubscription = _scannerController!.barcodes.listen(_onDetect);
    ScannerService().start();
    if (mounted && !_isDisposed) setState(() {});
  }

  void _startScanner() {
    if (_isDisposed) return;
    if (_scannerController == null) {
      _initScanner();
      return;
    }
    _barcodeSubscription?.cancel();
    _barcodeSubscription = _scannerController!.barcodes.listen(_onDetect);
    ScannerService().start();
    if (mounted && !_isDisposed) setState(() {});
  }

  void _stopScanner() {
    _barcodeSubscription?.cancel();
    _barcodeSubscription = null;
    ScannerService().stop();
  }

  void _onDetect(Object? event) {
    if (!mounted || _isDisposed) return;
    if (event is! BarcodeCapture) return;
    final now = DateTime.now();
    for (final barcode in event.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      if (_lastScanTimes.containsKey(raw) &&
          now.difference(_lastScanTimes[raw]!) < _scanCooldown) continue;
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
      if (mounted && !_isDisposed && _isCameraOn) _startScanner();
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
            NotificationHelper.show(context,
                state.message ?? 'حدث خطأ أثناء إتمام البيع');
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        appBar: const CustomAppBar(showModeSwitch: true, showDonation: true),
        body: Stack(
          children: [
            // TOP: Scanner Section
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.38,
              child: _buildScannerSection(),
            ),
            // BOTTOM: Cart Panel
            Positioned(
              top: (MediaQuery.of(context).size.height * 0.38) - 24,
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildCartPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerSection() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera View
          if (_isCameraOn && _scannerController != null)
            MobileScanner(
              key: const ValueKey('scanner'),
              controller: _scannerController!,
              errorBuilder: (context, error, child) {
                return Container(
                  color: const Color(0xFF1E293B),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Colors.white70, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'تعذر تشغيل الكاميرا',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else if (!_isCameraOn)
            Container(
              color: const Color(0xFF1E293B),
              child: const Center(
                child: Icon(Icons.videocam_off, color: Colors.white, size: 48),
              ),
            )
          else
            Container(
              color: const Color(0xFF1E293B),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
            ),
          // Scan Frame
          if (_isCameraOn)
            Center(
              child: Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(children: [
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                ]),
              ),
            ),
          // Control Buttons
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _buildControlButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  onPressed: () {
                    setState(() => _isFlashOn = !_isFlashOn);
                    _scannerController?.toggleTorch();
                  },
                ),
                const SizedBox(width: 8),
                _buildControlButton(
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

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
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

  Widget _buildCartPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with total
          BlocBuilder<BillingBloc, BillingState>(
            builder: (context, state) {
              final totalItems =
                  state.cartItems.fold<int>(0, (sum, i) => sum + i.quantity);
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('السلة',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('$totalItems منتج',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('الإجمالي',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500])),
                        Text(
                          '${state.totalAmount.toStringAsFixed(2)} $_currencySymbol',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          // Cart List
          Expanded(
            child: BlocBuilder<BillingBloc, BillingState>(
              builder: (context, state) {
                if (state.cartItems.isEmpty) {
                  return _buildEmptyCart();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildCartItemCard(state.cartItems[index]),
                );
              },
            ),
          ),
          // Checkout Button
          BlocBuilder<BillingBloc, BillingState>(
            builder: (context, state) {
              return _buildCheckoutButton(state);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_outlined,
                size: 40, color: AppTheme.primaryColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          const Text('السلة فارغة',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1A1C1E))),
          const SizedBox(height: 8),
          Text('امسح الباركود لإضافة منتجات',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F2F5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                  ? Image.file(
                      File(item.product.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultImage(),
                    )
                  : _buildDefaultImage(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  item.product.price.toStringAsFixed(2),
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQtyButton(Icons.remove_rounded, () {
                  if (item.quantity > 1) {
                    context.read<BillingBloc>().add(UpdateQuantityEvent(
                        item.product.id, item.quantity - 1));
                  } else {
                    context
                        .read<BillingBloc>()
                        .add(RemoveProductFromCartEvent(item.product.id));
                  }
                }),
                SizedBox(
                  width: 32,
                  child: Text('${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                _buildQtyButton(Icons.add_rounded, () {
                  context.read<BillingBloc>().add(
                      UpdateQuantityEvent(item.product.id, item.quantity + 1));
                }, isAdd: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed,
      {bool isAdd = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 18,
              color: isAdd ? AppTheme.primaryColor : Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Center(
      child: Image.asset(
        'assets/naqdilogo.jpg',
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.inventory_2_outlined,
          color: AppTheme.primaryColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(BillingState state) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, -3)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: state.cartItems.isEmpty
              ? null
              : () => _goToCheckout(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                state.cartItems.isEmpty
                    ? 'السلة فارغة'
                    : 'مراجعة الطلب (${state.cartItems.length})',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
