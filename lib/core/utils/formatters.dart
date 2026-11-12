DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

class Fmt {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _daysFull = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  static String date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
  static String dateShort(DateTime d) => '${d.day} ${_months[d.month - 1]}';
  static String weekday(DateTime d) => _days[d.weekday - 1];
  static String weekdayFull(DateTime d) => _daysFull[d.weekday - 1];
  static String monthYear(DateTime d) => '${_monthsFull[d.month - 1]} ${d.year}';
  static String monthShort(DateTime d) => _months[d.month - 1];
  static String fullDate(DateTime d) => '${weekdayFull(d)}, ${d.day} ${_monthsFull[d.month - 1]} ${d.year}';

  static String time(DateTime? d) {
    if (d == null) return '--:--';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  static String hm(int hour, int minute) => time(DateTime(2000, 1, 1, hour, minute));

  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  static String clock(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  /// Indian digit grouping: 1,23,456
  static String money(num v) {
    final n = v.round();
    final s = n.abs().toString();
    String out;
    if (s.length <= 3) {
      out = s;
    } else {
      final last3 = s.substring(s.length - 3);
      var rest = s.substring(0, s.length - 3);
      final parts = <String>[];
      while (rest.length > 2) {
        parts.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) parts.insert(0, rest);
      out = '${parts.join(',')},$last3';
    }
    return '${n < 0 ? '-' : ''}\u20B9$out';
  }

  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return date(d);
  }

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
