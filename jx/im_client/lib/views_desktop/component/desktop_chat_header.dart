import 'package:agora/agora_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';

class DesktopChatHeader extends StatelessWidget {
  const DesktopChatHeader({
    super.key,
    required this.isSearching,
    required this.selectedChat,
    required this.onTap,
    required this.backOnTapped,
    this.isTyping = false,
    this.user,
    this.group,
  });

  final RxBool isSearching;
  final Chat selectedChat;
  final Function() onTap;
  final Function() backOnTapped;
  final bool isTyping;
  final User? user;
  final Group? group;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: colorBackground,
        border: Border(
          bottom: BorderSide(
            color: colorBackground6,
            width: 1,
          ),
        ),
      ),
      child: Obx(
        () => !isSearching.value
            ? DesktopGeneralButton(
                horizontalPadding: 0,
                onPressed: onTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    if (ObjectMgr.screenMQ!.size.width <= 675)
                      DesktopGeneralButton(
                        horizontalPadding: 0,
                        onPressed: backOnTapped,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: SvgPicture.asset(
                            'assets/svgs/Back.svg',
                            width: 24,
                            height: 24,
                            color: colorTextSecondary,
                          ),
                        ),
                      )
                    else
                      const SizedBox(
                        width: 10,
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            buildPhoto(
                              selectedChat,
                              36,
                            ),
                            Flexible(
                              child: getTitle(selectedChat),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(),
                    Row(
                      children: [
                        DesktopGeneralButton(
                          horizontalPadding: 15,
                          onPressed: () {
                            Toast.showToast(localized(homeToBeContinue));
                          },
                          child: const Icon(
                            Icons.search,
                            color: colorTextSecondary,
                            size: 20,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: VerticalDivider(
                            color: colorBackground6,
                            thickness: 1,
                          ),
                        ),
                        DesktopGeneralButton(
                          horizontalPadding: 15,
                          onPressed: () {
                            if (selectedChat.isValid) {
                              if (objectMgr.callMgr.getCurrentState() !=
                                  CallState.Idle) {
                                Toast.showToast(localized(toastEndCall));
                              } else {
                                audioManager.audioStateBtnClick(context);
                              }
                            } else {
                              Toast.showToast(
                                localized(youAreNoLongerInThisGroup),
                              );
                            }
                          },
                          child: const Icon(
                            Icons.call,
                            color: colorTextSecondary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : const SizedBox(),
      ),
    );
  }

  Widget buildPhoto(Chat selectedChat, double standardSize) {
    Widget child;
    final Key key = ValueKey(selectedChat.chat_id);
    if (selectedChat.typ == chatTypeSystem) {
      child = SystemMessageIcon(
        size: standardSize,
      );
    } else if (selectedChat.typ == chatTypeSmallSecretary) {
      child = SecretaryMessageIcon(
        size: standardSize,
      );
    } else if (selectedChat.typ == chatTypeSaved) {
      child = SavedMessageIcon(
        size: standardSize,
      );
    } else if (selectedChat.typ == chatTypeGroup) {
      child = CustomAvatar.chat(
        selectedChat,
        size: standardSize,
        key: key,
      );
    } else {
      child = CustomAvatar.normal(
        selectedChat.friend_id,
        size: standardSize,
        key: key,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        right: 12,
        left: 16,
      ),
      child: child,
    );
  }

  Widget getTitle(Chat selectedChat) {
    final Widget childWidget;
    String chatroomDetail = '';
    switch (selectedChat.typ) {
      case chatTypeSaved:
        childWidget = Text(
          localized(homeSavedMessage),
          style: jxTextStyle.secretaryChatTitleStyle(),
        );
        chatroomDetail = '';
        break;
      case chatTypeSystem:
        childWidget = Text(
          localized(homeSystemMessage),
          style: jxTextStyle.secretaryChatTitleStyle(),
        );
        chatroomDetail = '';
        break;
      case chatTypeSmallSecretary:
        childWidget = Text(
          localized(chatSecretary),
          style: jxTextStyle.secretaryChatTitleStyle(),
        );
        chatroomDetail = '';
        break;
      default:
        childWidget = NicknameText(
          key: ValueKey(selectedChat.name),
          uid: selectedChat.typ == chatTypeSingle
              ? selectedChat.friend_id
              : selectedChat.chat_id,
          isGroup: selectedChat.typ == chatTypeGroup,
          fontSize: MFontSize.size16.value,
          fontWeight: MFontWeight.bold5.value,
          color: colorTextPrimary,
          overflow: TextOverflow.ellipsis,
          isTappable: false,
        );
        if (selectedChat.typ == chatTypeSingle && user != null) {
          if (isTyping) {
            chatroomDetail = localized(chatTyping);
          } else {
            chatroomDetail = UserUtils.onlineStatus(user!.lastOnline);
          }
        } else if (selectedChat.typ == chatTypeGroup && group != null) {
          chatroomDetail =
              UserUtils.groupMembersLengthInfo(group!.members.length);
        }
        break;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        childWidget,
        Text(
          chatroomDetail,
          style: const TextStyle(
            color: colorTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
