import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/attendance_detail_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';
import 'attendance_detail_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String _selectedKelas = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Load history dan kelas options
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudentProvider>().loadStudents();
      context.read<AttendanceProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildActiveFilter(),
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  // ── Filter chip aktif ────────────────────────────────────────────────────

  Widget _buildActiveFilter() {
    final hasFilter =
        _selectedKelas.isNotEmpty || _startDate != null || _endDate != null;
    if (!hasFilter) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (_selectedKelas.isNotEmpty)
            _ActiveChip(
              label: 'Kelas: $_selectedKelas',
              onRemove: () => _applyFilter(kelas: ''),
            ),
          if (_startDate != null)
            _ActiveChip(
              label:
                  'Dari: ${DateFormat('dd/MM/yyyy').format(_startDate!)}',
              onRemove: () => _applyFilter(clearStart: true),
            ),
          if (_endDate != null)
            _ActiveChip(
              label: 'S/d: ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
              onRemove: () => _applyFilter(clearEnd: true),
            ),
          TextButton.icon(
            onPressed: _clearFilter,
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Reset', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // ── Daftar riwayat ───────────────────────────────────────────────────────

  Widget _buildHistoryList() {
    return Consumer<AttendanceProvider>(
      builder: (_, ap, __) {
        if (ap.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ap.history.isEmpty) {
          return const _EmptyHistory();
        }

        // Grup by bulan
        final grouped = _groupByMonth(ap.history);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: grouped.length,
          itemBuilder: (_, i) {
            final entry = grouped.entries.elementAt(i);
            return _MonthGroup(
              monthLabel: entry.key,
              items: entry.value,
              onTap: (att) => _openDetail(att),
            );
          },
        );
      },
    );
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  /// Kelompokkan list attendance berdasarkan "Bulan Tahun"
  Map<String, List<Attendance>> _groupByMonth(List<Attendance> list) {
    final map = <String, List<Attendance>>{};
    for (final att in list) {
      final dt = DateTime.parse(att.tanggal);
      final key = DateFormat('MMMM yyyy', 'id').format(dt);
      map.putIfAbsent(key, () => []).add(att);
    }
    return map;
  }

  void _openDetail(Attendance att) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceDetailScreen(attendance: att),
      ),
    );
  }

  // ── Filter bottom sheet ──────────────────────────────────────────────────

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        kelasList: context.read<StudentProvider>().kelasList,
        selectedKelas: _selectedKelas,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (kelas, start, end) {
          Navigator.pop(context);
          setState(() {
            _selectedKelas = kelas;
            _startDate = start;
            _endDate = end;
          });
          _loadFiltered();
        },
      ),
    );
  }

  void _applyFilter({String? kelas, bool clearStart = false, bool clearEnd = false}) {
    setState(() {
      if (kelas != null) _selectedKelas = kelas;
      if (clearStart) _startDate = null;
      if (clearEnd) _endDate = null;
    });
    _loadFiltered();
  }

  void _clearFilter() {
    setState(() {
      _selectedKelas = '';
      _startDate = null;
      _endDate = null;
    });
    context.read<AttendanceProvider>().loadHistory();
  }

  void _loadFiltered() {
    final fmt = DateFormat('yyyy-MM-dd');
    context.read<AttendanceProvider>().loadHistory(
          kelas: _selectedKelas.isEmpty ? null : _selectedKelas,
          start: _startDate != null ? fmt.format(_startDate!) : null,
          end: _endDate != null ? fmt.format(_endDate!) : null,
        );
  }
}

// ── Widget: Month Group ──────────────────────────────────────────────────────

class _MonthGroup extends StatelessWidget {
  final String monthLabel;
  final List<Attendance> items;
  final ValueChanged<Attendance> onTap;

  const _MonthGroup({
    required this.monthLabel,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            monthLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...items.map((att) => _HistoryTile(att: att, onTap: () => onTap(att))),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Widget: History Tile ─────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final Attendance att;
  final VoidCallback onTap;

  const _HistoryTile({required this.att, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(att.tanggal);
    final dayName = DateFormat('EEEE', 'id').format(dt);
    final dateStr = DateFormat('d MMMM yyyy', 'id').format(dt);
    final isWeekend = dt.weekday == DateTime.saturday ||
        dt.weekday == DateTime.sunday;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isWeekend
                ? Colors.orange.withOpacity(0.12)
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dt.day.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isWeekend
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                DateFormat('MMM', 'id').format(dt),
                style: TextStyle(
                  fontSize: 10,
                  color: isWeekend
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          '$dayName, $dateStr',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.class_, size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Kelas ${att.kelas}',
                style: const TextStyle(fontSize: 12)),
            if (att.catatan != null && att.catatan!.isNotEmpty) ...[
              const Text(' · ', style: TextStyle(color: Colors.grey)),
              Expanded(
                child: Text(
                  att.catatan!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

// ── Widget: Empty State ──────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat absensi',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai input absensi dari menu Absensi',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Active Filter Chip ───────────────────────────────────────────────

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── Widget: Filter Bottom Sheet ──────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final List<String> kelasList;
  final String selectedKelas;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(String kelas, DateTime? start, DateTime? end) onApply;

  const _FilterSheet({
    required this.kelasList,
    required this.selectedKelas,
    required this.startDate,
    required this.endDate,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _kelas;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _kelas = widget.selectedKelas;
    _start = widget.startDate;
    _end = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Filter Riwayat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),

          // Kelas
          DropdownButtonFormField<String>(
            value: _kelas.isEmpty ? null : _kelas,
            decoration: const InputDecoration(labelText: 'Kelas'),
            hint: const Text('Semua kelas'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Semua Kelas')),
              ...widget.kelasList
                  .map((k) => DropdownMenuItem(value: k, child: Text(k))),
            ],
            onChanged: (v) => setState(() => _kelas = v ?? ''),
          ),
          const SizedBox(height: 12),

          // Rentang tanggal
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Dari',
                  value: _start,
                  onPick: (d) => setState(() => _start = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'Sampai',
                  value: _end,
                  onPick: (d) => setState(() => _end = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: () => widget.onApply(_kelas, _start, _end),
            child: const Text('Terapkan Filter'),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Date Button ──────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  const _DateButton(
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
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(
        value != null
            ? DateFormat('dd/MM/yyyy').format(value!)
            : label,
        style: const TextStyle(fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
      ),
    );
  }
}