import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/avatar/data_provider.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';

class DesktopForwardController extends GetxController
    with GetTickerProviderStateMixin {
  TextEditingController userSearchController = TextEditingController();
  TextEditingController chatSearchController = TextEditingController();
  TabController? tabController;
  RxList contactList = RxList();
  RxList<Chat> chatList = RxList<Chat>();

  @override
  onInit() async {
    super.onInit();
    tabController = TabController(
      length: 2,
      vsync: this,
    );
    tabController?.addListener(() => clearSearching());

    await getOriginalList();
  }

  Future<List> getFriendWithSavedMessage() async {
    final List returnList = [objectMgr.userMgr.friendWithoutBlacklist];
    return returnList;
  }

  void clearSearching<T>() {
    if (T == User) {
      userSearchController.clear();
    } else if (T == Chat) {
      chatSearchController.clear();
    } else {
      userSearchController.clear();
      chatSearchController.clear();
    }
    getOriginalList();
  }

  Future<void> searchingNow<T>(String param) async {
    if (param.isEmpty) {
      getOriginalList();
      return;
    }
    if (T == User) {
      contactList.assignAll(
        [
          objectMgr.userMgr.friendWithoutBlacklist
              .where(
                (element) => objectMgr.userMgr
                    .getUserTitle(element)
                    .toLowerCase()
                    .contains(param.toLowerCase()),
              )
              .toList(),
        ],
      );
    } else if (T == Chat) {
      final List<Chat> chats = await objectMgr.chatMgr.loadAllLocalChats();
      sortSavedFirst(chats);
      chatList.assignAll(
        chats.where(
          (element) => element.name.toLowerCase().contains(param.toLowerCase()),
        ),
      );
    }
  }

  Future<void> getOriginalList() async {
    contactList.assignAll(await getFriendWithSavedMessage());
    chatList.assignAll(await objectMgr.chatMgr.loadAllLocalChats());
    sortSavedFirst(chatList);
  }

  Widget getTitle<T>(int uid, bool isGroup, T listItem) {
    if (T == Chat) {
      switch ((listItem as Chat).typ) {
        case chatTypeSystem:
          return Text(
            localized(homeSystemMessage),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          );
        case chatTypeSmallSecretary:
          return Text(
            localized(chatSecretary),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          );
        case chatTypeSaved:
          return Text(
            localized(homeSavedMessage),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          );
      }
    }
    return NicknameText(
      key: ValueKey(uid),
      uid: uid,
      overflow: TextOverflow.ellipsis,
      isTappable: false,
      isGroup: isGroup,
    );
  }

  Widget getHead<T>(int uid, bool isGroup, T listItem) {
    if (T == Chat) {
      switch ((listItem as Chat).typ) {
        case chatTypeSystem:
          return const SystemMessageIcon(
            size: 35,
          );
        case chatTypeSmallSecretary:
          return const SecretaryMessageIcon(
            size: 35,
          );
        case chatTypeSaved:
          return const SavedMessageIcon(
            size: 35,
          );
      }
    }
    return CustomAvatar(
      key: ValueKey(uid),
      dataProvider: DataProvider(uid: uid, isGroup: isGroup),
      size: 35,
    );
  }
}
