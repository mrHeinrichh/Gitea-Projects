import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/managers/chat_mgr.dart';

class MemberView extends StatefulWidget {
  final GroupChatInfoController groupController;

  const MemberView({super.key, required this.groupController});

  @override
  State<MemberView> createState() => _MemberTabState();
}

class _MemberTabState extends State<MemberView>
    with AutomaticKeepAliveClientMixin {
  late final controller = widget.groupController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    objectMgr.chatMgr.on(ChatMgr.eventLastSeenStatus, _onLastSeenChanged);
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventLastSeenStatus, _onLastSeenChanged);
    super.dispose();
  }

  void _onLastSeenChanged(Object sender, Object type, Object? data) {
    if (mounted) {
      setState(() {});
    }
  }

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
            style: jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
          ),
        ],
      );
    }

    return CustomScrollView(
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
                  color: JXColors.bgSecondaryColor,
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SvgPicture.asset(
                          'assets/svgs/add_friends_plus.svg',
                          width: 40,
                          height: 40,
                          colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
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
                            style: jxTextStyle.textStyle16(color: accentColor),
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
                final _key = ValueKey(controller.groupMemberListData[index].id);
                return Builder(builder: (BuildContext context) {
                  return Slidable(
                    key: _key,
                    enabled: (controller.isOwner.value ||
                            controller.isAdmin.value) &&
                        !objectMgr.userMgr
                            .isMe(controller.groupMemberListData[index].id),
                    closeOnScroll: true,
                    endActionPane: _createEndActionPane(context, index),
                    child: GestureDetector(
                      key: _key,
                      onTap: () => controller.onMemberClicked(
                          controller.groupMemberListData[index].id),
                      onLongPress: () {
                        if ((controller.isOwner.value ||
                                controller.isAdmin.value) &&
                            !objectMgr.userMgr.isMe(
                                controller.groupMemberListData[index].id)) {
                          RenderBox renderBox =
                              context.findRenderObject() as RenderBox;
                          controller.onMemberItemLongPress(
                            context,
                            renderBox,
                            index,
                            target: memberItem(index),
                          );
                        }
                      },
                      child: memberItem(index),
                    ),
                  );
                });
              },
              childCount: controller.groupMemberListData.length,
            ),
          ),
        ),
      ],
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
          backgroundColor: JXColors.red,
          foregroundColor: JXColors.cIconPrimaryColor,
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
      children: children,
      extentRatio: 0.18,
    );
  }

  Widget memberItem(int index) {
    var uid = controller.groupMemberListData[index].id;
    if (objectMgr.userMgr.friendOnlineTime.containsKey(uid) &&
        controller.groupMemberListData[index].lastOnline <
            objectMgr.userMgr.friendOnlineTime[uid]!) {
      controller.groupMemberListData[index].lastOnline =
          objectMgr.userMgr.friendOnlineTime[uid]!;
    }
    return Obx(
      () {
        return ForegroundOverlayEffect(
          child: Container(
            color: JXColors.bgSecondaryColor,
            width: MediaQuery.of(context).size.width,
            constraints: const BoxConstraints(maxHeight: 56),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Stack(
                    children: [
                      CustomAvatar(
                        uid: controller.groupMemberListData[index].id,
                        size: 40,
                        headMin: Config().headMin,
                      ),
                      if (FormatTime.isOnline(
                          controller.groupMemberListData[index].lastOnline))
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: JXColors.green,
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
                              objectMgr.userMgr.isMe(
                                      controller.groupMemberListData[index].id)
                                  ? Text(
                                      localized(chatInfoYou),
                                      style: objectMgr.loginMgr.isDesktop
                                          ? jxTextStyle.textStyle13()
                                          : jxTextStyle.textStyleBold16(
                                              fontWeight:MFontWeight.bold6.value,
                                            ),
                                    )
                                  : NicknameText(
                                      isTappable: false,
                                      uid: controller
                                          .groupMemberListData[index].id,
                                      fontSize: objectMgr.loginMgr.isDesktop
                                          ? MFontSize.size13.value
                                          : MFontSize.size16.value,
                                      fontWeight: objectMgr.loginMgr.isDesktop
                                          ?MFontWeight.bold4.value
                                          :MFontWeight.bold6.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              const SizedBox(
                                height: 2,
                              ),
                              Visibility(
                                visible: controller
                                        .groupMemberListData[index].lastOnline >
                                    0,
                                child: Text(
                                  FormatTime.formatTimeFun(controller
                                      .groupMemberListData[index].lastOnline),
                                  style: jxTextStyle.textStyle14(
                                    color: (FormatTime.isOnline(controller
                                            .groupMemberListData[index]
                                            .lastOnline))
                                        ? accentColor
                                        : JXColors.secondaryTextBlack,
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
                                color: JXColors.secondaryTextBlack,
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
                                color: JXColors.secondaryTextBlack,
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
      },
    );
  }
}
