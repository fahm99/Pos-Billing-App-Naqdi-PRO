import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../billing/presentation/bloc/billing_bloc.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/cart_item.dart';

class ScannerTabPage extends StatefulWidget {
  const ScannerTabPage({super.key});

  @override
  State<ScannerTabPage> createState() => _ScannerTabPageState();
}

class _ScannerTabPageState extends State<ScannerTabPage>
    with SingleTickerProviderStateMixin {
  // ==================== Controllers & State ====================
  late final MobileScannerController _scannerController;
  bool _isCameraOn = true;
  bool _isFlashOn = false;
  final Map<String, DateTime> _lastScanTimes = {};

  // ==================== Constants ====================
  static const double _scannerAspectRatio = 0.85;
  static const double _scanFrameSize = 240.0; // Adjusted for better visibility
  static const double _overlayButtonSize = 52.0;
  static const Duration _scanCooldown = Duration(seconds: 2);

  // ==================== Lifecycle ====================
  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // ==================== Barcode Detection ====================
  void _onDetect(BarcodeCapture capture) {
    final now = DateTime.now();

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      if (_lastScanTimes.containsKey(raw) &&
          now.difference(_lastScanTimes[raw]!) < _scanCooldown) {
        continue;
      }

      _lastScanTimes[raw] = now;
      HapticFeedback.mediumImpact();

      if (mounted) {
        context.read<BillingBloc>().add(ScanBarcodeEvent(raw));
      }
      break;
    }
  }

  // ==================== Build ====================
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF), // Surface color from DS
      appBar: const CustomAppBar(showDonationButton: true),
      body: BlocListener<BillingBloc, BillingState>(
        listenWhen: (previous, current) =>
            previous.error != current.error && current.error != null,
        listener: _showErrorSnackBar,
        child: Column(
          children: [
            // Scanner Section
            _buildScannerSection(screenWidth),

            // Cart Panel
            Expanded(child: _buildCartPanel()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(bottomPadding),
    );
  }

  void _showErrorSnackBar(BuildContext context, BillingState state) {
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ==================== Scanner Section ====================
  Widget _buildScannerSection(double screenWidth) {
    final scannerHeight = screenWidth * _scannerAspectRatio;

    return SizedBox(
      height: scannerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Custom Viewfinder Overlay
          if (_isCameraOn) _buildScannerOverlay(),

          if (!_isCameraOn) _buildCameraOffState(),

          // Control Buttons - Top Right
          Positioned(
            top: 20,
            right: 20,
            child: _buildControlButtons(),
          ),

          // Center Scan Line (Animated effect)
          if (_isCameraOn)
            Center(
              child: Container(
                width: _scanFrameSize - 40,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF00B386).withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // Instructions Floating Label
          if (_isCameraOn)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(child: _buildInstructions()),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        // Darkened background with hole
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.7),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: _scanFrameSize,
                  height: _scanFrameSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        BorderRadius.circular(32), // Rounded corners from DS
                  ),
                ),
              ),
            ],
          ),
        ),
        // Frame Corners
        Center(
          child: CustomPaint(
            size: const Size(_scanFrameSize, _scanFrameSize),
            painter: ViewfinderPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraOffState() {
    return Container(
      color: const Color(0xFF121212),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded,
                color: Colors.white.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            Text(
              'الكاميرا متوقفة',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        if (_isCameraOn) ...[
          _buildOverlayButton(
            icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            onPressed: _toggleFlash,
            isActive: _isFlashOn,
          ),
          const SizedBox(height: 16),
        ],
        _buildOverlayButton(
          icon:
              _isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
          onPressed: _toggleCamera,
          isActive: !_isCameraOn,
        ),
      ],
    );
  }

  Widget _buildOverlayButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      width: _overlayButtonSize,
      height: _overlayButtonSize,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
    _scannerController.toggleTorch();
  }

  void _toggleCamera() {
    setState(() => _isCameraOn = !_isCameraOn);
    if (_isCameraOn) {
      _scannerController.start();
    } else {
      _scannerController.stop();
    }
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Text(
            'وجّه الكاميرا نحو الباركود',
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ==================== Cart Panel ====================
  Widget _buildCartPanel() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
        ],
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          Expanded(
            child: BlocBuilder<BillingBloc, BillingState>(
              builder: (context, state) {
                if (state.cartItems.isEmpty) return _buildEmptyState();
                return _buildCartList(state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F2F5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_outlined,
                size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          const Text(
            'السلة فارغة',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1C1E)),
          ),
          const SizedBox(height: 8),
          Text(
            'امسح المنتجات لإضافتها للسلة',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(BillingState state) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: state.cartItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) =>
          _buildCartItemCard(state.cartItems[index]),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F2F5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.product.price}ر',
                  style: const TextStyle(
                      color: Color(0xFF00B386), fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          _buildQuantityControls(item),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => _updateQuantity(item, false),
          ),
          Text('${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add, size: 18, color: Color(0xFF00B386)),
            onPressed: () => _updateQuantity(item, true),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(CartItem item, bool increment) {
    final newQty = increment ? item.quantity + 1 : item.quantity - 1;
    if (newQty > 0) {
      context
          .read<BillingBloc>()
          .add(UpdateQuantityEvent(item.product.id, newQty));
    } else {
      context
          .read<BillingBloc>()
          .add(RemoveProductFromCartEvent(item.product.id));
    }
  }

  // ==================== Bottom Bar ====================
  Widget _buildBottomBar(double bottomPadding) {
    return BlocBuilder<BillingBloc, BillingState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0F2F5))),
          ),
          child: PrimaryButton(
            onPressed: state.cartItems.isNotEmpty
                ? () => _navigateToCheckout(context)
                : null,
            label: 'مراجعة الطلب',
            icon: Icons.receipt_long_rounded,
            borderRadius: 16,
          ),
        );
      },
    );
  }

  Future<void> _navigateToCheckout(BuildContext context) async {
    _scannerController.stop();
    await context.push('/checkout');
    if (_isCameraOn && mounted) _scannerController.start();
  }
}

class ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerSize = 40.0;
    const radius = 24.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerSize)
        ..lineTo(0, radius)
        ..arcToPoint(const Offset(radius, 0),
            radius: const Radius.circular(radius))
        ..lineTo(cornerSize, 0),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerSize, 0)
        ..lineTo(size.width - radius, 0)
        ..arcToPoint(Offset(size.width, radius),
            radius: const Radius.circular(radius))
        ..lineTo(size.width, cornerSize),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerSize)
        ..lineTo(0, size.height - radius)
        ..arcToPoint(Offset(radius, size.height),
            radius: const Radius.circular(radius))
        ..lineTo(cornerSize, size.height),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerSize, size.height)
        ..lineTo(size.width - radius, size.height)
        ..arcToPoint(Offset(size.width, size.height - radius),
            radius: const Radius.circular(radius))
        ..lineTo(size.width, size.height - cornerSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
