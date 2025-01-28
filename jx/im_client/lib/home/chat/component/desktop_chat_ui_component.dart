import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_text.dart';
import 'package:jxim_client/home/chat/components/chat_cell_time_text.dart';
import 'package:jxim_client/home/chat/components/chat_cell_unread_text.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/custom_input/component/text_input_field.dart';
import 'package:jxim_client/managers/object_mgr.dart';
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
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views_desktop/component/chat_option_menu.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

// 桌面端 聊天室组件View
class DesktopChatUIComponent extends StatelessWidget {
  final Chat chat;
  final int index;

  const DesktopChatUIComponent({
    super.key,
    required this.chat,
    required this.index,
  });

  final double _maxChatCellHeight = 70;

  ChatListController get controller => Get.find<ChatListController>();

  bool get isDesktop => true;

  @override
  Widget build(BuildContext context) {
    return createItemView(context, index);
  }

  Widget createItemView(BuildContext context, int index) {
    final childWidget = Obx(() {
      final isOnline = objectMgr.onlineMgr.friendOnlineString[chat.friend_id] ==
          localized(chatOnline);
      final enableAudio = chat.enableAudioChat.value;
      final isSingle = chat.typ == chatTypeSingle;
      Widget child = OverlayEffect(
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
                        if (isOnline && !enableAudio && isSingle)
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
                              height: 14,
                              width: 14,
                            ),
                          )
                        else if (chat.autoDeleteEnabled && !enableAudio)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorOverlay40,
                              ),
                              height: 20,
                              width: 20,
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 5.0, sigmaY: 5.0),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: <Widget>[
                                      SvgPicture.asset(
                                        'assets/svgs/icon_auto_delete.svg',
                                        fit: BoxFit.contain,
                                        height: 22,
                                        width: 22,
                                      ),
                                      Text(
                                        parseAutoDeleteInterval(
                                            chat.autoDeleteInterval),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20 * 0.4,
                                          fontWeight: MFontWeight.bold6.value,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else if (enableAudio)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: SvgPicture.asset(
                              'assets/svgs/agora_mark_icon.svg',
                              width: 20,
                              height: 20,
                            ),
                          ),
                      ],
                    ),
                  ),

                  /// 內容
                  Expanded(
                    child: SizedBox(
                      key: ValueKey('chat_cell_${chat.id}_$index'),
                      height: _maxChatCellHeight,
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
      );

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
          child: Container(
            decoration: BoxDecoration(
              color:
                  controller.desktopSelectedChatID.value == chat.id && isDesktop
                      ? colorDesktopChatBlue
                      : controller.selectedChatIDForEdit.contains(chat.chat_id)
                          ? themeColor.withOpacity(0.08)
                          : chat.sort != 0
                              ? colorBgPin
                              : Colors.white,
            ),
            child: child,
          ),
        ),
      );
    });

    return childWidget;
  }

  Widget buildHeadView(BuildContext context) {
    return CustomAvatar.chat(
      key: ValueKey('chat_avatar_${chat.id}_28'),
      chat,
      size: jxDimension.chatListAvatarSize(),
      headMin: Config().headMin,
      fontSize: 28.0,
      shouldAnimate: false,
    );
  }

  Widget titleBuilder(BuildContext context) {
    return Row(
      children: <Widget>[
        if (chat.isEncrypted)
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: SvgPicture.asset(
              'assets/svgs/chat_icon_encrypted.svg',
              width: 16,
              height: 16,
            ),
          ),
        Expanded(child: buildNameView(context)),
        buildTimeView(context),
      ],
    );
  }

  Widget buildNameView(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: NicknameText(
            uid: chat.typ == chatTypeSingle ? chat.friend_id : chat.id,
            displayName: chat.name,
            isGroup: chat.isGroup,
            color:
                controller.desktopSelectedChatID.value == chat.id && isDesktop
                    ? colorWhite
                    : colorTextPrimary,
            isTappable: false,
            fontSize: 15,
            fontWeight: MFontWeight.bold5.value,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (chat.isMuteRX.value || chat.isMute)
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
