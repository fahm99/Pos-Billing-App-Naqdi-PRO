import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/app_settings.dart';

/// SettingsPage - صفحة الإعدادات
/// التعديل: إضافة وضع الفتح الافتراضي وزر النسخ الاحتياطي وإدارة الديون والمصروفات والزكاة
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _defaultOpenAsAdmin = false;

  @override
  void initState() {
    super.initState();
    _defaultOpenAsAdmin = AppSettings.getDefaultOpenMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المزيد',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Hardware Section
            _buildSectionHeader('الأجهزة'),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.print,
                  title: 'جهاز الطباعة',
                  subtitleWidget: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange[200]!)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              'سيتم إضافة الميزة قريباً',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  trailingIcon: null,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // App Settings Section
            _buildSectionHeader('إعدادات التطبيق'),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.security_outlined,
                  title: 'إعدادات الأمان',
                  subtitle: 'تغيير اسم المستخدم وكلمة المرور',
                  onTap: () => context.push('/security-settings'),
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.backup_outlined,
                  title: 'النسخ الاحتياطي',
                  subtitle: 'إدارة النسخ الاحتياطي والاستعادة',
                  onTap: () => context.push('/backup'),
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.auto_awesome,
                  title: 'المساعد الذكي',
                  subtitle: 'الذكاء الاصطناعي لتحليل البيانات',
                  onTap: () => context.push('/ai-settings'),
                ),
                _buildDivider(),
                // وضع الفتح الافتراضي
                _buildListItem(
                  icon: Icons.open_in_full_outlined,
                  title: 'الفتح الافتراضي',
                  subtitleWidget: SwitchListTile(
                    title: Text(
                      _defaultOpenAsAdmin ? 'وضع الأدمن' : 'وضع الكاشير',
                      style: const TextStyle(fontSize: 13),
                    ),
                    value: _defaultOpenAsAdmin,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) async {
                      setState(() => _defaultOpenAsAdmin = value);
                      await AppSettings.setDefaultOpenMode(value);
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  trailingIcon: null,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // App Info
            _buildSectionHeader('عن التطبيق'),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.info_outline,
                  title: 'الإصدار',
                  subtitle: '1.0.01',
                  trailingIcon: null,
                ),
              ],
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildListGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[50], indent: 64);
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? trailingWidget,
    IconData? trailingIcon = Icons.chevron_left,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: 4),
                    subtitleWidget,
                  ]
                ],
              ),
            ),
            if (trailingWidget != null)
              trailingWidget
            else if (trailingIcon != null)
              Icon(trailingIcon, color: Colors.grey[300]),
          ],
        ),
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
