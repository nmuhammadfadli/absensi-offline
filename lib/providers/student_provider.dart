import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/models/student_model.dart';
import '../data/repositories/student_repository.dart';

class StudentProvider with ChangeNotifier {
  final _repo = StudentRepository();

  List<Student> _students = [];
  List<String> _kelasList = [];
  String _selectedKelas = '';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Student> get students    => _students;
  List<String>  get kelasList   => _kelasList;
  String        get selectedKelas => _selectedKelas;
  bool          get isLoading   => _isLoading;
  String?       get error       => _error;

  // ── Load ────────────────────────────────────────────────────────────────

  Future<void> loadStudents() async {
    // Cegah double load & pastikan tidak memanggil notifyListeners
    // saat frame sedang dibangun — gunakan microtask
    if (_isLoading) return;

    _isLoading = true;
    // notifyListeners satu kali di awal, setelah frame selesai (aman)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final results = await Future.wait([
        _repo.getAll(
          kelas: _selectedKelas.isEmpty ? null : _selectedKelas,
          search: _searchQuery.isEmpty ? null : _searchQuery,
        ),
        _repo.getKelasOptions(),
      ]);

      _students  = results[0] as List<Student>;
      _kelasList = results[1] as List<String>;
      _error     = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // aman: dipanggil setelah await (di luar build)
    }
  }

  // ── CRUD ────────────────────────────────────────────────────────────────

  Future<bool> addStudent(Student student) async {
    try {
      await _repo.insert(student);
      await loadStudents();
      return true;
    } catch (e) {
      _error = 'NIS sudah terdaftar atau terjadi kesalahan';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStudent(Student student) async {
    try {
      await _repo.update(student);
      await loadStudents();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent(int id) async {
    try {
      await _repo.delete(id);
      await loadStudents();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Filter / Search ─────────────────────────────────────────────────────

  void setKelasFilter(String kelas) {
    if (_selectedKelas == kelas) return; // tidak perlu reload jika sama
    _selectedKelas = kelas;
    loadStudents();
  }

  void setSearch(String query) {
    _searchQuery = query;
    loadStudents();
  }

  // ── Error ────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}