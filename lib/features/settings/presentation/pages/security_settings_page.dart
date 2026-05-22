import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/notification_helper.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;
  late TextEditingController _currentPasswordCtrl;
  late TextEditingController _newPasswordCtrl;
  late TextEditingController _confirmPasswordCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: AppSettings.adminUsername ?? '');
    _currentPasswordCtrl = TextEditingController();
    _newPasswordCtrl = TextEditingController();
    _confirmPasswordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final currentPassword = _currentPasswordCtrl.text;

      if (AppSettings.hasAdminPassword) {
        if (!AppSettings.verifyAdminPassword(currentPassword)) {
          NotificationHelper.show(context, 'كلمة السر الحالية غير صحيحة');
          setState(() => _isSaving = false);
          return;
        }
      }

      await AppSettings.setAdminUsername(_usernameCtrl.text.trim());
      await AppSettings.setAdminPassword(_newPasswordCtrl.text);
      await AppSettings.setLastMode(true);

      if (mounted) {
        NotificationHelper.show(context, 'تم تحديث بيانات الأمان بنجاح');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.show(context, 'حدث خطأ: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('إعدادات الأمان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تغيير اسم المستخدم وكلمة السر',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'سيتم استخدام بيانات الدخول هذه للوصول إلى وضع الأدمن',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),

              Text('اسم المستخدم', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 6),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  hintText: 'أدخل اسم المستخدم',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              Text('كلمة السر الحالية', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 6),
              TextFormField(
                controller: _currentPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'أدخل كلمة السر الحالية',
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'مطلوبة' : null,
              ),
              const SizedBox(height: 16),

              Text('كلمة السر الجديدة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 6),
              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'أدخل كلمة سر جديدة',
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                ),
                validator: (v) => (v == null || v.length < 4) ? '4 أحرف على الأقل' : null,
              ),
              const SizedBox(height: 16),

              Text('تأكيد كلمة السر', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'أعد إدخال كلمة السر',
                  prefixIcon: Icon(Icons.lock_outline, size: 20),
                ),
                validator: (v) => (v != _newPasswordCtrl.text) ? 'غير متطابقة' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('حفظ التغييرات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
