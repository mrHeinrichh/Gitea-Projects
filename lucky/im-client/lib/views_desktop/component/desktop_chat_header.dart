import 'package:agora/agora_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/utils/toast.dart';
import '../../im/model/group/group.dart';
import '../../managers/object_mgr.dart';
import '../../object/chat/chat.dart';
import '../../object/user.dart';
import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/saved_message_icon.dart';
import '../../utils/secretary_message_icon.dart';
import '../../utils/system_message_icon.dart';
import '../../utils/theme/text_styles.dart';
import '../../utils/user_utils.dart';
import '../../views/component/nickname_text.dart';
import '../../views/component/custom_avatar.dart';
import 'desktop_general_button.dart';

class DesktopChatHeader extends StatelessWidget {
  const DesktopChatHeader({
    Key? key,
    required this.isSearching,
    required this.selectedChat,
    required this.onTap,
    required this.backOnTapped,
    this.isTyping = false,
    this.user,
    this.group,
  }) : super(key: key);

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
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(
          bottom: BorderSide(
            color: JXColors.outlineColor,
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
                  /// 普通界面
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
                            color: JXColors.secondaryTextBlack,
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
                            color: JXColors.secondaryTextBlack,
                            size: 20,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: VerticalDivider(
                            color: JXColors.outlineColor,
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
                                  localized(youAreNoLongerInThisGroup));
                            }
                          },
                          child: const Icon(
                            Icons.call,
                            color: JXColors.secondaryTextBlack,
                            size: 20,
                          ),
                        ),
                        // const Padding(
                        //   padding: EdgeInsets.symmetric(vertical: 20),
                        //   child: VerticalDivider(
                        //     color: JXColors.outlineColor,
                        //     thickness: 1,
                        //   ),
                        // ),
                        // DesktopGeneralButton(
                        //   horizontalPadding: 15,
                        //   onPressed: () {},
                        //   child: const Icon(
                        //     Icons.call,
                        //     color: JXColors.secondaryTextBlack,
                        //     size: 20,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              )
            // : Row(
            //     /// 搜索的界面
            //     children: [
            //       Padding(
            //         padding: const EdgeInsets.only(left: 10),
            //         child: DesktopGeneralButton(
            //           onPressed: () => chatController.isSearching.value = false,
            //           child: Icon(
            //             Icons.arrow_back_ios,
            //             color: activeIconColor,
            //             size: 15,
            //           ),
            //         ),
            //       ),
            //       Flexible(
            //         child: Padding(
            //           padding: const EdgeInsets.all(5),
            //           child: DesktopSearchingBar(
            //             height: 30,
            //             iconSize: 15,
            //             fontSize: 12,
            //             controller: chatController.searchController,
            //           ),
            //         ),
            //       ),
            //       Padding(
            //         padding: const EdgeInsets.only(right: 10),
            //         child: DesktopGeneralButton(
            //           onPressed: () {
            //             Toast.showToast(
            //               'Search by Calendar, coming soon',
            //             );
            //           },
            //           child: Icon(
            //             Icons.calendar_month_outlined,
            //             color: activeIconColor,
            //             size: 15,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),

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
      child = CustomAvatar(
        uid: selectedChat.id,
        size: standardSize,
        isGroup: true,
        key: key,
      );
    } else {
      child = CustomAvatar(
        uid: selectedChat.friend_id,
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
          fontSize: 16,
          fontWeight: MFontWeight.bold5.value,
          color: JXColors.primaryTextBlack,
          overflow: TextOverflow.ellipsis,
          isTappable: false,
        );
        if (selectedChat.typ == chatTypeSingle && user != null) {
          if (isTyping)
            chatroomDetail = localized(chatTyping);
          else
            chatroomDetail = UserUtils.onlineStatus(user!.lastOnline);
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
            color: JXColors.secondaryTextBlack,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
