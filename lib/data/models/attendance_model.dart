class Attendance {
  final int? id;
  final String tanggal; // format: 'yyyy-MM-dd'
  final String kelas;
  final String? catatan;
  final String createdAt;

  Attendance({
    this.id,
    required this.tanggal,
    required this.kelas,
    this.catatan,
    required this.createdAt,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      tanggal: map['tanggal'],
      kelas: map['kelas'],
      catatan: map['catatan'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tanggal': tanggal,
      'kelas': kelas,
      'catatan': catatan,
      'created_at': createdAt,
    };
  }
}