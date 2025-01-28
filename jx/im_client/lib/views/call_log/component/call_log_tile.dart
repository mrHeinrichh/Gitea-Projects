import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/call.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/component/component.dart';

class CallLogTile extends StatefulWidget {
  const CallLogTile({
    super.key,
    required this.tabIndex,
    required this.callItem,
    required this.isLastIndex,
  });

  final int tabIndex;
  final Call callItem;
  final bool isLastIndex;

  @override
  State<StatefulWidget> createState() => CallLogTileState();
}

class CallLogTileState extends State<CallLogTile>
    with TickerProviderStateMixin {
  SlidableController? sliderController;

  @override
  void initState() {
    super.initState();
    sliderController = SlidableController(this);
  }

  @override
  void dispose() {
    sliderController?.close();
    super.dispose();
  }

  openEndAction() async {
    sliderController?.openEndActionPane();
  }

  @override
  Widget build(BuildContext context) {
    Call callItem = widget.callItem;
    final CallLogController controller = Get.find<CallLogController>();
    final Chat? chat = objectMgr.chatMgr.getChatById(callItem.chatId);

    if (chat == null) {
      return const SizedBox();
    } else {
      return OverlayEffect(
        overlayColor: colorBackground8,
        child: Slidable(
          controller: sliderController!,
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.2,
            children: [
              CustomSlidableAction(
                onPressed: (context) async =>
                    controller.onDeleteCallLog(callItem),
                backgroundColor: colorRed,
                foregroundColor: colorWhite,
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
            onTap: () async {
              if (controller.isEditing.value) {
                if (!controller.isDeleting) {
                  controller.tapForEdit(callItem);
                }
                return;
              }

              if (chat.isGroup) {
                Get.toNamed(
                  RouteName.groupChatInfo,
                  arguments: {'groupId': chat.id},
                );
              } else {
                User? user = objectMgr.userMgr.getUserById(chat.friend_id);
                if (user != null) {
                  controller.showCallSingleOption(
                    context,
                    user,
                    callItem.isVideoCall == 0,
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Obx(
                () => Row(
                  children: [
                    /// 點擊編輯後出現的左邊選取區塊
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.centerRight,
                      curve: Curves.easeInOutCubic,
                      widthFactor: controller.isEditing.value ? 1 : 0,
                      child: CustomImage(
                        'assets/svgs/remove_circle.svg',
                        padding: const EdgeInsets.only(right: 12),
                        size: 20,
                        onClick: () => controller.onDeleteBtnClicked(
                          widget.tabIndex,
                          callItem,
                        ),
                      ),
                    ),
                    CustomImage(
                      getCallLogImage(callItem),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    CustomAvatar.chat(
                      chat,
                      size: 40,
                      headMin: Config().headMin,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: widget.isLastIndex ? null : customBorder,
                        ),
                        height: 52,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  NicknameText(
                                    uid: chat.isGroup
                                        ? chat.chat_id
                                        : chat.friend_id,
                                    fontSize: MFontSize.size17.value,
                                    fontWeight: MFontWeight.bold5.value,
                                    color: objectMgr.callLogMgr
                                            .isMissCallLog(callItem)
                                        ? colorRed
                                        : colorTextPrimary,
                                    overflow: TextOverflow.ellipsis,
                                    isTappable: false,
                                  ),
                                  Text(
                                    getDescription(),
                                    style: jxTextStyle.normalSmallText(
                                      color: colorTextSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              FormatTime.chartTime(
                                callItem.createdAt,
                                true,
                                todayShowTime: true,
                                dateStyle: DateStyle.MMDDYYYY,
                              ),
                              style: jxTextStyle.textStyle15(
                                color: colorTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!controller.isEditing.value)
                              CustomImage(
                                'assets/svgs/info-icon.svg',
                                color: themeColor,
                                padding: const EdgeInsets.only(
                                  right: 12,
                                ),
                                size: 24,
                                onClick: () async {
                                  if (chat.isGroup) {
                                    Get.toNamed(
                                      RouteName.groupChatInfo,
                                      arguments: {"uid": chat.chat_id},
                                    );
                                  } else {
                                    Get.toNamed(
                                      RouteName.chatInfo,
                                      arguments: {"uid": chat.friend_id},
                                      id: objectMgr.loginMgr.isDesktop
                                          ? 1
                                          : null,
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  String getCallLogImage(Call callItem) {
    String imageName =
        callItem.isVideoCall == 1 ? "icon_video_call" : "icon_call";
    String callerReceiver =
        objectMgr.userMgr.isMe(callItem.callerId) ? "_caller" : "_receiver";
    String takenCallOrRejected = "";
    String imageFull = "$imageName$takenCallOrRejected$callerReceiver";
    return 'assets/svgs/$imageFull.svg';
  }

  String getDescription() {
    switch (CallEvent.values[widget.callItem.status]) {
      case CallEvent.CallInitFailed:
      case CallEvent.CallOptReject:
      case CallEvent.CallReject:
      case CallEvent.RequestFailed:
      case CallEvent.CallCancel:
      case CallEvent.CallOptCancel:
      case CallEvent.CallBusy:
      case CallEvent.CallTimeOut:
      case CallEvent.CallOptBusy:
      case CallEvent.CallOtherDeviceReject:
      case CallEvent.CallOtherDeviceAccepted:
      case CallEvent.CallLogout:
      case CallEvent.CallNoPermisson:
        return localized(missedCall);
      case CallEvent.CallOptEnd:
      case CallEvent.CallEnd:
        return (widget.callItem.isVideoCall == 1
                ? localized(attachmentCallVideo)
                : localized(attachmentCallVoice)) +
            " (" +
            (constructTimeDetail(widget.callItem.duration)) +
            ")";
      default:
        if (widget.callItem.duration > 0) {
          return (widget.callItem.isVideoCall == 1
                  ? localized(attachmentCallVideo)
                  : localized(attachmentCallVoice)) +
              " (" +
              (constructTimeDetail(widget.callItem.duration)) +
              ")";
        } else {
          return localized(missedCall);
        }
    }
  }
}
