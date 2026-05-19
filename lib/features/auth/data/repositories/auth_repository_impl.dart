import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import '../../../../core/data/app_settings.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// تنفيذ مستودع المصادقة - Auth Repository Implementation
class AuthRepositoryImpl implements AuthRepository {
  static const String _currentUserKey = 'currentUserId';

  Box<UserModel> get _userBox => HiveDatabase.userBox;
  Box get _settingsBox => HiveDatabase.settingsBox;

  @override
  Future<Either<Failure, User>> login(String username, String password) async {
    try {
      // التحقق من بيانات دخول الأدمن باستخدام AppSettings
      if (AppSettings.hasAdminPassword) {
        final savedUsername = AppSettings.adminUsername;
        if (username == savedUsername &&
            AppSettings.verifyAdminPassword(password)) {
          await setAdminMode(true);

          final adminUser = UserModel(
            id: 'admin',
            username: username,
            passwordHash: _hashPassword(password),
            role: UserRole.owner,
            name: 'المالك',
            isActive: true,
            createdAt: DateTime.now(),
          );

          await _settingsBox.put(_currentUserKey, adminUser.id);
          return Right(adminUser);
        }
      }

      // التحقق من المستخدمين الآخرين
      final hashedPassword = _hashPassword(password);
      final user = _userBox.values.firstWhere(
        (u) => u.username == username && u.passwordHash == hashedPassword,
        orElse: () => throw Exception('User not found'),
      );

      if (!user.isActive) {
        return const Left(AuthFailure('هذا الحساب غير مفعل'));
      }

      await _settingsBox.put(_currentUserKey, user.id);
      await setAdminMode(user.role == UserRole.owner);
      return Right(user);
    } catch (e) {
      return const Left(AuthFailure('بيانات الدخول غير صحيحة'));
    }
  }

  @override
  Future<void> logout() async {
    await _settingsBox.delete(_currentUserKey);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userId = _settingsBox.get(_currentUserKey) as String?;
      if (userId == null) return const Right(null);

      final user = _userBox.get(userId);
      return Right(user);
    } catch (e) {
      return const Left(AuthFailure('فشل في الحصول على بيانات المستخدم'));
    }
  }

  @override
  bool get isLoggedIn {
    return _settingsBox.containsKey(_currentUserKey);
  }

  @override
  bool get isAdminMode {
    return _settingsBox.get('isAdminMode', defaultValue: false) as bool;
  }

  @override
  Future<void> setAdminMode(bool isAdmin) async {
    await _settingsBox.put('isAdminMode', isAdmin);
  }

  @override
  Future<Either<Failure, void>> addUser(User user) async {
    try {
      if (_userBox.values.any((u) => u.username == user.username)) {
        return const Left(AuthFailure('اسم المستخدم موجود مسبقاً'));
      }

      final userModel = UserModel.fromEntity(user);
      await _userBox.put(user.id, userModel);
      return const Right(null);
    } catch (e) {
      return const Left(AuthFailure('فشل في إضافة المستخدم'));
    }
  }

  @override
  Future<Either<Failure, List<User>>> getAllUsers() async {
    try {
      final users = _userBox.values.toList();
      return Right(users);
    } catch (e) {
      return const Left(AuthFailure('فشل في الحصول على قائمة المستخدمين'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await _userBox.put(user.id, userModel);
      return const Right(null);
    } catch (e) {
      return const Left(AuthFailure('فشل في تحديث بيانات المستخدم'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await _userBox.delete(userId);
      return const Right(null);
    } catch (e) {
      return const Left(AuthFailure('فشل في حذف المستخدم'));
    }
  }

  @override
  Future<Either<Failure, void>> changeCredentials({
    required String newUsername,
    required String newPassword,
  }) async {
    try {
      if (!isAdminMode) {
        return const Left(AuthFailure('لا تملك صلاحية تغيير بيانات الدخول'));
      }

      await AppSettings.setAdminUsername(newUsername);
      await AppSettings.setAdminPassword(newPassword);
      return const Right(null);
    } catch (e) {
      return const Left(AuthFailure('فشل في تغيير بيانات الدخول'));
    }
  }

  @override
  Future<Map<String, String>> getCredentials() async {
    final username = AppSettings.adminUsername ?? '';
    return {'username': username, 'password': ''};
  }

  /// تشفير كلمة المرور باستخدام SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}

/// فشل المصادقة - Auth Failure
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
