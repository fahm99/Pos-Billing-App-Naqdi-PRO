import 'package:hive/hive.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// نموذج المستخدم لقاعدة البيانات - User Model for Hive
/// typeId: 8 (معرف فريد في Hive)
@HiveType(typeId: 8)
class UserModel extends User {
  @override
  @HiveField(0)
  final String id;

  @override
  @HiveField(1)
  final String username;

  @override
  @HiveField(2)
  final String passwordHash;

  @override
  @HiveField(3)
  final UserRole role;

  @override
  @HiveField(4)
  final String name;

  @override
  @HiveField(5)
  final bool isActive;

  @override
  @HiveField(6)
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.name,
    this.isActive = true,
    required this.createdAt,
  }) : super(
          id: id,
          username: username,
          passwordHash: passwordHash,
          role: role,
          name: name,
          isActive: isActive,
          createdAt: createdAt,
        );

  /// تحويل من كيان إلى نموذج
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      passwordHash: user.passwordHash,
      role: user.role,
      name: user.name,
      isActive: user.isActive,
      createdAt: user.createdAt,
    );
  }

  /// تحويل إلى خريطة للحفظ
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'role': role.name,
      'name': name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// إنشاء من خريطة
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      passwordHash: json['passwordHash'],
      role: UserRole.values.firstWhere((r) => r.name == json['role']),
      name: json['name'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
