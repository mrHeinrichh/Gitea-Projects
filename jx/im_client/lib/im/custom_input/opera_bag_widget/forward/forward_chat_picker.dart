import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views_desktop/component/desktop_forward_controller.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:jxim_client/views_desktop/component/desktop_searching_bar.dart';

class ForwardChatPicker extends StatefulWidget {
  final Chat chat;
  final List<dynamic>? forwardMsg;
  final bool fromChatInfo;
  final bool fromMediaDetail;
  final bool isForward;

  const ForwardChatPicker({
    super.key,
    required this.chat,
    this.forwardMsg,
    this.fromChatInfo = false,
    this.fromMediaDetail = false,
    this.isForward = true,
  });

  @override
  State<ForwardChatPicker> createState() => _ForwardChatPickerState();
}

class _ForwardChatPickerState extends State<ForwardChatPicker> {
  CustomInputController? controller;
  List<Chat> _chatList = [];
  bool isVisible = false;

  final FocusNode searchFocus = FocusNode();
  TextEditingController forwardChatSearchController = TextEditingController();
  RxBool isSearching = false.obs;
  RxString searchParam = ''.obs;

  bool get isDesktop => objectMgr.loginMgr.isDesktop;

  /// 转发 - 切换到对应的聊天室
  void onForwardAction(
    BuildContext context,
    Chat chat,
    List<dynamic> forwardData,
  ) async {
    if (!widget.isForward) {
      if (isDesktop) {
        Get.back();
      } else {
        Navigator.of(context).pop(chat);
      }
      return;
    }

    if (isDesktop) {
      Get.back();
    } else {
      Get.back();
    }

    List<Message> forwardMessages = [];
    for (var msg in forwardData) {
      if (msg is Message) {
        Message newMsg = msg.removeReplyContent();
        newMsg = newMsg.processMentionContent();
        forwardMessages.add(newMsg);
      } else if (msg is AlbumDetailBean) {
        Message? newMsg = msg.currentMessage;
        newMsg = newMsg.removeReplyContent();
        newMsg = newMsg.processMentionContent();
        forwardMessages.add(newMsg);
      } else {
        pdebug("未识别类型,请检查");
      }
    }
    objectMgr.chatMgr.selectedMessageMap[chat.chat_id] = forwardMessages;

    if (controller == null) {
      if (isDesktop) {
        Routes.toChat(chat: chat);
      } else {
        Routes.toChat(chat: chat);
      }
      return;
    }

    controller!.chatController.chooseMore.value = false;
    if (chat.typ == chatTypeSaved) {
      try {
        await controller!.onForwardSaveMsg(chat.chat_id);
        if (isDesktop) {
          Get.back();
        } else {
          Get.back();
        }
      } catch (e) {
        pdebug('AppException: ${e.toString()}');
      }
      if (Get.isRegistered<ChatInfoController>() ||
          Get.isRegistered<GroupChatInfoController>()) {
        Get.back(id: isDesktop ? 1 : null);
      }
      if (controller!.chatController.chat.typ != chatTypeSaved) {
        Get.back(id: isDesktop ? 1 : null);
        if (isDesktop) {
          Routes.toChat(chat: chat);
        } else {
          Routes.toChat(chat: chat);
        }
      }
      Toast.showToast(localized(msgMessagesSaved));
    } else {
      if (chat.id == widget.chat.id) {
        controller!.sendState.value = true;
        if (widget.fromChatInfo) {
          Get.back(id: isDesktop ? 1 : null);
        }

        if (widget.fromMediaDetail) {
          if (!isDesktop) {
            Get.back();
          } else {
            if (Get.isRegistered<ChatInfoController>() ||
                Get.isRegistered<GroupChatInfoController>()) {
              Get.back(id: isDesktop ? 1 : null);
            }
          }
        }
      } else {
        if (chat.isSingle) {
          final User? user = objectMgr.userMgr.getUserById(chat.friend_id);
          if (user != null) {
            if (user.deletedAt > 0) {
              Toast.showToast(localized(userHasBeenDeleted));
              return;
            }
          }
        }

        if (!isDesktop) {
          if (Get.isRegistered<ChatInfoController>()) {
            Get.until((route) => Get.currentRoute == RouteName.chatInfo);
          } else if (Get.isRegistered<GroupChatInfoController>()) {
            Get.until((route) => Get.currentRoute == RouteName.groupChatInfo);
          }
        }

        Get.back(id: isDesktop ? 1 : null);

        if (isDesktop) {
          Routes.toChat(chat: chat);
        } else {
          Routes.toChat(chat: chat);
        }
      }
    }

    controller!.update();
  }

  Future<void> onSearch(String searchParam) async {
    List<Chat> chatList = await sortList(searchParam: searchParam);

    setState(() {
      _chatList = chatList;
    });
  }

