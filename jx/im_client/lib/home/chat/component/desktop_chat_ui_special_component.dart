import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_text.dart';
import 'package:jxim_client/home/chat/components/chat_cell_time_text.dart';
import 'package:jxim_client/home/chat/components/chat_cell_unread_text.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/special_avatar/mini_app_icon.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';
import 'package:jxim_client/views_desktop/component/chat_option_menu.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

// 桌面端 聊天室组件View
class DesktopChatUISpecialComponent extends GetView<ChatListController> {
  final double _maxChatCellHeight = 70;

  // 消息对象
  final Chat chat;
  final int index;

  bool get isDesktop => true;

  const DesktopChatUISpecialComponent({
    super.key,
    required this.chat,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return createItemView(context, index);
  }

  Widget createItemView(BuildContext context, int index) {
    final childWidget = Obx(() {
      return GestureDetector(
        onTap: () {
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
          child: OverlayEffect(
            child: Container(
              decoration: BoxDecoration(
                color: controller.desktopSelectedChatID.value == chat.id &&
                        isDesktop
                    ? colorDesktopChatBlue
                    : controller.selectedChatIDForEdit.contains(chat.chat_id)
                        ? themeColor.withOpacity(0.08)
                        : chat.sort != 0
                            ? colorBgPin
                            : Colors.white,
              ),
              child: Column(
                children: [
                  Container(
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
                  Padding(
                    padding: EdgeInsets.only(
                      left: jxDimension.chatCellPadding(),
                    ),
                    child: const CustomDivider(),
                  )
                ],
              ),
            ),
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
      case chatTypeMiniApp:
        return MiniAppIcon(size: jxDimension.chatListAvatarSize());
      default:
        return CustomAvatar.chat(
          key: ValueKey('chat_avatar_${chat.id}_28'),
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
        Expanded(
            child: Row(
          children: [
            buildNameView(context),
            buildIcon(),
          ],
        )),
        buildTimeView(context),
      ],
    );
  }

  Widget buildIcon() {
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
        fontSize: 14,
        color: controller.desktopSelectedChatID.value == chat.id
            ? colorWhite
            : colorTextPrimary,
        decoration: TextDecoration.none,
        letterSpacing: 0,
        overflow: TextOverflow.ellipsis,
        height: 1.2,
      ),
    );
  }

  String specialChatName() {
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
}
