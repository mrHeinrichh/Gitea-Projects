import 'dart:io';

import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/reel/utils/reel_utils.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';

class ReelSaveMgr {
  ReelSaveMgr._();

  static final ReelSaveMgr _instance = ReelSaveMgr._();

  static ReelSaveMgr get instance => _instance;

  updateSave(
    List<ReelPost> data,
    bool isSaved, {
    Function()? onTapSavedSuccessfullyCallback,
  }) async {
    int isSave = isSaved ? 1 : 0;
    List<int> datas = [];
    for (var element in data) {
      //update current data
      datas.add(element.id.value!);
      element.isSaved.value = isSaved;
      element.savedCount.value = element.savedCount.value! + (isSaved ? 1 : -1);
    }

    try {
      bool res = await savePosts(datas, isSave);
      if (res) {
        if (isSaved) {
          imBottomToast(
            navigatorKey.currentContext!,
            title: localized(ReelSaveSuccessfully),
            backgroundColor: colorWhite,
            textColor: colorTextPrimary,
            icon: ImBottomNotifType.success,
            alignment: reelUtils.getToastAlignment(),
            withAction: true,
            actionArrow: true,
            actionButtonText: ReelGoCheck,
            actionTxtColor: colorRed,
            actionFunction: onTapSavedSuccessfullyCallback,
          );
        } else {
          imBottomToast(
            navigatorKey.currentContext!,
            title: localized(ReelUnsaved),
            backgroundColor: colorWhite,
            textColor: colorTextPrimary,
            alignment: reelUtils.getToastAlignment(),
          );
        }
      }
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
    }
  }
}
