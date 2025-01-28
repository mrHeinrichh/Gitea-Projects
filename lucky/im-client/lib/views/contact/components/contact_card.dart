
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import '../../../home/component/custom_divider.dart';
import '../../../main.dart';
import '../../../object/user.dart';
import '../../../utils/color.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({
    Key? key,
    required this.user,
    required this.subTitle,
    this.subTitleColor,
    this.trailing,
    this.isSelected = false,
    this.withCustomBorder = false,
    this.gotoChat = true,
    this.isCalling = false,
    this.onTap,
    this.leftPadding = 12.0,
    this.isSelectMode = false,
    this.isDisabled = false,
  }) : super(key: key);

  final User user;
  final String? subTitle;
  final Color? subTitleColor;
  final List<Widget>? trailing;
  final bool isSelected;
  final bool withCustomBorder;
  final bool gotoChat;
  final bool isCalling;
  final GestureTapCallback? onTap;
  final double leftPadding;
  final bool isSelectMode;
  final bool isDisabled;

  bool get isDesktop => objectMgr.loginMgr.isDesktop;

  ContactController get controller => Get.find<ContactController>();

  Widget _buildAvatar() {
    return Padding(
      padding: EdgeInsets.only(
        left: isDesktop ? 10.0 : leftPadding,
        right: isDesktop ? 10.0 : 12.0,
      ),
      child: Center(
        child: CustomAvatar(
          key: ValueKey(user.uid),
          uid: user.uid,
          size: 40,
          headMin: Config().headMin,
          shouldAnimate: false,
          onTap: isSelectMode ? (){} : null,
        ),
      ),
    );
  }

  Widget _buildUserContent() {
    return Padding(
      padding: EdgeInsets.only(
        right: isDesktop ? 8.0 : 16.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NicknameText(
                  key: ValueKey(user.uid),
                  uid: user.uid,
                  fontSize: jxTextStyle.chatCellNameSize(),
                  fontWeight: MFontWeight.bold5.value,
                  color: controller.selectedUserUID.value == user.uid &&
                          objectMgr.loginMgr.isDesktop
                      ? JXColors.white
                      : JXColors.primaryTextBlack,
                  overflow: TextOverflow.ellipsis,
                  isTappable: false,
                ),
                // ImGap.hGap12,
                SizedBox(height: isDesktop ? 5 : 4),
                if (notBlank(subTitle))
                  Text(
                    subTitle ?? '',
                    style: jxTextStyle.contactCardSubtitle(
                      controller.selectedUserUID.value == user.uid &&
                              objectMgr.loginMgr.isDesktop
                          ? JXColors.white
                          : subTitleColor ?? JXColors.secondaryTextBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Row(children: trailing ?? []),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) {
      return Obx(
        () => OverlayEffect(
          child: Container(
            key: key,
            // color: Colors.white,
            child: Row(
              children: [
                ClipRRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 350),
                    alignment: Alignment.centerLeft,
                    curve: Curves.easeInOutCubic,
                    widthFactor: isSelectMode ? 1 : 0,
                    child: GestureDetector(
                      onTap: (){
                        if (!isDisabled) {
                          controller.selectUser(user.accountId);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: CheckTickItem(isCheck: controller.selectedList.contains(user.accountId),),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  key: ValueKey(user.uid),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (onTap != null || isSelectMode) {
                      onTap!.call();
                      return;
                    }
                    if (isCalling) {
                      clickToCall(context, user);
                    } else {
                      controller.clearSearching();
                      controller.searchFocus.unfocus();

                      Get.toNamed(RouteName.chatInfo,
                          arguments: {"uid": user.uid, "id": user.uid});
                    }
                  },
                  child: _buildAvatar(),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (onTap != null || isSelectMode) {
                        onTap!.call();
                        return;
                      }
                      if (isCalling) {
                        clickToCall(context, user);
                      } else {
                        if (gotoChat) {
                          controller
                              .redirectToChat(context, user.id)
                              .whenComplete(() {
                            controller.clearSearching();
                            controller.searchFocus.unfocus();
                          });
                        } else {
                          Get.toNamed(RouteName.chatInfo,
                              arguments: {"uid": user.uid, "id": user.uid});
                        }
                      }
                    },
                    child: Column(
                      children: [
                        SizedBox(
                          height: 50,
                          child: _buildUserContent(),
                        ),
                        if (withCustomBorder) SeparateDivider(indent: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Obx(
        () => ElevatedButtonTheme(
          data: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.selectedUserUID.value == user.uid &&
                      objectMgr.loginMgr.isDesktop
                  ? JXColors.desktopChatBlue
                  : Colors.white,
              disabledBackgroundColor: Colors.white,
              shadowColor: Colors.transparent,
              surfaceTintColor: JXColors.outlineColor,
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0))),
              elevation: 0.0,
            ),
          ),
          child: ElevatedButton(
            onPressed: () {
              if (controller.selectedUserUID.value != user.uid) {
                if (controller.selectedUserUID.value != user.uid) {
                  controller.selectedUserUID.value = user.uid;
                  Get.offAllNamed('empty', id: 2);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    Get.toNamed(RouteName.chatInfo,
                        arguments: {"uid": user.uid}, id: 2);
                  });
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  _buildAvatar(),
                  Expanded(
                    child: _buildUserContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  void clickToCall(BuildContext context, User user) {
    final CallLogController callLogController = Get.find<CallLogController>();
    if (user.deletedAt > 0) {
      Toast.showToast(localized(userHasBeenDeleted));
    } else {
      Navigator.pop(context);
      callLogController.showCallOptionPopup(context, user);
    }
  }
}
