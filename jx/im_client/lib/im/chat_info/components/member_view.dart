import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/services/chat_pop_animation_info.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class MemberView extends StatefulWidget {
  final GroupChatInfoController groupController;
  final Chat? chat;

  const MemberView({
    super.key,
    required this.groupController,
    this.chat,
  });

  @override
  State<MemberView> createState() => _MemberTabState();
}

class _MemberTabState extends MessageWidgetMixin<MemberView>
    with AutomaticKeepAliveClientMixin {
  late final controller = widget.groupController;

  final List<TargetWidgetKeyModel> _keyList = [];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!controller.chat.value!.isValid) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/svgs/empty_state.svg',
            width: 60,
            height: 60,
          ),
          const SizedBox(height: 16),
          Text(
            localized(noHistoryYet),
            style: jxTextStyle.textStyleBold16(),
          ),
          Text(
            localized(yourHistoryIsEmpty),
            style: jxTextStyle.textStyle14(color: colorTextSecondary),
          ),
        ],
      );
    }
    _keyList.clear();
    controller.setUpItemKey(controller.groupMemberListData, _keyList);
    return WillPopScope(
      onWillPop: Platform.isAndroid
          ? () async {
              final controller = Get.find<ChatContentController>(
                  tag: widget.chat!.id.toString());
              controller.chatController.resetPopupWindow();
              return true;
            }
          : null,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverToBoxAdapter(
            child: Visibility(
              visible: controller.addMemberEnable.value,
              child: GestureDetector(
                onTap: controller.onAddMemberTap,
                child: OpacityEffect(
                  child: Container(
                    color: colorWhite,
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SvgPicture.asset(
                            'assets/svgs/add_friends_plus.svg',
                            width: 40,
                            height: 40,
                            colorFilter:
                                ColorFilter.mode(themeColor, BlendMode.srcIn),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              border: customBorder,
                            ),
                            child: Text(
                              localized(addNewMember),
                              style: jxTextStyle.headerText(color: themeColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SlidableAutoCloseBehavior(
            child: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final key =
                      ValueKey(controller.groupMemberListData[index].id);
                  return Builder(builder: (BuildContext context) {
                    Widget child = memberItem(index);
                    TargetWidgetKeyModel model = _keyList[index];

                    return Slidable(
                      key: key,
                      enabled: (controller.isOwner.value ||
                              controller.isAdmin.value) &&
                          !objectMgr.userMgr
                              .isMe(controller.groupMemberListData[index].id),
                      closeOnScroll: true,
                      endActionPane: _createEndActionPane(context, index),
                      child: GestureDetector(
                        // key: _key,
                        key: model.targetWidgetKey,
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (details) {
                          tapPosition = details.globalPosition;
                        },
                        onTap: () => EasyDebounce.debounce(
                          'chat_group_member_click',
                          const Duration(milliseconds: 200),
                          () => controller.onMemberClicked(
                              controller.groupMemberListData[index].id),
                        ),
                        onLongPress: () {
                          if ((controller.isOwner.value ||
                                  controller.isAdmin.value) &&
                              !objectMgr.userMgr.isMe(
                                  controller.groupMemberListData[index].id)) {
                            if (objectMgr.loginMgr.isDesktop) {
                              RenderBox renderBox =
                                  context.findRenderObject() as RenderBox;
                              bool filter = controller
                                  .onMemberItemLongPressMenuFilter(index);
                              if (filter) {
                                return;
                              }
                              vibrate();
                              controller.onMemberItemLongPress(
                                context,
                                renderBox,
                                index,
                                target: child,
                              );
                            } else {
                              bool filter = controller
                                  .onMemberItemLongPressMenuFilter(index);
                              if (filter) {
                                return;
                              }
                              vibrate();
                              Widget menu =
                                  controller.onMemberItemLongPressMenu(index);
                              if (widget.chat != null) {
                                enableFloatingWindowInfoMember(
                                  context,
                                  widget.chat!.id,
                                  child,
                                  model.targetWidgetKey,
                                  tapPosition,
                                  menu,
                                  chatPopAnimationType:
                                      ChatPopAnimationType.right,
                                  menuHeight: controller
                                      .onMemberItemLongPressMenuHeight(index),
                                );
                              }
                            }
                          }
                        },
                        child: child,
                      ),
                    );
                  });
                },
                childCount: controller.groupMemberListData.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //左滑選項
  ActionPane _createEndActionPane(BuildContext context, int index) {
    List<Widget> children = [];
    final user = controller.groupMemberListData[index];

    if ((!controller.isOwner.value && !controller.isAdmin.value) ||
        (controller.isAdmin.value &&
            (user.uid == controller.group.value!.owner ||
                controller.adminList.contains(user.uid)))) {
      children = [];
    } else {
      /// Delete
      children.add(
        CustomSlidableAction(
          onPressed: (context) => objectMgr.myGroupMgr
              .kickMembers(controller.group.value!.id, [user.id]),
          backgroundColor: colorRed,
          foregroundColor: colorWhite,
          padding: EdgeInsets.zero,
          flex: 1,
          child: Text(
            localized(chatDelete),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: jxTextStyle.slidableTextStyle(),
          ),
        ),
      );
    }

    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.18,
      children: children,
    );
  }

  Widget memberItem(int index) {
    var uid = controller.groupMemberListData[index].uid;
    // bool isOnline = (objectMgr.onlineMgr.friendOnlineString[uid] ??
    //         FormatTime.isOnline(
    //             controller.groupMemberListData[index].lastOnline)) ==
    //     localized(chatOnline);
    String onlineStatus = objectMgr.onlineMgr.friendOnlineString[uid] ??
        FormatTime.formatTimeFun(
          controller.groupMemberListData[index].lastOnline,
        );

    bool isOnline = onlineStatus == localized(chatOnline);

    if (objectMgr.userMgr.isMe(uid)) {
      isOnline = true;
      onlineStatus = localized(chatOnline);
    }

    return Obx(
      () {
        if (controller.groupMemberListData != null &&
            controller.groupMemberListData.length > index) {
          return ForegroundOverlayEffect(
            child: Container(
              color: colorWhite,
              width: MediaQuery.of(context).size.width,
              constraints: const BoxConstraints(maxHeight: 56),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Stack(
                      children: [
                        CustomAvatar.user(
                          controller.groupMemberListData[index],
                          size: 40,
                          headMin: Config().headMin,
                        ),
                        if (isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorGreen,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.0),
                              ),
                              height: 12,
                              width: 12,
                            ),
                          )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        border: customBorder,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                objectMgr.userMgr.isMe(controller
                                        .groupMemberListData[index].id)
                                    ? Text(
                                        localized(chatInfoYou),
                                        style: jxTextStyle.headerText(
                                          fontWeight:
                                              objectMgr.loginMgr.isDesktop
                                                  ? MFontWeight.bold4.value
                                                  : MFontWeight.bold5.value,
                                        ),
                                      )
                                    : NicknameText(
                                        isTappable: false,
                                        groupId: controller.groupId,
                                        uid: controller
                                            .groupMemberListData[index].id,
                                        fontSize: MFontSize.size17.value,
                                        fontWeight: objectMgr.loginMgr.isDesktop
                                            ? MFontWeight.bold4.value
                                            : MFontWeight.bold5.value,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                Visibility(
                                  visible: onlineStatus.isNotEmpty,
                                  child: Text(
                                    onlineStatus,
                                    style: jxTextStyle.normalSmallText(
                                      color: isOnline
                                          ? themeColor
                                          : colorTextSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Obx(
                            () => Visibility(
                              visible: controller.group.value?.owner ==
                                  controller.groupMemberListData[index].id,
                              child: Text(
                                localized(chatInfoOwner),
                                style: jxTextStyle.textStyle14(
                                  color: colorTextSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Obx(
                            () => Visibility(
                              visible: controller.adminList.contains(
                                  controller.groupMemberListData[index].id),
                              child: Text(
                                localized(chatInfoAdmin),
                                style: jxTextStyle.textStyle14(
                                  color: colorTextSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Container();
      },
    );
  }
}
