import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/message/share_image.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/message/share/share_chat_data.dart';
import 'package:vibration/vibration.dart';

class NewShareChatController extends GetxController {
  final selectedChatList = <Chat>[].obs;
  final searchDebouncer = Debounce(const Duration(milliseconds: 300));
  late TextEditingController searchController;

  late TextEditingController captionController;
  final isSearching = false.obs;
  late FocusNode searchFocus;
  late FocusNode captionFocus;

  RxString searchParam = ''.obs;
  final isPin = false.obs;
  List<Chat> chatList = [];
  final RxList<Chat> filterChatList = <Chat>[].obs;
  ShareChatData shareChatData = ShareChatData();
  ShareImage? shareImage;

  late ScrollController? scrollController;
  late DraggableScrollableController? draggableScrollableController;
  RxBool validSend = false.obs;
  RxList<Chat> selectedChats = RxList();
  RxBool validShare = false.obs;
  List<Message> forwardMessageList = [];
  final bool isForward = false;

  @override
  onInit() {
    super.onInit();
    objectMgr.chatMgr.on(ChatMgr.eventChatListLoaded, _onRefreshChatList);
    chatList = objectMgr.chatMgr.getAllChats();
    objectMgr.chatMgr.sortChatList(chatList);
    filterChat();
  }

  filterChat() {
    filterChatList.clear();
    for (Chat chat in chatList) {
      if (chat.typ <= chatTypeSaved && chat.isValid && !chat.isDeleteAccount) {
        if (chat.typ == chatTypeSaved) {
          filterChatList.insert(0, chat);
        } else {
          filterChatList.add(chat);
        }
      }
    }
  }

  @override
  onClose() {
    onDispose();
    super.onClose();
    objectMgr.chatMgr.off(ChatMgr.eventChatListLoaded, _onRefreshChatList);
  }

  _onRefreshChatList(_, __, ___) {
    chatList = Get.find<ChatListController>().chatList;
    filterChat();
  }

  onSend(Chat chat, {bool isHousekeeperShare = false}) async {
    Get.back();
    String nickname = chat.name;
    if (chat.isSingle) {
      User? user = await objectMgr.userMgr.loadUserById2(chat.friend_id);
      if (user != null && user.deletedAt > 0 ||
          user?.relationship != Relationship.friend) {
        common.showWarningToast(
          localized(chatInfoPleaseTryAgainLater),
          bottomMargin: 73.w,
        );
      }
      nickname = objectMgr.userMgr.getUserTitle(user);
    }

    shareImage!.chatId = chat.id;
    if (captionController.text.isNotEmpty) {
      shareImage!.caption = captionController.text;
    }
    objectMgr.shareMgr.shareDataToChat(shareImage!, openChatRoom: true && !isHousekeeperShare);
    if (!isHousekeeperShare) {
      common.showSuccessToast(
        localized(messageForwardedSuccessfullyToParam, params: [nickname]),
        bottomMargin: 73.w,
      );
    } else {
      imBottomToast(
        Get.context!,
        icon: ImBottomNotifType.success,
        title: localized(toastShare),
        margin: const EdgeInsets.only(
            bottom: 15,
            left: 12,
            right: 12),
      );
    }
  }

  void clearSearching({isUnfocus = false}) async {
    isSearching.value = false;
    searchController.clear();
    searchParam.value = '';

    if (isUnfocus && searchFocus.hasFocus) {
      searchFocus.unfocus();
    }
    filterChatList.clear();
    for (Chat chat in chatList) {
      if (chat.typ <= chatTypeSaved) {
        filterChatList.add(chat);
      }
    }
  }

  onScroll(ScrollNotification notification) {
    /// close keyboard when scrolling
    searchFocus.unfocus();
    if (isSearching.value) {
      if (!isPin.value) {
        isPin.value = true;
      }
      if (searchParam.value == '') {
        isSearching.value = false;
      }
    } else {
      isPin.value = false;
    }
  }

