import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/hover_click_builder.dart';
import 'package:jxim_client/views_desktop/component/desktop_chat_option.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';

class ChatOptionMenu extends StatefulWidget {
  const ChatOptionMenu({
    super.key,
    required this.offset,
    required this.chat,
  });

  final Offset offset;
  final Chat chat;

  @override
  State<ChatOptionMenu> createState() => _ChatOptionMenuState();
}

class _ChatOptionMenuState extends State<ChatOptionMenu> {
  final GlobalKey _widgetKey = GlobalKey();
  double topStartingPoint = 0;
  final ChatListController controller = Get.find<ChatListController>();
  List<MenuListItem> itemList = [];

  @override
  void initState() {
    super.initState();
    itemList = getMenuList();
    topStartingPoint = widget.offset.dy;
    contentReplace();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.back(),
      onSecondaryTap: () => Get.back(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            AnimatedPositioned(
              key: _widgetKey,
              left: widget.offset.dx,
              top: topStartingPoint,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              child: Container(
                width: 150,
                padding: const EdgeInsets.symmetric(vertical: 4),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFF4F7F9).withOpacity(0.75),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: colorTextPrimary.withOpacity(0.15),
                    )
                  ],
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: itemList.length,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final item = itemList[index];
                      return _ChatOptionMenu(
                        item: item,
                        index: index,
                        lastIndex: itemList.length,
                      );
                    },
                    // separatorBuilder: (_, __) => const CustomDivider(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void contentReplace() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final RenderBox renderBox =
          _widgetKey.currentContext!.findRenderObject() as RenderBox;
      final double widgetHeight = renderBox.size.height;
      final screenHeight = ObjectMgr.screenMQ!.size.height;
      if (widget.offset.dy + widgetHeight >= (screenHeight - 60)) {
        setState(() {
          final double yReplacement =
              widget.offset.dy + widgetHeight - screenHeight + 60;
          topStartingPoint = widget.offset.dy - yReplacement;
        });
      }
    });
  }

  List<MenuListItem> getMenuList() {
    List<MenuListItem> listItem = [];

    listItem.add(
      MenuListItem(
        icon: widget.chat.sort != 0
            ? 'assets/svgs/desktop_unpin.svg'
            : 'assets/svgs/desktop_pin.svg',
        title:
            widget.chat.sort != 0 ? localized(chatUnpin) : localized(chatPin),
        onPressed: () {
          Get.back();
          if (Get.isRegistered<ChatListController>()) {
            Get.find<ChatListController>().onPinnedChat(context, widget.chat);
          }
        },
      ),
    );
    if (!widget.chat.isSaveMsg) {
      listItem.add(
        MenuListItem(
          icon: checkIsMute(widget.chat.mute)
              ? 'assets/svgs/desktop_unmute.svg'
              : 'assets/svgs/desktop_mute.svg',
          title: checkIsMute(widget.chat.mute)
              ? localized(unmute)
              : localized(mute),
          onPressed: () async {
            Get.back();
            try {
              objectMgr.chatMgr.onChatMute(widget.chat,
                  expireTime: checkIsMute(widget.chat.mute) ? 0 : -1,
                  isNotHomePage: true);
              widget.chat.isMuteRX.value = !checkIsMute(widget.chat.mute);
              objectMgr.chatMgr.updateNotificationStatus(
                widget.chat,
                checkIsMute(widget.chat.mute) ? 0 : -1,
              );
            } catch (e) {
              pdebug('desktop mute chat error');
            }
          },
        ),
      );
    }

    listItem.add(
      MenuListItem(
        icon: widget.chat.typ == chatTypeSmallSecretary || widget.chat.isSaveMsg
            ? 'assets/svgs/desktop_clear.svg'
            : 'assets/svgs/desktop_hide.svg',
        title:
            widget.chat.typ == chatTypeSmallSecretary || widget.chat.isSaveMsg
                ? localized(chatClear)
                : localized(chatHide),
        onPressed: () {
          Get.back();
          final Chat chat = widget.chat;
          if (chat.typ == chatTypeSmallSecretary || widget.chat.isSaveMsg) {
            desktopGeneralDialog(
              context,
              widgetChild: DesktopChatOptionDialog(
                title: localized(chatClearHistory),
                subtitle: localized(chatDoYouWantToClear),
                chat: chat,
                function: () async {
                  try {
                    await objectMgr.chatMgr.clearMessage(chat);
                  } catch (e) {
                    pdebug('desktop clear chat error');
                  } finally {
                    Get.back();
                  }
                },
              ),
            );
          } else {
            desktopGeneralDialog(
              context,
              widgetChild: DesktopChatOptionDialog(
                title: localized(chatHideChat),
                subtitle: localized(chatDoYouWantToHide),
                chat: chat,
                function: () async {
                  try {
                    await objectMgr.chatMgr.setChatHide(chat);
                  } catch (e) {
                    pdebug('desktop hide chat error');
                  } finally {
                    Get.back();
                  }
                },
              ),
            );
          }
        },
      ),
    );
    if (!widget.chat.isSaveMsg) {
      listItem.add(
        MenuListItem(
          icon: 'assets/svgs/desktop_delete.svg',
          title: localized(delete),
          onPressed: () {
            Get.back();
            desktopGeneralDialog(
              context,
              widgetChild: DesktopChatOptionDialog(
                title: localized(chatDeleteChat),
                subtitle: localized(chatDoYouWantToDelete),
                chat: widget.chat,
                function: () async {
                  try {
                    await objectMgr.chatMgr.onChatDelete(widget.chat);
                  } catch (e) {
                    pdebug('desktop delete chat error');
                  } finally {
                    Get.back();
                    Get.back(id: 1);
                  }
                },
              ),
            );
          },
          color: colorRed,
        ),
      );
    }
    return listItem;
  }
}

class _ChatOptionMenu extends StatelessWidget {
  const _ChatOptionMenu({
    required this.item,
    required this.index,
    required this.lastIndex,
  });

  final MenuListItem item;
  final int index;
  final int lastIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onPressed,
      behavior: HitTestBehavior.opaque,
      child: HoverClickBuilder(
        builder: (bool isHovered, bool isClick) {
          return Transform.scale(
            scale: isClick ? 0.95 : 1,
            child: Container(
              decoration: BoxDecoration(
                color: isHovered || isClick ? colorBackground6 : null,
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                height: 30,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.title,
                        style: TextStyle(
                            fontSize: 14,
                            height: jxTextStyle.textHeight,
                            color: item.color)),
                    SvgPicture.asset(
                      item.icon,
                      width: 16,
                      height: 16,
                      fit: BoxFit.fill,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MenuListItem {
  final String icon;
  final String title;
  final Function() onPressed;
  final Color color;

  const MenuListItem({
    required this.icon,
    required this.title,
    required this.onPressed,
    this.color = Colors.black,
  });
}

bool checkIsMute(int timeStamp) {
  return DateTime.now().millisecondsSinceEpoch ~/ 1000 < timeStamp ||
      timeStamp == -1;
}
