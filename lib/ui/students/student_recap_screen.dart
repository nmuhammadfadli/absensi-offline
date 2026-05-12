import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/pdf_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/student_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';

class StudentRecapScreen extends StatefulWidget {
  const StudentRecapScreen({super.key});

  @override
  State<StudentRecapScreen> createState() => _StudentRecapScreenState();
}

class _StudentRecapScreenState extends State<StudentRecapScreen> {
  Student? _selectedStudent;
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, int>? _rekap;
  bool _isLoading = false;
  bool _isPrinting = false;

  // Warna per status
  static const _statusItems = [
    _StatusItem('Hadir',  Color(0xFF2E7D32), Color(0xFFE8F5E9), Icons.check_circle_outline),
    _StatusItem('Izin',   Color(0xFF1565C0), Color(0xFFE3F2FD), Icons.info_outline),
    _StatusItem('Sakit',  Color(0xFFE65100), Color(0xFFFFF3E0), Icons.local_hospital_outlined),
    _StatusItem('Alfa',   Color(0xFFC62828), Color(0xFFFFEBEE), Icons.cancel_outlined),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StudentProvider>().loadStudents();
    });
  }

  Future<void> _loadRekap() async {
    if (_selectedStudent == null) return;
    setState(() => _isLoading = true);

    final fmt = DateFormat('yyyy-MM-dd');
    final result = await context.read<AttendanceProvider>().getRekapSiswa(
          _selectedStudent!.id!,
          start: _startDate != null ? fmt.format(_startDate!) : null,
          end: _endDate != null ? fmt.format(_endDate!) : null,
        );

    setState(() {
      _rekap = result;
      _isLoading = false;
    });
  }

  int get _total => _rekap == null
      ? 0
      : _rekap!.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Absensi Siswa'),
        actions: [
          if (_rekap != null && _total > 0)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF',
              onPressed: _isPrinting ? null : _exportPdf,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentSelector(),
            const SizedBox(height: 12),
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            if (_isLoading)
              const LoadingState(message: 'Memuat rekap...')
            else if (_rekap == null)
              const EmptyState(
                icon: Icons.bar_chart_outlined,
                title: 'Pilih siswa untuk melihat rekap',
                subtitle: 'Rekap menampilkan total kehadiran siswa',
              )
            else if (_total == 0)
              const EmptyState(
                icon: Icons.assignment_outlined,
                title: 'Belum ada data absensi',
                subtitle: 'Belum ada absensi tercatat untuk siswa dan periode ini',
              )
            else ...[
              _buildSummaryCards(),
              const SizedBox(height: 16),
              _buildDetailBars(),
              const SizedBox(height: 16),
              _buildPercentageSummary(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Student Selector ─────────────────────────────────────────────────────

  Widget _buildStudentSelector() {
    return Consumer<StudentProvider>(
      builder: (_, sp, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Siswa',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Student>(
              value: _selectedStudent,
              decoration: const InputDecoration(
                hintText: 'Pilih siswa...',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: sp.students
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.nama} — ${s.kelas}',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (s) {
                setState(() {
                  _selectedStudent = s;
                  _rekap = null;
                });
                if (s != null) _loadRekap();
              },
            ),
            if (_selectedStudent != null) ...[
              const SizedBox(height: 8),
              _StudentInfoCard(student: _selectedStudent!),
            ],
          ],
        );
      },
    );
  }

  // ── Period Selector ──────────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Periode',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DatePickerBtn(
                label: 'Dari',
                value: _startDate,
                onPick: (d) {
                  setState(() => _startDate = d);
                  _loadRekap();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DatePickerBtn(
                label: 'Sampai',
                value: _endDate,
                onPick: (d) {
                  setState(() => _endDate = d);
                  _loadRekap();
                },
              ),
            ),
            if (_startDate != null || _endDate != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _loadRekap();
                },
                icon: const Icon(Icons.clear, size: 20),
                tooltip: 'Reset periode',
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
        if (_startDate != null && _endDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              AppDateUtils.rangeLabel(_startDate!, _endDate!),
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary),
            ),
          ),
      ],
    );
  }

  // ── Summary Cards ────────────────────────────────────────────────────────

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Ringkasan',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_total hari',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: _statusItems.map((item) {
            final count = _rekap![item.key.toLowerCase()] ?? 0;
            return _RekapCard(item: item, count: count, total: _total);
          }).toList(),
        ),
      ],
    );
  }

  // ── Progress Bars ────────────────────────────────────────────────────────

  Widget _buildDetailBars() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distribusi Kehadiran',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 16),
            ..._statusItems.map((item) {
              final count = _rekap![item.key.toLowerCase()] ?? 0;
              final persen = _total == 0 ? 0.0 : count / _total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, color: item.color, size: 16),
                        const SizedBox(width: 6),
                        Text(item.key,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(
                          '$count hari (${(persen * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: persen,
                        backgroundColor: item.bg,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(item.color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Percentage Summary ───────────────────────────────────────────────────

  Widget _buildPercentageSummary() {
    final hadir = _rekap!['hadir'] ?? 0;
    final persenHadir =
        _total == 0 ? 0.0 : (hadir / _total * 100);
    final isLulus = persenHadir >= 75;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isLulus ? Icons.verified_outlined : Icons.warning_amber_outlined,
              color: isLulus ? Colors.green : Colors.orange,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLulus ? 'Kehadiran Mencukupi' : 'Kehadiran Kurang',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLulus ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Persentase hadir: ${persenHadir.toStringAsFixed(1)}% '
                    '(min. 75%)',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    if (_selectedStudent == null || _rekap == null) return;
    setState(() => _isPrinting = true);
    final fmt = DateFormat('yyyy-MM-dd');
    await PdfUtils.printRekapSiswa(
      namaSiswa: _selectedStudent!.nama,
      nisSiswa: _selectedStudent!.nis,
      kelas: _selectedStudent!.kelas,
      rekap: _rekap!,
      startDate: _startDate != null ? fmt.format(_startDate!) : null,
      endDate: _endDate != null ? fmt.format(_endDate!) : null,
    );
    if (mounted) setState(() => _isPrinting = false);
  }
}

// ── Helper data class ────────────────────────────────────────────────────────

class _StatusItem {
  final String key;
  final Color color;
  final Color bg;
  final IconData icon;

  const _StatusItem(this.key, this.color, this.bg, this.icon);
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _StudentInfoCard extends StatelessWidget {
  final Student student;

  const _StudentInfoCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: student.jenisKelamin == 'L'
                ? const Color(0xFFE3F2FD)
                : const Color(0xFFFCE4EC),
            child: Text(
              student.nama[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: student.jenisKelamin == 'L'
                    ? const Color(0xFF1565C0)
                    : const Color(0xFFAD1457),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.nama,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                'NIS: ${student.nis}  ·  Kelas ${student.kelas}',
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RekapCard extends StatelessWidget {
  final _StatusItem item;
  final int count;
  final int total;

  const _RekapCard(
      {required this.item, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final persen =
        total == 0 ? '0%' : '${(count / total * 100).toStringAsFixed(1)}%';

    return Container(
      decoration: BoxDecoration(
        color: item.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(item.icon, color: item.color, size: 18),
              const Spacer(),
              Text(persen,
                  style: TextStyle(
                      fontSize: 11,
                      color: item.color.withOpacity(0.8))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: item.color,
            ),
          ),
          Text(
            item.key,
            style: TextStyle(
                fontSize: 12,
                color: item.color,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _DatePickerBtn extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  const _DatePickerBtn(
      {required this.label, this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onPick(d);
      },
      icon: const Icon(Icons.calendar_today, size: 15),
      label: Text(
        value != null
            ? DateFormat('dd/MM/yy').format(value!)
            : label,
        style: const TextStyle(fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}