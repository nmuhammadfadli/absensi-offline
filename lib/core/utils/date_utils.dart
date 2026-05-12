import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  // ── Format ───────────────────────────────────────────────────────────────

  /// yyyy-MM-dd  →  untuk simpan ke SQLite
  static String toDbDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  /// DateTime  →  '7 Mei 2025'
  static String toReadable(DateTime dt) =>
      DateFormat('d MMMM yyyy', 'id').format(dt);

  /// DateTime  →  'Selasa, 7 Mei 2025'
  static String toLongReadable(DateTime dt) =>
      DateFormat('EEEE, d MMMM yyyy', 'id').format(dt);

  /// DateTime  →  'Mei 2025'
  static String toMonthYear(DateTime dt) =>
      DateFormat('MMMM yyyy', 'id').format(dt);

  /// DateTime  →  '07/05/2025'
  static String toShort(DateTime dt) =>
      DateFormat('dd/MM/yyyy').format(dt);

  /// DateTime  →  '07:30'
  static String toTimeStr(DateTime dt) =>
      DateFormat('HH:mm').format(dt);

  /// 'yyyy-MM-dd' string  →  DateTime
  static DateTime fromDbDate(String s) => DateTime.parse(s);

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Apakah tanggal adalah hari ini?
  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Apakah weekend?
  static bool isWeekend(DateTime dt) =>
      dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;

  /// Ambil list hari dalam satu bulan
  static List<DateTime> daysInMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    return List.generate(
      last.day,
      (i) => DateTime(year, month, i + 1),
    );
  }

  /// Range string untuk label filter
  /// Contoh: '1 Jan – 31 Jan 2025'
  static String rangeLabel(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} – ${DateFormat('d MMM yyyy', 'id').format(end)}';
    }
    return '${DateFormat('d MMM', 'id').format(start)} – '
        '${DateFormat('d MMM yyyy', 'id').format(end)}';
  }

  /// Konversi TimeOfDay ke string 'HH:mm'
  static String timeOfDayToStr(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Parse string 'HH:mm' ke map {hour, minute}
  static Map<String, int>? parseTimeStr(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    return {
      'hour': int.tryParse(parts[0]) ?? 0,
      'minute': int.tryParse(parts[1]) ?? 0,
    };
  }
}