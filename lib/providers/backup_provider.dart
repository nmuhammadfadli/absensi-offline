import 'package:flutter/foundation.dart';
import '../data/services/backup_service.dart';

enum BackupStatus { idle, loading, success, error }

class BackupProvider with ChangeNotifier {
  final _service = BackupService.instance;

  List<BackupFile> _backups = [];
  BackupStatus _status = BackupStatus.idle;
  String _message = '';
  String _backupDirPath = '';
  bool _isRestoring = false;

  List<BackupFile> get backups => _backups;
  BackupStatus get status => _status;
  String get message => _message;
  String get backupDirPath => _backupDirPath;
  bool get isRestoring => _isRestoring;
  bool get isLoading => _status == BackupStatus.loading || _isRestoring;

  Future<void> init() async {
    try {
      _status = BackupStatus.loading;
      notifyListeners();

      _backupDirPath = await _service.getBackupDirPath();
      _backups = await _service.listBackups();

      _status = BackupStatus.idle;
    } catch (e) {
      _status = BackupStatus.error;
      _message = 'Gagal memuat backup: $e';
      debugPrint('BackupProvider.init error: $e');
    }

    notifyListeners();
  }

  Future<void> loadBackups() async {
    try {
      _status = BackupStatus.loading;
      notifyListeners();

      _backupDirPath = await _service.getBackupDirPath();
      _backups = await _service.listBackups();

      _status = BackupStatus.idle;
    } catch (e) {
      _status = BackupStatus.error;
      _message = 'Gagal memuat daftar backup: $e';
      debugPrint('BackupProvider.loadBackups error: $e');
    }

    notifyListeners();
  }

  Future<BackupResult> doBackup() async {
    _status = BackupStatus.loading;
    _message = '';
    notifyListeners();

    final result = await _service.backup();

    _status = result.success ? BackupStatus.success : BackupStatus.error;
    _message = result.message;
    notifyListeners();

    await loadBackups();
    return result;
  }

  Future<BackupResult> doRestore(String path) async {
    _isRestoring = true;
    _status = BackupStatus.loading;
    _message = '';
    notifyListeners();

    final result = await _service.restore(path);

    _isRestoring = false;
    _status = result.success ? BackupStatus.success : BackupStatus.error;
    _message = result.message;
    notifyListeners();

    if (result.success) {
      await loadBackups();
    }

    return result;
  }

  Future<BackupResult> doDelete(String path) async {
    _status = BackupStatus.loading;
    notifyListeners();

    final result = await _service.deleteBackup(path);

    _status = result.success ? BackupStatus.success : BackupStatus.error;
    _message = result.message;
    notifyListeners();

    if (result.success) {
      await loadBackups();
    }

    return result;
  }

  void resetStatus() {
    _status = BackupStatus.idle;
    _message = '';
    notifyListeners();
  }
}