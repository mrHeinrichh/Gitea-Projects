import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import '../../../main.dart';
import '../../../managers/call_mgr.dart';
import '../../../object/call.dart';
import '../../../object/chat/chat.dart';
import '../../../routes.dart';
import '../../../utils/color.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';

class CallLogTile extends StatelessWidget {
  const CallLogTile({
    Key? key,
    required this.callItem,
    required this.isLastIndex,
  }) : super(key: key);

  final Call callItem;
  final bool isLastIndex;

  @override
  Widget build(BuildContext context) {
    final CallLogController controller = Get.find<CallLogController>();
    final Chat? chat = objectMgr.chatMgr.getChatById(callItem.chatId);
    final bool outGoing = objectMgr.userMgr.isMe(callItem.callerId);

    if (chat == null) {
      return const SizedBox();
    } else {
      return OverlayEffect(
        child: Column(
          children: [
            Slidable(
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.2,
                children: [
                  CustomSlidableAction(
                    onPressed: (context) =>
                        controller.onDeleteCallLog(callItem),
                    backgroundColor: JXColors.red,
                    foregroundColor: JXColors.cIconPrimaryColor,
                    padding: EdgeInsets.zero,
                    flex: 7,
                    child: Text(
                      localized(chatDelete),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: jxTextStyle.slidableTextStyle(),
                    ),
                  ),
                ],
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (controller.isEditing.value) {
                    if (!controller.isDeleting) {
                      controller.tapForEdit(callItem);
                    }
                    return;
                  }

                  if (chat.isGroup) {
                    Get.toNamed(RouteName.groupChatInfo, arguments: {
                      'groupId': chat.id,
                    });
                  } else {
                    User? user = objectMgr.userMgr.getUserById(chat.friend_id);
                    if (user != null) {
                      controller.showCallSingleOption(
                          context, user, callItem.isVideoCall == 0);
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                  child: Obx(
                    () => Row(
                      children: [
                        /// 點擊編輯後出現的左邊選取區塊
                        ClipRRect(
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 350),
                            alignment: Alignment.centerLeft,
                            curve: Curves.easeInOutCubic,
                            widthFactor: controller.isEditing.value ? 1 : 0,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: controller.selectedChannelIDForEdit
                                      .contains(callItem)
                                  ? const Icon(
                                      Icons.remove_circle_outlined,
                                      size: 20,
                                      color: JXColors.red,
                                    )
                                  : Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        // Shape of the container
                                        border: Border.all(
                                          color: JXColors.primaryTextBlack
                                              .withOpacity(
                                                  0.28), // Border color
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        SvgPicture.asset(
                          objectMgr.callMgr.getMissedStatus(callItem)
                              ? callItem.isVideoCall == 1
                                  ? 'assets/svgs/missedcall-video.svg'
                                  : 'assets/svgs/missed-call.svg'
                              : outGoing
                                  ? callItem.isVideoCall == 1
                                      ? 'assets/svgs/outgoing-video.svg'
                                      : 'assets/svgs/outgoing-call.svg'
                                  : callItem.isVideoCall == 1
                                      ? 'assets/svgs/incoming-video.svg'
                                      : 'assets/svgs/incoming-call.svg',
                          width: 16,
                          height: 16,
                        ),
                        ImGap.hGap12,
                        CustomAvatar(
                          key: key,
                          uid: chat.isGroup ? chat.chat_id : chat.friend_id,
                          isGroup: chat.isGroup,
                          size: 40,
                          headMin: Config().headMin,
                        ),
                        ImGap.hGap12,
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                NicknameText(
                                  key: key,
                                  uid: chat.isGroup
                                      ? chat.chat_id
                                      : chat.friend_id,
                                  fontSize: jxTextStyle.chatCellNameSize(),
                                  fontWeight: MFontWeight.bold5.value,
                                  color: objectMgr.callMgr
                                          .getMissedStatus(callItem)
                                      ? JXColors.red
                                      : JXColors.primaryTextBlack,
                                  overflow: TextOverflow.ellipsis,
                                  isTappable: false,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  getDescription(),
                                  style: jxTextStyle.contactCardSubtitle(
                                      JXColors.secondaryTextBlack),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        ImGap.hGap16,
                        Text(
                          '${FormatTime.chartTime(
                            callItem.createdAt,
                            true,
                            todayShowTime: true,
                            dateStyle: DateStyle.MMDDYYYY,
                          )}',
                          style: jxTextStyle.textStyle14(
                            color: JXColors.secondaryTextBlack,
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (chat.isGroup) {
                              Get.toNamed(RouteName.groupChatInfo,
                                  arguments: {"uid": chat.chat_id});
                            } else {
                              Get.toNamed(RouteName.chatInfo,
                                  arguments: {
                                    "uid": chat.friend_id,
                                  },
                                  id: objectMgr.loginMgr.isDesktop ? 1 : null);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 12),
                            child: SvgPicture.asset(
                              'assets/svgs/info-icon.svg',
                              color: accentColor,
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                accentColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!isLastIndex)
              Obx(
                () => Padding(
                  padding: EdgeInsets.only(
                          left: controller.isEditing.value ? 124 : 96)
                      .w,
                  child: Container(
                    color: JXColors.borderPrimaryColor,
                    height: 0.3.w,
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  String getDescription() {
    switch (CallEvent.values[callItem.status]) {
      case CallEvent.CallInitFailed:
        return localized(callInitFailed);
      case CallEvent.CallConnectFailed:
        return localized(callConnectFailed);
      case CallEvent.CallCancel:
        return localized(cancelledCall);
      case CallEvent.CallOptCancel:
      case CallEvent.CallBusy:
        return localized(missedCall);
      case CallEvent.CallTimeOut:
        if (objectMgr.userMgr.isMe(callItem.callerId)) {
          return localized(callUnanswered);
        } else {
          return localized(missedCall);
        }
      case CallEvent.CallOptBusy:
        return localized(callingBusy);
      case CallEvent.CallOptReject:
      case CallEvent.CallReject:
        return localized(declinedCall);
      case CallEvent.CallOptEnd:
      case CallEvent.CallEnd:
        if (objectMgr.userMgr.isMe(callItem.callerId)) {
          return localized(chatOutGoingCall,
              params: ['${constructTimeDetail(callItem.duration)}']);
        } else {
          return localized(chatIncomingCall,
              params: ['${constructTimeDetail(callItem.duration)}']);
        }
      case CallEvent.CallOtherDeviceReject:
        return localized(callOtherDeviceReject);
      case CallEvent.CallOtherDeviceAccepted:
        return localized(callOtherDeviceAccepted);
      case CallEvent.CallLogout:
        return localized(callLogout);
      case CallEvent.CallNoPermisson:
        return localized(callFailPermission);
      default:
        return localized(callStatusError);
    }
  }
}
