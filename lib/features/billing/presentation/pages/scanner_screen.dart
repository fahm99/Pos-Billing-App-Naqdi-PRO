import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../bloc/billing_bloc.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../domain/entities/cart_item.dart';

/// ScannerScreen - شاشة المسح بملء الشاشة
/// التعديل: إصلاح تهنيج الماسح بعد حفظ الفاتورة
/// - تحسين dispose و initState لمنع Memory Leak و Camera Freeze
/// - إعادة تهيئة الماسح عند العودة من شاشة أخرى
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _fullscreenController;
  bool _isFullscreenScannerActive = false;
  bool _isFlashOn = false;
  bool _isControllerReady = false;
  final Map<String, DateTime> _lastScanTimes = {};
  static const Duration _scanCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeFullscreenController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopFullscreenScanner();
    } else if (state == AppLifecycleState.resumed && _isFullscreenScannerActive) {
      // إعادة تشغيل الماسح عند العودة للتطبيق
      _initFullscreenController();
    }
  }

  /// التخلص من وحدة التحكم بشكل آمن لمنع Camera Lock و Memory Leak
  Future<void> _disposeFullscreenController() async {
    try {
      await _fullscreenController?.stop();
      await _fullscreenController?.dispose();
    } catch (_) {}
    _fullscreenController = null;
    _isControllerReady = false;
  }

  /// تهيئة وحدة التحكم بشكل آمن
  Future<void> _initFullscreenController() async {
    await _disposeFullscreenController();
    if (!mounted) return;
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
    try {
      await controller.start();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _fullscreenController = controller;
        _isControllerReady = true;
      });
    } catch (_) {
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _fullscreenController = controller;
        _isControllerReady = false;
      });
    }
  }

  void _stopFullscreenScanner() {
    try {
      _fullscreenController?.stop();
    } catch (_) {}
    if (mounted) {
      setState(() => _isFullscreenScannerActive = false);
    }
  }

  void _openFullscreenScanner() async {
    await _initFullscreenController();
    if (mounted) {
      setState(() => _isFullscreenScannerActive = true);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isControllerReady || !mounted) return;
    final now = DateTime.now();
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      if (_lastScanTimes.containsKey(raw) &&
          now.difference(_lastScanTimes[raw]!) < _scanCooldown) continue;
      _lastScanTimes[raw] = now;
      HapticFeedback.mediumImpact();
      if (mounted) {
        context.read<BillingBloc>().add(ScanBarcodeEvent(raw));
      }
      _stopFullscreenScanner();
      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return MultiBlocListener(
      listeners: [
        BlocListener<BillingBloc, BillingState>(
          listenWhen: (previous, current) =>
              previous.error != current.error && current.error != null,
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
        ),
        // تحديث لحظي للمخزون بعد البيع
        BlocListener<SalesBloc, SalesState>(
          listenWhen: (previous, current) =>
              current.status == SalesStatus.success &&
              previous.status != current.status,
          listener: (context, state) {
            context.read<ProductBloc>().add(LoadProducts());
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        appBar: const CustomAppBar(showDonationButton: true),
        body: Stack(
          children: [
            // المحتوى الرئيسي
            BlocBuilder<BillingBloc, BillingState>(
              builder: (context, state) {
                if (state.cartItems.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildCartState(state, bottomPadding);
              },
            ),

            // الماسح بملء الشاشة
            if (_isFullscreenScannerActive)
              _buildFullscreenScanner(),
          ],
        ),
      ),
    );
  }

  // ==================== الحالة: السلة فارغة ====================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'السلة فارغة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'امسح الباركود لإضافة منتجات',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton(
              onPressed: _openFullscreenScanner,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'اضغط للمسح',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== الحالة: السلة تحتوي على منتجات ====================
  Widget _buildCartState(BillingState state, double bottomPadding) {
    return Column(
      children: [
        // قائمة المنتجات في السلة
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.cartItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _buildCartItemCard(state.cartItems[index]),
          ),
        ),

        // حاوية الإجمالي الثابتة أسفل الشاشة
        _buildCartSummary(state, bottomPadding),
      ],
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
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // صورة مصغرة
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF16A34A), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${item.product.price.toStringAsFixed(2)} ر.س',
                  style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          // عداد الكمية (+/-)
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
                    context.read<BillingBloc>().add(
                        UpdateQuantityEvent(item.product.id, item.quantity - 1));
                  } else {
                    context.read<BillingBloc>().add(
                        RemoveProductFromCartEvent(item.product.id));
                  }
                }),
                SizedBox(
                  width: 32,
                  child: Text('${item.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed, {bool isAdd = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18,
              color: isAdd ? const Color(0xFF16A34A) : Colors.grey[600]),
        ),
      ),
    );
  }

  // ==================== ملخص السلة السفلي ====================
  Widget _buildCartSummary(BillingState state, double bottomPadding) {
    // حساب الضريبة والخصم والمجموع
    final subtotal = state.totalAmount;
    const taxPercent = 0.0;
    const discountAmount = 0.0;
    final taxAmount = subtotal * (taxPercent / 100);
    final total = subtotal - discountAmount + taxAmount;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black, blurRadius: 16, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // تفاصيل المجموع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المجموع الفرعي', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text('${subtotal.toStringAsFixed(2)} ر.س',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          if (taxAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الضريبة', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                Text('${taxAmount.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ],
          if (discountAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الخصم', style: TextStyle(fontSize: 13, color: Colors.red[400])),
                Text('-${discountAmount.toStringAsFixed(2)} ر.س',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.red[400])),
              ],
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المجموع الكلي',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
              Text('${total.toStringAsFixed(2)} ر.س',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
            ],
          ),
          const SizedBox(height: 12),
          // زر مراجعة الطلب
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.push('/checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('مراجعة الطلب',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== الماسح بملء الشاشة ====================
  Widget _buildFullscreenScanner() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // الكاميرا
          if (_isControllerReady && _fullscreenController != null)
            MobileScanner(
              controller: _fullscreenController!,
              onDetect: _onDetect,
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),

          // إطار المسح
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // نص التعليمات (يظهر لمدة 3 ثواني)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: _ScannerInstructions(),
          ),

          // أزرار التحكم
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: _stopFullscreenScanner,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: Column(
              children: [
                _buildScannerControlButton(
                  icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  onPressed: () {
                    setState(() => _isFlashOn = !_isFlashOn);
                    _fullscreenController?.toggleTorch();
                  },
                ),
                const SizedBox(height: 16),
                _buildScannerControlButton(
                  icon: Icons.videocam_off_rounded,
                  onPressed: _stopFullscreenScanner,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
      ),
    );
  }
}

/// النص الإرشادي الذي يظهر في الماسح لمدة 3 ثواني
class _ScannerInstructions extends StatefulWidget {
  @override
  State<_ScannerInstructions> createState() => _ScannerInstructionsState();
}

class _ScannerInstructionsState extends State<_ScannerInstructions>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(_animController);
    _animController.forward();
    // إخفاء النص بعد 3 ثواني
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _animController.reverse();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 60),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'وجه الكاميرا نحو الباركود',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}