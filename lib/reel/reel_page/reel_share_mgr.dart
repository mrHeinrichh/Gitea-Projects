import 'dart:io';

import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';

class ReelShareMgr {

  ReelShareMgr._();

  static final ReelShareMgr _instance = ReelShareMgr._();

  static ReelShareMgr get instance => _instance;

  Future<bool> updatePostSharing(ReelPost data) async {
    bool success = false;
    try {
      success = await sharePost(data.id.value!);

      if (success) {
        data.sharedCount.value = data.sharedCount.value! + 1;
      }
    } catch (e) {
      // New Open
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
    }

    return success;
  }
}
