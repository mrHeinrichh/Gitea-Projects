import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/views/component/component.dart';

class ChooseMoreField extends StatelessWidget {
  final CustomInputController controller;

  const ChooseMoreField({
    super.key,
    required this.controller,
  });


  bool deleteMessagePermissionCheck(Message message) {
    return objectMgr.userMgr.isMe(message.send_id) &&
        DateTime.now().millisecondsSinceEpoch - (message.create_time * 1000) <
            const Duration(days: 1).inMilliseconds;
  }

  CustomInputController get inputController =>
    Get.find<CustomInputController>(tag: controller.chatController.chat.id.toString());


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 16.0.w,
        horizontal: 12.0.w,
      ),
      // height: 50.h,
      child: Obx(() {
        bool hasSelect =
            controller.chatController.chooseMessage.values.isNotEmpty;

        if (controller.chatController.isEnableFavourite.value){
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              /// 收藏
              GestureDetector(
                onTap: () {
                  if (hasSelect) {
                    List<Message> listMessages = controller.chatController.chooseMessage.values.toList();
                    objectMgr.favouriteMgr.addMessageToFavourite(
                      listMessages,
                      controller.chat!,
                    );
                    controller.chatController.onChooseMoreCancel();
                  }
                },
                child: OpacityEffect(
                  child: SvgPicture.asset(
                    'assets/svgs/favourite_icon.svg',
                    colorFilter: ColorFilter.mode(
                      hasSelect ? themeColor : const Color(0x7a121212),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              /// 刪除
              GestureDetector(
                onTap: () {
                  if (hasSelect && controller.chatController.canDelete.value) {

                    bool showDeleteForEveryone = true;
                    for(Message message in controller.chatController.chooseMessage.values){
                      if(!controller.chatController.chat.isValid ||
                          controller.chatController.chat.isSaveMsg ||
                          message.typ == messageTypeSendRed ||
                          controller.chatController.chat.typ == chatTypeSmallSecretary){
                        showDeleteForEveryone = false;
                        break;
                      }else {
                        if (inputController.type == chatTypeGroup) {
                          final GroupChatController groupController =
                          Get.find<GroupChatController>(tag: controller.chatController.chat.id.toString());
                          if (groupController.isOwner) {
                            if (objectMgr.userMgr.isMe(message.send_id)) {
                              showDeleteForEveryone =
                                  deleteMessagePermissionCheck(message);
                              if(!showDeleteForEveryone) break;
                            }
                          } else if (groupController.isAdmin) {
                            if (objectMgr.userMgr.isMe(message.send_id)) {
                              showDeleteForEveryone =
                                  deleteMessagePermissionCheck(message);
                              if(!showDeleteForEveryone) break;
                            } else if (groupController.group.value != null &&
                                groupController.group.value!.owner ==
                                    message.send_id) {
                              showDeleteForEveryone = false;
                              break;
                            }
                          } else {
                            showDeleteForEveryone =
                                deleteMessagePermissionCheck(message);
                            if(!showDeleteForEveryone) break;

                          }
                        } else if (inputController.type == chatTypeSingle) {
                          showDeleteForEveryone =
                              deleteMessagePermissionCheck(message);
                          if(!showDeleteForEveryone) break;
                        }
                      }
                    }

                    showCustomBottomAlertDialog(
                      context,
                      withHeader: false,
                      cancelTextColor: themeColor,
                      items: [
                        CustomBottomAlertItem(
                          text: localized(deleteForMe),
                          textColor: colorRed,
                          onClick: (){
                            controller.onDeleteMessage(
                              context,
                              controller.chatController.chooseMessage.values.toList(),
                              isMore: true,);
                          },
                        ),
                        if(showDeleteForEveryone)
                          CustomBottomAlertItem(
                            text: localized(deleteForEveryone),
                            textColor: colorRed,
                            onClick: (){
                              controller.onDeleteMessage(
                                context,
                                controller.chatController.chooseMessage.values.toList(),
                                isMore: true,
                                isAll: true,
                              );
                            },
                          ),
                      ],
                    );
                  }
                },
                child: OpacityEffect(
                  child: SvgPicture.asset(
                    'assets/svgs/muti_selected_del.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      hasSelect ?
                      themeColor : const Color(0x7a121212),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

              /// 轉發
              GestureDetector(
                onTap: () {
                  if (controller.chatController.chooseMessage.isEmpty) {
                    Toast.showToast(localized(toastSelectMessage));
                    return;
                  }
                  if (controller.chatController.canForward.value) {
                    controller.onForwardMessage();
                  }
                },
                child: OpacityEffect(
                  child: SvgPicture.asset(
                    'assets/svgs/muti_selected_forward.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      hasSelect && (controller.chatController.canForward.value)?
                      themeColor : const Color(0x7a121212),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
