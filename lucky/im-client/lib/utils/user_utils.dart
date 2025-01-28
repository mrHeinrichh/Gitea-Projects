import 'format_time.dart';
import 'lang_util.dart';
import 'localization/app_localizations.dart';

class UserUtils {
  static String onlineStatus(int lastOnline) {
    String userLastOnline = (lastOnline == 0)
        ? ""
        : FormatTime.formatTimeFun(lastOnline);

    return userLastOnline;
  }

  static String groupMembersLengthInfo(int length) {
    return '${length}${localized(chatInfoMembers)}';
  }
}
