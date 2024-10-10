import 'package:jxim_client/data/row_object.dart';

class Alias extends RowObject {
  int get aliasid => getValue('user_id', 0);
  int get aliastargetid => getValue('target_id', 0);
  String get aliasname => getValue('name', '');

  static Alias creator() {
    return Alias();
  }
}
