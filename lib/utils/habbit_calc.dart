import 'package:intl/intl.dart';

class HabbitCalc {
  static double getPercentage({required int target, required Duration diff}) {
    if (diff.inMinutes >= 0) {
      return (diff.inMinutes / Duration(days: target).inMinutes) * 100;
    }
    return (Duration(days: target).inMinutes / diff.inMinutes.abs()) * 100;
  }

  static Duration calculateDateDifference({
    required int target,
    required DateTime specificDate,
  }) {
    return DateTime.now().difference(specificDate);
  }

  static Duration getRemainingDays({
    required Duration diff,
    required int target,
  }) {
    return Duration(days: target) - diff;
  }

  static DateTime memoryToStartDateTime(habbit) {
    final int year = habbit['dateTime']['year'];
    final int month = habbit['dateTime']['month'];
    final int day = habbit['dateTime']['day'];
    final int hour = habbit['dateTime']['hour'];
    final int minute = habbit['dateTime']['minute'];
    final int second = habbit['dateTime']['second'];
    final int millisecond = habbit['dateTime']['millisecond'];

    return DateTime(year, month, day, hour, minute, second, millisecond);
  }

  static DateTime memoryToEndDateTime(habbit) {
    final int year = habbit['endDateTime']['year'];
    final int month = habbit['endDateTime']['month'];
    final int day = habbit['endDateTime']['day'];
    final int hour = habbit['endDateTime']['hour'];
    final int minute = habbit['endDateTime']['minute'];
    final int second = habbit['endDateTime']['second'];
    final int millisecond = habbit['endDateTime']['millisecond'];

    return DateTime(year, month, day, hour, minute, second, millisecond);
  }

  static String formatTwoDigitNumber(int number) {
    return number < 10 ? '0$number' : '$number';
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}
