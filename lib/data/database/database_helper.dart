import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('absensi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        nis TEXT NOT NULL UNIQUE,
        kelas TEXT NOT NULL,
        jenis_kelamin TEXT NOT NULL,
        no_hp_ortu TEXT,
        alamat TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        kelas TEXT NOT NULL,
        catatan TEXT,
        created_at TEXT NOT NULL,
        UNIQUE(tanggal, kelas)
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attendance_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'alfa',
        jam_masuk TEXT,
        jam_pulang TEXT,
        keterangan TEXT,
        FOREIGN KEY (attendance_id) REFERENCES attendances(id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        UNIQUE(attendance_id, student_id)
      )
    ''');

    // Index untuk performa query
    await db.execute(
        'CREATE INDEX idx_attendance_tanggal ON attendances(tanggal)');
    await db.execute(
        'CREATE INDEX idx_attendance_kelas ON attendances(kelas)');
    await db.execute(
        'CREATE INDEX idx_detail_attendance ON attendance_details(attendance_id)');
    await db.execute(
        'CREATE INDEX idx_detail_student ON attendance_details(student_id)');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}