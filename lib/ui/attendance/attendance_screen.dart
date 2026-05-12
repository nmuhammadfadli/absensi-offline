import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/attendance_detail_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    // Pre-load kelas options
    context.read<StudentProvider>().loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Absensi')),
      body: Consumer2<AttendanceProvider, StudentProvider>(
        builder: (_, ap, sp, __) {
          return Column(
            children: [
              _buildDateKelasSelector(ap, sp),
              if (ap.selectedKelas.isNotEmpty) ...[
                Expanded(child: _buildStudentList(ap)),
                _buildSaveButton(ap),
              ] else
                const Expanded(
                  child: Center(
                    child: Text('Pilih kelas terlebih dahulu',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateKelasSelector(
      AttendanceProvider ap, StudentProvider sp) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date picker row
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'id').format(ap.selectedDate),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: ap.selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) ap.setDate(picked);
                },
                child: const Text('Ganti Tanggal'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Kelas dropdown
          DropdownButtonFormField<String>(
            value: ap.selectedKelas.isEmpty ? null : ap.selectedKelas,
            decoration: const InputDecoration(
              labelText: 'Pilih Kelas',
              filled: true,
              fillColor: Colors.white,
            ),
            hint: const Text('Pilih kelas'),
            items: sp.kelasList
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            onChanged: (v) {
              if (v != null) ap.setKelas(v);
            },
          ),
          if (ap.currentAttendance != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text('Data absensi sudah ada — dapat diedit',
                      style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentList(AttendanceProvider ap) {
    if (ap.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ap.currentDetails.isEmpty) {
      return const Center(child: Text('Tidak ada siswa di kelas ini'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      itemCount: ap.currentDetails.length,
      itemBuilder: (_, i) {
        final detail = ap.currentDetails[i];
        return _AttendanceRow(
          detail: detail,
          onChanged: (status) => ap.updateDetail(
            detail.studentId,
            status: status,
          ),
          onJamMasuk: (jam) =>
              ap.updateDetail(detail.studentId, jamMasuk: jam),
          onJamPulang: (jam) =>
              ap.updateDetail(detail.studentId, jamPulang: jam),
        );
      },
    );
  }

  Widget _buildSaveButton(AttendanceProvider ap) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton.icon(
        onPressed: ap.isSaving
            ? null
            : () async {
                final ok = await ap.saveAbsensi();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Absensi berhasil disimpan!'
                        : ap.error ?? 'Gagal menyimpan'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              },
        icon: ap.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save),
        label: const Text('Simpan Absensi'),
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final AttendanceDetail detail;
  final ValueChanged<AbsensiStatus> onChanged;
  final ValueChanged<String?> onJamMasuk;
  final ValueChanged<String?> onJamPulang;

  const _AttendanceRow({
    required this.detail,
    required this.onChanged,
    required this.onJamMasuk,
    required this.onJamPulang,
  });

  static const _statusColors = {
    AbsensiStatus.hadir: Colors.green,
    AbsensiStatus.izin: Colors.blue,
    AbsensiStatus.sakit: Colors.orange,
    AbsensiStatus.alfa: Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(detail.namaSiswa ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(detail.nisSiswa ?? '',
                    style: TextStyle(color: Colors.grey.shade600,
                        fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            // Status buttons
            Wrap(
              spacing: 6,
              children: AbsensiStatus.values.map((s) {
                final selected = detail.status == s;
                return ChoiceChip(
                  label: Text(s.label),
                  selected: selected,
                  selectedColor:
                      (_statusColors[s] ?? Colors.grey).withOpacity(0.2),
                  onSelected: (_) => onChanged(s),
                  side: BorderSide(
                    color: selected
                        ? (_statusColors[s] ?? Colors.grey)
                        : Colors.transparent,
                  ),
                );
              }).toList(),
            ),
            if (detail.status == AbsensiStatus.hadir) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Jam Masuk',
                      value: detail.jamMasuk,
                      onChanged: onJamMasuk,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeField(
                      label: 'Jam Pulang',
                      value: detail.jamPulang,
                      onChanged: onJamPulang,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _TimeField(
      {required this.label, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final parts = value?.split(':');
        final init = parts != null
            ? TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 7,
                minute: int.tryParse(parts[1]) ?? 0)
            : const TimeOfDay(hour: 7, minute: 0);
        final picked = await showTimePicker(
          context: context,
          initialTime: init,
        );
        if (picked != null) {
          onChanged(
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(value ?? label,
                style: TextStyle(
                    color: value != null ? Colors.black87 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}