  void clearSearching() {
    isSearching.value = false;
    if (!isSearching.value) {
      forwardChatSearchController.clear();
      searchParam.value = '';
    }
    onSearch(searchParam.value);
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CustomInputController>(
      tag: widget.chat.id.toString(),
    )) {
      controller =
          Get.find<CustomInputController>(tag: widget.chat.id.toString());
    }
    getChatList();
  }

  getChatList() async {
    _chatList = await sortList();
    if (mounted) {
      setState(() {});
    }
  }

  Future<List<Chat>> sortList({searchParam = ''}) async {
    List<Chat> tempList = (objectMgr.chatMgr.getAllChats())
        .where(
          (chat) => (chat.typ < chatTypeSystem &&
              chat.isValid &&
              chat.last_typ != messageTypeGroupMute),
        )
        .toList();

    tempList.sort((a, b) {
      if (a.typ == chatTypeSaved) {
        return -1; // Place save chat first
      } else if (b.typ == chatTypeSaved) {
        return 1; // Place save chat before other chats
      } else {
        if (a.sort != b.sort) {
          return b.sort - a.sort;
        }
        return b.last_time.compareTo(a.last_time); // sort by last_time
      }
    });

    if (searchParam.isNotEmpty) {
      tempList = tempList
          .where(
            (element) =>
                element.name.toLowerCase().contains(searchParam.toLowerCase()),
          )
          .toList();
    }
    return tempList;
  }

  @override
  Widget build(BuildContext context) {
    if (!objectMgr.loginMgr.isDesktop) {
      return Column(
        children: <Widget>[
          /// appBar
          Container(
            height: kToolbarHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.0),
                topRight: Radius.circular(18.0),
              ),
            ),
            child: Center(
              child: Text(
                localized(forward),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: MFontWeight.bold5.value,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          /// search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: colorBackground6,
                  width: 1.w,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: 8.h,
                right: 16.w,
                left: 16.w,
                bottom: 8.h,
              ),
              child: SearchingAppBar(
                onTap: () => isSearching(true),
                onChanged: (value) async {
                  searchParam.value = value;
                  onSearch(value);
                },
                onCancelTap: () {
                  searchFocus.unfocus();
                  clearSearching();
                },
                isSearchingMode: isSearching.value,
                isAutoFocus: false,
                focusNode: searchFocus,
                controller: forwardChatSearchController,
                suffixIcon: Visibility(
                  visible: searchParam.value.isNotEmpty,
                  child: GestureDetector(
                    onTap: () {
                      forwardChatSearchController.clear();
                      searchParam.value = '';
                      onSearch(searchParam.value);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SvgPicture.asset(
                        'assets/svgs/close_round_icon.svg',
                        width: 20,
                        height: 20,
                        color: colorTextSupporting,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// Chat List
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.separated(
                itemCount: _chatList.length,
                itemBuilder: (BuildContext context, int index) {
                  final Chat chat = _chatList[index];
                  return GestureDetector(
                    key: ValueKey(_chatList[index].id),
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      List<Message> forwardMessage = controller
                              ?.chatController.chooseMessage.values
                              .map((e) => e.copyWith(null))
                              .toList() ??
                          [];
                      onForwardAction(
                        context,
                        chat,
                        widget.forwardMsg ?? forwardMessage,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 12.5,
                      ),
                      child: Row(
                        children: <Widget>[
                          chat.typ != chatTypeSaved
                              ? CustomAvatar.chat(
                                  chat,
                                  size: 52,
                                  headMin: Config().headMin,
                                )
                              : const SavedMessageIcon(
                                  size: 52,
                                ),
                          const SizedBox(width: 10),
                          chat.typ != chatTypeSaved
                              ? Flexible(
                                  child: NicknameText(
                                    uid:
                                        chat.isGroup ? chat.id : chat.friend_id,
                                    isGroup: chat.isGroup,
                                    isTappable: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : Text(chat.name),
                          if (chat.isGroup)
                            const Padding(
                              padding: EdgeInsets.only(left: 5.0),
                              child: Icon(
                                Icons.group_outlined,
                                color: Colors.black,
                                size: 15,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const CustomDivider();
                },
              ),
            ),
          ),
        ],
      );
    } else {
      final desktopForwardController = Get.find<DesktopForwardController>();
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DesktopSearchingBar(
              fontSize: 12,
              height: 25,
              iconSize: 15,
              controller: desktopForwardController.chatSearchController,
              onChanged: (param) =>
                  desktopForwardController.searchingNow<Chat>(param),
              suffixIcon: DesktopGeneralButton(
                onPressed: () =>
                    desktopForwardController.clearSearching<Chat>(),
                child: const Icon(
                  Icons.close,
                  size: 15,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (BuildContext context) {
                return Obx(
                  () => desktopForwardController.chatList.isNotEmpty &&
                          desktopForwardController.contactList.isNotEmpty
                      ? ListView.separated(
                          shrinkWrap: true,
                          itemCount: desktopForwardController.chatList.length,
                          itemBuilder: (context, index) {
                            final Chat chat =
                                desktopForwardController.chatList[index];
                            int uid =
                                chat.isGroup ? chat.chat_id : chat.friend_id;
                            bool isGroup = chat.isGroup;
                            return DesktopGeneralButton(
                              onPressed: () {
                                Get.back();
                                List<Message> forwardMessage = controller
                                        ?.chatController.chooseMessage.values
                                        .map((e) => e.copyWith(null))
                                        .toList() ??
                                    [];
                                onForwardAction(
                                  context,
                                  chat,
                                  widget.forwardMsg ?? forwardMessage,
                                );
                              },
                              child: SizedBox(
                                height: 55,
                                child: Row(
                                  children: <Widget>[
                                    desktopForwardController.getHead<Chat>(
                                      uid,
                                      isGroup,
                                      chat,
                                    ),
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          desktopForwardController
                                              .getTitle<Chat>(
                                            uid,
                                            isGroup,
                                            chat,
                                          ),
                                          // const SizedBox(
                                          //   height: 5,
                                          // ),
                                          // Text(
                                          //   subtitle,
                                          //   style: const TextStyle(
                                          //     color: Colors.grey,
                                          //     fontSize: 12,
                                          //     fontWeight:MFontWeight.bold4.value,
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return const CustomDivider();
                          },
                        )
                      : Center(
                          child: SizedBox(
                            height: 30,
                            width: 30,
                            child: BallCircleLoading(
                              radius: 10,
                              ballStyle: BallStyle(
                                size: 4,
                                color: themeColor,
                                ballType: BallType.solid,
                                borderWidth: 1,
                                borderColor: themeColor,
                              ),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    forwardChatSearchController.dispose();
    super.dispose();
  }
}
