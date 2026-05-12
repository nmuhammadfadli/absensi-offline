import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/models/attendance_model.dart';
import '../data/models/attendance_detail_model.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/student_repository.dart';

class AttendanceProvider with ChangeNotifier {
  final _attendanceRepo = AttendanceRepository();
  final _studentRepo    = StudentRepository();

  DateTime  _selectedDate    = DateTime.now();
  String    _selectedKelas   = '';
  Attendance?              _currentAttendance;
  List<AttendanceDetail>   _currentDetails = [];
  List<Attendance>         _history        = [];
  bool    _isLoading  = false;
  bool    _isSaving   = false;
  String? _error;

  // Getters
  DateTime               get selectedDate      => _selectedDate;
  String                 get selectedKelas     => _selectedKelas;
  Attendance?            get currentAttendance => _currentAttendance;
  List<AttendanceDetail> get currentDetails    => _currentDetails;
  List<Attendance>       get history           => _history;
  bool                   get isLoading         => _isLoading;
  bool                   get isSaving          => _isSaving;
  String?                get error             => _error;

  String get formattedDate =>
      DateFormat('yyyy-MM-dd').format(_selectedDate);

  // ── Date & Kelas ─────────────────────────────────────────────────────────

  void setDate(DateTime date) {
    if (_selectedDate == date) return;
    _selectedDate = date;
    if (_selectedKelas.isNotEmpty) _loadOrCreateAbsensi();
  }

  void setKelas(String kelas) {
    _selectedKelas = kelas;
    if (kelas.isNotEmpty) _loadOrCreateAbsensi();
  }

  // ── Load absensi untuk tanggal+kelas yang dipilih ─────────────────────

  Future<void> _loadOrCreateAbsensi() async {
    _isLoading = true;
    notifyListeners(); // aman: dipanggil dari event handler (bukan saat build)

    try {
      final tanggal = formattedDate;

      _currentAttendance = await _attendanceRepo
          .getByTanggalKelas(tanggal, _selectedKelas);

      if (_currentAttendance != null) {
        // Absensi sudah ada → load detail yang tersimpan
        _currentDetails = await _attendanceRepo
            .getDetailsByAttendanceId(_currentAttendance!.id!);
      } else {
        // Belum ada → buat template dari daftar siswa aktif di kelas ini
        final students =
            await _studentRepo.getAll(kelas: _selectedKelas);
        _currentDetails = students
            .map((s) => AttendanceDetail(
                  attendanceId: 0,
                  studentId: s.id!,
                  status: AbsensiStatus.hadir,
                  namaSiswa: s.nama,
                  nisSiswa: s.nis,
                ))
            .toList();
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update satu detail (status / jam) ───────────────────────────────────

  void updateDetail(
    int studentId, {
    AbsensiStatus? status,
    String? jamMasuk,
    String? jamPulang,
    String? keterangan,
  }) {
    final idx =
        _currentDetails.indexWhere((d) => d.studentId == studentId);
    if (idx == -1) return;

    _currentDetails[idx] = _currentDetails[idx].copyWith(
      status: status,
      jamMasuk: jamMasuk,
      jamPulang: jamPulang,
      keterangan: keterangan,
    );
    notifyListeners();
  }

  // ── Simpan absensi ───────────────────────────────────────────────────────

  Future<bool> saveAbsensi() async {
    if (_selectedKelas.isEmpty) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final now = DateTime.now().toIso8601String();

      final attendance = Attendance(
        id: _currentAttendance?.id,
        tanggal: formattedDate,
        kelas: _selectedKelas,
        createdAt: now,
      );

      final id = await _attendanceRepo.insertAttendance(attendance);

      _currentAttendance = Attendance(
        id: id,
        tanggal: attendance.tanggal,
        kelas: attendance.kelas,
        createdAt: attendance.createdAt,
      );

      await _attendanceRepo.saveDetails(id, _currentDetails);

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── Riwayat ──────────────────────────────────────────────────────────────

  Future<void> loadHistory({
    String? kelas,
    String? start,
    String? end,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _attendanceRepo.getHistory(
        kelas: kelas,
        startDate: start,
        endDate: end,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Helper untuk detail & rekap ──────────────────────────────────────────

  Future<List<AttendanceDetail>> getDetailForId(int attendanceId) {
    return _attendanceRepo.getDetailsByAttendanceId(attendanceId);
  }

  Future<Map<String, int>> getRekapSiswa(
    int studentId, {
    String? start,
    String? end,
  }) {
    return _attendanceRepo.getRekapSiswa(
      studentId,
      startDate: start,
      endDate: end,
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}