import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.user,
    required this.subTitle,
    this.subTitleColor,
    this.trailing,
    this.isSelected = false,
    this.withCustomBorder = false,
    this.gotoChat = true,
    this.isCalling = false,
    this.onTap,
    this.leftPadding = 16.0,
    this.isSelectMode = false,
    this.isDisabled = false,
    this.titleWidget,
  });

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
  final Widget? titleWidget;

  bool get isDesktop => objectMgr.loginMgr.isDesktop;

  ContactController get controller => Get.find<ContactController>();

  Widget _buildAvatar() {
    return Padding(
      padding: EdgeInsets.only(
        left: isDesktop ? 8 : leftPadding,
        right: isDesktop ? 10.0 : 12.0,
      ),
      child: Center(
        child: CustomAvatar.user(
          key: ValueKey(user.uid),
          user,
          size: isDesktop ? 32 : 40,
          headMin: Config().headMin,
          shouldAnimate: false,
          onTap: isSelectMode ? () {} : null,
        ),
      ),
    );
  }

  Widget _buildUserContent() {
    return SizedBox(
      height: isDesktop ? 48 : null,
      child: Padding(
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
                  titleWidget ??
                      NicknameText(
                        key: ValueKey(user.uid),
                        uid: user.uid,
                        fontSize: jxTextStyle.chatCellNameSize(),
                        fontWeight: MFontWeight.bold5.value,
                        color: controller.selectedUserUID.value == user.uid &&
                                objectMgr.loginMgr.isDesktop
                            ? colorWhite
                            : colorTextPrimary,
                        overflow: TextOverflow.ellipsis,
                        isTappable: false,
                      ),
                  if (notBlank(subTitle))
                    Text(
                      subTitle ?? '',
                      style: jxTextStyle.normalSmallText(
                        color: controller.selectedUserUID.value == user.uid &&
                                objectMgr.loginMgr.isDesktop
                            ? colorWhite
                            : subTitleColor ?? colorTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Row(children: trailing ?? []),
          ],
        ),
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
            child: Row(
              children: [
                ClipRRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 350),
                    alignment: Alignment.centerLeft,
                    curve: Curves.easeInOutCubic,
                    widthFactor: isSelectMode ? 1 : 0,
                    child: GestureDetector(
                      onTap: () {
                        if (!isDisabled) {
                          controller.selectUser(user.accountId);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: CheckTickItem(
                          isCheck:
                              controller.selectedList.contains(user.accountId),
                        ),
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

                      Get.toNamed(
                        RouteName.chatInfo,
                        arguments: {"uid": user.uid, "id": user.uid},
                      );
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
                          Get.toNamed(
                            RouteName.chatInfo,
                            arguments: {"uid": user.uid, "id": user.uid},
                          );
                        }
                      }
                    },
                    child: Column(
                      children: [
                        SizedBox(
                          height: 50,
                          child: _buildUserContent(),
                        ),
                        if (withCustomBorder) separateDivider(indent: 0.0),
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
                  ? colorDesktopChatBlue
                  : Colors.white,
              disabledBackgroundColor: Colors.white,
              shadowColor: Colors.transparent,
              surfaceTintColor: colorBackground6,
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(0)),
              ),
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
                    Get.toNamed(
                      RouteName.chatInfo,
                      arguments: {"uid": user.uid},
                      id: 2,
                    );
                  });
                }
              }
            },
            child: Row(
              children: [
                _buildAvatar(),
                Expanded(
                  child: Column(
                    children: [
                      _buildUserContent(),
                      if (withCustomBorder) separateDivider(indent: 0.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void clickToCall(BuildContext context, User user) {
    if (user.deletedAt > 0) {
      Toast.showToast(localized(userHasBeenDeleted));
    } else {
      Navigator.pop(context);
      controller.showCallOptionPopup(context, user);
    }
  }
}
