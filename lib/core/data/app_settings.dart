import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

/// إعدادات التطبيق - Application Settings
/// تخزين بيانات الإعداد الأولي وكلمة سر الأدمن والإعدادات العامة
class AppSettings {
  // ========== Keys ==========
  static const String _isFirstRunKey = 'is_first_run';
  static const String _adminPasswordHashKey = 'admin_password_hash';
  static const String _lastModeKey = 'last_mode'; // 'admin' or 'cashier'
  static const String _defaultOpenModeKey =
      'default_open_mode'; // 'admin' or 'cashier'
  static const String _autoLockEnabledKey = 'auto_lock_enabled';
  static const String _autoLockMinutesKey = 'auto_lock_minutes';
  static const String _shopSetupCompleteKey = 'shop_setup_complete';

  // ========== Box Reference ==========
  static Box get _settingsBox => Hive.box('settings');

  // ========== First Run Check ==========

  /// التحقق من أول تشغيل - Check if first run
  static bool get isFirstRun {
    return _settingsBox.get(_isFirstRunKey, defaultValue: true) as bool;
  }

  /// تعيين أن الإعداد الأولي تم - Mark setup as complete
  static Future<void> markSetupComplete() async {
    await _settingsBox.put(_isFirstRunKey, false);
    await _settingsBox.put(_shopSetupCompleteKey, true);
  }

  /// التحقق من اكتمال إعداد المتجر - Check if shop setup is complete
  static bool get isShopSetupComplete {
    return _settingsBox.get(_shopSetupCompleteKey, defaultValue: false) as bool;
  }

  // ========== Admin Password ==========

  /// تعيين كلمة سر الأدمن - Set admin password
  static Future<void> setAdminPassword(String password) async {
    final hash = _hashPassword(password);
    await _settingsBox.put(_adminPasswordHashKey, hash);
  }

  /// التحقق من كلمة سر الأدمن - Verify admin password
  static bool verifyAdminPassword(String password) {
    final storedHash = _settingsBox.get(_adminPasswordHashKey) as String?;
    if (storedHash == null) return false;
    return _hashPassword(password) == storedHash;
  }

  /// التحقق من وجود كلمة سر محفوظة - Check if password is set
  static bool get hasAdminPassword {
    return _settingsBox.containsKey(_adminPasswordHashKey);
  }

  /// تشفير كلمة المرور - Hash password using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ========== Last Mode ==========

  /// حفظ آخر وضع - Save last mode
  static Future<void> setLastMode(bool isAdmin) async {
    await _settingsBox.put(_lastModeKey, isAdmin ? 'admin' : 'cashier');
  }

  /// الحصول على آخر وضع - Get last mode
  /// يعيد true إذا كان آخر وضع أدمن، false إذا كان كاشير
  static bool getLastMode() {
    final mode =
        _settingsBox.get(_lastModeKey, defaultValue: 'cashier') as String;
    return mode == 'admin';
  }

  // ========== Default Open Mode ==========

  /// تعيين وضع الفتح الافتراضي - Set default open mode
  static Future<void> setDefaultOpenMode(bool isAdmin) async {
    await _settingsBox.put(_defaultOpenModeKey, isAdmin ? 'admin' : 'cashier');
  }

  /// الحصول على وضع الفتح الافتراضي - Get default open mode
  static bool getDefaultOpenMode() {
    final mode = _settingsBox.get(_defaultOpenModeKey, defaultValue: 'cashier')
        as String;
    return mode == 'admin';
  }

  // ========== Auto Lock ==========

  /// تفعيل/إلغاء تفعيل القفل التلقائي - Enable/disable auto lock
  static Future<void> setAutoLockEnabled(bool enabled) async {
    await _settingsBox.put(_autoLockEnabledKey, enabled);
  }

  /// الحصول على حالة القفل التلقائي - Get auto lock status
  static bool get isAutoLockEnabled {
    return _settingsBox.get(_autoLockEnabledKey, defaultValue: false) as bool;
  }

  /// تعيين دقائق القفل التلقائي - Set auto lock minutes
  static Future<void> setAutoLockMinutes(int minutes) async {
    await _settingsBox.put(_autoLockMinutesKey, minutes);
  }

  /// الحصول على دقائق القفل التلقائي - Get auto lock minutes
  static int get autoLockMinutes {
    return _settingsBox.get(_autoLockMinutesKey, defaultValue: 5) as int;
  }

  // ========== Admin Credentials ==========

  /// حفظ اسم مستخدم الأدمن - Save admin username
  static Future<void> setAdminUsername(String username) async {
    await _settingsBox.put('admin_username', username);
  }

  /// الحصول على اسم مستخدم الأدمن - Get admin username
  static String? get adminUsername {
    return _settingsBox.get('admin_username') as String?;
  }

  // ========== Backup Settings ==========

  /// حفظ مسار مجلد النسخ الاحتياطي - Save backup folder path
  static Future<void> setBackupPath(String path) async {
    await _settingsBox.put('backup_path', path);
  }

  /// الحصول على مسار مجلد النسخ الاحتياطي - Get backup folder path
  static String? get backupPath {
    return _settingsBox.get('backup_path') as String?;
  }

  /// حفظ تردد النسخ الاحتياطي - Save backup frequency
  static Future<void> setBackupFrequency(String frequency) async {
    await _settingsBox.put('backup_frequency', frequency);
  }

  /// الحصول على تردد النسخ الاحتياطي - Get backup frequency
  static String getBackupFrequency() {
    return _settingsBox.get('backup_frequency', defaultValue: 'none') as String;
  }

  // ========== Reset ==========

  /// إعادة تعيين جميع الإعدادات - Reset all settings
  static Future<void> resetAll() async {
    await _settingsBox.clear();
  }
}
