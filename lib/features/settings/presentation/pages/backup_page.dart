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
  List<_BackupInfo> _backups = [];
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isRestoring = false;
  String? _selectedBackupPath;

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
        final backupDirs = entities.whereType<Directory>().toList();
        backupDirs.sort((a, b) {
          return b.statSync().modified.compareTo(a.statSync().modified);
        });
        final backups = <_BackupInfo>[];
        for (final d in backupDirs) {
          final info = await _readBackupInfo(d);
          backups.add(info);
        }
        setState(() => _backups = backups);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل النسخ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<_BackupInfo> _readBackupInfo(Directory dir) async {
    final stat = dir.statSync();
    final name = dir.uri.pathSegments.last;
    final date = stat.modified;

    int totalSize = 0;
    final dbDir = Directory('${dir.path}/database');
    if (await dbDir.exists()) {
      await for (final entity in dbDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }

    String infoContent = '';
    final infoFile = File('${dir.path}/info.txt');
    if (await infoFile.exists()) {
      infoContent = await infoFile.readAsString();
    }

    return _BackupInfo(
      path: dir.path,
      name: name,
      date: date,
      size: totalSize,
      infoContent: infoContent,
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isCreating = true);
    try {
      final backupPath = await _getBackupDirPath();
      final dateStr = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final backupDir = Directory('$backupPath/Backup_$dateStr');
      await backupDir.create(recursive: true);

      final dbPath = '${backupDir.path}/database';
      final dbDir = Directory(dbPath);
      await dbDir.create(recursive: true);

      final appDir = await getApplicationDocumentsDirectory();
      final hiveFiles = await Directory(appDir.path).list().toList();
      for (final file in hiveFiles) {
        if (file.path.endsWith('.hive')) {
          try {
            await File(file.path).copy('$dbPath/${file.uri.pathSegments.last}');
          } catch (_) {}
        }
      }

      final infoFile = File('${backupDir.path}/info.txt');
      await infoFile.writeAsString(
        'نقدي - نظام نقاط البيع\n'
        'تاريخ النسخ الاحتياطي: $dateStr\n'
        'الإصدار: 1.0.0\n'
        'عدد المنتجات: ${HiveDatabase.productBox.length}\n'
        'عدد الفواتير: ${HiveDatabase.invoiceBox.length}\n'
        'عدد العملاء: ${HiveDatabase.customerBox.length}\n'
        'عدد الموردين: ${HiveDatabase.supplierBox.length}\n'
        'عدد المصروفات: ${HiveDatabase.expenseBox.length}\n'
        'عدد الديون: ${HiveDatabase.debtBox.length}\n'
        'عدد مدفوعات الزكاة: ${HiveDatabase.zakatPaymentBox.length}\n'
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
          SnackBar(content: Text('❌ فشل إنشاء النسخ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _confirmRestore(_BackupInfo backup) async {
    final sizeStr = backup.size > 1024 * 1024
        ? '${(backup.size / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(backup.size / 1024).toStringAsFixed(1)} KB';
    final dateStr = DateFormat('yyyy/MM/dd HH:mm', 'ar').format(backup.date);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة النسخة الاحتياطية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('الاسم', backup.name),
                  _infoRow('التاريخ', dateStr),
                  _infoRow('الحجم', sizeStr),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (backup.infoContent.isNotEmpty) ...[
              const Text('محتوى النسخة:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  backup.infoContent,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم استبدال البيانات الحالية. سيتم إنشاء نسخة احتياطية تلقائياً قبل الاستعادة.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    if (confirmed == true) {
      await _restoreBackup(backup);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _restoreBackup(_BackupInfo backup) async {
    setState(() {
      _isRestoring = true;
      _selectedBackupPath = backup.path;
    });

    try {
      await _createBackup();

      final dbPath = '${backup.path}/database';
      final dbDir = Directory(dbPath);
      if (await dbDir.exists()) {
        final files = await dbDir.list().toList();
        final appDir = await getApplicationDocumentsDirectory();
        for (final file in files) {
          if (file is File) {
            final fileName = file.uri.pathSegments.last;
            if (fileName.endsWith('.lock')) continue;
            try {
              await file.copy('${appDir.path}/$fileName');
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('✅ تمت الاستعادة بنجاح'),
            content: const Text(
              'تم استعادة البيانات بنجاح.\n\n'
              'يرجى إغلاق التطبيق بالكامل وإعادة فتحه لتطبيق التغييرات.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text('حسناً'),
              ),
            ],
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
      setState(() {
        _isRestoring = false;
        _selectedBackupPath = null;
      });
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                label: Text(_isCreating ? 'جاري الإنشاء...' : 'إنشاء نسخة احتياطية جديدة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

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
                          padding: const EdgeInsets.all(16),
                          itemCount: _backups.length,
                          itemBuilder: (context, index) => _buildBackupCard(_backups[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(_BackupInfo backup) {
    final sizeStr = backup.size > 1024 * 1024
        ? '${(backup.size / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(backup.size / 1024).toStringAsFixed(1)} KB';
    final dateStr = DateFormat('yyyy/MM/dd HH:mm', 'ar').format(backup.date);
    final isRestoring = _isRestoring && _selectedBackupPath == backup.path;

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
          child: isRestoring
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.backup_outlined, color: AppTheme.primaryColor, size: 24),
        ),
        title: Text(backup.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text('$dateStr • $sizeStr', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.orange, size: 22),
              tooltip: 'استعادة',
              onPressed: isRestoring ? null : () => _confirmRestore(backup),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
              tooltip: 'حذف',
              onPressed: isRestoring ? null : () => _deleteBackup(backup),
            ),
          ],
        ),
        onTap: isRestoring ? null : () => _confirmRestore(backup),
      ),
    );
  }

  Future<void> _deleteBackup(_BackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف النسخة الاحتياطية'),
        content: Text('هل تريد حذف "${backup.name}"؟'),
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
        await Directory(backup.path).delete(recursive: true);
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

class _BackupInfo {
  final String path;
  final String name;
  final DateTime date;
  final int size;
  final String infoContent;

  const _BackupInfo({
    required this.path,
    required this.name,
    required this.date,
    required this.size,
    required this.infoContent,
  });
}
