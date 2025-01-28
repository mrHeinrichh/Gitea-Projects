import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_content_container.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';

import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';

class ForwardContainer extends StatefulWidget {
  const ForwardContainer({
    Key? key,
    this.reel,
    this.chat,
    this.forwardMsg,
    this.isForward = false,
  }) : super(key: key);

  final ReelData? reel;
  final Chat? chat;
  final List<dynamic>? forwardMsg;
  final bool isForward;

  @override
  State<ForwardContainer> createState() => _ForwardContainerState();
}

class _ForwardContainerState extends State<ForwardContainer> {
  CustomInputController? controller;
  List<Chat> chatList = [];
  List<Message> forwardMessageList = [];
  RxBool validShare = false.obs;
  RxBool validSend = false.obs;
  RxList<Chat> selectedChats = RxList();
  RxBool isExtend = false.obs;

  final FocusNode searchFocus = FocusNode();
  TextEditingController searchController = TextEditingController();
  RxBool isSearching = false.obs;
  RxString searchParam = ''.obs;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CustomInputController>(
        tag: widget.chat?.id.toString())) {
      controller =
          Get.find<CustomInputController>(tag: widget.chat?.id.toString());
    }
    getChatList();
    getForwardMessageList();
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  getChatList() async {
    chatList = await sortList();
    if (mounted) {
      setState(() {});
    }
  }

  getForwardMessageList() async {
    int errorShareCount = 0;
    List<dynamic> forwardMessages = [];
    if (widget.forwardMsg != null) {
      forwardMessages = widget.forwardMsg!;
    } else {
      forwardMessages = controller?.chatController.chooseMessage.values
              .map((e) => e.copyWith(null))
              .toList() ??
          [];
    }

    forwardMessages.forEach((msg) {
      if (msg is Message) {
        Message newMsg = msg.removeReplyContent();
        newMsg = newMsg.processMentionContent();
        forwardMessageList.add(newMsg);
        if (msg.typ != messageTypeImage &&
            msg.typ != messageTypeVideo &&
            msg.typ != messageTypeFile) {
          errorShareCount += 1;
        }
      } else if (msg is AlbumDetailBean) {
        Message? newMsg = msg.currentMessage;
        newMsg = newMsg.removeReplyContent();
        newMsg = newMsg.processMentionContent();
        forwardMessageList.add(newMsg);
      } else {
        pdebug("未识别类型,请检查");
      }
    });

    if (forwardMessages.length == 1 && errorShareCount == 0) {
      validShare.value = true;
    }
  }

  Future<List<Chat>> sortList({searchParam = ''}) async {
    List<Chat> tempList = (await objectMgr.chatMgr.getAllChats())
        .where((chat) => (chat.typ < chatTypeSystem &&
            chat.isValid &&
            !chat.isDeleteAccount &&
            chat.last_typ != messageTypeGroupMute))
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
          .where((element) =>
              element.name.toLowerCase().contains(searchParam.toLowerCase()))
          .toList();

      if (tempList.isEmpty) {
        tempList = await getContactList();
      }
    }
    return tempList;
  }

  Future<List<Chat>> getContactList() async {
    List<Chat> chatList = [];
    List<User> userList = objectMgr.userMgr.friendWithoutBlacklist;
    if (searchParam.isNotEmpty) {
      for (final user in userList) {
        if (objectMgr.userMgr
                .getUserTitle(user)
                .toLowerCase()
                .contains(searchParam.toLowerCase()) &&
            user.deletedAt == 0) {
          Chat? chat = await objectMgr.chatMgr.getChatByFriendId(user.uid);
          if (chat != null) {
            chatList.add(chat);
          }
        }
      }
    }
    return chatList;
  }

  Future<void> onSearch(String searchParam) async {
    List<Chat> chats = await sortList(searchParam: searchParam);

    setState(() {
      chatList = chats;
    });
  }

  void clearSearching() {
    isSearching.value = false;
    searchController.clear();
    searchParam.value = '';
    onSearch(searchParam.value);
  }

  void slideHeader(DragUpdateDetails details) {
    if (details.primaryDelta != null) {
      if (details.primaryDelta! < -2) {
        if (!isExtend.value) {
          isExtend.value = true;
        }
      }
    }
  }

  Widget setAvatar() {
    if (selectedChats.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      width: (24 *
              (selectedChats.length < 3
                  ? selectedChats.length == 1
                      ? 1.5
                      : selectedChats.length
                  : 3))
          .toDouble(),
      height: 24.0,
      child: Stack(
        children: List.generate(selectedChats.length, (index) {
          if (index > 2) {
            return const SizedBox();
          }

          if (index == 2) {
            return Positioned(
              left: index == 0 ? 0 : (16 * index).toDouble(),
              top: 0.0,
              child: ClipOval(
                child: Stack(
                  children: [
                    Container(
                      color: Colors.white,
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      child: Text(
                        "+${selectedChats.length - 2}",
                        style: jxTextStyle.textStyle10(color: accentColor),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ColoredBox(
                        color: accentColor.withOpacity(0.3),
                      ),
                    )
                  ],
                ),
              ),
            );
          }

          return Positioned(
            left: index == 0 ? 0 : (16 * index).toDouble(),
            top: 0.0,
            child: selectedChats[index].isSaveMsg
                ? const SavedMessageIcon(
                    size: 24,
                  )
                : CustomAvatar(
                    key: ValueKey(selectedChats[index].isGroup
                        ? selectedChats[index].id
                        : selectedChats[index].friend_id),
                    uid: selectedChats[index].isGroup
                        ? selectedChats[index].id
                        : selectedChats[index].friend_id,
                    isGroup: selectedChats[index].isGroup,
                    size: 24,
                    headMin: Config().headMin,
                  ),
          );
        }),
      ),
    );
  }

  String setUsername() {
    String text = "";
    if (selectedChats.isNotEmpty) {
      if (selectedChats.length == 1) {
        text = selectedChats.first.name;
      } else if (selectedChats.length == 2) {
        text =
            "${setFilterUsername(selectedChats.first.name)} ${localized(shareAnd)} ${setFilterUsername(selectedChats[1].name)}";
      } else if (selectedChats.length > 2) {
        text =
            "${setFilterUsername(selectedChats.first.name)}, ${setFilterUsername(selectedChats[1].name)} ${localized(andOthersWithParam, params: [
              '${selectedChats.length - 2}'
            ])}";
      }
    }
    return text;
  }

  String setFilterUsername(String text) {
    String username = text;
    if (text.length > 7) {
      username = "${text.substring(0, 7)}...";
    }
    return username;
  }

  void onForwardAction(BuildContext context, List<Chat> chat) async {
    if (forwardMessageList.any((element) => element.isExpired == true)){
      ImBottomToast(
        Get.context!,
        title: localized(actionCannotBePerformed),
        icon: ImBottomNotifType.warning,
        duration: 1,
        isStickBottom: false,
      );
      return;
    }

    if (widget.isForward) {
      if (!objectMgr.loginMgr.isDesktop) {
        Navigator.of(context).pop(chat);
      }
      return;
    }

    if (widget.reel != null) {
      doSendReel(context);
      return;
    }

    int errorCount = 0;

    chat.forEach((element) async {
      objectMgr.chatMgr.selectedMessageMap[element.chat_id] =
          forwardMessageList;
      try {
        if (controller != null) {
          await controller!.onForwardSaveMsg(element.chat_id);
        } else {
          await forwardMessage(element);
        }
      } catch (e) {
        errorCount += 1;
        pdebug('AppException: ${e.toString()}');
      }
    });

    if (errorCount == 0) {
      if (chat.length > 1) {
        ImBottomToast(
          Routes.navigatorKey.currentContext!,
          title: localized(messageForwardedSuccessfullyToParam,
              params: [setUsername()]),
          icon: ImBottomNotifType.success,
          duration: 3,
          isStickBottom: false,
        );
      } else if (chat.length == 1 &&
          !Get.currentRoute.contains("${chat.first.id}")) {
        ImBottomToast(
          Routes.navigatorKey.currentContext!,
          title: localized(messageForwardedSuccessfullyToParam,
              params: [setUsername()]),
          icon: ImBottomNotifType.success,
          withAction: chat.length == 1 && chat.first.id != widget.chat?.id,
          duration: 3,
          actionFunction: () {
            if (chat.length == 1 && chat.first.id != widget.chat?.id) {
              Routes.toChat(chat: chat.first);
            }
          },
          isStickBottom: false,
        );
      }
    } else {
      ImBottomToast(
        Routes.navigatorKey.currentContext!,
        title:
            localized(messageForwardedFailedToParam, params: [setUsername()]),
        icon: ImBottomNotifType.warning,
        isStickBottom: false,
      );
    }
    if (controller != null) {
      controller!.update();
    }

    Get.back();
  }

  forwardMessage(Chat chat) async {
    if (notBlank(objectMgr.chatMgr.selectedMessageMap[chat.chat_id])) {
      for (Message item
          in objectMgr.chatMgr.selectedMessageMap[chat.chat_id]!) {
        if ((item.typ <= messageTypeGroupChangeInfo &&
                item.typ >= messageTypeImage) ||
            item.typ == messageTypeRecommendFriend) {
          await objectMgr.chatMgr.sendForward(
            chat.chat_id,
            item,
            item.typ,
          );
        } else {
          var _contentStr = '';
          if (item.typ == messageTypeText ||
              item.typ == messageTypeReply ||
              item.typ == messageTypeReplyWithdraw) {
            MessageText _textMsg = item.decodeContent(cl: MessageText.creator);
            _contentStr = _textMsg.text;
          } else {
            _contentStr = ChatHelp.typShowMessage(chat, item);
          }
          await objectMgr.chatMgr.sendForward(
            chat.chat_id,
            item,
            messageTypeText,
            text: _contentStr,
          );
        }
      }
    }
    objectMgr.chatMgr.selectedMessageMap[chat.chat_id]?.clear();
    objectMgr.chatMgr.selectedMessageMap.remove(chat.chat_id);
  }

  doSendReel(BuildContext context) async {
    // {"url":"Video/b1/9a/b19a90c13df7c7222627ce427fac0e4e/b19a90c13df7c7222627ce427fac0e4e.m3u8","size":77167456,"width":1280,"height":720,"second":192,"caption":null,"reply":null,"showOriginal":false,"sendTime":1710255651686,"fileName":"share_f5bb3e842a350ab4509bea2ce8e61cbc.mp4","cover":"Image/1e/ab/1eabe7eb120d8355c8f17ad92886d8bd/1eabe7eb120d8355c8f17ad92886d8bd.jpg"}
    List<Future<ResponseData>> responseDataFuts = [];
    selectedChats.forEach((chat) {
      String filename = "";
      String url = widget.reel?.post?.files?.first.path ?? "";
      String coverUrl = widget.reel?.post?.thumbnail ?? "";
      List<String> urlParts = url.split("/");
      List<String> coverUrlParts = coverUrl.split("/");
      if (urlParts.length == 8) {
        urlParts = urlParts.sublist(3, urlParts.length);
        url = urlParts.join("/");
      }

      if (coverUrlParts.length == 8) {
        coverUrlParts = coverUrlParts.sublist(3, coverUrlParts.length);
        coverUrl = coverUrlParts.join("/");
        filename = Uri.parse(coverUrlParts.last).path;
      }

      final contentData = {
        "url": url,
        "size": widget.reel!.post!.files?.first.size,
        "width": widget.reel!.post!.files?.first.width,
        "height": widget.reel!.post!.files?.first.height,
        "second": widget.reel!.post!.duration,
        "caption": "",
        "reply": "",
        "showOriginal": false,
        "sendTime": DateTime.now().millisecondsSinceEpoch,
        "fileName": filename,
        "cover": coverUrl
      };

      responseDataFuts.add(objectMgr.chatMgr.mySendMgr
          .send(chat.id, messageTypeReel, jsonEncode(contentData)));
    });

    await Future.wait(responseDataFuts);

    Navigator.pop(context);

    pdebug("ForwardReelPost=====> ${widget.reel?.post?.id}");
    if (selectedChats.length == 1) {
      Routes.toChat(chat: selectedChats.first);
    } else {
      Toast.showToast("发送成功");
    }
  }

  void onShareAction(BuildContext context) {
    if (forwardMessageList.isNotEmpty) {
      objectMgr.shareMgr.shareMessage(context, forwardMessageList.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SafeArea(
        child: AnimatedContainer(
          curve: Curves.easeIn,
          duration: Duration(
              milliseconds: (MediaQuery.of(Get.context!).viewInsets.bottom != 0)
                  ? 0
                  : 200),
          margin: EdgeInsets.only(
            top: MediaQuery.of(Get.context!).viewPadding.top,
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
            left: 10,
            right: 10,
          ),
          color: Colors.transparent,
          width: MediaQuery.of(context).size.width,
          height:
              MediaQuery.of(context).size.height * (isExtend.value ? 1 : 0.6),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragUpdate: (details) {
                          slideHeader(details);
                        },
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            // transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                            child: !isSearching.value
                                ? NavigationToolbar(
                                    leading: GestureDetector(
                                      onTap: () {
                                        isSearching(true);
                                        searchFocus.requestFocus();
                                        isExtend(true);
                                      },
                                      behavior: HitTestBehavior.translucent,
                                      child: OpacityEffect(
                                        child: SvgPicture.asset(
                                          'assets/svgs/Search.svg',
                                          width: 24,
                                          height: 24,
                                          colorFilter: ColorFilter.mode(
                                              accentColor, BlendMode.srcIn),
                                        ),
                                      ),
                                    ),
                                    middle: Text(localized(forwardTo),
                                        style: jxTextStyle.textStyleBold17(
                                            fontWeight:
                                                MFontWeight.bold6.value)),
                                    trailing: Visibility(
                                      visible: validShare.value,
                                      child: GestureDetector(
                                        onTap: () => onShareAction(context),
                                        behavior: HitTestBehavior.translucent,
                                        child: OpacityEffect(
                                          child: SvgPicture.asset(
                                            'assets/svgs/share_icon.svg',
                                            width: 24,
                                            height: 24,
                                            colorFilter: ColorFilter.mode(
                                                accentColor, BlendMode.srcIn),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : SearchingAppBar(
                                    hintText: localized(search),
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
                                    controller: searchController,
                                    suffixIcon: Visibility(
                                      visible: searchParam.value.isNotEmpty,
                                      child: GestureDetector(
                                        onTap: () {
                                          searchController.clear();
                                          searchParam.value = '';
                                          onSearch(searchParam.value);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: SvgPicture.asset(
                                            'assets/svgs/close_round_icon.svg',
                                            width: 20,
                                            height: 20,
                                            colorFilter: const ColorFilter.mode(
                                                JXColors.iconSecondaryColor,
                                                BlendMode.srcIn),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ForwardContentContainer(
                            chatList: chatList,
                            clickCallback: (value) {
                              if (value.isNotEmpty) {
                                validSend.value = true;
                              } else {
                                validSend.value = false;
                              }
                              selectedChats.value = value;
                            },
                            slideCallback: (status) {
                              if (status) {
                                if (isExtend.value && !searchFocus.hasFocus) {
                                  isExtend.value = false;
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      ClipRRect(
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.bottomCenter,
                          curve: Curves.easeInOutCubic,
                          heightFactor: validSend.value ? 1 : 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: JXColors.outlineColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 12.0,
                                      bottom: 8,
                                      right: 16,
                                      left: 16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          setAvatar(),
                                          Expanded(
                                            child: Text(
                                              setUsername(),
                                              style: jxTextStyle.textStyle12(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                OverlayEffect(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () => onForwardAction(
                                      context,
                                      selectedChats,
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: MediaQuery.of(context).size.width,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18.0),
                                      child: Text(
                                        localized(send),
                                        style: jxTextStyle.textStyle16(
                                            color: accentColor),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Visibility(
                visible: !searchFocus.hasFocus,
                child: OverlayEffect(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Text(
                        localized(buttonCancel),
                        style: jxTextStyle.textStyle16(color: accentColor),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
