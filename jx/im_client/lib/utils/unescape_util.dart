import 'package:html_unescape/html_unescape.dart';

var unescape = HtmlUnescape();

class UnescapeUtil {
  // 特殊字符替換
  static encodedString(String txt) {
    return unescape.convert(txt);
  }

}
