import 'dart:io';

import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/api/reel.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/components/reel_toast.dart';
import 'package:jxim_client/reel/reel_page/reel_post_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';

class ReelProfileMgr extends EventDispatcher {
  ReelProfileMgr._();

  static final ReelProfileMgr _instance = ReelProfileMgr._();

  static ReelProfileMgr get instance => _instance;

  final Map<int, ReelProfile> _profileMap = {};

  ReelProfile getCurrentProfile(int userId) {
    ReelProfile? p = _profileMap[userId];
    if (p == null) {
      var user = objectMgr.userMgr.getUserById(userId);
      var name = "";
      if (user != null) name = objectMgr.userMgr.getUserTitle(user);
      ReelProfile profile = ReelProfile(userid: userId, name: name);
      _profileMap[userId] = profile;
      return profile;
    }

    return p;
  }

  removeAllData() {
    _profileMap.clear();
  }

  Future<ReelProfile?> getUserProfile(int userId) async {
    ReelProfile reelProfile;
    try {
      reelProfile = await getProfile(userId);
      reelProfile = _syncProfile(reelProfile);
      ReelPostMgr.instance.syncProfile(reelProfile);
    } catch (e) {
      // New Open
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
      return null;
    }
    return reelProfile;
  }

  syncFollow(int userId, int newRs, isFollow) {
    if (_profileMap[userId] != null) {
      ReelProfile item = _profileMap[userId]!;
      item.rs.value = newRs;
      item.totalFollowerCount.value =
          (item.totalFollowerCount.value ?? 0) + (isFollow ? 1 : -1);
    }

    ReelProfile myProfile = ReelProfileMgr.instance
        .getCurrentProfile(objectMgr.userMgr.mainUser.uid);
    myProfile.totalFolloweeCount.value =
        (myProfile.totalFolloweeCount.value ?? 0) + (isFollow ? 1 : -1);
  }

  void syncLikes(int userId, bool isLiked) {
    if (_profileMap[userId] != null) {
      ReelProfile item = _profileMap[userId]!;
      item.totalLikesReceived.value =
          item.totalLikesReceived.value! + (isLiked ? 1 : -1);
    }
  }

  ReelProfile _syncProfile(ReelProfile profile) {
    ReelProfile p;
    if (_profileMap[profile.userid.value] != null) {
      ReelProfile item = _profileMap[profile.userid.value]!;
      item.sync(profile);
      p = item;
    } else {
      _profileMap[profile.userid.value!] = profile;
      p = profile;
    }
    return p;
  }

  Future<bool> updateUserInfo(
    ReelProfile data, {
    String? name,
    String? bio,
    String? profilePic,
    String? backgroundPic,
  }) async {
    bool success = false;
    try {
      success = await updateProfileInfo(
        name: name,
        bio: bio,
        profilePic: profilePic,
        backgroundPic: backgroundPic,
      );
      if (success) {
        if (name != null) data.name.value = name;
        if (bio != null) data.bio.value = bio;
        if (profilePic != null) {
          data.profilePic.value = profilePic;
        }
        if (backgroundPic != null) data.backgroundPic.value = backgroundPic;
        ReelPostMgr.instance.syncProfile(data);
      }
    } catch (e) {
      if (e is NetworkException || e is HttpException) {
        showReelToast(value: localized(reelNoInternet));
      } else {
        Toast.showToast(e.toString());
      }
    }
    return success;
  }
}
