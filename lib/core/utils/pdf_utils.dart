import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/attendance_detail_model.dart';
import '../constants/app_strings.dart';

class PdfUtils {
  PdfUtils._();

  // ── Single date PDF ───────────────────────────────────────────────────────

  static Future<void> printAbsensi({
    required Attendance attendance,
    required List<AttendanceDetail> details,
  }) async {
    final pdf = await _buildSinglePdf(attendance, details);
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  static Future<pw.Document> _buildSinglePdf(
    Attendance attendance,
    List<AttendanceDetail> details,
  ) async {
    final pdf = pw.Document();
    final tanggal = DateFormat('EEEE, d MMMM yyyy', 'id')
        .format(DateTime.parse(attendance.tanggal));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => _header(tanggal, attendance.kelas),
        footer: (ctx) => _footer(ctx),
        build: (_) => [
          _summaryRow(details),
          pw.SizedBox(height: 12),
          _table(details),
        ],
      ),
    );
    return pdf;
  }

  // ── Multi date / range PDF ────────────────────────────────────────────────

  static Future<void> printRangePdf({
    required List<Attendance> attendances,
    required Map<int, List<AttendanceDetail>> detailsMap,
    String? kelas,
    String? startDate,
    String? endDate,
  }) async {
    final pdf = pw.Document();

    for (final att in attendances) {
      final details = detailsMap[att.id] ?? [];
      final tanggal = DateFormat('EEEE, d MMMM yyyy', 'id')
          .format(DateTime.parse(att.tanggal));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          header: (_) => _header(tanggal, att.kelas),
          footer: (ctx) => _footer(ctx),
          build: (_) => [
            _summaryRow(details),
            pw.SizedBox(height: 12),
            _table(details),
          ],
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  // ── Rekap per siswa PDF ───────────────────────────────────────────────────

  static Future<void> printRekapSiswa({
    required String namaSiswa,
    required String nisSiswa,
    required String kelas,
    required Map<String, int> rekap,
    String? startDate,
    String? endDate,
  }) async {
    final pdf = pw.Document();
    final total = rekap.values.fold(0, (a, b) => a + b);

    final periodeLabel = (startDate != null && endDate != null)
        ? '${DateFormat('d MMM yyyy', 'id').format(DateTime.parse(startDate))} '
          's/d ${DateFormat('d MMM yyyy', 'id').format(DateTime.parse(endDate))}'
        : 'Semua Periode';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Kop surat
            _schoolHeader(),
            pw.Divider(),
            pw.SizedBox(height: 8),

            pw.Text('Rekap Absensi Siswa',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 12),

            // Info siswa
            _infoRow('Nama Siswa', namaSiswa),
            _infoRow('NIS', nisSiswa),
            _infoRow('Kelas', kelas),
            _infoRow('Periode', periodeLabel),
            _infoRow('Total Pertemuan', '$total hari'),
            pw.SizedBox(height: 16),

            // Tabel rekap
            pw.TableHelper.fromTextArray(
              headers: ['Status', 'Jumlah', 'Persentase'],
              data: [
                ['Hadir',
                  '${rekap['hadir'] ?? 0}',
                  _persen(rekap['hadir'] ?? 0, total)],
                ['Izin',
                  '${rekap['izin'] ?? 0}',
                  _persen(rekap['izin'] ?? 0, total)],
                ['Sakit',
                  '${rekap['sakit'] ?? 0}',
                  _persen(rekap['sakit'] ?? 0, total)],
                ['Alfa',
                  '${rekap['alfa'] ?? 0}',
                  _persen(rekap['alfa'] ?? 0, total)],
              ],
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              cellStyle: const pw.TextStyle(fontSize: 11),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue100),
              cellAlignments: {
                1: pw.Alignment.center,
                2: pw.Alignment.center,
              },
            ),

            pw.SizedBox(height: 24),
            _signatureBlock(),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  // ── Building blocks ───────────────────────────────────────────────────────

  static pw.Widget _schoolHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(AppStrings.namaSekolah,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.Text(AppStrings.alamatSekolah,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(AppStrings.laporanAbsensi,
                style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _header(String tanggal, String kelas) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _schoolHeader(),
        pw.SizedBox(height: 6),
        pw.Divider(),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Text('Tanggal : ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text(tanggal, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(width: 24),
            pw.Text('Kelas : ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text(kelas, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              AppStrings.appName,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryRow(List<AttendanceDetail> details) {
    int hadir = 0, izin = 0, sakit = 0, alfa = 0;
    for (final d in details) {
      switch (d.status) {
        case AbsensiStatus.hadir: hadir++; break;
        case AbsensiStatus.izin:  izin++;  break;
        case AbsensiStatus.sakit: sakit++; break;
        case AbsensiStatus.alfa:  alfa++;  break;
      }
    }
    return pw.Row(
      children: [
        _summaryBox('Hadir', hadir, PdfColors.green100, PdfColors.green800),
        pw.SizedBox(width: 8),
        _summaryBox('Izin', izin, PdfColors.blue100, PdfColors.blue800),
        pw.SizedBox(width: 8),
        _summaryBox('Sakit', sakit, PdfColors.orange100, PdfColors.orange800),
        pw.SizedBox(width: 8),
        _summaryBox('Alfa', alfa, PdfColors.red100, PdfColors.red800),
        pw.SizedBox(width: 8),
        _summaryBox('Total', details.length, PdfColors.grey200, PdfColors.grey800),
      ],
    );
  }

  static pw.Widget _summaryBox(
      String label, int count, PdfColor bg, PdfColor fg) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              count.toString(),
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 16, color: fg),
            ),
            pw.Text(label,
                style: pw.TextStyle(fontSize: 9, color: fg)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _table(List<AttendanceDetail> details) {
    return pw.TableHelper.fromTextArray(
      headers: ['No', 'Nama Siswa', 'NIS', 'Status', 'Jam Masuk', 'Jam Pulang'],
      data: details.asMap().entries.map((e) {
        final d = e.value;
        return [
          '${e.key + 1}',
          d.namaSiswa ?? '-',
          d.nisSiswa ?? '-',
          d.status.label,
          d.jamMasuk ?? '-',
          d.jamPulang ?? '-',
        ];
      }).toList(),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColors.blue100),
      rowDecoration: const pw.BoxDecoration(),
      oddRowDecoration:
          const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignments: {
        0: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        3: const pw.FixedColumnWidth(48),
        4: const pw.FixedColumnWidth(56),
        5: const pw.FixedColumnWidth(56),
      },
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 11)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _signatureBlock() {
    final now = DateFormat('d MMMM yyyy', 'id').format(DateTime.now());
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          children: [
            pw.Text('Mengetahui, $now',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 50),
            pw.Container(
                width: 150, height: 1, color: PdfColors.grey600),
            pw.SizedBox(height: 4),
            pw.Text('Wali Kelas / Guru',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  // ── Util ─────────────────────────────────────────────────────────────────

  static String _persen(int value, int total) {
    if (total == 0) return '0%';
    return '${(value / total * 100).toStringAsFixed(1)}%';
  }
}