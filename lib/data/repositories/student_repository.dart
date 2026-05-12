import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/student_model.dart';

class StudentRepository {
  final _db = DatabaseHelper.instance;

  Future<int> insert(Student student) async {
    final db = await _db.database;
    return db.insert('students', student.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> update(Student student) async {
    final db = await _db.database;
    return db.update('students', student.toMap(),
        where: 'id = ?', whereArgs: [student.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<Student?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('students', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Student.fromMap(maps.first);
  }

  Future<List<Student>> getAll({
    String? kelas,
    String? search,
    bool activeOnly = true,
  }) async {
    final db = await _db.database;
    String where = activeOnly ? 'is_active = 1' : '';
    List<dynamic> whereArgs = [];

    if (kelas != null && kelas.isNotEmpty) {
      where += (where.isNotEmpty ? ' AND ' : '') + 'kelas = ?';
      whereArgs.add(kelas);
    }

    if (search != null && search.isNotEmpty) {
      where += (where.isNotEmpty ? ' AND ' : '') +
          '(nama LIKE ? OR nis LIKE ?)';
      whereArgs.addAll(['%$search%', '%$search%']);
    }

    final maps = await db.query(
      'students',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'nama ASC',
    );

    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<List<String>> getKelasOptions() async {
    final db = await _db.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT kelas FROM students WHERE is_active = 1 ORDER BY kelas ASC');
    return result.map((r) => r['kelas'] as String).toList();
  }
}