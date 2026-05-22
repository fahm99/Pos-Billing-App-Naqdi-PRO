import 'package:equatable/equatable.dart';

/// كيان المستخدم - User Entity
/// يحتوي على البيانات الأساسية للمستخدم
class User extends Equatable {
  final String id;
  final String username;
  final String passwordHash;
  final UserRole role;
  final String name;
  final bool isActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.name,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, username, passwordHash, role, name, isActive, createdAt];
}

/// أنواع المستخدمين - User Roles
/// owner: المالك (له جميع الصلاحيات)
/// employee: العامل (صلاحيات محدودة - البيع فقط)
enum UserRole {
  owner,
  employee;

  String get arabicName {
    switch (this) {
      case UserRole.owner:
        return 'مالك';
      case UserRole.employee:
        return 'عامل';
    }
  }
}
