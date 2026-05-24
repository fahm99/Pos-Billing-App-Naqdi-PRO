import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = [
    const _NavItem(
        icon: Icons.home_rounded, label: 'الرئيسية', path: '/admin-home'),
    const _NavItem(
        icon: Icons.inventory_2_outlined,
        label: 'المنتجات',
        path: '/products-nav'),
    const _NavItem(icon: Icons.receipt_long, label: 'المبيعات', path: '/sales'),
    const _NavItem(
        icon: Icons.inventory_outlined, label: 'المخزون', path: '/inventory'),
    const _NavItem(icon: Icons.more_horiz, label: 'المزيد', path: '/settings'),
  ];

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final showAppBar = currentPath == '/admin-home' || currentPath == '/scan';

    return Scaffold(
      appBar: showAppBar
          ? const CustomAppBar(showModeSwitch: true, showDonation: true)
          : null,
      body: Column(
        children: [
          Expanded(child: widget.child),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_navItems.length, (index) {
                    final item = _navItems[index];
                    final isSelected = _currentIndex == index;
                    return _buildNavItem(
                      icon: item.icon,
                      label: item.label,
                      isSelected: isSelected,
                      onTap: () => _onTap(index),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}
