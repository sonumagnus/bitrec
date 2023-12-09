import 'package:intl/intl.dart';

class StreakCalc {
  static double getPercentage({required int target, required Duration diff}) {
    if (diff.inMinutes >= 0) {
      return (diff.inMinutes / Duration(days: target).inMinutes) * 100;
    }
    return (Duration(days: target).inMinutes / diff.inMinutes.abs()) * 100;
  }

  static String formatTwoDigitNumber(int number) {
    return number < 10 ? '0$number' : '$number';
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}
