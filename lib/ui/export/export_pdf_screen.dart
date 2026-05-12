import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/pdf_utils.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/attendance_detail_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';

class ExportPdfScreen extends StatefulWidget {
  const ExportPdfScreen({super.key});

  @override
  State<ExportPdfScreen> createState() => _ExportPdfScreenState();
}

class _ExportPdfScreenState extends State<ExportPdfScreen> {
  String _selectedKelas = '';
  DateTime? _startDate;
  DateTime? _endDate;
  _ExportMode _mode = _ExportMode.perTanggal;

  List<Attendance> _previewList = [];
  bool _isLoadingPreview = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Gunakan addPostFrameCallback agar notifyListeners() tidak dipanggil
    // saat widget tree sedang dalam proses build (mencegah setState during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StudentProvider>().loadStudents();
    });
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export PDF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModeSelector(),
            const SizedBox(height: 16),
            _buildFilterSection(),
            const SizedBox(height: 16),
            _buildPreviewSection(),
            const SizedBox(height: 24),
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  // ── Mode selector (tab-like) ─────────────────────────────────────────────

  Widget _buildModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mode Export',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            SegmentedButton<_ExportMode>(
              segments: const [
                ButtonSegment(
                  value: _ExportMode.perTanggal,
                  label: Text('Tanggal'),
                  icon: Icon(Icons.calendar_today, size: 16),
                ),
                ButtonSegment(
                  value: _ExportMode.perRentang,
                  label: Text('Rentang'),
                  icon: Icon(Icons.date_range, size: 16),
                ),
                ButtonSegment(
                  value: _ExportMode.perKelas,
                  label: Text('Per Kelas'),
                  icon: Icon(Icons.class_, size: 16),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) {
                setState(() {
                  _mode = s.first;
                  _previewList = [];
                  _startDate = null;
                  _endDate = null;
                });
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _modeDescription,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String get _modeDescription {
    switch (_mode) {
      case _ExportMode.perTanggal:
        return 'Export absensi untuk satu tanggal tertentu';
      case _ExportMode.perRentang:
        return 'Export semua absensi dalam rentang tanggal (multi halaman)';
      case _ExportMode.perKelas:
        return 'Export semua absensi untuk kelas tertentu';
    }
  }

  // ── Filter section ───────────────────────────────────────────────────────

  Widget _buildFilterSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),

            // Kelas (semua mode bisa filter kelas)
            Consumer<StudentProvider>(
              builder: (_, sp, __) => DropdownButtonFormField<String>(
                value: _selectedKelas.isEmpty ? null : _selectedKelas,
                decoration: const InputDecoration(
                  labelText: 'Kelas',
                  prefixIcon: Icon(Icons.class_),
                ),
                hint: const Text('Semua kelas'),
                items: [
                  const DropdownMenuItem(
                      value: '', child: Text('Semua Kelas')),
                  ...sp.kelasList.map(
                      (k) => DropdownMenuItem(value: k, child: Text(k))),
                ],
                onChanged: (v) => setState(() {
                  _selectedKelas = v ?? '';
                  _previewList = [];
                }),
              ),
            ),

            // Tanggal / Rentang
            if (_mode == _ExportMode.perTanggal) ...[
              const SizedBox(height: 12),
              _DatePickerField(
                label: 'Tanggal',
                value: _startDate,
                onPick: (d) => setState(() {
                  _startDate = d;
                  _endDate = d; // same day
                  _previewList = [];
                }),
              ),
            ] else if (_mode == _ExportMode.perRentang ||
                _mode == _ExportMode.perKelas) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Dari',
                      value: _startDate,
                      onPick: (d) => setState(() {
                        _startDate = d;
                        _previewList = [];
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Sampai',
                      value: _endDate,
                      onPick: (d) => setState(() {
                        _endDate = d;
                        _previewList = [];
                      }),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoadingPreview ? null : _loadPreview,
              icon: _isLoadingPreview
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search, size: 18),
              label: const Text('Cek Data'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Preview section ──────────────────────────────────────────────────────

  Widget _buildPreviewSection() {
    if (_isLoadingPreview) {
      return const LoadingState(message: 'Memuat data...');
    }
    if (_previewList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview_outlined,
                    size: 18, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Preview Data',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Chip(
                  label: Text('${_previewList.length} sesi'),
                  backgroundColor: Colors.green.shade50,
                  side: BorderSide(color: Colors.green.shade200),
                  labelStyle: const TextStyle(
                      color: Colors.green, fontSize: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Tampilkan maks 5 item preview
            ..._previewList.take(5).map((att) => _PreviewTile(att: att)),
            if (_previewList.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... dan ${_previewList.length - 5} sesi lainnya',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Generate button ──────────────────────────────────────────────────────

  Widget _buildGenerateButton() {
    final canGenerate = _previewList.isNotEmpty && !_isGenerating;
    return FilledButton.icon(
      onPressed: canGenerate ? _generate : null,
      icon: _isGenerating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.picture_as_pdf_rounded),
      label: Text(_isGenerating ? 'Membuat PDF...' : 'Generate & Print PDF'),
    );
  }

  // ── Logic ────────────────────────────────────────────────────────────────

  Future<void> _loadPreview() async {
    setState(() => _isLoadingPreview = true);

    final fmt = DateFormat('yyyy-MM-dd');
    await context.read<AttendanceProvider>().loadHistory(
          kelas: _selectedKelas.isEmpty ? null : _selectedKelas,
          start: _startDate != null ? fmt.format(_startDate!) : null,
          end: _endDate != null ? fmt.format(_endDate!) : null,
        );

    if (mounted) {
      setState(() {
        _previewList = context.read<AttendanceProvider>().history;
        _isLoadingPreview = false;
      });
    }
  }

  Future<void> _generate() async {
    if (_previewList.isEmpty) return;
    setState(() => _isGenerating = true);

    try {
      final ap = context.read<AttendanceProvider>();

      // Ambil semua details per attendance id
      final Map<int, List<AttendanceDetail>> detailsMap = {};
      for (final att in _previewList) {
        detailsMap[att.id!] = await ap.getDetailForId(att.id!);
      }

      await PdfUtils.printRangePdf(
        attendances: _previewList,
        detailsMap: detailsMap,
        kelas: _selectedKelas.isEmpty ? null : _selectedKelas,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

// ── Enum mode ────────────────────────────────────────────────────────────────

enum _ExportMode { perTanggal, perRentang, perKelas }

// ── Widgets ──────────────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  const _DatePickerField(
      {required this.label, this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onPick(d);
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value != null
              ? DateFormat('dd/MM/yyyy').format(value!)
              : 'Pilih tanggal',
          style: TextStyle(
            fontSize: 14,
            color: value != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final Attendance att;

  const _PreviewTile({required this.att});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(att.tanggal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.circle,
              size: 8, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            DateFormat('EEEE, d MMM yyyy', 'id').format(dt),
            style: const TextStyle(fontSize: 13),
          ),
          const Spacer(),
          Text(
            'Kelas ${att.kelas}',
            style:
                const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}