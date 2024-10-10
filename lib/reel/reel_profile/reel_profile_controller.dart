import 'dart:io';

import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/reel/reel_page/reel_post_mgr.dart';
import 'package:jxim_client/reel/reel_page/reel_profile_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';

class ReelProfileController extends GetxController {
  RxInt userId = objectMgr.userMgr.mainUser.uid.obs;

  Rx<ReelProfile> reelProfile = ReelProfile(
    userid: objectMgr.userMgr.mainUser.uid,
    name: objectMgr.userMgr.mainUser.username,
  ).obs;
  RxList<ReelPost> posts = RxList<ReelPost>();

  RxList tabBarList = ['reel_post'].obs;

  ReelProfileController(int userId) {
    this.userId.value = userId;
  }

  clearCache() {

  }

  @override
  onClose() {
    // posts.clear();
    super.onClose();
  }

  void updatePostProfiles(int userId, String profilePic, String name) {
    posts.where((p0) => p0.creator.value?.id.value == userId).toList().forEach((element) {
      element.creator.value?.profilePic.value = profilePic;
      element.creator.value?.name.value = name;
    });
  }

  Future<void> updateController() async {
    List<Future> futures = [];
    futures.add(getProfile(userId.value));
    futures.add(getPosts(userId.value));

    await futures.wait;
  }

  Future<ReelProfile?> getProfile(int userId) async {
    this.userId.value = userId;

    reelProfile.value = ReelProfileMgr.instance.getCurrentProfile(userId);
    return await ReelProfileMgr.instance.getUserProfile(userId);
  }

  Future<List<ReelPost>> getPosts(int userId, {int? lastId}) async {
    try {
      final list = await ReelPostMgr.instance.getPosts(userId, lastId: lastId);
      if (list.isNotEmpty) {
        if (lastId == null) {
          posts.assignAll(list);
        } else {
          posts.addAll(list);
        }
      }

      return list;
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
      return [];
    }
  }
}
