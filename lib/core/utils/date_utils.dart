import 'package:intl/intl.dart';

class DateKeyUtils {
  static String today() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}
