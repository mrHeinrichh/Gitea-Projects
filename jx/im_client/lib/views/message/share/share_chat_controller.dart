import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/message/share_image.dart';
import 'package:jxim_client/views/message/share/share_chat_data.dart';

import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class ShareChatController extends GetxController {
  final selectedChatList = <Chat>[].obs;
  final searchDebouncer = Debounce(const Duration(milliseconds: 300));
  final TextEditingController searchController = TextEditingController();
  final TextEditingController captionController = TextEditingController();
  final isSearching = false.obs;
  final FocusNode searchFocus = FocusNode();
  final FocusNode captionFocus = FocusNode();
  final searchParam = ''.obs;
  final isPin = false.obs;
  final ScrollController scrollController = ScrollController();
  List<Chat> chatList = [];
  final filterChatList = [].obs;
  ShareChatData shareChatData = ShareChatData();
  ShareImage? shareImage;

  @override
  onInit() {
    super.onInit();
    objectMgr.chatMgr.on(ChatMgr.eventChatListLoaded, _onRefreshChatList);
    chatList = Get.arguments["chatList"];
    shareImage = Get.arguments["shareImage"];
    filterChat();
    objectMgr.shareMgr.clearShare;
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
    objectMgr.chatMgr.off(ChatMgr.eventChatListLoaded, _onRefreshChatList);
    super.onClose();
  }

  _onRefreshChatList(_, __, ___) {
    chatList = Get.find<ChatListController>().chatList;
    filterChat();
  }

  chatOnTap(int index) {
    Chat chatSelected = filterChatList[index];
    // bool isSelected = selectedChatList.contains(chatSelected);
    // if (isSelected) {
    //   selectedChatList.remove(chatSelected);
    // } else {
    //   selectedChatList.add(chatSelected);
    // }
    onSend(chatSelected);
  }

  onSend(Chat chat) async {
    Get.back();
    String nickname = chat.name;
    // int successCount = 0;
    // for (Chat chat in selectedChatList) {
    if (chat.isSingle) {
      User? user = await objectMgr.userMgr.loadUserById2(chat.friend_id);
      if (user != null && user.deletedAt > 0 ||
          user?.relationship != Relationship.friend) {
        // continue;
        // remove below toast when support multiple
        imBottomToast(
          navigatorKey.currentContext!,
          title: localized(chatInfoPleaseTryAgainLater),
          icon: ImBottomNotifType.warning,
          duration: 3,
        );
      }
      nickname = objectMgr.userMgr.getUserTitle(user);
    }

    shareImage!.chatId = chat.id;
    if (captionController.text.isNotEmpty) {
      shareImage!.caption = captionController.text;
    }
    // successCount++;
    objectMgr.shareMgr.shareDataToChat(shareImage!, openChatRoom: true);
    // }
    // if (successCount == selectedChatList.length) {
    imBottomToast(
      navigatorKey.currentContext!,
      title: localized(messageForwardedSuccessfullyToParam, params: [nickname]),
      icon: ImBottomNotifType.success,
      duration: 3,
    );
    // } else {
    //   ImBottomToast(
    //     navigatorKey.currentContext!,
    //     title: localized(chatInfoPleaseTryAgainLater),
    //     icon: ImBottomNotifType.warning,
    //     duration: 3,
    //   );
    // }
  }

  onSearchChanged(String value) {
    searchParam.value = value;
    searchDebouncer.call(() => searchChat());
  }

  searchChat() {
    List<Chat> newChatList = [];
    for (Chat chat in chatList) {
      if (chat.typ <= chatTypeSaved) {
        if (searchParam.value.isEmpty ||
            chat.name.toLowerCase().contains(searchParam.value.toLowerCase())) {
          newChatList.add(chat);
        }
      }
    }
    filterChatList.value = newChatList;
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
}
