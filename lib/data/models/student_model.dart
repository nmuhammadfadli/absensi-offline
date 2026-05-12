class Student {
  final int? id;
  final String nama;
  final String nis;
  final String kelas;
  final String jenisKelamin; // 'L' atau 'P'
  final String? noHpOrtu;
  final String? alamat;
  final bool isActive;
  final String createdAt;

  Student({
    this.id,
    required this.nama,
    required this.nis,
    required this.kelas,
    required this.jenisKelamin,
    this.noHpOrtu,
    this.alamat,
    this.isActive = true,
    required this.createdAt,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      nama: map['nama'],
      nis: map['nis'],
      kelas: map['kelas'],
      jenisKelamin: map['jenis_kelamin'],
      noHpOrtu: map['no_hp_ortu'],
      alamat: map['alamat'],
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'nis': nis,
      'kelas': kelas,
      'jenis_kelamin': jenisKelamin,
      'no_hp_ortu': noHpOrtu,
      'alamat': alamat,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  Student copyWith({
    int? id,
    String? nama,
    String? nis,
    String? kelas,
    String? jenisKelamin,
    String? noHpOrtu,
    String? alamat,
    bool? isActive,
    String? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nis: nis ?? this.nis,
      kelas: kelas ?? this.kelas,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      noHpOrtu: noHpOrtu ?? this.noHpOrtu,
      alamat: alamat ?? this.alamat,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}