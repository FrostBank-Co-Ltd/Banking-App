import 'package:intl/intl.dart';

/// Date presentation for day headers, rows, and detail screens.
abstract final class Dates {
  static final DateFormat _dayHeader = DateFormat('EEEE, d MMMM', 'en_US');
  static final DateFormat _shortDay = DateFormat('d MMM y', 'en_US');
  static final DateFormat _time = DateFormat('h:mm a', 'en_US');
  static final DateFormat _monthYear = DateFormat('MMMM y', 'en_US');

  static DateTime dayKey(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String dayHeader(DateTime value, {DateTime? now}) {
    final today = dayKey(now ?? DateTime.now());
    final day = dayKey(value);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return _dayHeader.format(day);
  }

  static String shortDay(DateTime value) => _shortDay.format(value);

  static String time(DateTime value) => _time.format(value);

  static String dayAndTime(DateTime value) =>
      '${_shortDay.format(value)} at ${_time.format(value)}';

  static String monthYear(DateTime value) => _monthYear.format(value);

  static String relative(DateTime value, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final gap = reference.difference(value);
    if (gap.inMinutes < 1) return 'Just now';
    if (gap.inMinutes < 60) {
      final minutes = gap.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }
    if (gap.inHours < 24) {
      final hours = gap.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    if (gap.inDays < 7) {
      final days = gap.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
    return _shortDay.format(value);
  }
}
