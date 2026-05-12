import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/attendance_model.dart';
import '../models/attendance_detail_model.dart';

class AttendanceRepository {
  final _db = DatabaseHelper.instance;

  // ── Attendance header ──────────────────────────────────────

  Future<int> insertAttendance(Attendance a) async {
    final db = await _db.database;
    return db.insert('attendances', a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Attendance?> getByTanggalKelas(String tanggal, String kelas) async {
    final db = await _db.database;
    final maps = await db.query('attendances',
        where: 'tanggal = ? AND kelas = ?', whereArgs: [tanggal, kelas]);
    if (maps.isEmpty) return null;
    return Attendance.fromMap(maps.first);
  }

  Future<List<Attendance>> getHistory({
    String? kelas,
    String? startDate,
    String? endDate,
  }) async {
    final db = await _db.database;
    String where = '';
    List<dynamic> args = [];

    if (kelas != null) {
      where += 'kelas = ?';
      args.add(kelas);
    }
    if (startDate != null) {
      where += (where.isNotEmpty ? ' AND ' : '') + 'tanggal >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      where += (where.isNotEmpty ? ' AND ' : '') + 'tanggal <= ?';
      args.add(endDate);
    }

    final maps = await db.query('attendances',
        where: where.isNotEmpty ? where : null,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'tanggal DESC');
    return maps.map((m) => Attendance.fromMap(m)).toList();
  }

  // ── Attendance details ────────────────────────────────────

  Future<void> saveDetails(
      int attendanceId, List<AttendanceDetail> details) async {
    final db = await _db.database;
    final batch = db.batch();

    for (final d in details) {
      batch.insert(
        'attendance_details',
        d.copyWith().toMap()..['attendance_id'] = attendanceId,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<AttendanceDetail>> getDetailsByAttendanceId(
      int attendanceId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT ad.*, s.nama, s.nis
      FROM attendance_details ad
      JOIN students s ON s.id = ad.student_id
      WHERE ad.attendance_id = ?
      ORDER BY s.nama ASC
    ''', [attendanceId]);
    return maps.map((m) => AttendanceDetail.fromMap(m)).toList();
  }

  // Rekap absensi per siswa
  Future<Map<String, int>> getRekapSiswa(int studentId,
      {String? startDate, String? endDate}) async {
    final db = await _db.database;
    String dateFilter = '';
    List<dynamic> args = [studentId];

    if (startDate != null) {
      dateFilter += ' AND a.tanggal >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      dateFilter += ' AND a.tanggal <= ?';
      args.add(endDate);
    }

    final result = await db.rawQuery('''
      SELECT ad.status, COUNT(*) as jumlah
      FROM attendance_details ad
      JOIN attendances a ON a.id = ad.attendance_id
      WHERE ad.student_id = ? $dateFilter
      GROUP BY ad.status
    ''', args);

    final rekap = <String, int>{
      'hadir': 0, 'izin': 0, 'sakit': 0, 'alfa': 0
    };
    for (final r in result) {
      rekap[r['status'] as String] = r['jumlah'] as int;
    }
    return rekap;
  }
}