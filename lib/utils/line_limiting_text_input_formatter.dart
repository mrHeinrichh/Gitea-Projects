import 'package:flutter/services.dart';

///TextField行數限制器(inputFormatters)
class LineLimitingTextInputFormatter extends TextInputFormatter {
  final int maxLines;

  LineLimitingTextInputFormatter(this.maxLines);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final int newLineCount = '\n'.allMatches(newValue.text).length + 1;
    if (newLineCount > maxLines) {
      return oldValue;
    }
    return newValue;
  }
}