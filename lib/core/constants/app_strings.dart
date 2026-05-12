class AppStrings {
  AppStrings._();

  // ── App ──────────────────────────────────────────────────────────────────
  static const appName       = 'Absensi Siswa';
  static const appTagline    = 'Sistem Absensi Offline';
  static const namaSekolah   = 'TPA Widya Mandala';
  static const alamatSekolah = 'PERUM KEMBANG PERMAI 36 RT 26 RW 09';

  // ── Dashboard ────────────────────────────────────────────────────────────
  static const dashboard    = 'Dashboard';
  static const selamatDatang = 'Selamat Datang!';
  static const pilihMenu    = 'Pilih menu yang ingin digunakan';
  static const menuSiswa    = 'Data Siswa';
  static const menuAbsensi  = 'Absensi';
  static const menuRiwayat  = 'Riwayat';
  static const menuExport   = 'Export PDF';

  // ── Siswa ────────────────────────────────────────────────────────────────
  static const dataSiswa      = 'Data Siswa';
  static const tambahSiswa    = 'Tambah Siswa';
  static const editSiswa      = 'Edit Siswa';
  static const hapusSiswa     = 'Hapus Siswa';
  static const cariSiswa      = 'Cari nama atau NIS...';
  static const semuaKelas     = 'Semua Kelas';
  static const belumAdaSiswa  = 'Belum ada data siswa';
  static const mulaiTambah    = 'Tambahkan siswa pertama Anda';

  static const fieldNama      = 'Nama Siswa';
  static const fieldNis       = 'NIS';
  static const fieldKelas     = 'Kelas';
  static const fieldJk        = 'Jenis Kelamin';
  static const fieldHp        = 'No. HP Orang Tua';
  static const fieldAlamat    = 'Alamat';
  static const fieldStatus    = 'Status Aktif';
  static const hintKelas      = 'Contoh: 7A, 8B, 9C';
  static const lakiLaki       = 'Laki-laki';
  static const perempuan      = 'Perempuan';

  static const simpanPerubahan = 'Simpan Perubahan';
  static const konfirmasiHapus = 'Yakin ingin menghapus siswa ini?';
  static const batalkan        = 'Batal';
  static const hapus           = 'Hapus';

  // ── Absensi ──────────────────────────────────────────────────────────────
  static const inputAbsensi     = 'Input Absensi';
  static const pilihKelas       = 'Pilih Kelas';
  static const pilihTanggal     = 'Pilih Tanggal';
  static const gantiTanggal     = 'Ganti Tanggal';
  static const simpanAbsensi    = 'Simpan Absensi';
  static const absensiSudahAda  = 'Data absensi sudah ada — dapat diedit';
  static const pilihKelasDulu   = 'Pilih kelas terlebih dahulu';
  static const tidakAdaSiswa    = 'Tidak ada siswa di kelas ini';

  static const statusHadir = 'Hadir';
  static const statusIzin  = 'Izin';
  static const statusSakit = 'Sakit';
  static const statusAlfa  = 'Alfa';

  static const jamMasuk  = 'Jam Masuk';
  static const jamPulang = 'Jam Pulang';

  // ── Riwayat ──────────────────────────────────────────────────────────────
  static const riwayatAbsensi   = 'Riwayat Absensi';
  static const belumAdaRiwayat  = 'Belum ada riwayat absensi';
  static const mulaiInputAbsensi = 'Mulai input absensi dari menu Absensi';
  static const filterRiwayat    = 'Filter Riwayat';
  static const terapkanFilter   = 'Terapkan Filter';
  static const resetFilter      = 'Reset';
  static const dariTanggal      = 'Dari';
  static const sampaiTanggal    = 'Sampai';

  // ── Detail ───────────────────────────────────────────────────────────────
  static const detailAbsensi = 'Detail Absensi';
  static const rekap         = 'Rekap';

  // ── PDF ──────────────────────────────────────────────────────────────────
  static const exportPdf     = 'Export PDF';
  static const filterLaporan = 'Filter Laporan';
  static const generatePdf   = 'Generate & Print PDF';
  static const tidakAdaData  = 'Tidak ada data absensi';
  static const laporanAbsensi = 'Laporan Absensi Siswa';

  // ── Validasi ─────────────────────────────────────────────────────────────
  static String wajibDiisi(String field) => '$field wajib diisi';
  static const nisDuplikat = 'NIS sudah terdaftar';

  // ── Snackbar ─────────────────────────────────────────────────────────────
  static const berhasilTambah   = 'Siswa berhasil ditambahkan';
  static const berhasilUpdate   = 'Data siswa berhasil diperbarui';
  static const berhasilHapus    = 'Siswa berhasil dihapus';
  static const berhasilSimpan   = 'Absensi berhasil disimpan!';
  static const gagalSimpan      = 'Gagal menyimpan absensi';
  static const terjadiKesalahan = 'Terjadi kesalahan';
}