import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class UserUtils {
  static String onlineStatus(int lastOnline) {
    String userLastOnline =
        (lastOnline == 0) ? "" : FormatTime.formatTimeFun(lastOnline);

    return userLastOnline;
  }

  static String groupMembersLengthInfo(int length) {
    return '$length${localized(chatInfoMembers)}';
  }
}
