import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/home/chat/controllers/chat_item_controller.dart';
import 'package:jxim_client/home/chat/create_chat/create_chat_bottom_sheet.dart';
import 'package:jxim_client/home/chat/create_chat/create_chat_controller.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/home/chat/pages/chat_view_app_bar.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:jxim_client/views/contact/searching_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:synchronized/synchronized.dart';

class ChatListEvent extends EventDispatcher {
  static const String eventChatPinnedUpdate = 'eventChatPinnedUpdate';
  static const String eventSearchStateChange = 'eventSearchStateChange';
  static const String eventMultiSelectStateChange =
      'eventMultiSelectStateChange';
  static const String eventChatEditSelect = 'eventChatEditSelect';
  static const String eventChatEnableEditStateChange =
      'eventChatEnableEditStateChange';

  static final ChatListEvent instance = ChatListEvent._internal();

  factory ChatListEvent() {
    return instance;
  }

  ChatListEvent._internal();
}

class ChatListController extends GetxController {
  /// VARIABLES

  // 提供滑动控制器到聊天列表
  final ScrollController scrollController = ScrollController();

  // 聊天列表事件分发器
  final ChatListEvent chatListEvent = ChatListEvent.instance;

  // 完整聊天列表
  final List<Chat> allChats = [];

  // 展示列表 (响应)
  final chatList = <Chat>[].obs;

  // 最大置顶值
  static int maxChatSort = 0;

  final CustomPopupMenuController popUpMenuController =
      Get.find<CustomPopupMenuController>();

  // 编辑聊天列表
  RxBool isEditing = false.obs;
  RxBool isSelectMore = true.obs;
  final selectedChatIDForEdit = <int>[].obs;

  // 搜索模块
  final searchDebouncer = Debounce(const Duration(milliseconds: 300));
  RxBool isSearching = false.obs;
  final FocusNode searchFocus = FocusNode();
  final TextEditingController searchController = TextEditingController();
  RxString searchParam = ''.obs;

  // 搜索开启时的置顶状态栏
  RxBool isPin = false.obs;
  RxBool isShowLabel = true.obs;
  bool touchUpDown = false;
  bool isShowSearch = false;

  //搜索到的信息列表
  Lock searchMsgLock = Lock();
  RxList<Message> messageList = RxList();

  // 桌面端 变量
  final desktopSelectedChatID = 01010.obs;
  Offset mousePosition = const Offset(0, 0);
  final selectedCellIndex = (-1).obs;

  /// METHODS
  @override
  void onInit() async {
    super.onInit();
    await objectMgr.chatMgr.loadLocalLastMessages();
    loadChatList();
    // 新增聊天室事件
    objectMgr.chatMgr.on(ChatMgr.eventChatJoined, _onChatJoined);

    // 聊天室移除事件
    objectMgr.sharedRemoteDB
        .on("$blockOptDelete:${DBChat.tableName}", _onChatDeleted);
    objectMgr.chatMgr.on(ChatMgr.eventChatHide, _onChatDeleted);
    objectMgr.chatMgr.on(ChatMgr.eventChatDelete, _onChatDeleted);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onChatDeleted);

    // 群语音
    objectMgr.chatMgr.on(ChatMgr.eventAudioChat, _onAudioChat);

    objectMgr.chatMgr
        .on(ChatMgr.eventChatLastMessageChanged, _onRefreshChatList);
    objectMgr.chatMgr.on(ChatMgr.eventMessageSend, _onRefreshChatList);
    objectMgr.chatMgr.on(ChatMgr.eventChatListLoaded, _onRefreshChatList);
    objectMgr.chatMgr
        .on(ChatMgr.eventAllLastMessageLoaded, _onLastMessageLoaded);
    objectMgr.chatMgr.on(ChatMgr.eventAddMentionChange, _onRefreshChatList);
    objectMgr.chatMgr.on(ChatMgr.eventDelMentionChange, _onRefreshChatList);

    // 聊天室置顶改变事件
    chatListEvent.on(ChatListEvent.eventChatPinnedUpdate, onChatPinnedUpdate);
    chatListEvent.on(
      ChatListEvent.eventSearchStateChange,
      _onSearchStateChanged,
    );
    chatListEvent.on(ChatListEvent.eventChatEditSelect, _onChatEditSelect);

    objectMgr.myGroupMgr.on(MyGroupMgr.eventTmpGroup, _onRefreshChatList);

