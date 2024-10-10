import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_text.dart';
import 'package:jxim_client/home/chat/components/chat_cell_mute_action_pane.dart';
import 'package:jxim_client/home/chat/components/chat_cell_start_action_pane.dart';
import 'package:jxim_client/home/chat/components/chat_cell_time_text.dart';
import 'package:jxim_client/home/chat/components/chat_cell_unread_text.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/secretary_message_icon.dart';
import 'package:jxim_client/utils/system_message_icon.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views_desktop/component/chat_option_menu.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

// 桌面端 聊天室组件View
class DesktopChatUISpecialComponent extends GetView<ChatListController> {
  final double _maxChatCellHeight = 85;

  // 消息对象
  final Chat chat;
  final int index;
  final Animation<double>? animation;

  bool get isDesktop => true;

  const DesktopChatUISpecialComponent({
    super.key,
    required this.chat,
    required this.index,
    required this.animation,
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

  Widget createItemView(BuildContext context, int index) {
    final childWidget = Obx(() {
      return ElevatedButtonTheme(
        data: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor:
            controller.desktopSelectedChatID.value == chat.id && isDesktop
                ? colorDesktopChatBlue
                : controller.selectedChatIDForEdit.contains(chat.chat_id)
                ? themeColor.withOpacity(0.08)
                : chat.sort != 0
                ? colorBgPin
                : Colors.white,
            disabledBackgroundColor: Colors.white,
            shadowColor: Colors.transparent,
            surfaceTintColor: colorBorder,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            elevation: 0.0,
          ),
        ),
        child: GestureDetector(
          onSecondaryTapDown: (details) {
            desktopGeneralDialog(
              context,
              color: Colors.transparent,
              widgetChild: ChatOptionMenu(
                offset: details.globalPosition,
                chat: chat,
              ),
            );
          },
          child: MouseRegion(
            onEnter: (enterEvent) {
              controller.mousePosition = enterEvent.position;
            },
            onHover: (hoverEvent) {
              controller.mousePosition = hoverEvent.position;
            },
            child: ElevatedButton(
                onPressed: () {
                  if (!controller.isCTRLPressed()) {
                    Routes.toChat(chat: chat);
                  } else {
                    desktopGeneralDialog(
                      context,
                      color: Colors.transparent,
                      widgetChild: ChatOptionMenu(
                        offset: controller.mousePosition,
                        chat: chat,
                      ),
                    );
                  }
                },
                child: OverlayEffect(
                  child: Container(
                    padding: jxDimension.messageCellPadding(),
                    // color: Colors.green,
                    child: Row(
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        /// 點擊編輯後出現的左邊選取區塊
                        ClipRRect(
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 350),
                            alignment: Alignment.centerLeft,
                            curve: Curves.easeInOutCubic,
                            widthFactor: controller.isEditing.value ? 1 : 0,
                            child: Container(
                              padding: const EdgeInsets.only(right: 8),
                              child: CheckTickItem(
                                isCheck: controller.selectedChatIDForEdit
                                    .contains(chat.chat_id),
                              ),
                            ),
                          ),
                        ),

                        /// 頭像
                        Container(
                          margin: const EdgeInsets.only(
                            left: 2, //the another 8 is on parent.
                            right: 10,
                          ),
                          child: Stack(
                            children: [
                              buildHeadView(context),
                            ],
                          ),
                        ),

                        /// 內容
                        Expanded(
                          child: SizedBox(
                            // color: Colors.grey,
                            height: _maxChatCellHeight,
                            // width: 100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                titleBuilder(context),
                                const SizedBox(height: 4),
                                contentBuilder(context, index),
                                // Text("SHit")
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ),
        ),
      );
    });

    return childWidget;
  }

  Widget buildHeadView(BuildContext context) {
    switch (chat.typ) {
      case chatTypeSystem:
        return SystemMessageIcon(size: jxDimension.chatListAvatarSize());
      case chatTypeSaved:
        return SavedMessageIcon(size: jxDimension.chatListAvatarSize());
      case chatTypeSmallSecretary:
        return SecretaryMessageIcon(size: jxDimension.chatListAvatarSize());
      default:
        return CustomAvatar.chat(
          chat,
          size: jxDimension.chatListAvatarSize(),
          headMin: Config().headMin,
          fontSize: 24.0,
          shouldAnimate: false,
        );
    }
  }

  Widget titleBuilder(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Row(
          children: [
            buildNameView(context),
            buildIcon(),
          ],
        )),
        buildTimeView(context),
      ],
    );
  }

  Widget buildIcon(){
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: SvgPicture.asset(
        'assets/svgs/secretary_check_icon.svg',
        width: 15,
        height: 15,
        colorFilter: ColorFilter.mode(
          themeColor,
          BlendMode.srcIn,
        ),
        fit: BoxFit.fitWidth,
      ),
    );
  }

  Widget buildNameView(BuildContext context) {
    return Text(
      specialChatName(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: MFontWeight.bold4.value,
        fontSize: MFontSize.size14.value,
        color: controller.desktopSelectedChatID.value == chat.id && isDesktop
            ? colorWhite
            : colorTextPrimary,
        decoration: TextDecoration.none,
        letterSpacing: 0,
        overflow: TextOverflow.ellipsis,
        height: 1.2,
      ),
    );
  }

  String specialChatName(){
    switch (chat.typ) {
      case chatTypeSystem:
        return localized(chatSystem);
      case chatTypeSaved:
        return localized(homeSavedMessage);
      case chatTypeSmallSecretary:
        return localized(chatSecretary);
      default:
        return localized(chatSystem);
    }
  }

  Widget buildTimeView(BuildContext context) {
    return ChatCellTimeText(chat: chat);
  }

  Widget contentBuilder(BuildContext context, int index) {
    return Row(
      children: <Widget>[
        Expanded(child: buildContentView(context)),
        buildUnreadView(context),
      ],
    );
  }

  Widget buildContentView(BuildContext context) {
    return ChatCellContentText(chat: chat);
  }

  Widget buildUnreadView(BuildContext context) {
    return ChatCellUnreadText(chat: chat);
  }

  ActionPane createStartActionPane(BuildContext context) {
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.2,
      children: [ChatCellStartActionPane(chat: chat)],
    );
  }

  ActionPane createEndActionPane(BuildContext context) {
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: !chat.isSaveMsg ? 0.6 : 0.2,
      children: createEndActionChildren(context),
    );
  }

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
