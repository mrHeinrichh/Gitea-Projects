import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';

import '../../main.dart';
import '../../object/user.dart';
import '../../utils/color.dart';
import '../../utils/localization/app_localizations.dart';
import '../component/click_effect_button.dart';
import '../component/custom_alert_dialog.dart';
import 'block_list_controller.dart';

class BlockListView extends GetView<BlockListController> {
  const BlockListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PrimaryAppBar(
        title: localized(blockList),
        bgColor: Colors.transparent,
      ),
      body: Obx(() {
        return controller.userList.isEmpty
            ? Container(
                color: JXColors.white,
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
                            color: JXColors.secondaryTextBlack),
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
                          color: JXColors.white,
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
                                  vertical: 15.5, horizontal: 16),
                              child: Text(
                                localized(unblockAllUser),
                                style:
                                    jxTextStyle.textStyle16(color: accentColor),
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
                                      color: JXColors.white,
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
                                                builder:
                                                    (BuildContext context) {
                                                  return CustomAlertDialog(
                                                    title: localized(
                                                        unblockUserName,
                                                        params: [
                                                          objectMgr.userMgr
                                                              .getUserTitle(
                                                                  user)
                                                        ]),
                                                    content: Text(
                                                      localized(
                                                          unblockUserDesc),
                                                      style: jxTextStyle
                                                          .textDialogContent(),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    confirmText: localized(
                                                        buttonUnblock),
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
                                            backgroundColor: errorColor,
                                            foregroundColor: JXColors.white,
                                            padding: EdgeInsets.zero,
                                            flex: 7,
                                            child: Text(
                                              localized(buttonUnblock),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: jxTextStyle
                                                  .slidableTextStyle(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Row(
                                          children: [
                                            CustomAvatar(
                                                uid: user.uid, size: 40),
                                            const SizedBox(width: 12),
                                            Expanded(
                                                child: NicknameText(
                                              uid: user.uid,
                                              overflow: TextOverflow.ellipsis,
                                            )),
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
                            }),
                      )
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
            topLeft: Radius.circular(10), topRight: Radius.circular(10));
      }
    } else if (index == controller.userList.length - 1) {
      // last one
      return const BorderRadius.only(
          bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10));
    } else {
      return null;
    }
  }

  _getActionBorderRadius(index) {
    if (index == 0) {
      // only one
      if (controller.userList.length == 1) {
        return const BorderRadius.only(
            topRight: Radius.circular(10), bottomRight: Radius.circular(10));
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