    objectMgr.chatMgr.handleShareData();
  }

  void onScroll(ScrollNotification notification) async {
    /// close keyboard when scrolling
    searchFocus.unfocus();
    if (isSearching.value) {
      if (!isPin.value) {
        isPin.value = true;
      }
    } else {
      isPin.value = false;
    }

    if (isSearching.value) {
      return;
    }

    var offsetY = scrollController.offset;

    if (touchUpDown) {
      if (kSearchHeight.value <= kSearchHeightMax * 0.5) {
        kSearchHeight.value = 0;
      } else {
        kSearchHeight.value = kSearchHeightMax;
      }
      if (kSearchHeight.value == kSearchHeightMax) {
        isShowSearch = true;
        return;
      } else {
        isShowSearch = false;
      }
    }

    if (offsetY <= -kSearchHeightMax - 30 && offsetY >= kSearchHeightMax + 30) {
      return;
    }

    if (offsetY <= 0) {
      if (isShowSearch) {
        if (offsetY <= 0) {
          kSearchHeight.value = kSearchHeightMax;
        }
      } else {
        if (offsetY >= -kSearchHeightMax) {
          kSearchHeight.value = -offsetY;
        } else {
          kSearchHeight.value = kSearchHeightMax;
        }
      }
    } else {
      if (isShowSearch) {
        var height = kSearchHeightMax - offsetY;
        if (height <= 0) {
          kSearchHeight.value = 0.0;
        } else {
          kSearchHeight.value = height;
        }
      } else {
        if (offsetY >= 0) {
          kSearchHeight.value = 0.0;
        }
      }
    }
  }

  void _onRefreshChatList(Object? sender, Object? type, Object? data) async {
    loadChatList();
  }

  void _onLastMessageLoaded(_, __, ___) async {
    final chats = await objectMgr.chatMgr.loadAllLocalChats();
    if (chats.isNotEmpty) {
      objectMgr.chatMgr.sortChatList(chats);
      chatList.assignAll(chats);
      objectMgr.shareMgr.syncChatList(chats);
      update();
    }
  }

  void _onChatJoined(p0, p1, p2) {
    if (p2 is Chat) {
      final index = chatList.indexWhere((chat) => chat.id == p2.chat_id);
      if (index == -1) {
        if (p2.delete_time > 0) {
          Group? group = objectMgr.myGroupMgr.getGroupById(p2.id);
          if (group?.roomType == GroupType.TMP.num) {
            objectMgr.chatMgr.doTmpGroupReJoin(p2);

            chatList.add(p2);
            objectMgr.chatMgr.sortChatList(chatList);
          }
        } else if (p2.isVisible) {
          chatList.add(p2);
          objectMgr.chatMgr.sortChatList(chatList);
        }
      }
    }
  }

  Future<void> _onChatDeleted(Object sender, __, Object? deletedChat) async {
    if (deletedChat != null && deletedChat is Chat) {
      if (!deletedChat.isVisible) {
        final removeIdx = chatList
            .indexWhere((element) => element.chat_id == deletedChat.chat_id);
        if (removeIdx != -1) {
          chatList.removeAt(removeIdx);
          Get.findAndDelete<ChatItemController>(
            tag: 'chat_item_${deletedChat.id.toString()}',
            force: true,
          );
        }
      } else {
        loadChatList();
      }
    } else if (deletedChat is int) {
      final removeIdx =
          chatList.indexWhere((element) => element.chat_id == deletedChat);
      if (removeIdx != -1) {
        chatList.removeAt(removeIdx);
        Get.findAndDelete<ChatItemController>(
          tag: 'chat_item_${deletedChat.toString()}',
          force: true,
        );
      }
    } 
  }

  void onChatPinnedUpdate(_, __, Object? data) {
    if (data == null || data is! Map) return;

    final chatId = data['chat_id'];
    final sort = data['sort'];

    final chat = chatList.firstWhereOrNull((element) => element.id == chatId);
    if (chat != null) {
      chat.updateValue({'sort': sort});
      objectMgr.chatMgr.sortChatList(chatList);
    }
  }

  void _onAudioChat(_, __, Object? msg) {
    if (msg is! Message) return;
    final chat = objectMgr.chatMgr.getChatById(msg.chat_id);
    if (msg.typ == messageTypeAudioChatOpen) {
      chat?.enableAudioChat.value = true;
    } else {
      chat?.enableAudioChat.value = false;
    }
  }

  void _onSearchStateChanged(_, __, Object? data) {
    if (data is bool && data) {
      clearSearching(isUnfocus: true);
    }
  }

  void _onChatEditSelect(_, __, Object? data) {
    if (data is! Chat) return;

    isEditing.value = true;
    if (selectedChatIDForEdit.contains(data.id)) {
      selectedChatIDForEdit.remove(data.id);
    } else {
      selectedChatIDForEdit.add(data.id);
    }
  }

  @override
  void onClose() {
    for (final chat in allChats) {
      Get.findAndDelete<ChatItemController>(
        tag: 'chat_item_${chat.id.toString()}',
        force: true,
      );
    }

    objectMgr.chatMgr.off(ChatMgr.eventChatJoined, _onChatJoined);

    objectMgr.sharedRemoteDB
        .off("$blockOptDelete:${DBChat.tableName}", _onChatDeleted);
    objectMgr.chatMgr.off(ChatMgr.eventChatHide, _onChatDeleted);
    objectMgr.chatMgr.off(ChatMgr.eventChatDelete, _onChatDeleted);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, _onChatDeleted);

    objectMgr.chatMgr.off(ChatMgr.eventAudioChat, _onAudioChat);

    objectMgr.chatMgr.off(ChatMgr.eventMessageSend, _onRefreshChatList);
    objectMgr.chatMgr.off(ChatMgr.eventChatListLoaded, _onRefreshChatList);
    objectMgr.chatMgr.off(ChatMgr.eventAddMentionChange, _onRefreshChatList);
    objectMgr.chatMgr.off(ChatMgr.eventDelMentionChange, _onRefreshChatList);
    objectMgr.chatMgr
        .off(ChatMgr.eventAllLastMessageLoaded, _onLastMessageLoaded);

    chatListEvent.off(ChatListEvent.eventChatPinnedUpdate, onChatPinnedUpdate);
    chatListEvent.off(
      ChatListEvent.eventSearchStateChange,
      _onSearchStateChanged,
    );
    chatListEvent.off(ChatListEvent.eventChatEditSelect, _onChatEditSelect);
    objectMgr.myGroupMgr.off(MyGroupMgr.eventTmpGroup, _onRefreshChatList);

    super.onClose();
  }

  // ================================ 业务逻辑 ==================================
  loadChatList() async {
    final chats = await objectMgr.chatMgr.loadAllLocalChats();

    if (chats.isEmpty) {
      allChats.clear();
      chatList.clear();
      return;
    }

    allChats.assignAll(chats);

    for (var element in allChats) {
      Get.findOrPut<ChatItemController>(
        ChatItemController(chat: element, isEditing: isEditing),
        tag: 'chat_item_${element.id.toString()}',
        permanent: true,
      );

      if (element.sort > maxChatSort) {
        maxChatSort = element.sort;
      }
      if(element.flag != 0 && element.chat_key == "" && element.isGroup){
        objectMgr.encryptionMgr.getChatCipherKey(element.chat_id);
      }
    }

    List olds = chatList.map((e) => e.msg_idx).toList();
    objectMgr.chatMgr.sortChatList(chats);
    List news = chats.map((e) => e.msg_idx).toList();
    if (!listEquals(olds, news)) {
      chatList.assignAll(chats);
      objectMgr.shareMgr.syncChatList(chats);
    }

    if (objectMgr.pushMgr.initMessage != null) {
      objectMgr.pushMgr.notificationRouting(objectMgr.pushMgr.initMessage!);
    }
    searchChat();
  }

  void onItemClick(int index) {
    Chat chat = chatList[index];
    Routes.toChat(chat: chat);
  }

  void onChatEditTap() {
    isEditing.value = !isEditing.value;
    chatListEvent.event(
      chatListEvent,
      ChatListEvent.eventMultiSelectStateChange,
      data: isEditing.value,
    );
    if (isEditing.value == false) {
      clearSelectedChatForEdit();
    }
    clearSearching();
  }

  // 隐藏聊天室
  Future<void> hideChat(BuildContext context, Chat? chat) async {
    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      confirmText:
          localized(hide1Chat, params: ['${selectedChatIDForEdit.length}']),
      onConfirmListener: () {
        isSelectMore.value = false;
        chatListEvent.event(
          chatListEvent,
          ChatListEvent.eventChatEnableEditStateChange,
          data: isSelectMore.value,
        );

        imBottomToast(
          context,
          title: localized(
            hide1Chat,
            params: ['${selectedChatIDForEdit.length}'],
          ),
          icon: ImBottomNotifType.timer,
          duration: 5,
          timerFunction: () {
            for (var chatId in selectedChatIDForEdit) {
              Chat? chat = chatList
                  .firstWhereOrNull((element) => element.chat_id == chatId);
              if (chat != null) {
                objectMgr.chatMgr.setChatHide(chat);
              }
            }
            isEditing.value = false;
            clearSelectedChatForEdit();

            isSelectMore.value = true;
            chatListEvent.event(
              chatListEvent,
              ChatListEvent.eventChatEnableEditStateChange,
              data: isSelectMore.value,
            );
            Get.back();
          },
          undoFunction: () {
            BotToast.removeAll(BotToast.textKey);
            isSelectMore.value = true;
            chatListEvent.event(
              chatListEvent,
              ChatListEvent.eventChatEnableEditStateChange,
              data: isSelectMore.value,
            );
          },
          withCancel: true,
          isStickBottom: false,
        );
      },
    );
  }

  // 删除聊天室
  Future<void> onDeleteChat(BuildContext context, Chat? chat) async {
    BotToast.removeAll(BotToast.textKey);

    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      confirmText: localized(
        deleteParamChat,
        params: ['${selectedChatIDForEdit.length}'],
      ),
      onConfirmListener: () {
        isSelectMore.value = false;
        chatListEvent.event(
          chatListEvent,
          ChatListEvent.eventChatEnableEditStateChange,
          data: isSelectMore.value,
        );

        imBottomToast(
          context,
          title: localized(
            deleteParamChat,
            params: ['${selectedChatIDForEdit.length}'],
          ),
          icon: ImBottomNotifType.timer,
          duration: 5,
          withCancel: true,
          timerFunction: () {
            for (var chatId in selectedChatIDForEdit) {
              Chat? chat = chatList
                  .firstWhereOrNull((element) => element.chat_id == chatId);
              if (chat != null) {
                objectMgr.chatMgr.onChatDelete(chat);
              }
            }
            isEditing.value = false;
            clearSelectedChatForEdit();
            isSelectMore.value = true;
            chatListEvent.event(
              chatListEvent,
              ChatListEvent.eventChatEnableEditStateChange,
              data: isSelectMore.value,
            );
            Get.back();
          },
          undoFunction: () {
            BotToast.removeAll(BotToast.textKey);
            isSelectMore.value = true;
            chatListEvent.event(
              chatListEvent,
              ChatListEvent.eventChatEnableEditStateChange,
              data: isSelectMore.value,
            );
          },
          isStickBottom: false,
        );
      },
    );
  }

  /// 聊天置顶
  void onPinnedChat(BuildContext context, Chat chat) async {
    final isTop = chat.sort == 0;
    final sort = isTop ? ChatListController.maxChatSort + 1 : 0;

    try {
      await objectMgr.chatMgr.setChatTop(chat, sort);
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  Future<void> scanQRCode({
    Function(String)? didGetText,
    bool isWallet = false,
  }) async {
    popUpMenuController.hideMenu();
    FocusManager.instance.primaryFocus?.unfocus();

    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    final PermissionStatus status = await Permission.camera.status;
    if (status.isGranted) {
      Get.toNamed(
        RouteName.qrCodeScanner,
        arguments: {
          'didGetText': didGetText,
        },
      );
    } else {
      final bool rationale = await Permission.camera.shouldShowRequestRationale;
      if (rationale || status.isPermanentlyDenied) {
        openSettingPopup(Permissions().getPermissionName(Permission.camera));
      } else {
        final PermissionStatus status = await Permission.camera.request();
        if (status.isGranted) Get.toNamed(RouteName.qrCodeScanner);
        if (status.isPermanentlyDenied) {
          openSettingPopup(Permissions().getPermissionName(Permission.camera));
        }
      }
    }
  }

  /// =============================== 搜索模块 ==================================
  onSearchChanged(String value) {
    searchParam.value = value;
    searchDebouncer.call(() => searchLocal());
  }

  /// 搜索信息
  void searchLocal() async {
    await searchMessages();
    searchChat();
  }

  ///搜索本地的聊天室列表
  void searchChat() async {
    if (isSearching.value) {
      //List<Chat> tempChatList = await objectMgr.chatMgr.loadAllLocalChats();
      List<Chat> tempChatList = allChats;
      if (notBlank(searchParam.value)) {
        tempChatList = tempChatList.where((element) {
          if (element.isVisible) {
            return element.name
                .toLowerCase()
                .contains(searchParam.value.toLowerCase());
          } else {
            return false;
          }
        }).toList();
        // dispatcher.dispatchNewList(List.from(tempChatList));
      }
      objectMgr.chatMgr.sortChatList(tempChatList);
      chatList.assignAll(tempChatList);
    }
  }

  Future<void> searchMessageFromColdTable(String content) async {
    List<String> tables = await objectMgr.localDB.getColdMessageTables(0, 0);
    for (int i = 0; i < tables.length; i++) {
      List<Message> messages = [];
      List<Map<String, dynamic>> rows =
          await objectMgr.localDB.searchMessage(content, tbname: tables[i]);
      messages = objectMgr.chatMgr.searchMessageFromRows(content, rows);
      messages.sort((a, b) => b.create_time - a.create_time);
      if (content != searchParam.value) {
        return;
      }
      messageList.addAll(messages);
      messages.clear();
    }
  }

  ///搜索本地所有信息列表
  Future<void> searchMessages() async {
    await searchMsgLock.synchronized(() async {
      messageList.value = [];
      if (!notBlank(searchParam.value)) {
        return;
      }
      // 暂时储存信息的列表
      await searchMessageFromColdTable(searchParam.value);
    });
  }

  ///转换信息的格式
  List<Message> mapMessageConversion(List<Map<String, dynamic>> messages) {
    return messages.map((element) {
      final Message msg = Message()..init(element);
      return msg;
    }).toList();
  }

  ///清除搜索flag
  void clearSearching({isUnfocus = false}) async {
    isSearching.value = false;
    searchController.clear();
    searchParam.value = '';

    if (isUnfocus && searchFocus.hasFocus) {
      searchFocus.unfocus();
    }

    loadChatList();
  }

  ///Desktop Version ====================================================
  bool isCTRLPressed() {
    return HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.controlRight);
  }

  void tapForEdit(Chat chat) {
    if (chat.isSpecialChat) {
      Toast.showToast(
        localized(hideOrDeleteSavedMessageIsNotAllowed,params: [getSpecialChatName(chat.typ)]),
        isStickBottom: false,
      );
    } else {
      selectedChatIDForEdit.contains(chat.chat_id)
          ? selectedChatIDForEdit.remove(chat.chat_id)
          : selectedChatIDForEdit.add(chat.chat_id);
      update();
    }
  }

  void clearSelectedChatForEdit() {
    selectedChatIDForEdit.clear();
    update();
  }

  // ================================== 工具 ====================================

  Chat? getChat(int chatId) {
    final list = chatList.where((element) => element.id == chatId).toList();
    if (list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  /// 创建聊天室
  void showCreateChatPopup(BuildContext context) {
    CreateChatController createChatController = Get.put(CreateChatController());

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return CreateChatBottomSheet(
          controller: createChatController,
          createGroupCallback: (type) {
            if (type == GroupType.FRIEND) {
              Get.close(1);
              showAddFriendBottomSheet(context);
            } else {
              showCreateGroupPopup(context);
            }
          },
        );
      },
    ).then((value) {
      Get.findAndDelete<CreateChatController>();
    });
  }

  /// 创建群组
  void showCreateGroupPopup(BuildContext context) {
    CreateGroupBottomSheetController createGroupBottomSheetController =
        Get.put(CreateGroupBottomSheetController());
    // createGroupBottomSheetController.groupType = type;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return CreateGroupBottomSheet(
          controller: createGroupBottomSheetController,
          cancelCallback: () {
            createGroupBottomSheetController.closePopup();
          },
        );
      },
    ).then((value) {
      Get.findAndDelete<CreateGroupBottomSheetController>();
    });
  }

  Future<void> showAddFriendBottomSheet(BuildContext ctx) async {
    Get.put(SearchContactController());
    showModalBottomSheet(
      context: ctx,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        Get.find<SearchContactController>().isModalBottomSheet = true;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.94,
            child: const SearchingView(),
          ),
        );
      },
    ).whenComplete(() {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => Get.findAndDelete<SearchContactController>(),
      );
    });
  }

  Future<void> onRefresh() async {
    if (!isSearching.value) {
      await objectMgr.onAppDataReload();
    }
  }

  void enterSecretaryChat() {
    Chat? chat = objectMgr.chatMgr.getChatByTyp(chatTypeSmallSecretary);
    if (chat != null) {
      if (searchParam.value.trim().isNotEmpty){
        objectMgr.chatMgr.sendText(chat.id, searchParam.value, false);
      }

      Routes.toChat(chat: chat);
    }

    searchFocus.unfocus();
    clearSearching();
  }
}
