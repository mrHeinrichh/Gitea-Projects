import 'dart:core';

import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/reel_page/reel_comment_controller.dart';
import 'package:jxim_client/reel/reel_profile/reel_my_profile_controller.dart';
import 'package:jxim_client/reel/reel_profile/reel_profile_controller.dart';

final ReelNavigationMgr reelNavigationMgr = ReelNavigationMgr();

class ReelNavigationMgr {
  List<ReelProfileController> profileControllers = [];
  List<ReelMyProfileController> myProfileControllers = [];
  List<ReelCommentController> commentControllers = [];

  clearCache() {
    for (var element in profileControllers) {
      element.clearCache();
    }

    for (var element in myProfileControllers) {
      element.clearCache();
    }

    for (var element in commentControllers) {
      element.onClose();
    }

    profileControllers.clear();
    myProfileControllers.clear();
    commentControllers.clear();
  }

  ReelCommentController addCommentView(dynamic controllerToPause, ReelPost post) {
    ReelCommentController controller =
        ReelCommentController(controllerToPause: controllerToPause, post: post);
    commentControllers.add(controller);
    return controller;
  }

  ReelMyProfileController addMyProfile() {
    ReelMyProfileController myProfileController = ReelMyProfileController();
    myProfileControllers.add(myProfileController);
    return myProfileController;
  }

  onCloseComment(ReelCommentController controller) {
    commentControllers.remove(controller);
    controller.onClose();
  }

  ReelProfileController addProfile(int userId) {
    ReelProfileController controller = ReelProfileController(userId);
    profileControllers.add(controller);
    controller.updateController();
    return controller;
  }

  onCloseMyProfile(ReelMyProfileController profileController) {
    myProfileControllers.remove(profileController);
    profileController.clearCache();
  }

  onCloseProfile(ReelProfileController profileController) {
    profileControllers.remove(profileController);
    profileController.clearCache();
  }
}
