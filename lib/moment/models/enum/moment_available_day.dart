import 'package:jxim_client/utils/lang_util.dart' as lang_util;
import 'package:jxim_client/utils/localization/app_localizations.dart';

enum MomentAvailableDays {
  forever(0),
  threeDays(3),
  oneMonth(30),
  halfYear(180);

  const MomentAvailableDays(this.value);

  final int value;

  String get title {
    switch (this) {
      case MomentAvailableDays.forever:
        return localized(lang_util.forever);
      case MomentAvailableDays.threeDays:
        return '3 ${localized(lang_util.days)}';
      case MomentAvailableDays.oneMonth:
        return localized(lang_util.timeOneMonth);
      case MomentAvailableDays.halfYear:
        return localized(lang_util.timeSixMonths);
      default:
        return localized(lang_util.forever);
    }
  }

  static MomentAvailableDays parseValue(int value) {
    switch (value) {
      case 0:
        return MomentAvailableDays.forever;
      case 3:
        return MomentAvailableDays.threeDays;
      case 30:
        return MomentAvailableDays.oneMonth;
      case 180:
        return MomentAvailableDays.halfYear;
      default:
        return MomentAvailableDays.forever;
    }
  }
}
