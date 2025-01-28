import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_factory.dart';
import 'package:jxim_client/home/chat/components/chat_cell_mute_action_pane.dart';
import 'package:jxim_client/home/chat/components/chat_cell_start_action_pane.dart';
import 'package:jxim_client/home/chat/controllers/chat_item_controller.dart';
import 'package:jxim_client/home/chat/component/chat_ui_base.dart';
import 'package:jxim_client/im/group_chat/group_chat_view.dart';
import 'package:jxim_client/im/services/animated_flip_counter.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/tasks/chat_typing_task.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

import '../../../views/component/check_tick_item.dart';

// 移动端聊天室组件View
class ChatUIComponent extends ChatUIBase<ChatItemController> {
  final double _maxChatCellHeight = 76;

  const ChatUIComponent({
    super.key,
    required super.chat,
    required super.index,
    required super.animation,
    required super.tag,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Slidable(
      key: Key(chat.id.toString()),
      enabled: !objectMgr.loginMgr.isDesktop && !controller.isSearching.value,
      closeOnScroll: true,
      startActionPane: createStartActionPane(context),
      endActionPane: createEndActionPane(context),
      child: createItemView(context, index),
    );

    if (animation != null) {
      return SizeTransition(
        sizeFactor: animation!,
        axisAlignment: 1.0,
        child: child,
      );
    }

    return child;
  }

  @override
  Widget createItemView(BuildContext context, int index) {
    final childWidget = Obx(
      () => Container(
        color: controller.isSelected.value
            ? JXColors.bgSelectedChatEdit
            : chat.sort != 0
                ? JXColors.bgPinColor
                : Colors.white,
        height: _maxChatCellHeight,
        child: OverlayEffect(
          child: Container(
            padding: jxDimension.messageCellPadding(),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 350),
                    alignment: Alignment.centerLeft,
                    curve: Curves.easeInOutCubic,
                    widthFactor: controller.isEditing.value ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.only(right: 8),
                      child: CheckTickItem(
                        isCheck: controller.isSelected.value,
                      ),
                    ),
                  ),
                ),

                /// 頭像
                Padding(
                  padding: const EdgeInsets.only(
                    left: 2.0,
                    right: 10.0,
                  ),
                  child: buildHeadView(context),
                ),

                /// 內容
                Expanded(
                  child: Container(
                    height: _maxChatCellHeight,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        titleBuilder(context),
                        const SizedBox(height: 4.0),
                        contentBuilder(context, index),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ), //OverlayEffect(child: child),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: controller.onItemClick,
      onLongPress: controller.onItemLongPress,
      child: childWidget,
    );
  }

  @override
  Widget buildHeadView(BuildContext context) {
    return CustomAvatar(
      key: ValueKey('${chat.id}_${Config().headMin}_24'),
      uid: chat.isGroup ? chat.id : chat.friend_id,
      size: jxDimension.chatListAvatarSize(),
      headMin: Config().headMin,
      isGroup: chat.isGroup,
      fontSize: 24.0,
      shouldAnimate: false,
    );
  }

  Widget titleBuilder(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: buildNameView(context)),
        buildTimeView(context),
      ],
    );
  }

  @override
  Widget buildNameView(BuildContext context) {
    return Obx(
      () => Row(
        children: <Widget>[
          Flexible(
            child: NicknameText(
              uid: chat.isSingle ? chat.friend_id : chat.id,
              displayName: chat.name,
              fontSize: MFontSize.size16.value,
              fontWeight: MFontWeight.bold5.value,
              color: JXColors.primaryTextBlack.withOpacity(1),
              isTappable: false,
              overflow: TextOverflow.ellipsis,
              fontSpace: 0,
            ),
          ),
          if (controller.isMuted.value)
            Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: SvgPicture.asset(
                'assets/svgs/mute_icon3.svg',
                width: 16,
                height: 16,
                fit: BoxFit.fill,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget buildTimeView(BuildContext context) {
    return Obx(
      () => controller.lastMessage.value != null &&
              controller.lastMessage.value!.create_time > 0
          ? Text(
              FormatTime.chartTime(
                controller.lastMessage.value!.create_time,
                true,
                todayShowTime: true,
                dateStyle: DateStyle.MMDDYYYY,
              ),
              style: jxTextStyle
                  .textStyle14(color: JXColors.secondaryTextBlack)
                  .useSystemChineseFont(),
            )
          : const SizedBox(),
    );
  }

  Widget contentBuilder(BuildContext context, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: buildContentView(context)),
        buildUnreadView(context),
      ],
    );
  }

  @override
  Widget buildContentView(BuildContext context) {
    return Obx(
      () {
        if (controller.isTyping.value) {
          return whoIsTypingWidget(
            ChatTypingTask.whoIsTyping[chat.id]!,
            jxTextStyle.chatCellContentStyle(),
            mainAlignment: MainAxisAlignment.start,
          );
        }

        if (controller.lastMessage.value != null) {
          return ChatCellContentFactory.createComponent(
            chat: chat,
            lastMessage: controller.lastMessage.value!,
            messageSendState: controller.lastMsgSendState.value,
          );
        }

        return const SizedBox(
          height: 20,
        );
      },
    );
  }

  @override
  Widget buildUnreadView(BuildContext context) {
    return Obx(() {
      if (controller.unreadCount.value <= 0 && !controller.isNewChat.value) {
        if (chat.sort != 0) {
          return Container(
            margin: const EdgeInsets.only(left: 8),
            constraints: const BoxConstraints(minWidth: 20, maxHeight: 24),
            child: SvgPicture.asset(
              'assets/svgs/chat_cell_pin_icon.svg',
              width: 20,
              height: 20,
              color: JXColors.iconPrimaryColor,
              fit: BoxFit.fill,
            ),
          );
        }
        return const SizedBox();
      }

      return Row(
        children: <Widget>[
          if (controller.isNewChat.value)
            Text(
              localized(homeNew),
              style:
                  jxTextStyle.textStyleBold14(color: const Color(0xFFEB6A61)),
              textAlign: TextAlign.center,
            ),
          if (objectMgr.chatMgr.mentionMessageMap[chat.chat_id] != null &&
              objectMgr.chatMgr.mentionMessageMap[chat.chat_id]!.length > 0)
            Container(
              margin:
                  EdgeInsets.only(left: objectMgr.loginMgr.isDesktop ? 10 : 8),
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: accentColor,
                shape: const CircleBorder(),
              ),
              child: Text(
                "@",
                style: jxTextStyle.textStyle14(
                  color: JXColors.primaryTextWhite,
                ),
              ),
            ),
          if (controller.unreadCount.value > 0)
            Container(
              height: 20,
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: controller.isMuted.value
                    ? JXColors.supportingTextBlack
                    : accentColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: controller.unreadCount.value < 999
                    ? AnimatedFlipCounter(
                        value: controller.unreadCount.value,
                        textStyle: jxTextStyle.textStyle12(
                          color: JXColors.primaryTextWhite,
                        ),
                      )
                    : Text(
                        '999+',
                        style: jxTextStyle.textStyle14(
                          color: JXColors.primaryTextWhite,
                        ),
                      ),
              ),
            )
        ],
      );
    });
  }

  @override
  ActionPane createStartActionPane(BuildContext context) {
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.2,
      children: [ChatCellStartActionPane(chat: chat)],
    );
  }

  @override
  ActionPane createEndActionPane(BuildContext context) {
    return ActionPane(
      motion: const DrawerMotion(),
      children: createEndActionChildren(context),
      extentRatio: !chat.isSaveMsg ? 0.6 : 0.2,
    );
  }

  @override
  List<Widget> createEndActionChildren(BuildContext context) {
    List<Widget> list_children = [];

    /// Mute
    list_children.add(ChatCellMuteActionPane(chat: chat));

    /// Delete
    list_children.add(
      CustomSlidableAction(
        onPressed: (context) => controller.onDeleteChat(context, chat),
        backgroundColor: JXColors.red,
        foregroundColor: JXColors.cIconPrimaryColor,
        padding: EdgeInsets.zero,
        flex: 7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svgs/delete2_icon.svg',
              width: 40.w,
              height: 40.w,
              fit: BoxFit.fill,
            ),
            SizedBox(height: 4.w),
            Text(
              localized(chatDelete),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jxTextStyle.slidableTextStyle(),
            ),
          ],
        ),
      ),
    );

    /// Hide
    list_children.add(
      CustomSlidableAction(
        onPressed: (context) => controller.hideChat(context, chat),
        backgroundColor: greyColorB2,
        foregroundColor: JXColors.cIconPrimaryColor,
        padding: EdgeInsets.zero,
        flex: 7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svgs/hide_icon.svg',
              width: 40.w,
              height: 40.w,
              fit: BoxFit.fill,
            ),
            SizedBox(height: 4.w),
            Text(
              localized(chatOptionsHide),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jxTextStyle.slidableTextStyle(),
            ),
          ],
        ),
      ),
    );

    return list_children;
  }
}
