import 'dart:io';

import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/reel/reel_page/reel_post_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';

class ReelFollowMgr {

  ReelFollowMgr._();

  static final ReelFollowMgr _instance = ReelFollowMgr._();

  static ReelFollowMgr get instance => _instance;

  updateFollow(int userId, int? newRs, bool isFollow) async {
    int follow = isFollow ? 1 : 0;
    try {
      followProfile(userId, follow);
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
    }
    ReelPostMgr.instance.syncFollow(userId, newRs ?? 0);
    ReelProfileMgr.instance.syncFollow(userId, newRs ?? 0, isFollow);
  }
}
