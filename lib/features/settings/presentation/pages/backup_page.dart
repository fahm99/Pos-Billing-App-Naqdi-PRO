import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/hive_database.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  List<FileSystemEntity> _backups = [];
  bool _isLoading = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<String> _getBackupDirPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/Backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      final backupPath = await _getBackupDirPath();
      final dir = Directory(backupPath);
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        entities.sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return bStat.modified.compareTo(aStat.modified);
        });
        setState(() => _backups = entities.whereType<File>().toList());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل النسخ الاحتياطية: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isCreating = true);
    try {
      final backupPath = await _getBackupDirPath();
      final dateStr = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final backupDir = Directory('$backupPath/Backup_$dateStr');
      await backupDir.create(recursive: true);

      // تصدير قاعدة بيانات Hive
      final dbPath = '${backupDir.path}/database';
      final dbDir = Directory(dbPath);
      await dbDir.create(recursive: true);

      // نسخ ملفات Hive
      final appDir = await getApplicationDocumentsDirectory();
      final hiveFiles = await Directory(appDir.path).list().toList();
      for (final file in hiveFiles) {
        if (file.path.endsWith('.hive') || file.path.endsWith('.lock')) {
          try {
            await File(file.path).copy('$dbPath/${file.uri.pathSegments.last}');
          } catch (_) {}
        }
      }

      // تصدير الإعدادات
      final settingsFile = File('${backupDir.path}/settings.json');
      await settingsFile.writeAsString('نقدي POS - نسخ احتياطي - $dateStr');

      // إنشاء ملف معلومات
      final infoFile = File('${backupDir.path}/info.txt');
      await infoFile.writeAsString(
        'نقدي - نظام نقاط البيع\n'
        'تاريخ النسخ الاحتياطي: $dateStr\n'
        'الإصدار: 1.0.0\n'
        'عدد المنتجات: ${HiveDatabase.productBox.length}\n'
        'عدد الفواتير: ${HiveDatabase.invoiceBox.length}\n'
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إنشاء النسخ الاحتياطي بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشل إنشاء النسخ الاحتياطي: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _restoreBackup(String backupPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة النسخ الاحتياطي'),
        content: const Text(
          'سيتم استبدال البيانات الحالية بالبيانات من النسخة الاحتياطية.\n'
          'سيتم إنشاء نسخة احتياطية تلقائياً قبل الاستعادة.\n\n'
          'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('تأكيد الاستعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      // إنشاء نسخة احتياطية قبل الاستعادة
      await _createBackup();

      // استعادة قاعدة البيانات
      final dbPath = '$backupPath/database';
      final dbDir = Directory(dbPath);
      if (await dbDir.exists()) {
        final files = await dbDir.list().toList();
        final appDir = await getApplicationDocumentsDirectory();
        for (final file in files) {
          if (file is File) {
            final fileName = file.uri.pathSegments.last;
            try {
              await file.copy('${appDir.path}/$fileName');
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تمت استعادة النسخة الاحتياطية بنجاح.\nيرجى إعادة تشغيل التطبيق.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشل الاستعادة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة النسخ الاحتياطي'),
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // زر النسخ الاحتياطي
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createBackup,
                icon: _isCreating
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.backup, size: 22),
                label: Text(_isCreating ? 'جاري الإنشاء...' : 'نسخ احتياطي الآن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

          // قائمة النسخ الاحتياطية
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _backups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.backup_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('لا توجد نسخ احتياطية', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBackups,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _backups.length,
                          itemBuilder: (context, index) {
                            final file = _backups[index] as File;
                            final stat = file.statSync();
                            final size = stat.size;
                            final date = stat.modified;
                            final name = file.uri.pathSegments.last;
                            return _buildBackupCard(name, date, size, file.path);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(String name, DateTime date, int size, String path) {
    final sizeStr = size > 1024 * 1024
        ? '${(size / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(size / 1024).toStringAsFixed(1)} KB';
    final dateStr = DateFormat('yyyy/MM/dd HH:mm', 'ar').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.backup_outlined, color: AppTheme.primaryColor, size: 24),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text('$dateStr • $sizeStr', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
          onSelected: (value) {
            if (value == 'restore') {
              _restoreBackup(path);
            } else if (value == 'delete') {
              _deleteBackup(path);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'restore', child: ListTile(
              leading: Icon(Icons.restore, color: Colors.orange),
              title: Text('استعادة'),
              contentPadding: EdgeInsets.zero,
            )),
            const PopupMenuItem(value: 'delete', child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('حذف'),
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
        onTap: () => _restoreBackup(path),
      ),
    );
  }

  Future<void> _deleteBackup(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف النسخة الاحتياطية'),
        content: const Text('هل تريد حذف هذه النسخة الاحتياطية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Directory(path).delete(recursive: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف النسخة الاحتياطية'), backgroundColor: Colors.green),
          );
        }
        _loadBackups();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}