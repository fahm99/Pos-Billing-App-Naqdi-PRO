import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/app_settings.dart';
import '../../features/auth/presentation/widgets/admin_login_dialog.dart';

/// SplashPage - صفحة البداية
/// - أول تشغيل → شاشة الإعداد
/// - آخر وضع أدمن → شاشة الأدمن الرئيسية
/// - آخر وضع كاشير → شاشة المسح للكاشير
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (AppSettings.isFirstRun || !AppSettings.hasAdminPassword) {
      context.go('/setup');
      return;
    }

    // استعادة آخر وضع محفوظ
    final lastModeWasAdmin = AppSettings.getLastMode();

    if (lastModeWasAdmin) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AdminLoginDialog(),
      );

      if (!mounted) return;

      if (result == true) {
        context.go('/admin-home');
      } else {
        // فشل تسجيل الدخول → كاشير
        context.go('/scan');
      }
    } else {
      context.go('/scan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/naqdilogo.jpg',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'نقدي',
              style: GoogleFonts.cairo(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00A77E),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'نظام نقاط البيع المتكامل',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Color(0xFF00A77E),
            ),
          ],
        ),
      ),
    );
  }
}
