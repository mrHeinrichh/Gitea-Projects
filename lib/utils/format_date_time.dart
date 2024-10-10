import 'package:intl/intl.dart';

enum DateTimeStyle {
  twentyFourFormat(value: 'HH:mm'),
  twelveFormat(value: 'hh:mm a'),
  ddmmyyyySlash(value: 'dd/MM/yyyy'),
  mmddyyyySlash(value: 'MM/dd/yyyy'),
  ddmmyyyyDash(value: 'dd-MM-yyyy'),
  mmddyyyyDash(value: 'MM-dd-yyyy'),
  ddmmmyyyy(value: 'dd MMM yyyy'),
  mmmddyyyy(value: 'MMM dd yyyy');

  const DateTimeStyle({
    required this.value,
  });

  final String value;
}

class FormatDateTime {
  static String timerConverter({required String timeFormat, required int timestamp}){
    String dateTimeString = "";
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    dateTimeString = DateFormat(timeFormat).format(dateTime);
    return dateTimeString;
  }
}