  getSelectedName() {
    String text = "";
    List<Chat> selectedChats = selectedChatList;
    if (selectedChats.isNotEmpty) {
      if (selectedChats.length == 1) {
        text = selectedChats.first.name;
      } else if (selectedChats.length == 2) {
        text =
        "${setFilterUsername(selectedChats.first.name)} ${localized(shareAnd)} ${setFilterUsername(selectedChats[1].name)}";
      } else if (selectedChats.length > 2) {
        text =
        "${setFilterUsername(selectedChats.first.name)}, ${setFilterUsername(selectedChats[1].name)} ${localized(
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
        "${setFilterUsername(selectedChats.first.name)}, ${setFilterUsername(selectedChats[1].name)} ${localized(
          andOthersWithParam,
          params: [
            '${selectedChats.length - 2}',
          ],
        )}";
      }
    }
    return text;
  }

  void onForwardAction(BuildContext context, List<Chat> chat,
      {bool isHousekeeperShare = false}) async {
    if (forwardMessageList.any((element) => element.isExpired == true)) {
      common.showWarningToast(
        localized(actionCannotBePerformed),
        bottomMargin: 73.w,
      );
      return;
    }

    int errorCount = 0;
    for (var element in chat) {
      objectMgr.chatMgr.selectedMessageMap[element.chat_id] =
          forwardMessageList;
      try {
        await onSend(
          element,
          isHousekeeperShare:isHousekeeperShare,
        );
      } catch (e) {
        errorCount += 1;
        pdebug('AppException: ${e.toString()}');
      }
    }

    if (errorCount == 0) {
      if (chat.length > 1) {
        if (!isHousekeeperShare) {
          common.showSuccessToast(toastText, bottomMargin: 73.w);
        }
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate();
        }
      } else if (chat.length == 1 &&
          !Get.currentRoute.contains("${chat.first.id}")) {
        if(!isHousekeeperShare){
          imBottomToast(
            navigatorKey.currentContext!,
            title: toastText,
            icon: ImBottomNotifType.success,
            withAction: chat.length == 1,
            duration: 3,
            actionFunction: () {
              if (chat.length == 1) {
                Routes.toChat(chat: chat.first);
              }
            },
          );
        }
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate();
        }
      }
      selectedChats.clear();
      filterChatList.clear();
    } else {
      if (!isHousekeeperShare) {
        common.showWarningToast(
          localized(messageForwardedFailedToParam, params: [setUsername()]),
          bottomMargin: 73.w,
        );
      }
    }
    update();

    Get.back();
  }

  int get curMessageType {
    if (shareImage != null) {
      List<ShareItem> item = shareImage!.dataList;
      String fileType = getFileType(item);
      if (["avi", "flv", "mkv", "mov", "mp4", "mpeg", "webm", "wmv"]
          .contains(fileType)) {
        return messageTypeVideo;
      } else if (["bmp", "gif", "jpeg", "jpg", "png"].contains(fileType)) {
        return messageTypeImage;
      } else if (["aac", "midi", "mp3", "ogg", "wav"].contains(fileType)) {
        return messageTypeVoice;
      } else {
        return messageTypeFile;
      }
    }
    return -1;
  }

  String getFileType(List<ShareItem> item) {
    if (item.first.suffix.isNotEmpty) {
      return item.first.suffix;
    }
    if (item.first.imagePath.isNotEmpty) {
      return "png";
    }
    if (item.first.videoPath.isNotEmpty) {
      return "mp4";
    }
    return "-1";
  }

  Future<void> onSearch(String searchParam) async {
    this.searchParam.value = searchParam;
    if(searchParam.trim().isEmpty){
      return;
    }
    List<Chat> chats = await sortList(searchParam: searchParam);

    chatList = chats;
    filterChat();
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

  String get toastText {
    if (curMessageType == messageTypeVideo) {
      return localized(
        messageForwardedSuccessfully,
        params: [localized(videoText)],
      );
    } else if (curMessageType == messageTypeImage) {
      return localized(
        messageForwardedSuccessfully,
        params: [localized(imageText)],
      );
    } else if (curMessageType == messageTypeVoice) {
      return localized(
        messageForwardedSuccessfully,
        params: [localized(audio)],
      );
    } else if (curMessageType == messageTypeFile) {
      return localized(
        messageForwardedSuccessfully,
        params: [localized(document)],
      );
    }
    return '';
  }

  void focusNodeListener() {
    if (searchFocus.hasFocus || captionFocus.hasFocus) {
      draggableScrollableController?.jumpTo(0.98);
    } else {
      draggableScrollableController?.reset();
    }
  }

  void initData(
      ScrollController? scrollController,
      DraggableScrollableController? draggableScrollableController,
      ShareImage? shareImage,
      ) {
    searchController = TextEditingController();
    captionController = TextEditingController();
    searchFocus = FocusNode();
    captionFocus = FocusNode();
    this.shareImage = shareImage;
    this.scrollController = scrollController;
    this.draggableScrollableController = draggableScrollableController;
    objectMgr.shareMgr.clearShare;
    searchFocus.addListener(focusNodeListener);
    captionFocus.addListener(focusNodeListener);
  }

  void onDispose() {
    if (draggableScrollableController != null) {
      searchFocus.removeListener(focusNodeListener);
      captionFocus.removeListener(focusNodeListener);
    }
    selectedChats.clear();
    filterChatList.clear();
    searchController.dispose();
    captionController.dispose();
    captionFocus.dispose();
    searchFocus.dispose();
    // scrollController?.dispose();
  }

  void cancel() {
    selectedChats.clear();
    validSend.value = false;
  }
}
