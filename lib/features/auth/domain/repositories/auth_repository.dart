import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/user.dart';

/// مستودع المصادقة - Auth Repository
/// يحدد عمليات المصادقة وإدارة المستخدمين
abstract class AuthRepository {
  /// تسجيل الدخول
  Future<Either<Failure, User>> login(String username, String password);

  /// تسجيل الخروج
  Future<void> logout();

  /// الحصول على المستخدم الحالي
  Future<Either<Failure, User?>> getCurrentUser();

  /// التحقق من وجود مستخدم مسجل دخوله
  bool get isLoggedIn;

  /// التحقق من صلاحيات الأدمن
  bool get isAdminMode;

  /// تفعيل/إلغاء تفعيل وضع الأدمن
  Future<void> setAdminMode(bool isAdmin);

  /// إضافة مستخدم جديد (للمالك فقط)
  Future<Either<Failure, void>> addUser(User user);

  /// الحصول على جميع المستخدمين
  Future<Either<Failure, List<User>>> getAllUsers();

  /// تحديث بيانات مستخدم
  Future<Either<Failure, void>> updateUser(User user);

  /// حذف مستخدم
  Future<Either<Failure, void>> deleteUser(String userId);

  /// تغيير بيانات الدخول (للمالك فقط)
  Future<Either<Failure, void>> changeCredentials({
    required String newUsername,
    required String newPassword,
  });

  /// الحصول على بيانات الدخول الحالية
  Future<Map<String, String>> getCredentials();
}
