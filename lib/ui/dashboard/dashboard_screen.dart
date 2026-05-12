import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/student_provider.dart';
import '../students/student_list_screen.dart';
import '../students/student_recap_screen.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/attendance_history_screen.dart';
import '../export/export_pdf_screen.dart';
import '../backup/backup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudentProvider>().loadStudents();
      _fadeCtrl.forward();
      _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Greeting dinamis berdasarkan jam ────────────────────────────────────

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  IconData get _greetingIcon {
    final h = DateTime.now().hour;
    if (h < 11) return Icons.wb_sunny_rounded;
    if (h < 15) return Icons.light_mode_rounded;
    if (h < 18) return Icons.wb_twilight_rounded;
    return Icons.nights_stay_rounded;
  }

  String _dayName() {
    const d = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return d[DateTime.now().weekday % 7];
  }

  String _monthYear() {
    const m = [
      'Jan','Feb','Mar','Apr','Mei','Jun',
      'Jul','Agu','Sep','Okt','Nov','Des'
    ];
    final n = DateTime.now();
    return '${m[n.month - 1]} ${n.year}';
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    _buildStatRow(),
                    const SizedBox(height: 28),
                    _sectionLabel('Menu Utama'),
                    const SizedBox(height: 12),
                    _buildMenuGrid(),
                    const SizedBox(height: 28),
                    _sectionLabel('Aksi Cepat'),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sliver AppBar ────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1565C0),
      title: const Text(
        AppStrings.appName,
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _buildHeroBg(),
      ),
    );
  }

  Widget _buildHeroBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Dekorasi blob latar
          Positioned(
            right: -50, top: -50,
            child: _blob(180, Colors.white.withOpacity(0.06)),
          ),
          Positioned(
            right: 20, bottom: -30,
            child: _blob(110, Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            left: -30, bottom: 20,
            child: _blob(80, Colors.white.withOpacity(0.05)),
          ),
          // Konten
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_greetingIcon,
                              color: Colors.amber.shade300, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            _greeting,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Guru Wali Kelas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppStrings.namaSekolah,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Consumer<StudentProvider>(
                        builder: (_, sp, __) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${sp.students.length} siswa aktif',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Kotak tanggal
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_dayName(),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12)),
                      Text(
                        '${DateTime.now().day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      Text(_monthYear(),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // ── Stat Row ─────────────────────────────────────────────────────────────

  Widget _buildStatRow() {
    return Consumer<StudentProvider>(
      builder: (_, sp, __) => Row(
        children: [
          Expanded(
            child: _StatCard(
              value: sp.students.length.toString(),
              label: 'Total Siswa',
              icon: Icons.people_rounded,
              color: const Color(0xFF1565C0),
              bg: const Color(0xFFE3F2FD),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              value: sp.kelasList.length.toString(),
              label: 'Kelas Aktif',
              icon: Icons.class_rounded,
              color: const Color(0xFF2E7D32),
              bg: const Color(0xFFE8F5E9),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              value: '${DateTime.now().day}',
              label: _monthYear(),
              icon: Icons.today_rounded,
              color: const Color(0xFFE65100),
              bg: const Color(0xFFFFF3E0),
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu Grid ─────────────────────────────────────────────────────────────

  Widget _buildMenuGrid() {
    final menus = [
      _MenuData(
        icon: Icons.people_rounded,
        label: 'Data Siswa',
        subtitle: 'Kelola data siswa',
        color: const Color(0xFF1565C0),
        bg: const Color(0xFFE3F2FD),
        page: const StudentListScreen(),
      ),
      _MenuData(
        icon: Icons.fact_check_rounded,
        label: 'Absensi',
        subtitle: 'Input absensi harian',
        color: const Color(0xFF2E7D32),
        bg: const Color(0xFFE8F5E9),
        page: const AttendanceScreen(),
      ),
      _MenuData(
        icon: Icons.history_rounded,
        label: 'Riwayat',
        subtitle: 'Lihat riwayat absensi',
        color: const Color(0xFFE65100),
        bg: const Color(0xFFFFF3E0),
        page: const AttendanceHistoryScreen(),
      ),
      _MenuData(
        icon: Icons.bar_chart_rounded,
        label: 'Rekap Siswa',
        subtitle: 'Rekap kehadiran siswa',
        color: const Color(0xFF6A1B9A),
        bg: const Color(0xFFF3E5F5),
        page: const StudentRecapScreen(),
      ),
      _MenuData(
        icon: Icons.picture_as_pdf_rounded,
        label: 'Export PDF',
        subtitle: 'Generate laporan PDF',
        color: const Color(0xFFC62828),
        bg: const Color(0xFFFFEBEE),
        page: const ExportPdfScreen(),
      ),
      _MenuData(
        icon: Icons.backup_rounded,
        label: 'Backup & Restore',
        subtitle: 'Kelola backup data',
        color: const Color(0xFF00695C),
        bg: const Color(0xFFE0F2F1),
        page: const BackupScreen(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: menus.length,
      itemBuilder: (_, i) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 350 + (i * 80)),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, 18 * (1 - v)), child: child),
        ),
        child: _MenuCard(data: menus[i], onTap: () => _push(menus[i].page)),
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Column(
      children: [
        _QuickTile(
          icon: Icons.add_circle_rounded,
          iconColor: const Color(0xFF1565C0),
          bg: const Color(0xFFE3F2FD),
          title: 'Input Absensi Hari Ini',
          subtitle: 'Buka form absensi untuk tanggal hari ini',
          onTap: () => _push(const AttendanceScreen()),
        ),
        const SizedBox(height: 10),
        _QuickTile(
          icon: Icons.person_add_rounded,
          iconColor: const Color(0xFF2E7D32),
          bg: const Color(0xFFE8F5E9),
          title: 'Tambah Siswa Baru',
          subtitle: 'Daftarkan siswa baru ke dalam sistem',
          onTap: () => _push(const StudentListScreen()),
        ),
        const SizedBox(height: 10),
        _QuickTile(
          icon: Icons.picture_as_pdf_rounded,
          iconColor: const Color(0xFFC62828),
          bg: const Color(0xFFFFEBEE),
          title: 'Cetak Laporan PDF',
          subtitle: 'Export laporan absensi ke format PDF',
          onTap: () => _push(const ExportPdfScreen()),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A237E),
        ),
      );
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _MenuData {
  final IconData icon;
  final String label, subtitle;
  final Color color, bg;
  final Widget page;
  const _MenuData({
    required this.icon, required this.label, required this.subtitle,
    required this.color, required this.bg, required this.page,
  });
}

// Stat card
class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color, bg;
  const _StatCard({
    required this.value, required this.label,
    required this.icon, required this.color, required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// Menu card dengan press animation
class _MenuCard extends StatefulWidget {
  final _MenuData data;
  final VoidCallback onTap;
  const _MenuCard({required this.data, required this.onTap});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.data.color.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.data.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.data.icon,
                        color: widget.data.color, size: 22),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: widget.data.color.withOpacity(0.35)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF212121))),
                  const SizedBox(height: 2),
                  Text(widget.data.subtitle,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9E9E9E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quick action tile dengan press animation
class _QuickTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor, bg;
  final String title, subtitle;
  final VoidCallback onTap;
  const _QuickTile({
    required this.icon, required this.iconColor, required this.bg,
    required this.title, required this.subtitle, required this.onTap,
  });

  @override
  State<_QuickTile> createState() => _QuickTileState();
}

class _QuickTileState extends State<_QuickTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF212121))),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    color: widget.iconColor, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}