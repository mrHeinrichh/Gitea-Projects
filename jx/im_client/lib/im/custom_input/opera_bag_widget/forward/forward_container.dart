import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_content_container.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/message/larger_photo_data.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/download_media_util.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart' as jx;
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/data_provider.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:vibration/vibration.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

enum ForwardProgressStatus {
  start,
  ended, // Either failure or success
}

class ForwardContainer extends StatefulWidget {
  const ForwardContainer({
    super.key,
    this.chat,
    this.forwardMsg,
    this.isForward = false,
    this.isRecommendFriend = false,
    this.selectableText,
    this.onSend,
    this.showSaveButton = true,
    this.onSaveAction,
    this.onShareAction,
    this.onForwardProgressUpdate,
  });

  final Chat? chat;
  final bool showSaveButton;
  final List<dynamic>? forwardMsg;
  final bool isForward;
  final bool isRecommendFriend;
  final Function(List<Chat>, String name)? onSend;
  final String? selectableText;
  final Function? onSaveAction;
  final Function(Message)? onShareAction;
  final Function(ForwardProgressStatus)? onForwardProgressUpdate;

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
  final RxList<Map<String, dynamic>> computedAssets =
      RxList<Map<String, dynamic>>();
  final LargerPhotoData photoData = LargerPhotoData();

  final FocusNode searchFocus = FocusNode();
  TextEditingController searchController = TextEditingController();
  RxBool hasCaption = false.obs;
  TextEditingController captionController = TextEditingController();
  RxBool isSearching = false.obs;
  RxString searchParam = ''.obs;
  FocusNode captionFocus = FocusNode();
  DraggableScrollableController draggableScrollableController =
      DraggableScrollableController();

  bool keyboardEnabled(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 200;

  int get curMessageType {
    if (forwardMessageList.isNotEmpty) {
      final curMessage = forwardMessageList.first;
      return curMessage.typ;
    }
    return -1;
  }

  String get saveText {
    if (curMessageType == messageTypeImage) {
      return localized(save, params: [localized(image)]);
    } else if (curMessageType == messageTypeVideo) {
      return localized(save, params: [localized(video)]);
    } else if (curMessageType == messageTypeFile) {
      return localized(save, params: [localized(dropDocument)]);
    } else if (curMessageType == messageTypeGroupLink) {
      return localized(copyLink);
    }
    return localized(save);
  }

  String get toastText {
    if (curMessageType == messageTypeImage) {
      return localized(
        messageForwardedSuccessfully,
        params: [localized(imageText)],
      );
    } else if (curMessageType == messageTypeVideo) {
      return localized(
        messageForwardedSuccessfully,
        params: [localized(videoText)],
      );
    } else if (curMessageType == messageTypeFile) {
      return localized(
        messageForwardedSuccessfully,
        params: [localized(dropDocument)],
      );
    }
    return localized(
      messageForwardedSuccessfullyToParam,
      params: [setUsername()],
    );
  }

  bool get isShowCaptionInput {
    return curMessageType != messageTypeGroupLink;
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CustomInputController>(
      tag: widget.chat?.id.toString(),
    )) {
      controller = Get.findOrPut<CustomInputController>(CustomInputController(),
          tag: widget.chat?.id.toString());
    }
    getChatList();
    getForwardMessageList();
    searchFocus.addListener(focusNodeListener);
    captionFocus.addListener(focusNodeListener);

    captionController.addListener(captionListener);
  }

  @override
  void dispose() {
    searchController.dispose();
    captionController.dispose();
    captionFocus.dispose();
    searchFocus.dispose();
    searchFocus.removeListener(focusNodeListener);
    captionFocus.removeListener(focusNodeListener);
    draggableScrollableController.dispose();
    super.dispose();
  }

