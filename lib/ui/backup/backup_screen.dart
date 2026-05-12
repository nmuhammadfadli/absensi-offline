import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/services/backup_service.dart';
import '../../providers/backup_provider.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BackupProvider>().init();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: _buildAppBar(),
      body: Consumer<BackupProvider>(
        builder: (_, bp, __) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStorageInfo(bp),
                    const SizedBox(height: 20),
                    _buildBackupCard(bp),
                    const SizedBox(height: 20),
                    _buildBackupList(bp),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Backup & Restore'),
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Consumer<BackupProvider>(
          builder: (_, bp, __) => IconButton(
            icon: bp.status == BackupStatus.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed:
                bp.isLoading ? null : () => bp.loadBackups(),
          ),
        ),
      ],
    );
  }

  // ── Storage info banner ───────────────────────────────────────────────────

  Widget _buildStorageInfo(BackupProvider bp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ikon animasi pulse
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storage_rounded,
                  color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Folder Backup',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bp.backupDirPath.isEmpty
                      ? 'Memuat...'
                      : bp.backupDirPath,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _InfoPill(
                      icon: Icons.folder_rounded,
                      label: '${bp.backups.length} file backup',
                    ),
                    if (bp.backups.isNotEmpty)
                      _InfoPill(
                        icon: Icons.access_time_rounded,
                        label: 'Terakhir: ${bp.backups.first.dateLabel}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Backup card ───────────────────────────────────────────────────────────

  Widget _buildBackupCard(BackupProvider bp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.backup_rounded,
                    color: Color(0xFF1565C0), size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Buat Backup Baru',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Salin database ke folder AbsensiBackup di penyimpanan HP. '
            'File dapat dipindahkan ke perangkat lain untuk restore data.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Tombol Backup
          _ActionButton(
            label: 'Backup Sekarang',
            icon: Icons.cloud_upload_rounded,
            color: const Color(0xFF1565C0),
            isLoading:
                bp.status == BackupStatus.loading && !bp.isRestoring,
            onTap: () => _doBackup(bp),
          ),
        ],
      ),
    );
  }

  // ── Daftar backup ─────────────────────────────────────────────────────────

  Widget _buildBackupList(BackupProvider bp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Text(
              'Riwayat Backup',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const Spacer(),
            if (bp.backups.isNotEmpty)
              Text(
                '${bp.backups.length} file',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // List
        if (bp.status == BackupStatus.loading && bp.backups.isEmpty)
          const _LoadingList()
        else if (bp.backups.isEmpty)
          _buildEmptyBackup()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bp.backups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              // Stagger animasi
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + i * 60),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - v)),
                    child: child,
                  ),
                ),
                child: _BackupTile(
                  file: bp.backups[i],
                  isFirst: i == 0,
                  onRestore: () => _confirmRestore(bp, bp.backups[i]),
                  onDelete: () => _confirmDelete(bp, bp.backups[i]),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyBackup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.grey.shade200, width: 1.5,
            style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Belum ada backup',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tekan tombol "Backup Sekarang" untuk\nmembuat backup pertama Anda',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _doBackup(BackupProvider bp) async {
    HapticFeedback.mediumImpact();
    final result = await bp.doBackup();
    if (!mounted) return;
    _showResultSnack(result);
  }

  void _confirmRestore(BackupProvider bp, BackupFile file) {
    showDialog(
      context: context,
      builder: (_) => _RestoreDialog(
        file: file,
        onConfirm: () async {
          Navigator.pop(context);
          HapticFeedback.heavyImpact();
          final result = await bp.doRestore(file.path);
          if (!mounted) return;
          _showResultSnack(result);
          if (result.success) _showRestartDialog();
        },
      ),
    );
  }

  void _confirmDelete(BackupProvider bp, BackupFile file) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Backup'),
        content: Text(
          'Hapus file "${file.fileName}"?\n\nFile yang sudah dihapus tidak dapat dipulihkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await bp.doDelete(file.path);
              if (mounted) _showResultSnack(result);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle_rounded,
            color: Colors.green, size: 48),
        title: const Text('Restore Berhasil'),
        content: const Text(
          'Data berhasil dipulihkan dari backup.\n\n'
          'Tutup dan buka kembali aplikasi agar perubahan berlaku.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop(); // tutup app
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Tutup Aplikasi'),
          ),
        ],
      ),
    );
  }

  void _showResultSnack(BackupResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(result.message,
                    style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor:
            result.success ? const Color(0xFF2E7D32) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// ── Widget: BackupTile ────────────────────────────────────────────────────────

class _BackupTile extends StatefulWidget {
  final BackupFile file;
  final bool isFirst;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _BackupTile({
    required this.file,
    required this.isFirst,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  State<_BackupTile> createState() => _BackupTileState();
}

class _BackupTileState extends State<_BackupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: widget.isFirst
            ? Border.all(
                color: const Color(0xFF1565C0).withOpacity(0.3),
                width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: widget.isFirst
                ? const Color(0xFF1565C0).withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: widget.isFirst ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header tile
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Ikon file db
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.isFirst
                          ? const Color(0xFFE3F2FD)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.dataset_rounded,
                      color: widget.isFirst
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.isFirst) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'TERBARU',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                widget.file.fileName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: widget.isFirst
                                      ? const Color(0xFF1565C0)
                                      : const Color(0xFF212121),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.file.dateLabel,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.data_usage,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              widget.file.sizeLabel,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Expanded action buttons
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Restore',
                      icon: Icons.restore_rounded,
                      color: const Color(0xFF2E7D32),
                      isLoading: false,
                      onTap: widget.onRestore,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: 'Hapus',
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red,
                      isLoading: false,
                      onTap: widget.onDelete,
                      compact: true,
                      outlined: true,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ── Widget: RestoreDialog ─────────────────────────────────────────────────────

class _RestoreDialog extends StatelessWidget {
  final BackupFile file;
  final VoidCallback onConfirm;

  const _RestoreDialog({required this.file, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header merah
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E0),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restore_rounded,
                      color: Colors.orange, size: 36),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Restore Database',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFE65100)),
                ),
              ],
            ),
          ),
          // Konten
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Info file
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.dataset_rounded,
                          color: Colors.grey, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(file.fileName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                            Text(
                              '${file.dateLabel}  ·  ${file.sizeLabel}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Data saat ini akan ditimpa. '
                          'Proses ini tidak dapat dibatalkan.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onConfirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: const Text('Restore'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: ActionButton ──────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;
  final bool compact;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
    this.compact = false,
    this.outlined = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: widget.compact ? 42 : 50,
          decoration: BoxDecoration(
            color: widget.outlined
                ? Colors.transparent
                : (widget.isLoading
                    ? widget.color.withOpacity(0.6)
                    : widget.color),
            borderRadius: BorderRadius.circular(12),
            border: widget.outlined
                ? Border.all(color: widget.color, width: 1.5)
                : null,
            boxShadow: widget.outlined
                ? null
                : [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.outlined ? widget.color : Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        size: 18,
                        color: widget.outlined ? widget.color : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: widget.compact ? 13 : 14,
                          color:
                              widget.outlined ? widget.color : Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Widget: InfoPill ──────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ── Widget: LoadingList ───────────────────────────────────────────────────────

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}