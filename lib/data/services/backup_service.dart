import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:presensi_app/data/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

/// Model satu file backup
class BackupFile {
  final String path;
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;

  BackupFile({
    required this.path,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get dateLabel =>
      DateFormat('dd MMM yyyy, HH:mm', 'id').format(createdAt);
}

/// Hasil operasi backup / restore
class BackupResult {
  final bool success;
  final String message;
  final String? filePath;

  const BackupResult({
    required this.success,
    required this.message,
    this.filePath,
  });
}

class BackupService {
  BackupService._();
  static final instance = BackupService._();

  static const _backupFolderName = 'AbsensiBackup';
  static const _dbName = 'absensi.db';


 Future<Directory> get _backupDir async {
  final granted = await requestStoragePermission();
  if (!granted) {
    throw Exception('Izin storage ditolak');
  }

  final dir = Directory('/storage/emulated/0/Download/AbsensiBackup');

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  return dir;
}
  
  Future<bool> requestStoragePermission() async {
  if (await Permission.manageExternalStorage.isGranted) {
    return true;
  }

  final result = await Permission.manageExternalStorage.request();

  return result.isGranted;
}

  Future<String> get _dbPath async {
    final dbDir = await getDatabasesPath();
    return p.join(dbDir, _dbName);
  }

 Future<BackupResult> backup() async {
  try {
    // Request permission storage
    final granted = await requestStoragePermission();

    if (!granted) {
      return const BackupResult(
        success: false,
        message: 'Izin akses penyimpanan ditolak.',
      );
    }

    // File database aktif
    final src = File(await _dbPath);

    if (!await src.exists()) {
      return const BackupResult(
        success: false,
        message: 'File database tidak ditemukan.',
      );
    }

    // Folder backup publik
    final dir = Directory(
      '/storage/emulated/0/Download/AbsensiBackup',
    );

    // Buat folder jika belum ada
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Nama file backup
    final timestamp =
        DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

    final destPath = p.join(
      dir.path,
      'absensi_backup_$timestamp.db',
    );

    // Copy database
    await src.copy(destPath);

    return BackupResult(
      success: true,
      message:
          'Backup berhasil disimpan.\n📁 ${dir.path}',
      filePath: destPath,
    );
  } catch (e) {
    debugPrint('BackupService.backup error: $e');

    return BackupResult(
      success: false,
      message: 'Gagal membuat backup:\n$e',
    );
  }
}

  Future<BackupResult> restore(String backupPath) async {
    try {
      final src = File(backupPath);
      if (!await src.exists()) {
        return const BackupResult(
          success: false,
          message: 'File backup tidak ditemukan.',
        );
      }

      final dest = File(await _dbPath);

      await DatabaseHelper.instance.close();
      await src.copy(dest.path);

      return const BackupResult(
        success: true,
        message: 'Restore berhasil! Restart aplikasi untuk memuat data terbaru.',
      );
    } catch (e) {
      debugPrint('BackupService.restore error: $e');
      return BackupResult(
        success: false,
        message: 'Gagal melakukan restore: $e',
      );
    }
  }

  Future<List<BackupFile>> listBackups() async {
    try {
      final dir = await _backupDir;
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.db'))
          .toList();

      final result = files.map((f) {
        final stat = f.statSync();
        return BackupFile(
          path: f.path,
          fileName: p.basename(f.path),
          createdAt: stat.modified,
          sizeBytes: stat.size,
        );
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return result;
    } catch (e) {
      debugPrint('BackupService.listBackups error: $e');
      return [];
    }
  }

  Future<BackupResult> deleteBackup(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
      return const BackupResult(
        success: true,
        message: 'File backup berhasil dihapus.',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Gagal menghapus file: $e',
      );
    }
  }

  Future<String> getBackupDirPath() async {
    final dir = await _backupDir;
    return dir.path;
  }

  Future<Database> _openDb() async {
    return openDatabase(await _dbPath);
  }
}