  void handleVibration() async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate();
    }
  }

  void focusNodeListener() {
    void animateSheet(double size) {
      if (draggableScrollableController.isAttached) {
        draggableScrollableController.animateTo(
          size,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
        );
      }
    }

    if (searchFocus.hasFocus || captionFocus.hasFocus) {
      animateSheet(0.98);
    } else {
      animateSheet(0.6);
    }
  }

  void captionListener() {
    if (captionController.text.isNotEmpty) {
      hasCaption.value = true;
    } else {
      hasCaption.value = false;
    }
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

    for (var msg in forwardMessages) {
      if (msg is Message) {
        Message newMsg = msg.removeReplyContent();
        newMsg = newMsg.processMentionContent();
        forwardMessageList.add(newMsg);
        if (msg.typ != messageTypeImage &&
            msg.typ != messageTypeVideo &&
            msg.typ != messageTypeFile &&
            msg.typ != messageTypeRecommendFriend &&
            msg.typ != messageTypeGroupLink) {
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

      Future.delayed(const Duration(milliseconds: 10));
    }

    if (forwardMessages.length == 1 && errorShareCount == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          validShare.value = true;
        }
      });
    }
  }

  Future<List<Chat>> sortList({searchParam = ''}) async {
    List<Chat> tempList = (objectMgr.chatMgr.getAllChats())
        .where(
          (chat) => (chat.typ < chatTypeSystem &&
              chat.isValid &&
              !chat.isDeleteAccount &&
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

      if (tempList.isEmpty) {
        tempList = await getContactList();
      }
    }
    return tempList;
  }

  Future<List<Chat>> getContactList() async {
    List<Chat> chatList = [];
    List<User> userList = objectMgr.userMgr.friendWithoutBlacklist;
    if (searchParam.value.isNotEmpty) {
      final searchTerm = searchParam.value.toLowerCase();
      for (final user in userList) {
        if (objectMgr.userMgr
                .getUserTitle(user)
                .toLowerCase()
                .contains(searchTerm) &&
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
    final trimmedParam = searchParam.trim();
    List<Chat> chats = await sortList(searchParam: trimmedParam);

    setState(() {
      chatList = chats;
    });
  }

  void clearSearching() {
    isSearching.value = false;
    searchController.clear();
    searchParam.value = '';
    onSearch('');
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
                        style: jxTextStyle.textStyle10(color: themeColor),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ColoredBox(
                        color: themeColor.withOpacity(0.3),
                      ),
                    ),
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
                : CustomAvatar.chat(
                    key: ValueKey(
                      selectedChats[index].isGroup
                          ? selectedChats[index].id
                          : selectedChats[index].friend_id,
                    ),
                    selectedChats[index],
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
        text = selectedChats.first.isSpecialChat
            ? getSpecialChatName(selectedChats.first.typ)
            : selectedChats.first.name;
      } else if (selectedChats.length == 2) {
        final firstName = selectedChats.first.isSpecialChat
            ? getSpecialChatName(selectedChats.first.typ)
            : selectedChats.first.name;
        final secondName = selectedChats[1].isSpecialChat
            ? getSpecialChatName(selectedChats[1].typ)
            : selectedChats[1].name;
        text =
            "${setFilterUsername(firstName)} ${localized(shareAnd)} ${setFilterUsername(secondName)}";
      } else if (selectedChats.length > 2) {
        final firstName = selectedChats.first.isSpecialChat
            ? getSpecialChatName(selectedChats.first.typ)
            : selectedChats.first.name;
        final secondName = selectedChats[1].isSpecialChat
            ? getSpecialChatName(selectedChats[1].typ)
            : selectedChats[1].name;
        text =
            "${setFilterUsername(firstName)}, ${setFilterUsername(secondName)} ${localized(
          andOthersWithParam,
          params: [
            '${selectedChats.length - 2}',
          ],
        )}";
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

  bool _isSending = false;

  void onForwardAction(BuildContext context, List<Chat> chat) async {
    if (_isSending) {
      return;
    }
    setState(() {
      _isSending = true;
    });

    if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
      Navigator.pop(context);
    }

    if (widget.onSend != null) {
      widget.onSend!(chat, setUsername());
      handleVibration();
      Navigator.pop(context);
      setState(() {
        _isSending = false;
      });
      return;
    }

    if (forwardMessageList.any((element) => element.isExpired == true)) {
      imBottomToast(
        Get.context!,
        title: localized(actionCannotBePerformed),
        icon: ImBottomNotifType.warning,
        duration: 1,
      );
      setState(() {
        _isSending = false;
      });
      return;
    }

    if (widget.isForward) {
      if (!objectMgr.loginMgr.isDesktop) {
        Navigator.of(context).pop(chat);
      }
      setState(() {
        _isSending = false;
      });
      return;
    }

    if (widget.onForwardProgressUpdate != null) {
      //provide forwarding start here
      widget.onForwardProgressUpdate?.call(ForwardProgressStatus.start);
    }

    int errorCount = 0;
    for (var element in chat) {
      // 此处需使用 List.from 浅拷贝一下 forwardMessageList
      // 原因：CustomInputController -> onForwardSaveMsg -> objectMgr.chatMgr.selectedMessageMap[chatID]?.clear(); 会清空，导致forwardMessageList也被清空
      objectMgr.chatMgr.selectedMessageMap[element.chat_id] =
          List.from(forwardMessageList);
      try {
        if (controller != null) {
          await controller!.onForwardSaveMsg(
            element.chat_id,
            caption: captionController.text,
            selectableText: widget.selectableText,
          );
        } else {
          await forwardMessage(element);
        }
      } catch (e) {
        errorCount += 1;
        pdebug('AppException: ${e.toString()}');
      }
    }

    if (errorCount == 0) {
      if (chat.length > 1) {
        imBottomToast(
          navigatorKey.currentContext!,
          title: toastText,
          icon: ImBottomNotifType.success,
          duration: 3,
        );
        handleVibration();
      } else if (chat.length == 1 &&
          !Get.currentRoute.contains("${chat.first.id}")) {
        bool isGroupSelf = false;
        if (forwardMessageList.length == 1 &&
            forwardMessageList.first.typ == messageTypeGroupLink) {
          final MessageGroupLink groupLink = forwardMessageList.first
              .decodeContent(cl: MessageGroupLink.creator);
          isGroupSelf = chat.first.id == groupLink.group_id;
        }
        bool needAction = true;
        if (Get.isRegistered<CustomInputController>()) {
          int chatID = Get.find<CustomInputController>().chatId;
          if (chatID == chat.first.id && chat.length == 1) {
            needAction = false;
          }
        }
        imBottomToast(
          navigatorKey.currentContext!,
          title: toastText,
          icon: ImBottomNotifType.success,
          withAction: chat.length == 1 &&
              chat.first.id != widget.chat?.id &&
              !isGroupSelf &&
              needAction,
          duration: 3,
          actionFunction: () {
            if (chat.length == 1 && chat.first.id != widget.chat?.id) {
              Routes.toChat(chat: chat.first);
            }
          },
        );
        handleVibration();
      }
    } else {
      imBottomToast(
        navigatorKey.currentContext!,
        title:
            localized(messageForwardedFailedToParam, params: [setUsername()]),
        icon: ImBottomNotifType.warning,
      );
    }
    if (controller != null) {
      controller!.update();
    }

    setState(() {
      _isSending = false;
    });
    if (widget.onForwardProgressUpdate != null) {
      //if progress update provided, view is to dismiss itself
      widget.onForwardProgressUpdate?.call(ForwardProgressStatus.ended);
    } else {
      Navigator.pop(context);
    }
  }

  forwardMessage(Chat chat) async {
    if (notBlank(objectMgr.chatMgr.selectedMessageMap[chat.chat_id])) {
      for (Message item
          in objectMgr.chatMgr.selectedMessageMap[chat.chat_id]!) {
        if ((item.typ <= messageTypeGroupChangeInfo &&
                item.typ >= messageTypeImage) ||
            item.typ == messageTypeRecommendFriend) {
          if (captionController.text.isNotEmpty == true) {
            // 用户转发图片时输入了描述
            item = createMessageWithImageCaption(item, captionController.text);
          }
          await objectMgr.chatMgr.sendForward(
            chat.chat_id,
            item,
            item.typ,
          );
        } else {
          var contentStr = '';
          if (item.typ == messageTypeText ||
              item.typ == messageTypeReply ||
              item.typ == messageTypeReplyWithdraw) {
            MessageText textMsg = item.decodeContent(cl: MessageText.creator);
            contentStr = textMsg.text;
          } else {
            contentStr = ChatHelp.typShowMessage(chat, item);
          }
          await objectMgr.chatMgr.sendForward(
            chat.chat_id,
            item,
            messageTypeText,
            text: contentStr,
          );
        }
      }
    }
    objectMgr.chatMgr.selectedMessageMap[chat.chat_id]?.clear();
    objectMgr.chatMgr.selectedMessageMap.remove(chat.chat_id);
  }

  void onShareAction(BuildContext context) async {
    Get.back();
    if (widget.onShareAction != null) {
      if (forwardMessageList.isNotEmpty) {
        widget.onShareAction?.call(forwardMessageList.first);
      }
      return;
    }
    if (forwardMessageList.isNotEmpty) {
      final isSuccess = await objectMgr.shareMgr
          .shareMessage(context, forwardMessageList.first);
      if (isSuccess) {
        Get.back();
        handleVibration();
        imBottomToast(
          navigatorKey.currentContext!,
          title: toastText,
          icon: ImBottomNotifType.success,
          duration: 3,
        );
      }
    }
  }

  void onSaveAction(BuildContext context) async {
    if (widget.onSaveAction != null) {
      widget.onSaveAction?.call();
      return;
    }
    getAssetList(context, forwardMessageList.first);
  }

  void getAssetList(BuildContext context, Message message) async {
    List<Message> messages = [];
    if (controller == null) {
      messages.add(message);
    } else {
      messages.assignAll(controller!.chatController.combinedMessageList);
    }
    try {
      computedAssets.assignAll(downloadMediaUtil.processAssetList(messages));
    } catch (e) {
      objectMgr.tencentVideoMgr.addLog("解析错误", "", e.toString());
    }

    bool fromChatInfo = false;
    if (Get.isRegistered<ChatInfoController>() ||
        Get.isRegistered<GroupChatInfoController>()) {
      fromChatInfo = true;
    }

    if (fromChatInfo) {
      await getMessageListFromLocalDBDB();
    }

    int selectedIdx = 0;
    for (int i = 0; i < computedAssets.length; i++) {
      final el = computedAssets[i];
      if (el['message'].id == message.id) {
        if (el['message'].typ == messageTypeNewAlbum) {
          late String url;
          if (message.typ == messageTypeImage) {
            MessageImage messageImage =
                message.decodeContent(cl: MessageImage.creator);
            url = messageImage.url;
          }
          if (message.typ == messageTypeVideo ||
              message.typ == messageTypeReel) {
            MessageVideo messageVideo =
                message.decodeContent(cl: MessageVideo.creator);
            url = messageVideo.url;
          }
          AlbumDetailBean bean = el['asset'];
          if (bean.url == url) {
            selectedIdx = i;
            break;
          }
        } else {
          selectedIdx = i;
          break;
        }
      }
    }

    if (selectedIdx == -1) {
      return;
    }

    photoData.currentPage = selectedIdx;

    onDownLoad();
  }

  Future<void> getMessageListFromLocalDBDB() async {
    Chat chat = widget.chat!;
    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND chat_idx < ? AND (typ = ? OR typ = ? OR typ = ? OR typ = ?) AND expire_time == 0',
      [
        chat.id,
        chat.hide_chat_msg_idx,
        computedAssets.isEmpty
            ? chat.msg_idx + 1
            : computedAssets.last['message'].chat_idx,
        messageTypeImage,
        messageTypeVideo,
        messageTypeReel,
        messageTypeNewAlbum,
      ],
      'DESC',
      30,
      null,
    );

    if (tempList.isNotEmpty) {
      List<Message> mList =
          tempList.map<Message>((e) => Message()..init(e)).toList();
      computedAssets.addAll(downloadMediaUtil.processAssetList(mList));
    }
  }

  void onDownLoad() async {
    dynamic curData = computedAssets[photoData.currentPage]['asset'];
    Message message = computedAssets[photoData.currentPage]['message'];

    if (curData is AssetEntity) {
      File? file = await curData.file;
      await downloadMediaUtil.saveMedia(file!.path);
      return;
    }

    if (curData is File) {
      await downloadMediaUtil.saveMedia(curData.path);
      return;
    }

    bool isVideo = false;
    if (curData is AlbumDetailBean) {
      isVideo = curData.cover.isNotEmpty ||
          (curData.mimeType?.contains('video') ?? false);
      if (isVideo) {
        File file = File(curData.filePath);
        if (file.existsSync()) {
          await downloadMediaUtil.saveMedia(file.path);
          return;
        }

        curData = curData.url;
        final success = await downloadMediaUtil.saveM3U8ToAlbum(curData);
        if (success) return;
      } else {
        curData = curData.url;
        final success = await downloadMediaUtil.saveImageToAlum(curData);
        if (success) return;
      }
    }

    if (message.typ == messageTypeVideo) {
      isVideo = true;
      var messageVideo = message.decodeContent(cl: MessageVideo.creator);

      var file = File(messageVideo.filePath);
      if (File(messageVideo.filePath).existsSync()) {
        await downloadMediaUtil.saveMedia(file.path);
        return;
      }

      final success = await downloadMediaUtil.saveM3U8ToAlbum(messageVideo.url);
      if (success) return;
    }

    /// 可能到这个判断的 消息为 [MessageImage] 和 [MessageVideo]
    if (curData is String) {
      if (message.typ == messageTypeImage ||
          (message.typ == messageTypeNewAlbum && !isVideo)) {
        final success = await downloadMediaUtil.saveImageToAlum(curData);
        if (success) return;
      } else {
        if (curData.contains('.m3u8')) {
          final success = await downloadMediaUtil.saveM3U8ToAlbum(curData);
          if (success) return;
        }
      }
    }

    Toast.showToast(localized(toastHavenDownload));
  }

  @override
  Widget build(BuildContext context) {
    if (!objectMgr.loginMgr.isDesktop) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        controller: draggableScrollableController,
        builder: (BuildContext context, ScrollController scrollController) {
          return Obx(
            () => SafeArea(
              child: AnimatedContainer(
                curve: Curves.easeIn,
                duration: Duration(
                  milliseconds:
                      (MediaQuery.of(Get.context!).viewInsets.bottom != 0)
                          ? 0
                          : 200,
                ),
                margin: EdgeInsets.only(
                  top: MediaQuery.of(Get.context!).viewPadding.top,
                  bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
                  left: 10,
                  right: 10,
                ),
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              child: Container(
                                height: 60,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  // transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                  child: !isSearching.value
                                      ? NavigationToolbar(
                                          leading: GestureDetector(
                                            onTap: () {
                                              isSearching(true);
                                              searchFocus.requestFocus();
                                            },
                                            behavior:
                                                HitTestBehavior.translucent,
                                            child: OpacityEffect(
                                              child: Image.asset(
                                                'assets/icons/search_icon2.png',
                                                width: 24,
                                                height: 24,
                                                color: themeColor,
                                              ),
                                            ),
                                          ),
                                          middle: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 11),
                                            child: Column(
                                              children: [
                                                Text(
                                                  localized(shareTo),
                                                  style: jxTextStyle
                                                      .textStyleBold20(
                                                    fontWeight:
                                                        MFontWeight.bold5.value,
                                                  ),
                                                ),
                                                Text(
                                                    selectedChats.isNotEmpty
                                                        ? setUsername()
                                                        : localized(selectChat),
                                                    style: jxTextStyle
                                                        .normalSmallText(
                                                      color: colorTextLevelTwo,
                                                    )),
                                              ],
                                            ),
                                          ),
                                          trailing: Visibility(
                                            visible: validShare.value,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  onShareAction(context),
                                              behavior:
                                                  HitTestBehavior.translucent,
                                              child: OpacityEffect(
                                                child: Image.asset(
                                                  'assets/icons/share.png',
                                                  width: 24,
                                                  height: 24,
                                                  color: themeColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : SearchingAppBar(
                                          hintText: localized(search),
                                          onChanged: (value) async {
                                            final trimmedValue = value.trim();
                                            searchParam.value = trimmedValue;
                                            onSearch(trimmedValue);
                                          },
                                          tag: widget.chat?.id.toString(),
                                          onCancelTap: () {
                                            searchFocus.unfocus();
                                            clearSearching();
                                          },
                                          isSearchingMode: isSearching.value,
                                          isAutoFocus: false,
                                          focusNode: searchFocus,
                                          controller: searchController,
                                          suffixIcon: Visibility(
                                            visible:
                                                searchParam.value.isNotEmpty,
                                            child: GestureDetector(
                                              onTap: () {
                                                searchController.clear();
                                                searchParam.value = '';
                                                onSearch(searchParam.value);
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 8.0,
                                                ),
                                                child: SvgPicture.asset(
                                                  'assets/svgs/close_round_icon.svg',
                                                  width: 20,
                                                  height: 20,
                                                  colorFilter:
                                                      const ColorFilter.mode(
                                                    colorTextSupporting,
                                                    BlendMode.srcIn,
                                                  ),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: chatList.isEmpty
                                    ? SearchEmptyState(
                                        searchText:
                                            searchController.text.trim(),
                                        emptyMessage: localized(
                                          oppsNoResultFoundTryNewSearch,
                                          params: [
                                            searchController.text.trim()
                                          ],
                                        ),
                                      )
                                    : ForwardContentContainer(
                                        scrollController: scrollController,
                                        chatList: chatList,
                                        clickCallback: (value) {
                                          if (value.isNotEmpty) {
                                            validSend.value = true;
                                          } else {
                                            validSend.value = false;
                                          }
                                          selectedChats.value = value;
                                        },
                                      ),
                              ),
                            ),
                            if (validShare.value &&
                                !searchFocus.hasFocus &&
                                curMessageType != messageTypeFile &&
                                widget.showSaveButton)
                              ClipRRect(
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: Alignment.bottomCenter,
                                  curve: Curves.easeInOutCubic,
                                  heightFactor: !validSend.value ? 1 : 0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: colorDivider,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: OverlayEffect(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () => onSaveAction(context),
                                        child: Container(
                                          height: 56,
                                          alignment: Alignment.center,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: Text(
                                            saveText,
                                            style: jxTextStyle.titleSmallText(
                                              color: themeColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
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
                                        color: colorDivider,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (validShare.value &&
                                          isShowCaptionInput)
                                        Stack(
                                          children: [
                                            if (captionController.text.isEmpty)
                                              Align(
                                                alignment: Alignment.center,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          0, 22, 12, 22),
                                                  child: Text(
                                                    captionController
                                                            .text.isEmpty
                                                        ? localized(
                                                            writeACaption)
                                                        : '',
                                                    style: TextStyle(
                                                      fontSize: 16.0,
                                                      color: colorTextPrimary
                                                          .withOpacity(0.24),
                                                      height: 1.25,
                                                      textBaseline: TextBaseline
                                                          .alphabetic,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12.0,
                                                vertical: 8.0,
                                              ),
                                              child: TextField(
                                                contextMenuBuilder:
                                                    im.textMenuBar,
                                                autocorrect: false,
                                                enableSuggestions: false,
                                                textAlignVertical:
                                                    TextAlignVertical.center,
                                                textAlign: TextAlign.left,
                                                maxLines: 4,
                                                minLines: 1,
                                                focusNode: captionFocus,
                                                controller: captionController,
                                                keyboardType:
                                                    TextInputType.multiline,
                                                scrollPhysics:
                                                    const ClampingScrollPhysics(),
                                                maxLength: 4096,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                    4096,
                                                  ),
                                                ],
                                                cursorColor: themeColor,
                                                style: const TextStyle(
                                                  decoration:
                                                      TextDecoration.none,
                                                  fontSize: 16.0,
                                                  color: colorTextPrimary,
                                                  height: 1.25,
                                                  textBaseline:
                                                      TextBaseline.alphabetic,
                                                ),
                                                enableInteractiveSelection:
                                                    true,
                                                decoration: InputDecoration(
                                                  hintStyle: TextStyle(
                                                    fontSize: 16.0,
                                                    color: keyboardEnabled(
                                                            context)
                                                        ? colorTextPrimary
                                                            .withOpacity(0.24)
                                                        : colorTextPrimary
                                                            .withOpacity(0.24),
                                                    height: 1.25,
                                                    textBaseline:
                                                        TextBaseline.alphabetic,
                                                  ),
                                                  isDense: true,
                                                  fillColor: colorTextPrimary
                                                      .withOpacity(0.03),
                                                  filled: true,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  isCollapsed: true,
                                                  counterText: '',
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    vertical: 10,
                                                    horizontal: 16,
                                                  ),
                                                  suffixIcon: (captionController
                                                              .text
                                                              .isNotEmpty ||
                                                          captionFocus.hasFocus)
                                                      ? IconButton(
                                                          onPressed: () {
                                                            captionController
                                                                .clear();
                                                            setState(() {});
                                                          },
                                                          icon:
                                                              SvgPicture.asset(
                                                            'assets/svgs/clear.svg',
                                                            width: 14,
                                                            height: 14,
                                                          ),
                                                        )
                                                      : const SizedBox.shrink(),
                                                ),
                                                onTapOutside: (event) {
                                                  captionFocus.unfocus();
                                                },
                                                onChanged: (text) {
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      OverlayEffect(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () {
                                            onForwardAction(
                                              context,
                                              selectedChats,
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 18.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                _isSending
                                                    ? SizedBox(
                                                        height: 27,
                                                        width: 27,
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: themeColor,
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : Text(
                                                        localized(send),
                                                        style: jxTextStyle
                                                            .textStyle20(
                                                          color: themeColor,
                                                        ),
                                                      ),
                                                im.ImGap.hGap4,
                                                if (selectedChats.isNotEmpty &&
                                                    !_isSending)
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: themeColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        20,
                                                      ),
                                                    ),
                                                    height: 19,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4),
                                                    alignment: Alignment.center,
                                                    constraints:
                                                        const BoxConstraints(
                                                      minWidth: 19,
                                                    ),
                                                    child: Text(
                                                      selectedChats.length
                                                          .toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        height: 1.2,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Visibility(
                      visible: !searchFocus.hasFocus,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: OpacityEffect(
                            child: Container(
                              color: Colors.transparent,
                              width: MediaQuery.of(context).size.width,
                              height: 56,
                              alignment: Alignment.center,
                              child: Text(
                                localized(buttonCancel),
                                style:
                                    jxTextStyle.textStyle20(color: themeColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Dialog(
      backgroundColor: colorWhite,
      insetPadding: const EdgeInsets.all(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 360,
        child: Column(
          children: [
            _buildDesktopSearchBar(),
            const CustomDivider(),
            Expanded(child: _buildDesktopChatList()),
            Obx(
              () => validSend.value
                  ? MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => onForwardAction(context, selectedChats),
                        child: ForegroundOverlayEffect(
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    width: 0.3, color: jx.colorDivider),
                              ),
                            ),
                            child: Text(
                              localized(send),
                              style: jxTextStyle.textStyleBold14(
                                color: jx.themeColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomImage(
            'assets/svgs/close_round_outlined.svg',
            size: 24,
            color: jx.themeColor,
            padding: const EdgeInsets.fromLTRB(3, 2, 13, 3),
            onClick: () => Navigator.pop(context),
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  isSearching(true);
                  searchFocus.requestFocus();
                },
                child: Obx(
                  () => Container(
                    constraints: const BoxConstraints(minHeight: 30),
                    alignment: isSearching.value
                        ? Alignment.centerLeft
                        : Alignment.center,
                    padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                    decoration: BoxDecoration(
                      color: jx.colorBackground6,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Wrap(
                      children: [
                        for (var user in selectedChats)
                          _showDesktopTagInput(user),
                        IgnorePointer(
                          ignoring: !isSearching.value,
                          child: IntrinsicWidth(
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 20),
                              margin: const EdgeInsets.only(bottom: 5),
                              alignment: Alignment.center,
                              child: TextField(
                                controller: searchController,
                                focusNode: searchFocus,
                                cursorColor: themeColor,
                                cursorHeight: 16,
                                minLines: 1,
                                maxLines: null,
                                cursorRadius: const Radius.circular(2),
                                textAlignVertical: TextAlignVertical.center,
                                textInputAction: TextInputAction.search,
                                style: TextStyle(
                                  color: jx.colorTextPrimary,
                                  fontSize: MFontSize.size14.value,
                                  decorationThickness: 0,
                                ),
                                decoration: InputDecoration(
                                  prefixIconConstraints: const BoxConstraints(
                                    maxHeight: 16,
                                  ),
                                  prefixIcon: !isSearching.value
                                      ? const CustomImage(
                                          'assets/svgs/search_outlined.svg',
                                          size: 16,
                                          padding: EdgeInsets.only(right: 8),
                                          color: colorTextSecondary,
                                        )
                                      : const SizedBox.shrink(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: selectedChats.isNotEmpty
                                      ? ''
                                      : localized(search),
                                  hintStyle: jxTextStyle.textStyle14(
                                    color: jx.colorTextSecondary,
                                  ),
                                ),
                                onChanged: (value) async {
                                  final trimmedValue = value.trim();
                                  searchParam.value = trimmedValue;
                                  onSearch(trimmedValue);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _showDesktopTagInput(Chat user) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          searchFocus.requestFocus();

          if (selectedChats.contains(user)) {
            selectedChats.remove(user);
          }

          validSend.value = selectedChats.isNotEmpty;
        },
        child: OpacityEffect(
          child: Container(
            constraints: const BoxConstraints(minHeight: 20),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            margin: const EdgeInsets.only(bottom: 5, right: 5),
            decoration: BoxDecoration(
              color: jx.themeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomImage(
                  'assets/svgs/close_round_icon.svg',
                  size: 12,
                  color: jx.colorWhite.withOpacity(0.6),
                  padding: const EdgeInsets.only(right: 3),
                ),
                Text(
                  user.name,
                  style: jxTextStyle.textStyle13(color: jx.colorWhite),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopChatList() {
    if (chatList.isNotEmpty) {
      return ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: chatList.length,
        itemBuilder: (_, index) {
          final Chat chat = chatList[index];

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                isSearching(true);
                searchFocus.requestFocus();

                if (selectedChats.contains(chat)) {
                  selectedChats.remove(chat);
                } else {
                  selectedChats.add(chat);
                }

                validSend.value = selectedChats.isNotEmpty;
              },
              child: ForegroundOverlayEffect(
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Obx(
                          () => CheckTickItem(
                            isCheck: selectedChats.contains(chat),
                            circleSize: 16,
                            circlePaddingValue: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _getDesktopAvatar(chat),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _getDesktopTitle(chat),
                            _getDesktopSubtitle(chat),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const CustomDivider(indent: 76),
      );
    }

    return SearchEmptyState(
      searchText: searchController.text.trim(),
      emptyMessage: localized(
        oppsNoResultFoundTryNewSearch,
        params: [searchController.text.trim()],
      ),
    );
  }

  Widget _getDesktopAvatar(Chat chat) {
    double avatarSize = 32;
    int uid = chat.isGroup ? chat.chat_id : chat.friend_id;
    bool isGroup = chat.isGroup;

    switch (chat.typ) {
      case chatTypeSystem:
        return SystemMessageIcon(size: avatarSize);
      case chatTypeSmallSecretary:
        return SecretaryMessageIcon(size: avatarSize);
      case chatTypeSaved:
        return SavedMessageIcon(size: avatarSize);
      default:
        return CustomAvatar(
          key: ValueKey(uid),
          dataProvider: DataProvider(uid: uid, isGroup: isGroup),
          size: avatarSize,
        );
    }
  }

  Widget _getDesktopTitle(Chat chat) {
    int uid = chat.isGroup ? chat.chat_id : chat.friend_id;
    bool isGroup = chat.isGroup;

    switch (chat.typ) {
      case chatTypeSystem:
        return Text(
          localized(homeSystemMessage),
          style: jxTextStyle.textStyleBold14(),
        );
      case chatTypeSmallSecretary:
        return Text(
          localized(chatSecretary),
          style: jxTextStyle.textStyleBold14(),
        );
      case chatTypeSaved:
        return Text(
          localized(homeSavedMessage),
          style: jxTextStyle.textStyleBold14(),
        );
      default:
        return NicknameText(
          key: ValueKey(uid),
          uid: uid,
          fontWeight: MFontWeight.bold5.value,
          overflow: TextOverflow.ellipsis,
          isTappable: false,
          isGroup: isGroup,
        );
    }
  }

  Widget _getDesktopSubtitle(Chat chat) {
    if (chat.typ == chatTypeSystem ||
        chat.typ == chatTypeSmallSecretary ||
        chat.typ == chatTypeSaved) {
      return const SizedBox.shrink();
    }

    if (chat.isGroup) {
      String groupMembersLength = UserUtils.groupMembersLengthInfo(
          objectMgr.myGroupMgr.getGroupById(chat.chat_id)?.members.length ?? 0);

      return Text(
        groupMembersLength,
        style: jxTextStyle.textStyle12(color: colorTextSecondary),
      );
    } else {
      String userOnlineStatus = UserUtils.onlineStatus(
          objectMgr.onlineMgr.friendOnlineTime[chat.friend_id] ?? 0);

      return Text(
        userOnlineStatus,
        style: jxTextStyle.textStyle12(
          color: userOnlineStatus == localized(chatOnline)
              ? jx.themeColor
              : jx.colorTextSecondary,
        ),
      );
    }
  }
}
