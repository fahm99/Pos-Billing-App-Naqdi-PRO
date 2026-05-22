import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppNotification extends StatefulWidget {
  final Widget child;

  const AppNotification({super.key, required this.child});

  static AppNotificationState? of(BuildContext context) {
    return context.findAncestorStateOfType<AppNotificationState>();
  }

  @override
  State<AppNotification> createState() => AppNotificationState();
}

class AppNotificationState extends State<AppNotification>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlay;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void showNotification(String message) {
    _overlay?.remove();
    _overlay = OverlayEntry(
      builder: (ctx) => _NotificationCard(
        message: message,
        slideAnim: _slideAnim,
        fadeAnim: _fadeAnim,
        onDismiss: _dismiss,
      ),
    );
    Overlay.of(context).insert(_overlay!);
    _animController.forward();
    Future.delayed(const Duration(seconds: 2), _dismiss);
  }

  void _dismiss() {
    _animController.reverse().then((_) {
      _overlay?.remove();
      _overlay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _NotificationCard extends StatelessWidget {
  final String message;
  final Animation<Offset> slideAnim;
  final Animation<double> fadeAnim;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.message,
    required this.slideAnim,
    required this.fadeAnim,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SlideTransition(
        position: slideAnim,
        child: FadeTransition(
          opacity: fadeAnim,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: (_) => onDismiss(),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
