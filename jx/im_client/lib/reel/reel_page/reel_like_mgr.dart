import 'dart:io';

import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';

class ReelLikeMgr {

  ReelLikeMgr._();

  static final ReelLikeMgr _instance = ReelLikeMgr._();

  static ReelLikeMgr get instance => _instance;

  updateLike(List<ReelPost> data, bool isLiked) async {
    int isLike = isLiked ? 1 : 0;
    List<int> datas = [];
    for (var element in data) {
      datas.add(element.id.value!);
      element.isLiked.value = isLiked;
      element.likedCount.value = element.likedCount.value! + (isLiked ? 1 : -1);
      ReelProfileMgr.instance.syncLikes(element.creator.value!.id.value!, isLiked); //若资料页有该用户数据，就更新一下
    }

    try {
      bool res = await likePosts(datas, isLike);
      if (res) {
        if (isLiked) {
          ///UI表示點讚不需要跳toast,故先隱藏
          // ImBottomToast(navigatorKey.currentContext!,
          //   title: "Like Successfully",
          //   backgroundColor: colorWhite,
          //   textColor: colorTextPrimary,
          //   icon: ImBottomNotifType.success,
          // );
        } else {
          ///UI表示點讚不需要跳toast,故先隱藏
          // ImBottomToast(
          //   navigatorKey.currentContext!,
          //   title: "Unlike successfully",
          //   backgroundColor: colorWhite,
          //   textColor: colorTextPrimary,
          //   icon: ImBottomNotifType.empty,
          // );
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
