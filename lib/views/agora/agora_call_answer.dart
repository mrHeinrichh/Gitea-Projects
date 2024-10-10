import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:jxim_client/utils/toast.dart';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';

class AgoraCallAnswer extends StatelessWidget {
  final Chat chat;
  const AgoraCallAnswer(this.chat, {super.key});

  @override
  Widget build(BuildContext context) {
    logMgr.logCallMgr.addMetrics(
      LogCallMsg(
        msg:
            "AgoraCallAnswer -> friendId: ${chat.friend_id} version: ${appVersionUtils.currentAppVersion}",
        mediaType: "${objectMgr.userMgr.mainUser.uid}",
      ),
    );

    const notificationHeight = 104.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      width: double.infinity,
      height: notificationHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF757575),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //左邊區塊
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CustomAvatar.chat(
                      chat,
                      size: 16,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Text(
                      localized(
                        objectMgr.callMgr.isVoiceCall
                            ? callLogoVoice
                            : callLogoVideo,
                        params: [Config().appName],
                      ),
                      style: TextStyle(
                        fontWeight: MFontWeight.bold4.value,
                        color: ImColor.white60,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  objectMgr.userMgr.getUserTitle(objectMgr.callMgr.opponent),
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontWeight: MFontWeight.bold5.value,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          //右邊按鈕們
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  objectMgr.callMgr.rejectCall();
                },
                child: SvgPicture.asset('assets/svgs/agora_cancel.svg'),
              ),
              const SizedBox(
                width: 16,
              ),
              GestureDetector(
                onTap: () async {
                  InAppNotification.dismiss(context: context);

                  if (notBlank(objectMgr.callMgr.rtcChannelId)) {
                    if (objectMgr.callMgr.mustPermissionDialogOpened) {
                      Navigator.of(context).pop();
                    }

                    // 是否正在连蓝牙
                    // objectMgr.callMgr.checkBluetooth();
                    objectMgr.callMgr.acceptCall(informCallKit: true);
                    Get.toNamed(RouteName.agoraCallView);
                  } else {
                    Toast.showToast(localized(callCancelFriend));
                  }
                },
                child: SvgPicture.asset('assets/svgs/agora_pick_up.svg'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
