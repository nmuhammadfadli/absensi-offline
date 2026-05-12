import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../data/models/student_model.dart';
import 'student_form_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<StudentProvider>().loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Siswa')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Siswa'),
      ),
      body: Column(
        children: [
          _buildSearchFilter(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Consumer<StudentProvider>(
      builder: (_, p, __) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Cari nama atau NIS...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => p.setSearch(v),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _KelasChip(
                    label: 'Semua',
                    selected: p.selectedKelas.isEmpty,
                    onTap: () => p.setKelasFilter(''),
                  ),
                  ...p.kelasList.map((k) => _KelasChip(
                        label: k,
                        selected: p.selectedKelas == k,
                        onTap: () => p.setKelasFilter(k),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<StudentProvider>(
      builder: (_, p, __) {
        if (p.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (p.students.isEmpty) {
          return const Center(child: Text('Belum ada data siswa'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
          itemCount: p.students.length,
          itemBuilder: (_, i) => _StudentTile(
            student: p.students[i],
            onEdit: () => _openForm(context, student: p.students[i]),
            onDelete: () => _confirmDelete(context, p.students[i]),
          ),
        );
      },
    );
  }

  void _openForm(BuildContext context, {Student? student}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormScreen(student: student),
      ),
    ).then((_) => context.read<StudentProvider>().loadStudents());
  }

  void _confirmDelete(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: Text('Hapus ${student.nama}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<StudentProvider>().deleteStudent(student.id!);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(0, 40)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentTile(
      {required this.student, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Colors.blue,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            icon: Icons.delete,
            label: 'Hapus',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: student.jenisKelamin == 'L'
                ? Colors.blue.shade100
                : Colors.pink.shade100,
            child: Text(
              student.nama.isNotEmpty ? student.nama[0].toUpperCase() : '?',
              style: TextStyle(
                  color: student.jenisKelamin == 'L'
                      ? Colors.blue
                      : Colors.pink,
                  fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(student.nama,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('NIS: ${student.nis} · ${student.kelas}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onEdit,
        ),
      ),
    );
  }
}

class _KelasChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _KelasChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}