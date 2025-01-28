import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:jxim_client/views/agora/call_float.dart';

import '../../main.dart';
import '../../utils/lang_util.dart';
import '../../utils/theme/text_styles.dart';
import '../component/custom_avatar.dart';

class AgoraCallAnswer extends StatelessWidget{
  const AgoraCallAnswer(this.friend_id, {super.key});
  final int friend_id;
  @override
  Widget build(BuildContext context) {
    late Offset initialPosition;
    const notificationHeight = 104.0;
    double percentage = 0.0;
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        // Capture the initial position when the pointer is pressed
        initialPosition = event.position;
      },
      onPointerMove: (PointerMoveEvent event) {

        // Calculate the percentage of vertical drag movement relative to the notification size
        percentage = (event.position.dy - initialPosition.dy) / notificationHeight;
      },
      onPointerUp: (PointerEvent event) {
        if (percentage < -0.2) {
          CallFloat().onMinimizeWindow();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        width: double.infinity,
        height: notificationHeight,
        decoration: BoxDecoration(
            color: const Color(0xFF757575), borderRadius: BorderRadius.circular(12)),
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
                      CustomAvatar(
                        uid: friend_id,
                        size: 16,
                      ),
                      const SizedBox(width: 4,),
                      Text(localized(callLogoTitle,params: [Config().appName]),
                          style: TextStyle(
                              fontWeight:MFontWeight.bold4.value,
                              color: ImColor.white60,
                              fontSize: 16)
                      )
                    ],
                  ),
                  Text(objectMgr.userMgr
                      .getUserTitle(objectMgr.callMgr.opponent),
                      style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontWeight: MFontWeight.bold5.value,
                          color: Colors.white,
                          fontSize: 24)),
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
                const SizedBox(width: 16,),
                GestureDetector(
                  onTap: () {
                    InAppNotification.dismiss(context: Get.context!);
                    objectMgr.callMgr.acceptCall(informCallKit: true);
                    Get.toNamed(RouteName.agoraCallView);
                  },
                  child: SvgPicture.asset('assets/svgs/agora_pick_up.svg'),
                )
              ],
            )
          ],
        ),
      ),
    );
    ;
  }
}
