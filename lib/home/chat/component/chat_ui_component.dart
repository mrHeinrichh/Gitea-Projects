import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component/chat_ui_base.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_factory.dart';
import 'package:jxim_client/home/chat/components/chat_cell_mute_action_pane.dart';
import 'package:jxim_client/home/chat/components/chat_cell_start_action_pane.dart';
import 'package:jxim_client/home/chat/controllers/chat_item_controller.dart';
import 'package:jxim_client/im/custom_input/component/text_input_field.dart';
import 'package:jxim_client/im/group_chat/group_chat_view.dart';
import 'package:jxim_client/im/services/animated_flip_counter.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/tasks/chat_typing_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

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
        color: chat.sort != 0 ? colorBgPin : Colors.white,
        foregroundDecoration: BoxDecoration(
          color: controller.isSelected.value
              ? themeColor.withOpacity(0.08)
              : Colors.transparent,
        ),
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
    return Stack(
      children: <Widget>[
        CustomAvatar.chat(
          key: ValueKey('${chat.id}_${Config().headMin}_24'),
          chat,
          size: jxDimension.chatListAvatarSize(),
          headMin: Config().headMin,
          fontSize: 24.0,
          shouldAnimate: false,
        ),
        if (controller.autoDeleteInterval.value > 0)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: colorTextPlaceholder,
                shape: BoxShape.circle,
              ),
              height: 20,
              width: 20,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/svgs/icon_auto_delete.svg',
                    fit: BoxFit.contain,
                    height: 19,
                    width: 19,
                  ),
                  Text(
                    parseAutoDeleteInterval(
                      controller.autoDeleteInterval.value,
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: MFontWeight.bold6.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget titleBuilder(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: buildNameView(context)),
        const SizedBox(width: 12.0),
        buildTimeView(context),
      ],
    );
  }

  @override
  Widget buildNameView(BuildContext context) {
    return Obx(
      () {
        return Row(
          children: <Widget>[
            Visibility(
              visible: controller.chat.isEncrypted,
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: SvgPicture.asset(
                  'assets/svgs/chat_icon_encrypted.svg',
                  width: 16,
                  height: 16,
                ),
              ),
            ),
            Flexible(
              child: NicknameText(
                uid: chat.isSingle ? chat.friend_id : chat.id,
                displayName: chat.name,
                fontSize: MFontSize.size16.value,
                fontWeight: MFontWeight.bold5.value,
                color: colorTextPrimary.withOpacity(1),
                isTappable: false,
                isGroup: chat.isGroup,
                overflow: TextOverflow.ellipsis,
                fontSpace: 0,
              ),
            ),
            if (chat.isTmpGroup)
              Padding(
                padding: const EdgeInsets.only(left: 2.0),
                child: SvgPicture.asset(
                  'assets/svgs/temporary_indicator.svg',
                  width: 16,
                  height: 16,
                  fit: BoxFit.fill,
                  colorFilter: ColorFilter.mode(
                    controller.isGroupExpireSoon.value ? colorRed : themeColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            if (controller.isMuted.value)
              Padding(
                padding: const EdgeInsets.only(left: 2.0),
                child: SvgPicture.asset(
                  'assets/svgs/mute_icon3.svg',
                  width: 16,
                  height: 16,
                  fit: BoxFit.fill,
                ),
              ),
          ],
        );
      });
  }

  @override
  Widget buildTimeView(BuildContext context) {
    return Obx(
      () {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (chat.showMessageReadIcon &&
                controller.lastMessage.value != null &&
                controller.lastMessage.value!.hasReadView &&
                controller.lastMsgSendState.value == MESSAGE_SEND_SUCCESS &&
                objectMgr.userMgr.isMe(controller.lastMessage.value!.send_id))
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: SvgPicture.asset(
                  controller.messageIsRead.value
                      ? 'assets/svgs/done_all_icon.svg'
                      : 'assets/svgs/unread_tick_icon.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    colorReadColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            if (controller.lastMessage.value != null &&
                controller.lastMessage.value!.create_time > 0)
              Text(
                FormatTime.chartTime(
                  controller.lastMessage.value!.create_time,
                  true,
                  todayShowTime: true,
                  dateStyle: DateStyle.MMDDYYYY,
                ),
                style: jxTextStyle
                    .textStyle14(color: colorTextSecondary)
                    .useSystemChineseFont(),
              ),
          ],
        );
      },
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
        if (controller.draftString.value.isNotEmpty) {
          return RichText(
            text: TextSpan(
              style: jxTextStyle.chatCellContentStyle(
                color: colorTextSecondarySolid,
              ),
              children: <InlineSpan>[
                TextSpan(
                  text: '${localized(chatDraft)}: ',
                  style: jxTextStyle.textStyle14(color: colorRed),
                ),
                TextSpan(text: controller.draftString.value),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        if (controller.isTyping.value) {
          return whoIsTypingWidget(
            ChatTypingTask.whoIsTyping[chat.id]!,
            jxTextStyle.chatCellContentStyle(),
            isSingleChat: chat.isSingle,
            mainAlignment: MainAxisAlignment.start,
          );
        }

        if (controller.lastMessage.value != null) {
          return ChatCellContentFactory.createComponent(
            chat: chat,
            lastMessage: controller.lastMessage.value!,
            messageSendState: controller.lastMsgSendState.value,
            isVoicePlayed: controller.isVoicePlayed.value,
          );
        }

        return const SizedBox(height: 20);
      },
    );
  }

  @override
  Widget buildUnreadView(BuildContext context) {
    return Obx(() {
      final bool hasMention =
          notBlank(objectMgr.chatMgr.mentionMessageMap[chat.chat_id]);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasMention)
            Container(
              margin:
                  EdgeInsets.only(left: objectMgr.loginMgr.isDesktop ? 10 : 8),
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: themeColor,
                shape: const CircleBorder(),
              ),
              child: Text(
                "@",
                style: jxTextStyle.textStyle14(
                  color: colorWhite,
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
                color:
                    controller.isMuted.value ? colorTextSupporting : themeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: controller.unreadCount.value < 999
                    ? AnimatedFlipCounter(
                        value: controller.unreadCount.value,
                        textStyle: jxTextStyle.textStyle15(
                          color: colorWhite,
                        ),
                      )
                    : Text(
                        '999+',
                        style: jxTextStyle.textStyle15(
                          color: colorWhite,
                        ),
                      ),
              ),
            ),
          if (!hasMention && chat.sort != 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              constraints: const BoxConstraints(minWidth: 20, maxHeight: 24),
              child: SvgPicture.asset(
                'assets/svgs/chat_cell_pin_icon.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  colorTextSupporting,
                  BlendMode.srcIn,
                ),
                fit: BoxFit.fill,
              ),
            ),
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
      extentRatio: !chat.isSpecialChat ? 0.6 : 0.2,
      children: createEndActionChildren(context),
    );
  }

  @override
  List<Widget> createEndActionChildren(BuildContext context) {
    List<Widget> listChildren = [];

    /// Mute
    listChildren.add(ChatCellMuteActionPane(chat: chat));

    /// Delete
    listChildren.add(
      CustomSlidableAction(
        onPressed: (context) => controller.onDeleteChat(context, chat),
        backgroundColor: colorRed,
        foregroundColor: colorWhite,
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
    listChildren.add(
      CustomSlidableAction(
        onPressed: (context) => controller.hideChat(context, chat),
        backgroundColor: colorGrey,
        foregroundColor: colorWhite,
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

    return listChildren;
  }
}
