import 'package:azlistview/azlistview.dart';
import 'package:jxim_client/object/user.dart';

class AZItem extends ISuspensionBean {
  final String tag;
  final User user;

  AZItem({
    required this.tag,
    required this.user,
  });

  @override
  String getSuspensionTag() {
    RegExp isChar = RegExp(r'[A-Za-z~]');
    return isChar.hasMatch(tag) ? tag.toUpperCase() : "#";
  }
}
