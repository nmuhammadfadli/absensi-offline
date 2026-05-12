import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/student_model.dart';
import '../../providers/student_provider.dart';

class StudentFormScreen extends StatefulWidget {
  final Student? student;
  const StudentFormScreen({super.key, this.student});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama, _nis, _kelas, _hp, _alamat;
  String _jenisKelamin = 'L';
  bool _isActive = true;

  bool get isEdit => widget.student != null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nama = TextEditingController(text: s?.nama);
    _nis = TextEditingController(text: s?.nis);
    _kelas = TextEditingController(text: s?.kelas);
    _hp = TextEditingController(text: s?.noHpOrtu);
    _alamat = TextEditingController(text: s?.alamat);
    if (s != null) {
      _jenisKelamin = s.jenisKelamin;
      _isActive = s.isActive;
    }
  }

  @override
  void dispose() {
    for (final c in [_nama, _nis, _kelas, _hp, _alamat]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(isEdit ? 'Edit Siswa' : 'Tambah Siswa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('Nama Siswa', _nama, required: true),
              const SizedBox(height: 12),
              _field('NIS', _nis, required: true),
              const SizedBox(height: 12),
              _field('Kelas', _kelas, required: true,
                  hint: 'Contoh: 7A, 8B, 9C'),
              const SizedBox(height: 12),
              _buildGenderField(),
              const SizedBox(height: 12),
              _field('No. HP Orang Tua', _hp,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _field('Alamat', _alamat, maxLines: 3),
              if (isEdit) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Status Aktif'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Siswa'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false,
      String? hint,
      int maxLines = 1,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? '$label wajib diisi' : null
          : null,
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Jenis Kelamin'),
        const SizedBox(height: 8),
        Row(
          children: [
            _GenderOption(
              label: 'Laki-laki',
              value: 'L',
              groupValue: _jenisKelamin,
              onChanged: (v) => setState(() => _jenisKelamin = v),
            ),
            const SizedBox(width: 16),
            _GenderOption(
              label: 'Perempuan',
              value: 'P',
              groupValue: _jenisKelamin,
              onChanged: (v) => setState(() => _jenisKelamin = v),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final student = Student(
      id: widget.student?.id,
      nama: _nama.text.trim(),
      nis: _nis.text.trim(),
      kelas: _kelas.text.trim(),
      jenisKelamin: _jenisKelamin,
      noHpOrtu: _hp.text.trim().isEmpty ? null : _hp.text.trim(),
      alamat: _alamat.text.trim().isEmpty ? null : _alamat.text.trim(),
      isActive: _isActive,
      createdAt: widget.student?.createdAt ?? DateTime.now().toIso8601String(),
    );

    final provider = context.read<StudentProvider>();
    final success = isEdit
        ? await provider.updateStudent(student)
        : await provider.addStudent(student);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isEdit
                ? 'Data siswa berhasil diperbarui'
                : 'Siswa berhasil ditambahkan'),
            backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.error ?? 'Terjadi kesalahan'),
            backgroundColor: Colors.red),
      );
    }
  }
}

class _GenderOption extends StatelessWidget {
  final String label, value, groupValue;
  final ValueChanged<String> onChanged;

  const _GenderOption(
      {required this.label,
      required this.value,
      required this.groupValue,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: (v) => onChanged(v!),
        ),
        Text(label),
      ],
    );
  }
}