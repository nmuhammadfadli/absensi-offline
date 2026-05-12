import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/pdf_utils.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/attendance_detail_model.dart';
import '../../providers/attendance_provider.dart';
import 'attendance_screen.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final Attendance attendance;

  const AttendanceDetailScreen({super.key, required this.attendance});

  @override
  State<AttendanceDetailScreen> createState() =>
      _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  List<AttendanceDetail> _details = [];
  bool _isLoading = true;

  // Warna per status
  static const _statusColor = {
    AbsensiStatus.hadir: Color(0xFF2E7D32),  // green-800
    AbsensiStatus.izin:  Color(0xFF1565C0),  // blue-800
    AbsensiStatus.sakit: Color(0xFFE65100),  // orange-900
    AbsensiStatus.alfa:  Color(0xFFC62828),  // red-800
  };

  static const _statusBg = {
    AbsensiStatus.hadir: Color(0xFFE8F5E9),
    AbsensiStatus.izin:  Color(0xFFE3F2FD),
    AbsensiStatus.sakit: Color(0xFFFFF3E0),
    AbsensiStatus.alfa:  Color(0xFFFFEBEE),
  };

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final details = await context
        .read<AttendanceProvider>()
        .getDetailForId(widget.attendance.id!);
    setState(() {
      _details = details;
      _isLoading = false;
    });
  }

  // ── Summary count ────────────────────────────────────────────────────────

  Map<AbsensiStatus, int> get _summary {
    final m = {
      for (final s in AbsensiStatus.values) s: 0,
    };
    for (final d in _details) {
      m[d.status] = (m[d.status] ?? 0) + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final att = widget.attendance;
    final dt = DateTime.parse(att.tanggal);
    final tanggalStr =
        DateFormat('EEEE, d MMMM yyyy', 'id').format(dt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Absensi'),
        actions: [
          // Tombol edit — kembali ke AttendanceScreen dengan date & kelas terisi
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit absensi ini',
            onPressed: _editAbsensi,
          ),
          // Tombol print PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: _isLoading ? null : _exportPdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(tanggalStr, att.kelas),
                ),
                SliverToBoxAdapter(
                  child: _buildSummaryBar(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _DetailTile(
                        detail: _details[i],
                        statusColor: _statusColor,
                        statusBg: _statusBg,
                      ),
                      childCount: _details.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(String tanggalStr, String kelas) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 6),
              Text(
                tanggalStr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.class_,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 6),
              Text(
                'Kelas $kelas',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              Text(
                '${_details.length} siswa',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Summary bar (H / I / S / A) ──────────────────────────────────────────

  Widget _buildSummaryBar() {
    final s = _summary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: AbsensiStatus.values.map((status) {
          return Expanded(
            child: _SummaryCard(
              label: status.label,
              count: s[status] ?? 0,
              color: _statusColor[status]!,
              bg: _statusBg[status]!,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _editAbsensi() {
    final ap = context.read<AttendanceProvider>();
    // Set date & kelas di provider, lalu buka AttendanceScreen
    ap.setDate(DateTime.parse(widget.attendance.tanggal));
    ap.setKelas(widget.attendance.kelas);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AttendanceScreen()),
    ).then((_) => _loadDetails()); // Refresh setelah kembali
  }

  Future<void> _exportPdf() async {
    await PdfUtils.printAbsensi(
      attendance: widget.attendance,
      details: _details,
    );
  }
}

// ── Widget: Summary Card ─────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bg;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Detail Tile ──────────────────────────────────────────────────────

class _DetailTile extends StatelessWidget {
  final AttendanceDetail detail;
  final Map<AbsensiStatus, Color> statusColor;
  final Map<AbsensiStatus, Color> statusBg;

  const _DetailTile({
    required this.detail,
    required this.statusColor,
    required this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor[detail.status] ?? Colors.grey;
    final bg = statusBg[detail.status] ?? Colors.grey.shade100;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Avatar inisial
            CircleAvatar(
              radius: 18,
              backgroundColor: bg,
              child: Text(
                (detail.namaSiswa ?? '?')[0].toUpperCase(),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),

            // Nama & NIS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.namaSiswa ?? '-',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        detail.nisSiswa ?? '-',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                      if (detail.jamMasuk != null) ...[
                        const Text('  ·  ',
                            style: TextStyle(color: Colors.grey)),
                        const Icon(Icons.login,
                            size: 11, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(detail.jamMasuk!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                      if (detail.jamPulang != null) ...[
                        const Text('  →  ',
                            style: TextStyle(color: Colors.grey)),
                        const Icon(Icons.logout,
                            size: 11, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(detail.jamPulang!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Badge status
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                detail.status.label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}