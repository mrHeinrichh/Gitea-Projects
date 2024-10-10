import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';
import 'package:jxim_client/views/privacy_security/block_list_controller.dart';

class BlockListView extends GetView<BlockListController> {
  const BlockListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(blockList),
        bgColor: Colors.transparent,
      ),
      body: Obx(() {
        return controller.userList.isEmpty
            ? Container(
                color: colorWhite,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/svgs/search_empty_icon.svg',
                        width: 148,
                        height: 148,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 4),
                        child: Text(
                          localized(noResults),
                          style: jxTextStyle.textStyleBold16(),
                        ),
                      ),
                      Text(
                        localized(oopsNoResults),
                        style: jxTextStyle.textStyle14(
                          color: colorTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.only(bottom: 24),
                        child: OverlayEffect(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return CustomAlertDialog(
                                    title: localized(unblockAllUser),
                                    content: Text(
                                      localized(unblockUserDesc),
                                      style: jxTextStyle.textDialogContent(),
                                      textAlign: TextAlign.center,
                                    ),
                                    confirmText: localized(buttonUnblockAll),
                                    cancelText: localized(buttonNo),
                                    confirmCallback: () =>
                                        controller.unblockAllUsers(),
                                  );
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 15.5,
                                horizontal: 16,
                              ),
                              child: Text(
                                localized(unblockAllUser),
                                style:
                                    jxTextStyle.textStyle16(color: themeColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SlidableAutoCloseBehavior(
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: controller.userList.length,
                          itemBuilder: (ctx, index) {
                            User user = controller.userList[index];
                            return Column(
                              children: [
                                Container(
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                    color: colorWhite,
                                    borderRadius: _getBorderRadius(index),
                                  ),
                                  child: Slidable(
                                    endActionPane: ActionPane(
                                      motion: const DrawerMotion(),
                                      extentRatio: 0.2,
                                      children: [
                                        CustomSlidableAction(
                                          onPressed: (ctx) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return CustomAlertDialog(
                                                  title: localized(
                                                    unblockUserName,
                                                    params: [
                                                      objectMgr.userMgr
                                                          .getUserTitle(
                                                        user,
                                                      ),
                                                    ],
                                                  ),
                                                  content: Text(
                                                    localized(
                                                      unblockUserDesc,
                                                    ),
                                                    style: jxTextStyle
                                                        .textDialogContent(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  confirmText: localized(
                                                    buttonUnblock,
                                                  ),
                                                  cancelText:
                                                      localized(buttonNo),
                                                  confirmCallback: () =>
                                                      controller
                                                          .unblockUser(user),
                                                );
                                              },
                                            );
                                          },
                                          borderRadius:
                                              _getActionBorderRadius(index),
                                          backgroundColor: colorRed,
                                          foregroundColor: colorWhite,
                                          padding: EdgeInsets.zero,
                                          flex: 7,
                                          child: Text(
                                            localized(buttonUnblock),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                jxTextStyle.slidableTextStyle(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          CustomAvatar.user(
                                            user,
                                            size: 40,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: NicknameText(
                                              uid: user.uid,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: user != controller.userList.last,
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 65),
                                    child: CustomDivider(),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
      }),
    );
  }

  _getBorderRadius(index) {
    if (index == 0) {
      // only one
      if (controller.userList.length == 1) {
        return BorderRadius.circular(10);
      } else {
        // first one
        return const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        );
      }
    } else if (index == controller.userList.length - 1) {
      // last one
      return const BorderRadius.only(
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
      );
    } else {
      return null;
    }
  }

  _getActionBorderRadius(index) {
    if (index == 0) {
      // only one
      if (controller.userList.length == 1) {
        return const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        );
      } else {
        // first one
        return const BorderRadius.only(topRight: Radius.circular(10));
      }
    } else if (index == controller.userList.length - 1) {
      // last one
      return const BorderRadius.only(bottomRight: Radius.circular(10));
    } else {
      return BorderRadius.zero;
    }
  }
}
