import 'package:intl/intl.dart';

String? formatDate(String date, String? type) {
  if (date == "") return null;

  DateTime newDate = DateTime.parse(date);

  if (type == "time") {
    return DateFormat('HH:mm:ss').format(newDate);
  }

  return DateFormat('dd-MM-yyyy').format(newDate);
}
