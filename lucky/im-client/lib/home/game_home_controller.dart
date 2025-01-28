
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';

import '../main.dart';
import '../views/component/custom_avatar.dart';
import '../views/discovery/discovery_view.dart';

class GameHomeController extends GetxController {
  @override
  void onInit() {
    super.onInit();

    avatarHelper.genCustomAvatar = ({
      Key? key,
      required int uid,
      required double size,
      bool isGroup = false,
      int? headMin,
      Function()? onTap,
      Function()? onLongPress,
      double? fontSize,
      bool isFullPage = false,
      bool isShowInitial = false,
      bool withEditEmptyPhoto = false,
      bool shouldAnimate = true,
    }) {
      return CustomAvatar(uid: uid, size: size,isGroup: isGroup);
    };
  }
}


Widget getDiscoveryView() {
  if (objectMgr.loginMgr.isDesktop) {
    return const SizedBox();
  } else {
    return const DiscoveryView();
  }
}
