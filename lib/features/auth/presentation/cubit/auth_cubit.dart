import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/data/app_settings.dart';

/// حالات المصادقة - Auth States
abstract class AuthState {}

/// الحالة الأولية
class AuthInitial extends AuthState {}

/// جاري التحميل
class AuthLoading extends AuthState {}

/// وضع الكاشير (المستخدم العادي) - Cashier Mode
class CashierMode extends AuthState {}

/// وضع الأدمن (المالك) - Admin Mode
class AdminMode extends AuthState {
  final User user;

  AdminMode(this.user);
}

/// خطأ في المصادقة - Auth Error
class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

/// أحداث المصادقة - Auth Events
abstract class AuthEvent {}

/// حدث تسجيل الدخول
class LoginEvent extends AuthEvent {
  final String username;
  final String password;

  LoginEvent(this.username, this.password);
}

/// حدث تسجيل الخروج
class LogoutEvent extends AuthEvent {}

/// حدث التحقق من حالة المصادقة
class CheckAuthStatusEvent extends AuthEvent {}

/// حدث تفعيل وضع الأدمن
class EnableAdminModeEvent extends AuthEvent {
  final String username;
  final String password;

  EnableAdminModeEvent(this.username, this.password);
}

/// حدث إلغاء وضع الأدمن
class DisableAdminModeEvent extends AuthEvent {}

/// Auth Cubit - يدير حالة المصادقة
/// Manages authentication state with smart mode switching
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  Timer? _autoLockTimer;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    // التحقق من حالة المصادقة عند البدء
    checkAuthStatus();
  }

  /// التحقق من حالة المصادقة وتحميل الوضع المناسب
  /// Check auth status and load appropriate mode
  void checkAuthStatus() {
    emit(AuthLoading());

    // التحقق من اكتمال الإعداد الأولي
    if (AppSettings.isFirstRun || !AppSettings.hasAdminPassword) {
      // لم يتم الإعداد بعد - يبدأ في وضع الكاشير
      emit(CashierMode());
      return;
    }

    // التحقق من وضع الفتح الافتراضي
    final defaultOpenAsAdmin = AppSettings.getDefaultOpenMode();

    // التحقق من آخر وضع محفوظ
    final lastModeWasAdmin = AppSettings.getLastMode();

    // إذا كان الفتح الافتراضي هو الأدمن وكان آخر وضع أدمن
    if (defaultOpenAsAdmin && lastModeWasAdmin) {
      // افتح في وضع الأدمن
      final savedUsername = AppSettings.adminUsername ?? 'admin';
      emit(AdminMode(User(
        id: 'admin',
        username: savedUsername,
        passwordHash: '',
        role: UserRole.owner,
        name: savedUsername,
        isActive: true,
        createdAt: DateTime.now(),
      )));
      _startAutoLockTimer();
    } else {
      // افتح في وضع الكاشير (آخر وضع محفوظ)
      emit(CashierMode());
    }
  }

  /// تفعيل وضع الأدمن مباشرة بدون طلب كلمة السر (للفتح الافتراضي)
  /// Enable admin mode directly without password (for default open mode)
  void enableAdminModeByDefault() {
    final user = User(
      id: 'admin',
      username: AppSettings.adminUsername ?? 'admin',
      passwordHash: '',
      role: UserRole.owner,
      name: AppSettings.adminUsername ?? 'المالك',
      isActive: true,
      createdAt: DateTime.now(),
    );
    emit(AdminMode(user));
    AppSettings.setLastMode(true);
    _startAutoLockTimer();
  }

  /// تفعيل وضع الأدمن باسم المستخدم وكلمة السر
  /// Enable admin mode with username and password
  Future<bool> enableAdminMode(String username, String password) async {
    emit(AuthLoading());

    // التحقق من اسم المستخدم وكلمة السر
    final savedUsername = AppSettings.adminUsername;
    if (username == savedUsername && AppSettings.verifyAdminPassword(password)) {
      final user = User(
        id: 'admin',
        username: username,
        passwordHash: '',
        role: UserRole.owner,
        name: savedUsername ?? 'المالك',
        isActive: true,
        createdAt: DateTime.now(),
      );

      emit(AdminMode(user));

      // حفظ آخر وضع
      await AppSettings.setLastMode(true);

      // بدء مؤقت القفل التلقائي
      _startAutoLockTimer();

      return true;
    } else {
      emit(AuthError('اسم المستخدم أو كلمة السر غير صحيحة'));
      emit(CashierMode());
      return false;
    }
  }

  /// إلغاء وضع الأدمن (العودة لوضع الكاشير)
  /// Disable admin mode (return to cashier mode)
  Future<void> disableAdminMode() async {
    _stopAutoLockTimer();
    await AppSettings.setLastMode(false);
    emit(CashierMode());
  }

  /// بدء مؤقت القفل التلقائي
  /// Start auto-lock timer
  void _startAutoLockTimer() {
    if (!AppSettings.isAutoLockEnabled) return;

    _stopAutoLockTimer(); // إيقاف أي مؤقت سابق

    final minutes = AppSettings.autoLockMinutes;
    _autoLockTimer = Timer(Duration(minutes: minutes), () {
      // القفل التلقائي بعد انتهاء الوقت
      disableAdminMode();
    });
  }

  /// إيقاف مؤقت القفل التلقائي
  /// Stop auto-lock timer
  void _stopAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }

  /// إعادة تشغيل مؤقت القفل التلقائي (عند النشاط)
  /// Reset auto-lock timer on activity
  void resetAutoLockTimer() {
    if (state is AdminMode) {
      _startAutoLockTimer();
    }
  }

  /// تسجيل الدخول (للتوافق مع النظام القديم)
  Future<void> login(String username, String password) async {
    emit(AuthLoading());

    final result = await _authRepository.login(username, password);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        if (user.role == UserRole.owner) {
          emit(AdminMode(user));
          _startAutoLockTimer();
        } else {
          emit(CashierMode());
        }
      },
    );
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    _stopAutoLockTimer();
    await _authRepository.logout();
    await AppSettings.setLastMode(false);
    emit(CashierMode());
  }

  /// التحقق مما إذا كان وضع الأدمن مفعل
  bool get isAdminMode => state is AdminMode;

  /// الحصول على المستخدم الحالي (إن وجد)
  User? get currentUser {
    if (state is AdminMode) {
      return (state as AdminMode).user;
    }
    return null;
  }

  @override
  Future<void> close() {
    _stopAutoLockTimer();
    return super.close();
  }
}
