// Status absensi sebagai enum untuk type safety
enum AbsensiStatus { hadir, izin, sakit, alfa }

extension AbsensiStatusExt on AbsensiStatus {
  String get label {
    switch (this) {
      case AbsensiStatus.hadir: return 'Hadir';
      case AbsensiStatus.izin:  return 'Izin';
      case AbsensiStatus.sakit: return 'Sakit';
      case AbsensiStatus.alfa:  return 'Alfa';
    }
  }

  String get value => name; // 'hadir', 'izin', 'sakit', 'alfa'

  static AbsensiStatus fromString(String s) {
    return AbsensiStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => AbsensiStatus.alfa,
    );
  }
}

class AttendanceDetail {
  final int? id;
  final int attendanceId;
  final int studentId;
  final AbsensiStatus status;
  final String? jamMasuk;
  final String? jamPulang;
  final String? keterangan;

  // Join field (dari query JOIN)
  final String? namaSiswa;
  final String? nisSiswa;

  AttendanceDetail({
    this.id,
    required this.attendanceId,
    required this.studentId,
    required this.status,
    this.jamMasuk,
    this.jamPulang,
    this.keterangan,
    this.namaSiswa,
    this.nisSiswa,
  });

  factory AttendanceDetail.fromMap(Map<String, dynamic> map) {
    return AttendanceDetail(
      id: map['id'],
      attendanceId: map['attendance_id'],
      studentId: map['student_id'],
      status: AbsensiStatusExt.fromString(map['status'] ?? 'alfa'),
      jamMasuk: map['jam_masuk'],
      jamPulang: map['jam_pulang'],
      keterangan: map['keterangan'],
      namaSiswa: map['nama'],
      nisSiswa: map['nis'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'attendance_id': attendanceId,
      'student_id': studentId,
      'status': status.value,
      'jam_masuk': jamMasuk,
      'jam_pulang': jamPulang,
      'keterangan': keterangan,
    };
  }

  AttendanceDetail copyWith({
    AbsensiStatus? status,
    String? jamMasuk,
    String? jamPulang,
    String? keterangan,
  }) {
    return AttendanceDetail(
      id: id,
      attendanceId: attendanceId,
      studentId: studentId,
      status: status ?? this.status,
      jamMasuk: jamMasuk ?? this.jamMasuk,
      jamPulang: jamPulang ?? this.jamPulang,
      keterangan: keterangan ?? this.keterangan,
      namaSiswa: namaSiswa,
      nisSiswa: nisSiswa,
    );
  }
}