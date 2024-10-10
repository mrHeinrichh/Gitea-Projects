import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/contact/friend_request_confirm.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';

class SearchingResultList extends GetWidget<SearchContactController> {
  const SearchingResultList(
    this.list,
    this.title, {
    super.key,
    this.isUsername = true,
  });
  final List<User> list;
  final String title;
  final bool isUsername;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView.builder(
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: list.isNotEmpty ? list.length + 1 : list.length,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Container(
              height: 30,
              width: double.infinity,
              color: colorBackground,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                title,
                style: jxTextStyle.textStyle14(color: colorTextSecondary),
              ),
            );
          } else {
            final user = list[index - 1];
            return ContactCard(
              key: ValueKey(user.uid),
              onTap: () {
                if (controller.isModalBottomSheet) {
                  if (user.relationship == Relationship.friend ||
                      user.relationship == Relationship.blockByTarget ||
                      user.relationship == Relationship.blocked) {
                    Get.close(1);
                    Get.toNamed(
                      RouteName.chatInfo,
                      arguments: {"uid": user.uid},
                    );
                  } else {
                    controller.showChatInfoInSheet(user.uid, context);
                  }
                } else {
                  Get.toNamed(RouteName.chatInfo, arguments: {"uid": user.uid});
                }
              },
              withCustomBorder: index != list.length,
              user: user,
              subTitle: isUsername
                  ? user.username.isEmpty
                      ? ''
                      : "@${user.username}"
                  : "${user.countryCode}\t${user.contact}",
              trailing: [
                Visibility(
                  visible: user.relationship == Relationship.receivedRequest,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => controller.onAddFriendClick(context, user),
                        child: Padding(
                          padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.02,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Color(0xFF57C055),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();

                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext context) {
                              return CustomConfirmationPopup(
                                title: localized(contactFriendRequest),
                                subTitle:
                                    "${localized(reject)} ${user.nickname}${localized(sFriendRequest)}?",
                                confirmButtonText: localized(buttonConfirm),
                                cancelButtonText: localized(buttonCancel),
                                confirmCallback: () {
                                  controller.rejectFriend(context, user);
                                },
                                cancelCallback: () =>
                                    Navigator.of(context).pop(),
                              );
                            },
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: MediaQuery.of(context).size.width * 0.02,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: user.relationship != Relationship.receivedRequest,
                  child: GestureDetector(
                    child: controller.checkStatus(user.relationship),
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (user.relationship == Relationship.stranger) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isDismissible: false,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: FriendRequestConfirm(
                                user: user,
                                confirmCallback: (remark) {
                                  imBottomToast(
                                    context,
                                    title: localized(
                                      sendingFriendReq,
                                      params: [user.nickname],
                                    ),
                                    icon: ImBottomNotifType.timer,
                                    duration: 5,
                                    withCancel: true,
                                    timerFunction: () {
                                      objectMgr.userMgr
                                          .addFriend(user, remark: remark);
                                    },
                                    undoFunction: () {
                                      BotToast.removeAll(BotToast.textKey);
                                    },
                                  );
                                },
                                cancelCallback: () =>
                                    Navigator.of(context).pop(),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
