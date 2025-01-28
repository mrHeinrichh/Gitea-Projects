import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/api/chat.dart';
import 'package:jxim_client/api/chat.dart' as chat_api;
import 'package:jxim_client/api/group.dart' as group_api;
import 'package:jxim_client/api/socket.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_chat_category.dart';
import 'package:jxim_client/data/db_group.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_message.dart';
import 'package:jxim_client/data/db_red_packet.dart';
import 'package:jxim_client/data/object_pool.dart';
import 'package:jxim_client/data/shared_remote_db.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_text.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/home/share_home_extension.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/encryption_mgr.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/interface/base_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/message_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/send_message_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/managers/sys_oprate_mgr.dart';
import 'package:jxim_client/managers/translation_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_category.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/object/chat/chat_list.dart';
import 'package:jxim_client/object/chat/draft_model.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/chat/translation_model.dart';
import 'package:jxim_client/object/event_model.dart';
import 'package:jxim_client/object/get_store_model.dart';
import 'package:jxim_client/object/message/share_image.dart';
import 'package:jxim_client/object/retry.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/tasks/chat_typing_task.dart';
import 'package:jxim_client/tasks/expire_message_task.dart';
import 'package:jxim_client/tasks/sign_chat_task.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/link_analyzer/parser.dart';
import 'package:jxim_client/utils/net/request_data.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 消息分页数
const int messagePageCount = 50;
const int messagePreLoadCount = 50;
const int maxHotMessageTable = 1000;

///草稿
const String draftMessage = 'draft_message';

class ChatMgr extends BaseMgr with ChatSend implements TemplateMgrInterface {
  static const String eventChatListLoaded = 'eventChatListLoaded';

  // 远程聊天室文件夹创建事件
  static const String eventChatCategoryLoaded = 'eventChatCategoryLoaded';

  // 聊天室文件夹更新
  static const String eventChatCategoryChanged = 'eventChatCategoryChanged';

  // 聊天室未读消息数量变更事件
  static const String eventChatCategoryUnreadChanged =
      'eventChatCategoryUnreadChanged';

  static const String eventMessageComing = 'eventMessageComing';
  static const String eventMessageListComing = 'eventMessageListComing';
  static const String eventAllLastMessageLoaded = 'eventAllLastMessageLoaded';
  static const String eventChatLastMessageChanged =
      'eventChatLastMessageChanged';
  static const String eventMessageSend = 'eventMessageSend';
  static const String eventEmojiChange = "eventEmojiChange";
  static const String eventFileOperate = "eventMsgFileOperate"; //文件操作 用于通知聊天室页面
  static const String eventFileOperateDoMsg =
      "eventFileOperateDoMsg"; // 文件操作 用于通知首页会话列表
  static const String eventAddMentionChange = 'eventAddMentionChange';
  static const String eventDelMentionChange = 'eventDelMentionChange';
  static const String eventUnreadTotalCount = 'eventUnreadTotalCount';
  static const String eventChatPinnedMessage = 'eventChatPinnedMessage';
  static const String eventChatLocalPinnedMessage =
      'eventChatLocalPinnedMessage';
  static const String eventReadMessage = 'eventReadMessage';
  static const String eventUnreadPosition = 'eventUnreadPosition';
  static const String eventChatReload = 'eventChatReload';
  static const String eventDeleteMessage = 'eventDeleteMessage';
  static const String eventVoicePause = 'pauseVoice';
  static const String eventEditMessage = 'eventEditMessage';
  static const String eventChatKicked = "eventChatKicked";
  static const String eventChatMuteChanged = "eventChatMuteChanged";
  static const String eventChatJoined = "eventChatJoined";
  static const String eventChatHide = "eventChatHide";
  static const String eventChatDisband = "eventChatDisband";
  static const String eventChatDelete = "eventChatDelete";
  static const String eventRedPacketStatus = "eventRedPacketStatus";
  static const String eventAutoDeleteInterval = "eventAutoDeleteInterval";
  static const String eventAutoDeleteMsg = "eventAutoDeleteMsg";
  static const String eventSetPassword = 'eventSetPassword';
  static const String eventUpdateUnread = "eventUpdateUnread";
  static const String eventRejoined = 'eventRejoined';
  static const String eventAudioChat = 'eventAudioChat';
  static const String eventDecryptChat = 'eventDecryptChat';
  static const String eventChatEncryptionUpdate = 'eventChatEncryptionUpdate';

  static const String eventVoicePlayUpdate = 'eventVoicePlayUpdate';

  static const String eventChatIsTyping = 'eventChatIsTyping';
  static const String eventDraftUpdate = 'eventDraftUpdate';

  static const String cancelKeyboardEvent = 'cancelKeyboardEvent';
  static const String eventChatTranslateUpdate = "eventChatTranslateUpdate";
  static const String messagePlayingSound = "messagePlayingSound";
  static const String messageStopSound = "messageStopSound";
  static const String messageWaitingRead = "messageWaitingRead";
  static const String messageStopAllReading = "messageStopAllReading";
  static const String messagePauseReading = "messagePauseReading";
  static const String messageContinueRead = "messageContinueRead";

  /// 移除 react emoji事件
  static const String eventRemoveReactEmoji = 'eventRemoveReactEmoji';

  static const String eventSearchListChange = "eventSearchListChange";

  /// 聊天室滑动中
  static const String eventScrolling = "eventScrolling";

  Timer? _cooldownTimer;
  bool _pendingExecution = false;

  //需要刷新一下
  bool isNeedRefresh = false;

  //聊天自己发送数据管理
  final MySendMessageMgr mySendMgr = MySendMessageMgr();

  // 聊天列表事件分发器
  final ChatListEvent chatListEvent = ChatListEvent();

  RxBool loadingChats = false.obs;
  final totalUnreadCount = 0.obs;

  int loadMessageCount = 0;

  final List<ChatCategory> chatCategoryList = <ChatCategory>[];

  final Map<int, Set<int>> chatCategoryUnreadCount = <int, Set<int>>{};

  /// 消息
  final Map<int, Map<int, Message>> _chatMessageMap = {};

  Map<int, Map<int, Message>> get chatMessageMap => _chatMessageMap;

  /// 最后一条消息
  final Map<int, Message?> _lastChatMessageMap = {};

  Map<int, Message?> get lastChatMessageMap => _lastChatMessageMap;

  /// @消息
  final Map<int, Map<int, Message>> mentionMessageMap = {};

  Map<int, List<Message>> pinnedMessageList = {};

  /// react emoji
  final Map<int, Map<int, List<Message>>> _reactEmojiMap = {};

  Map<int, Map<int, List<Message>>> get reactEmojiMap => _reactEmojiMap;

  Map<int, ReplyModel> replyMessageMap = {};
  Map<int, List<Message>> selectedMessageMap = {};
  Map<int, Message> editMessageMap = {};
  Map<int, Metadata> linkPreviewData = {};

  final Map<int, List<RedPacketStatus>> _redPacketStatusMap = {};

  Map<int, List<RedPacketStatus>> get redPacketStatusMap => _redPacketStatusMap;
  final List<List<dynamic>> _redPacketRequestList = <List<dynamic>>[];

  /// chatID: dateStr-msgidx
  late SharedRemoteDB _sharedDB;
  late DBInterface _localDB;
  SharedTable? _chatTable;
  Map<int, Map<String, dynamic>> groupSlowMode = {};

  DateTime? lastCheckedTime;

  static final List<String> realMessageKeys = [];
  static const _methodChannel = MethodChannel("jxim/notification");

  // 消息日志对象
  final MessageLog _log = MessageLog.sharedInstance;

  @override
  Future<void> registerOnce() async {
    _sharedDB = objectMgr.sharedRemoteDB;
    _localDB = objectMgr.localDB;

    await Future.wait([registerModel()]);

    if (objectMgr.loginMgr.isLogin) {
      objectMgr.prepareDBData(objectMgr.loginMgr.account!.user!);
    }
  }

  /// 注册模版
  @override
  Future<void> registerModel() async {
    _sharedDB.registerModel(
      DBChat.tableName,
      JsonObjectPool<Chat>(Chat.creator),
    );
    _sharedDB.registerModel(
      DBMessage.tableName,
      JsonObjectPool<Message>(Message.creator),
    );
  }

  static String getCreateMessageTableSql(String tableName) {
    String messageCreateSql = '''
        CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY,
        message_id INTEGER,
        chat_id INTEGER,
        chat_idx INTEGER,
        send_id INTEGER,
        content TEXT,
        typ INTEGER,
        send_time INTEGER,
        expire_time INTEGER,
        create_time INTEGER,
        at_users TEXT,
        emojis TEXT DEFAULT "[]",
        edit_time INTEGER DEFAULT 0,
        ref_typ INTEGER DEFAULT 0,
        flag INTEGER DEFAULT 0,
        cmid TEXT DEFAULT ""
        );
      ''';
    return messageCreateSql;
  }

  @override
  Future<void> initialize() async {
    loadingChats.value = false;
    _chatTable = _sharedDB.getTable(DBChat.tableName);
    objectMgr.socketMgr.on(SocketMgr.eventSocketClose, _onSocketClosed);
    objectMgr.socketMgr.on(SocketMgr.updateChatReadBlock, _onReadMessageUpdate);
    objectMgr.sysOprateMgr.on(SysOprateMgr.eventChatInput, _onChatInput);

    if (Config().enableChatCategory) _initLocalChatCategory();
    _initChatMessages();
    getAllSlowModeGroup();
    reSendMessage();
  }

  void _initLocalChatCategory() async {
    final List<Map<String, dynamic>> tempList =
        await _localDB.getChatCategoryList();

    if (tempList.isNotEmpty) {
      List<ChatCategory> tempCategoryList = tempList
          .map<ChatCategory>(
            (e) => ChatCategory()..init(e),
          )
          .toList();

      chatCategoryList.assignAll(tempCategoryList);
    }
  }

  _initChatMessages() async {
    List<Chat> chats = await loadAllLocalChats();

    if (chats.isNotEmpty) {
      loadLocalLastMessages();
      countLocalUnreadNum(chats);
      loadLocalMentions();
      loadChatExpireMessages(ExpireMessageTask.expireTime);
      event(this, eventChatListLoaded);
    }
  }

  Future<void> onSocketOpen() async {
    objectMgr.appInitState.value = AppInitState.fetching;
    if (Config().enableChatCategory) loadChatCategory();
    for (int i = 1; i <= 3; i++) {
      if (await loadChats() != null) {
        break;
      }
      await Future.delayed(Duration(seconds: i));
    }
  }

  void reSendMessage() async {
    List<Message> listMsgs = await loadReSendMessage();
    for (Message msg in listMsgs) {
      if (msg.typ == messageTypeReqSignChat) {
        reqSignChat(msg, null);
      } else {
        mySendMgr.onResend(msg, isAuto: true);
      }
    }
  }

  Future<List<Message>> loadReSendMessage() async {
    List<Map<String, dynamic>> tempList = await objectMgr.localDB
        .loadReSendMessage(objectMgr.userMgr.mainUser.uid, 600);

    List<Message> mList = [];
    if (tempList.isNotEmpty) {
      mList = tempList.map<Message>((e) => Message()..init(e)).toList();
    }
    return mList;
  }

  Future<void> _onSocketClosed(a, b, c) async {
    if (objectMgr.socketMgr.socket!.open) {
      return;
    }
  }

  saveMessage(Message message) async {
    if (message.typ != messageTypeCommandFileOperate &&
        message.isInvisibleMsg) {
      return;
    }
    message.id = message.getID();
    await objectMgr.localDB.saveMessage(message);
    processInputMessage([message]);
  }

  Future<void> _loginChat() async {
    if (!objectMgr.loginMgr.isLogin) return;
    await chat_api.login(objectMgr.loginMgr.account!.token);

    //取得當前有在撥放語音群聊的群組
    ResponseData beans = await getTalkingChat();
    if (beans.success()) {
      final talkingChatIds = beans.data["talking_chat_ids"] ?? List.empty();
      for (int chatId in talkingChatIds) {
        final talkingChat = getChatById(chatId);
        talkingChat?.enableAudioChat.value = true;
      }
      List<Chat> chats = await loadAllLocalChats();
      for (var element in chats) {
        if (!talkingChatIds.contains(element.chat_id)) {
          //移除沒在list裡面的
          final talkingChat = getChatById(element.chat_id);
          talkingChat?.enableAudioChat.value = false;
        }
      }
    }
  }

  Future<void> loadMessageFromChat(Chat chat) async {
    if (!serversUriMgr.isKiWiConnected) {
      if (loadMessageCount < 50) {
        loadMessageCount++;
        Future.delayed(const Duration(milliseconds: 10), () {
          loadMessageFromChat(chat);
        });
        return;
      } else {
        loadMessageCount = 0;
        return;
      }
    } else {
      loadMessageCount = 0;
    }
    try {
      // 记录短链接获取消息拉取的时间
      _log.updateInfo(
        MessageModule.message_push,
        startRequestTime: DateTime.now().millisecondsSinceEpoch,
      );

      final res = await chat_api.history(
        chat.chat_id,
        chat.msg_idx + 1,
        forward: 0,
        count: 15,
      );

      if (res.success()) {
        List<Message> messages = [];
        for (final msg in res.data) {
          Message message = Message()..init(msg);
          message.origin = originHistory;
          if (message.isEncrypted && chat.isActiveChatKeyValid) {
            try {
              MessageMgr.decodeMsg(
                  message, chat, objectMgr.userMgr.mainUser.uid);
            } catch (e) {
              message.ref_typ = 4;
              pdebug("loadMessageFromChat aes decrypt err: $e");
            }
          }
          messages.add(message);
          if (message.isMediaType) {
            await cacheMediaMgr.getMessageGausImage(message);
          }
        }
        _log.updateInfo(
          MessageModule.message_push,
          endRequestTime: DateTime.now().millisecondsSinceEpoch,
          messageCount: messages.length,
        );

        processRemoteMessage(messages);

        if (!Get.currentRoute.contains("${chat.chat_id}")) {
          try {
            objectMgr.pushMgr.ifMinimizedCallView("notificationRouting1", chat);
            Get.until(
              (route) =>
                  Get.currentRoute == RouteName.home ||
                  Get.currentRoute.contains("${chat.chat_id}"),
            );
            Routes.toChat(chat: chat, fromNotification: true);
            Get.find<HomeController>().onPageChange(0);
          } catch (e) {
            pdebug('Get the Chat and rounting error $e');
          }
        }
      }
    } catch (_) {
    } finally {
      /// 离线推送流程结束
      _log.updateInfo(
        MessageModule.message_push,
        endTime: DateTime.now().millisecondsSinceEpoch,
        shouldAddLog: true,
        shouldUpload: true,
      );
    }
  }

  void _onRefresh() {
    if (_cooldownTimer?.isActive ?? false) {
      _pendingExecution = true;
      return;
    }
    _executeRefresh();
  }

  void _executeRefresh() {
    _initChatMessages();
    _cooldownTimer = Timer(const Duration(seconds: 3), () {
      if (_pendingExecution) {
        _pendingExecution = false;
        _executeRefresh();
      }
    });
  }

  loadMessageStatusChange(int state) async {
    if (state == 1) {
      objectMgr.appInitState.value = AppInitState.fetching;
    } else {
      if (objectMgr.appInitState.value == AppInitState.fetching) {
        if (isNeedRefresh) {
          _cooldownTimer?.cancel();
          _initChatMessages();
        }
        objectMgr.appInitState.value = AppInitState.done;
      }
    }
  }

  processRemoteMessage(List<Message> messages) async {
    if (messages.first.origin == originHistory &&
        objectMgr.appInitState.value == AppInitState.fetching) {
      isNeedRefresh = true;
      event(this, eventMessageListComing, data: messages);
      _onRefresh();
      return;
    }
    processMessage(messages, ProcessMessageType.net);
  }

  processLocalMessage(List<Message> messages) async {
    processMessage(messages, ProcessMessageType.db);
  }

  processInputMessage(List<Message> messages) async {
    processMessage(messages, ProcessMessageType.input);
  }

  processMessage(
    List<Message> messages,
    ProcessMessageType processMessageType,
  ) async {
    if (messages.isEmpty) {
      return;
    }

    Message lastMessage = messages.last;
    Chat? chat = getChatById(lastMessage.chat_id);
    if (chat == null) {
      return;
    }
    Chat? decryptChat;
    Message? lastVisibleMessage = _lastChatMessageMap[chat.id];
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (message.ref_typ == 1 && processMessageType == ProcessMessageType.db) {
        decryptChat = chat;
      }
      processOneMessage(message, processMessageType);
      if (message.chat_idx > lastMessage.chat_idx) {
        lastMessage = message;
      } else if (message.chat_idx == lastMessage.chat_idx &&
          message.create_time > lastMessage.create_time) {
        lastMessage = message;
      }
      bool showChat = false;
      if (!message.isInvisibleMsg) {
        if (lastVisibleMessage == null ||
            lastVisibleMessage.chat_idx < message.chat_idx) {
          lastVisibleMessage = message;
          showChat = true;
        } else if (message.chat_idx == lastVisibleMessage.chat_idx &&
            message.create_time > lastVisibleMessage.create_time) {
          lastVisibleMessage = message;
          showChat = true;
        }
      }

      if (showChat) {
        if (!chat.isVisible && lastVisibleMessage!.chat_idx > chat.cover_idx) {
          chat.msg_idx = lastVisibleMessage.chat_idx;
          if (chat.flag_my & ChatStatus.MyChatFlagHide.value != 0) {
            chat.flag_my &= ~ChatStatus.MyChatFlagHide.value;
          }
          event(this, ChatMgr.eventChatHide, data: chat);
          updateLocalTotalUnreadNumFromDB();
        }
      }

      if (processMessageType == ProcessMessageType.net &&
          message.chat_idx % 300 == 0) {
        objectMgr.localDB.adjustHotMessageTable(
          chat.chat_id,
          chat.read_chat_msg_idx,
          chat.hide_chat_msg_idx,
          maxHotMessageTable,
        );
      }
    }

    if (decryptChat != null && decryptChat.isActiveChatKeyValid) {
      objectMgr.messageManager.decryptChat([chat]);
    }

    if (_lastChatMessageMap[chat.id] != lastVisibleMessage) {
      _lastChatMessageMap[chat.id] = lastVisibleMessage;
      event(this, eventChatLastMessageChanged, data: lastVisibleMessage);
    }

    if (lastMessage.chat_idx > chat.read_chat_msg_idx) {
      event(this, eventUpdateUnread, data: chat);
      if (objectMgr.appLifecycleState == AppLifecycleState.resumed || objectMgr.loginMgr.isDesktop) {
        event(this, eventUnreadTotalCount);
      }
      if (lastMessage.origin == originReal &&
          lastMessage.typ != messageStartCall) {
        showNotification(lastMessage);
      }
    }

    if (lastMessage.typ == messageTypeAutoDeleteInterval) {
      event(this, eventAutoDeleteInterval, data: lastMessage);
    }

    if (ProcessMessageType.net == processMessageType) {
      event(this, eventMessageComing, data: lastMessage);
      event(this, eventMessageListComing, data: messages);
    }
  }

  processOneMessage(
    Message message,
    ProcessMessageType processMessageType,
  ) async {
    Chat? chat = getChatById(message.chat_id);
    if (chat == null) {
      return;
    }

    syncMessageKeysToNotification(message);

    if ((message.ref_typ == 1 || message.ref_typ == 2) &&
        chat.isActiveChatKeyValid) {
      MessageMgr.decodeMsg(message, chat, objectMgr.userMgr.mainUser.uid);
    }

    switch (message.typ) {
      case messageTypeReqSignChat:
        reqSignChat(message, chat);
        return;
      case messageTypeDeleted:
        remotelDelMessage(message, chat);
        return;
      case messageTypeEdit:
        remoteEditMessage(chat, message);
        return;
      case messageTypeSendRed:
        processRedPacketMsg(message);
        break;
      case messageTypeAddReactEmoji:
      case messageTypeRemoveReactEmoji:
        emojiMessageCheck(message, chat);
        break;
      case messageTypeCommandFileOperate:
        processFileOperateMessage(message, chat, processMessageType);
        return;
      case messageTypeTaskCreated:
        objectMgr.taskMgr.processTaskMessage(message);
        break;
      case messageTypeExpiryTimeUpdate:
        Group? group = objectMgr.myGroupMgr.getGroupById(chat.id);
        if (group != null) {
          if (group.expireTime != message.expire_time) {
            objectMgr.myGroupMgr.getGroupByRemote(group.id);
          }
        }
        break;
      default:
        break;
    }

    if (message.expire_time != 0) {
      ExpireMessageTask.addIncomingExpireMessages(message);
    }
    if (message.atUser.isNotEmpty) {
      _onProcessMentionMessage(message);
    }

    _preLoadAssets(chat, message, processMessageType);

    if (!objectMgr.userMgr.isMe(message.send_id) &&
        message.chat_idx > chat.read_chat_msg_idx) {
      if (!message.isSystemMsg && ProcessMessageType.db != processMessageType) {
        if (chat.unread_count != (chat.msg_idx - chat.read_chat_msg_idx)) {
        
          if (chat.unread_count == 0) {
            // 1. check chat exist in which chat category
            final List<ChatCategory?> found = chatCategoryList
                .where(
                  (category) =>
                      category.includedChatIds.contains(chat.id) ||
                      category.isAllChatRoom,
                )
                .toList();

            for (final category in found) {
              if (category != null) {
                if (chatCategoryUnreadCount[category.id] == null) {
                  chatCategoryUnreadCount[category.id] = <int>{chat.id};
                } else {
                  chatCategoryUnreadCount[category.id]!.add(chat.id);
                }
                event(this, eventChatCategoryChanged);
              }
            }
          }
          chat.unread_count = chat.unread_count + 1;
          if (chat.isCountUnread) {
            totalUnreadCount.value++;
          }
        }
      }
    }

    if (_chatMessageMap[chat.id] == null) {
      _chatMessageMap[chat.id] = {};
    }

    var chatMessages = _chatMessageMap[chat.id]!;
    if (message.typ != messageTypeDeleted && !message.isExpired) {
      Message? findMessage = chatMessages[message.id];
      if (findMessage != null) {
        if (ProcessMessageType.input == processMessageType) {
          findMessage.create_time = message.create_time;
          findMessage.sendState = message.sendState;
          findMessage.message_id = message.message_id;
          findMessage.content = message.content;
          findMessage.chat_idx = message.chat_idx;
        } else if (ProcessMessageType.net == processMessageType) {
          if (chat.msg_idx < message.chat_idx) {
            chat.msg_idx = message.chat_idx;
          }
          if (objectMgr.userMgr.isMe(findMessage.send_id)) {
            updateSendMessageIdx(
                chat.id, findMessage.chat_idx, message.chat_idx);
          }
          findMessage.create_time = message.create_time;
          findMessage.sendState = message.sendState;
          findMessage.message_id = message.message_id;
          findMessage.content = message.content;
          findMessage.chat_idx = message.chat_idx;
          findMessage.expire_time = message.expire_time;
        }
      }
      //只从input/db里添加
      if ((ProcessMessageType.net != processMessageType ||
              (message.chat_idx - chat.read_chat_msg_idx).abs() <=
                  messagePageCount * 2) &&
          chatMessages[message.id] == null) {
        if (ProcessMessageType.net != processMessageType) {
          chatMessages[message.id] = message;
        }
        if (message.isMediaType) cacheMediaMgr.getMessageGausImage(message);
      }
    }
  }

  _preLoadAssets(
      Chat chat, Message message, ProcessMessageType processMessageType) {
    if ((message.chat_idx - chat.read_chat_msg_idx).abs() <= messagePageCount ||
        ProcessMessageType.db == processMessageType ||
        (message.chat_idx - chat.msg_idx).abs() <= messagePageCount) {
      switch (message.typ) {
        case messageTypeImage:
          MessageImage msgImg = message.decodeContent(cl: MessageImage.creator);
          downloadMgrV2.download(
            msgImg.url,
            mini: Config().messageMin,
            downloadType: DownloadType.background,
          );
          break;
        case messageTypeNewAlbum:
          final msgMedia = message.decodeContent(cl: NewMessageMedia.creator);
          final List<AlbumDetailBean> beans = msgMedia.albumList ?? [];
          if (beans.isEmpty) break;
          for (final bean in beans) {
            final String src = bean.cover.isNotEmpty ? bean.cover : bean.url;
            if (src == null) continue;
            downloadMgrV2.download(
              src,
              mini: Config().messageMin,
              downloadType: DownloadType.background,
            );
          }
          break;
        case messageTypeVideo:
          final msgVideo = message.decodeContent(cl: MessageVideo.creator);
          if (msgVideo.cover != null) {
            downloadMgrV2.download(
              msgVideo.cover,
              mini: Config().messageMin,
              downloadType: DownloadType.background,
            );
          }
          break;
        case messageTypeVoice:
          final msgVoice = message.decodeContent(cl: MessageVoice.creator);
          downloadMgrV2
              .download(msgVoice.url, downloadType: DownloadType.background,
                  onReceiveProgress: (int received, int total) {
            EventDownloadProgress data = EventDownloadProgress(
              id: message.id,
              progress: received / total,
            );
            message.event(message, Message.eventDownloadProgress, data: data);
          });
          break;
      }
    }
  }

  updateDBChatReadChatMsgIdx(int chat_id, int read_chat_msg_idx) async {
    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptUpdate,
        DBChat.tableName,
        {
          'id': chat_id,
          'read_chat_msg_idx': read_chat_msg_idx,
        },
      ),
      save: true,
      notify: false,
    );
  }

  updateUnread(Chat chat, int read_chat_idx, {bool isForceDB = false}) async {
    if (chat.read_chat_msg_idx >= read_chat_idx) {
      if(isForceDB){
        removeMentionCache(chat.chat_id, chat.read_chat_msg_idx);
      }
      return;
    }

    if ((read_chat_idx + 1) == chat.read_chat_msg_idx) {
      chat.unread_count--;
      if (chat.isCountUnread) {
        totalUnreadCount.value--;
      }
    } else {
      if (isForceDB) {
        int newUnreadCount = await _localDB.getUnreadNum(chat.chat_id, read_chat_idx);
        if (chat.isCountUnread) {
          totalUnreadCount.value = totalUnreadCount.value - (chat.unread_count - newUnreadCount);
          if (totalUnreadCount.value < 0) totalUnreadCount.value = 0;
        }
        chat.unread_count = newUnreadCount;
      } else {
        if (_chatMessageMap[chat.id] == null) {
          _chatMessageMap[chat.id] = {};
        }

        var chatMessages = _chatMessageMap[chat.id]!;
        for (int i = chat.read_chat_msg_idx + 1; i <= read_chat_idx; i++) {
          if (chatMessages.values.any((msg) =>
              msg.chat_idx == i && !objectMgr.userMgr.isMe(msg.send_id))) {
            chat.unread_count--;
            if (chat.isCountUnread) {
              totalUnreadCount.value--;
            }
          }
        }
      }
    }
    chat.read_chat_msg_idx = read_chat_idx;
    if (chat.unread_count != 0 && chat.read_chat_msg_idx == chat.msg_idx) {
      if (chat.isCountUnread) {
        totalUnreadCount.value =
            totalUnreadCount.value - chat.unread_count;
        if (totalUnreadCount.value < 0) totalUnreadCount.value = 0;
      }
      chat.unread_count = 0;
    }
    if (chat.unread_count == 0) {
      final tempCount = Map.from(chatCategoryUnreadCount);
      tempCount.forEach((key, value) {
        chatCategoryUnreadCount[key]?.remove(chat.chat_id);
      });
      event(this, eventChatCategoryChanged);
    }
    removeMentionCache(chat.chat_id, chat.read_chat_msg_idx);
    event(this, eventUpdateUnread, data: chat);
    event(this, eventUnreadTotalCount);
    objectMgr.scheduleMgr.readMessageTask.addReadMessage(chat.chat_id, read_chat_idx);
  }

  syncMessageKeysToNotification(Message message) {
    if (objectMgr.appLifecycleState != AppLifecycleState.resumed) {
      return;
    }

    if (message.origin != originReal) {
      return;
    }

    var messageKey = "${message.chat_id}_${message.chat_idx}";
    realMessageKeys.add(messageKey);
    for (; realMessageKeys.length > 10;) {
      realMessageKeys.removeAt(0);
    }

    if (Platform.isIOS) {
      _methodChannel.invokeMethod("syncRealMessageKeys", [realMessageKeys]);
    }
  }

  updateSendMessageIdx(int chatId, int sendMessageIdx, int msgIdx) {
    var chatMessages = _chatMessageMap[chatId];
    if (chatMessages == null) {
      return;
    }
    chatMessages.forEach((key, value) {
      if (key >= sendMessageIdx &&
          value.sendState == MESSAGE_SEND_ING &&
          objectMgr.userMgr.isMe(value.send_id)) {
        value.chat_idx = msgIdx + 1;
        saveMessage(value);
      }
    });
  }

  // _preLoadAssets(
  //   Chat chat,
  //   Message message,
  //   ProcessMessageType processMessageType,
  // ) async {
  //   if ((message.chat_idx - chat.read_chat_msg_idx).abs() <= messagePageCount ||
  //       ProcessMessageType.db == processMessageType ||
  //       (message.chat_idx - chat.msg_idx).abs() <= messagePageCount) {
  //     cacheMediaMgr.getMessageGausImage(message);
  //   }
  // }

  _onProcessMentionMessage(Message message) async {
    Chat? chat = getChatById(message.chat_id);
    if (chat == null) {
      return;
    }
    if (message.typ == messageTypeDeleted) {
      MessageDelete msgDelete =
          message.decodeContent(cl: MessageDelete.creator);
      // 如果删除是delete for me 并且 删除人不是自己, 就不需要处理 mention map
      if (msgDelete.all == 0 && !objectMgr.userMgr.isMe(msgDelete.uid)) {
        return;
      }

      for (final messageId in msgDelete.message_ids) {
        if (mentionMessageMap[message.chat_id] != null &&
            mentionMessageMap[message.chat_id]!.containsKey(messageId)) {
          var msg = mentionMessageMap[message.chat_id]![messageId];
          mentionMessageMap[message.chat_id]!.remove(messageId);
          event(this, eventDelMentionChange, data: msg);
        }
      }
    } else {
      if (message.atUser.isNotEmpty &&
          message.chat_idx > chat.read_chat_msg_idx) {
        if (message.isMentionMessage(objectMgr.userMgr.mainUser.uid)) {
          if (mentionMessageMap[message.chat_id] == null) {
            mentionMessageMap[message.chat_id] = {};
          }
          mentionMessageMap[message.chat_id]![message.message_id] = message;
          event(this, eventAddMentionChange, data: message);
        }
      }
    }
  }

  List<Message> searchMessageFromRows(
    String content,
    List<Message> messagesList,
  ) {
    content = content.toLowerCase();
    List<Message> messages = [];
    for (Message message in messagesList) {
      final Chat? found = objectMgr.chatMgr.getChatById(message.chat_id);

      if (found != null) {
        if (found.hide_chat_msg_idx >= message.chat_idx) {
          continue;
        }

        if (found.isTmpGroup && (found.isKick || found.isDisband)) {
          continue;
        }
      }

      if (!message.isSystemMsg) {
        TranslationModel? translationModel = message.getTranslationModel();
        if (translationModel != null && translationModel.showTranslation) {
          if (translationModel.getContent().toLowerCase().contains(content)) {
            messages.add(message);
          }
          if (translationModel.visualType ==
              TranslationModel.showTranslationOnly) {
            continue;
          }
        }

        if (message.typ == messageTypeFile) {
          MessageFile file = message.decodeContent(cl: MessageFile.creator);
          if (file.file_name.toLowerCase().contains(content)) {
            messages.add(message);
          }
        }

        try {
          if (message.textAfterMention.toLowerCase().contains(content)) {
            messages.add(message);
          }
        } catch (e) {
          continue;
        }
      }
    }
    return messages;
  }

  List<Message> searchGroupUserMessageFromRows(
    User user,
    List<Map<String, dynamic>> rows,
  ) {
    List<Message> messages = [];
    for (var e in rows) {
      Message message = Message()..init(e);
      messages.add(message);
    }
    return messages;
  }

  ///problems point
  doChatChange(UpdateBlockBean block) async {
    /// 仅当不在群组或者不是好友的状态下删除聊天室的操作时会有blockOptDelete的socket
    if (block.opt == blockOptDelete) {
      Chat? chat = getChatById(block.data['id']);
      if (chat != null && chat.isGroup) {
        chatGroupDeleteProcess(chat);
      }
    } else {
      bool isPin = block.data[0] is Map && block.data[0].containsKey('pin');
      int? muteTime =
          (block.data[0] is Map && block.data[0].containsKey('mute'))
              ? block.data[0]['mute']
              : null;
      Chat? chat = getChatById(block.data[0]['id']);
      if (isPin) {
        event(this, ChatMgr.eventChatPinnedMessage, data: block.data[0]);
        if (chat != null) {
          List<Message> filteredPinnedMessageList = block.data[0]['pin']
              .map<Message>((e) => Message()..init(e))
              .toList();
          pinnedMessageList[chat.id] = filteredPinnedMessageList;

          // 查验聊天室加密设定变换
          _checkForEncryptionUpdate(block, chat);
          _sharedDB.applyUpdateBlock(
            UpdateBlockBean.created(
              blockOptReplace,
              DBChat.tableName,
              [
                {
                  'id': chat.id,
                  'pin': jsonEncode(filteredPinnedMessageList),
                }
              ],
            ),
            save: true, // 不需要保存
            notify: false,
          );
        }
        return;
      } else {
        if (chat != null) {
          ///更新mute的状态
          if (muteTime != null && muteTime != chat.mute) {
            updateNotificationStatus(chat, muteTime);
          }

          int myFlag = block.data[0]['flag_my'] ?? -1;

          if (myFlag != -1) {
            if (chat.flag_my & ChatStatus.MyChatFlagHide.value != 0 &&
                myFlag & ChatStatus.MyChatFlagHide.value == 0) {
            } else if (chat.flag_my != myFlag) {
              chat.setValue('flag_my', myFlag);

              if (ChatStatus.MyChatFlagJoined.value == myFlag) {
                getPinnedMessageByRemote([chat]);
                event(this, ChatMgr.eventChatJoined, data: chat);
              } else {
                if (myFlag & ChatStatus.MyChatFlagKicked.value != 0) {
                  objectMgr.myGroupMgr.onKicked(block.data[0]['id']);
                  event(this, ChatMgr.eventChatKicked, data: chat);
                }
                if (myFlag & ChatStatus.MyChatFlagDisband.value != 0) {
                  objectMgr.myGroupMgr.onDeleteTmpGroup(block.data[0]['id']);
                  event(this, ChatMgr.eventChatDisband, data: chat);
                  clearMessage(chat, showToast: false);
                }
              }
            }
          } else if (chat.flag_my & ChatStatus.MyChatFlagHide.value != 0) {
            /// 被隐藏的chat有新消息，需要重新显示
            if (block.data[0].containsKey('msg_idx') &&
                block.data[0]['msg_idx'] != chat.msg_idx) {
              /// emoji了一个被hide的消息就不显示了
              if (block.data[0].containsKey('last_msg')) {
                final lastMsg = block.data[0]['last_msg'];
                try {
                  final Map<String, dynamic> msgData = json.decode(lastMsg);
                  if (msgData.containsKey("msg_idx") &&
                      msgData.containsKey("emoji")) {
                    final originMsgIdx = msgData["msg_idx"];
                    if (originMsgIdx <= chat.hide_chat_msg_idx) {
                      return;
                    }
                  }
                } catch (e) {
                  pdebug(e.toString());
                }
              }
            }
          }

          /// 删除聊天室/聊天记录
          if (block.data[0].containsKey('hide_chat_msg_idx')) {
            int hideChatMsgIdx = block.data[0]['hide_chat_msg_idx'];
            if (hideChatMsgIdx != 0 &&
                chat.hide_chat_msg_idx != hideChatMsgIdx) {
              chat.setValue('hide_chat_msg_idx', hideChatMsgIdx);
              _removeLocalMessages(
                chat,
                hideChatMsgIdx,
                isClear: chat.msg_idx == hideChatMsgIdx,
              );
            }
          }

          /// 本地无网情况下已读消息需要同步给后端
          if (block.data[0].containsKey('read_chat_msg_idx')) {
            if (block.data[0]['read_chat_msg_idx'] > chat.read_chat_msg_idx) {
              updateUnread(chat, block.data[0]['read_chat_msg_idx'], isForceDB: true);
            } else if (block.data[0]['read_chat_msg_idx'] <
                chat.read_chat_msg_idx) {
              sendReadMessageIdx(
                  chat.chat_id, chat.read_chat_msg_idx);
            }
            return;
          }

          if (block.data[0].containsKey('start_idx')) {
            if (block.data[0]['start_idx'] != chat.start_idx) {
              chat.setValue('start_idx', block.data[0]['start_idx']);
              event(this, eventRejoined, data: chat);

              // 重新加入的群组触发数据同步
              final rep = await loadRemoteChatByChatID(block.data[0]['id']);
              if (rep != null) {
                objectMgr.messageManager.loadMsg([Chat()..init(rep.data)]);
              }
            }
          }

          // 当聊天室置顶值改变
          if (block.data[0].containsKey('sort')) {
            chatListEvent.event(
              chatListEvent,
              ChatListEvent.eventChatPinnedUpdate,
              data: {
                'chat_id': chat.id,
                'sort': block.data[0]['sort'],
              },
            );
          }

          // 查验聊天室加密设定变换
          _checkForEncryptionUpdate(block, chat);

          /// check whether to hide a chat
          int msgIdx = block.data[0]['msg_idx'] ?? chat.msg_idx;
          if (block.data[0].containsKey('cover_idx')) {
            int coverIdx = block.data[0]['cover_idx'];
            if (msgIdx <= coverIdx) {
              chat.cover_idx = coverIdx;
              updateHideChatFlag(chat);
              chat.isSelected = false;
            }
          }else if(block.data[0]['msg_idx'] != null){
            if(msgIdx == chat.cover_idx + 1){
              chat.msg_idx = msgIdx;
              updateHideChatFlag(chat);
            }
          }
          
        } else {
          // 新聊天触发数据同步
          final rep = await loadRemoteChatByChatID(block.data[0]['id']);
          if (rep != null) {
            await _checkForEncryptionUpdate(block, rep, isRemote: true);
            objectMgr.messageManager.loadMsg([Chat()..init(rep.data)]);
          }
          getPinnedMessageByRemote([Chat()..init(block.data[0])]);

          int myFlag = block.data[0]['flag_my'] ?? -1;
          if (ChatStatus.MyChatFlagJoined.value == myFlag) {
            await _sharedDB.applyUpdateBlock(block, vibrate: true);
            Chat? chat = getChatById(block.data[0]['id']);
            event(this, ChatMgr.eventChatJoined, data: chat ?? rep);
          }
        }
        _sharedDB.applyUpdateBlock(block, vibrate: true);
      }
    }
  }

  Future<void> _checkForEncryptionUpdate(UpdateBlockBean block, Chat chat,
      {bool isRemote = false}) async {
    //当聊天室加密设定变换
    int flag = block.data[0]['flag'] ?? chat.flag;
    int round = block.data[0]['round'] ?? chat.round;
    if (chat.flag == flag && chat.round == round) {
      return;
    }
    if (round < chat.round) {
      round = chat.round;
    }
    if (ChatHelp.hasEncryptedFlag(flag)) {
      chat.flag = flag;
      chat.round = round;
      //传来加密, 试着获取会话密钥
      objectMgr.encryptionMgr.toggleEncryptionChatUpdate(true);
      String? chatKey = chat.chatKey;
      int? keyRound = chat.chatKeyRound;
      if (!chat.isChatKeyValid) {
        (chatKey, keyRound) =
            await objectMgr.encryptionMgr.getChatCipherKey(chat.chat_id);
      }
      if (notBlank(chatKey) &&
          keyRound != null &&
          chatKey != EncryptionMgr.decryptFailureEmblem) {
        chat.updateChatKey(chatKey!, keyRound);
        String latestActiveKey =
            objectMgr.encryptionMgr.getCalculatedKey(chat, round);

        await updateDatabaseEncryptionSetting(
          chat,
          flag,
          round: round,
          chatKey: chatKey,
          chatRound: keyRound,
          activeChatKey: latestActiveKey,
          activeRound: round,
        );

        objectMgr.encryptionMgr.syncAllEncryptionChatKeys();
        objectMgr.messageManager.decryptChat([chat]);
        return;
      } else if (chatKey == EncryptionMgr.decryptFailureEmblem) {
        bool keyValid = await objectMgr.encryptionMgr.isKeyValid(
            objectMgr.encryptionMgr.encryptionPublicKey,
            privateKey: objectMgr.encryptionMgr.encryptionPrivateKey);
        if (keyValid) {
          await objectMgr.encryptionMgr.resetChatSessions([chat]);
        }
      }
    }

    updateDatabaseEncryptionSetting(chat, flag, round: round);
    objectMgr.messageManager.decryptChat([chat]);
  }

  void _onReadMessageUpdate(p0, p1, p2) async {
    if (p2 is UpdateBlockBean) {
      await _sharedDB.applyUpdateBlock(
        UpdateBlockBean.created(blockOptUpdate, DBChat.tableName, p2.data[0]),
        save: true,
        notify: false,
      );

      if (p2.data[0] is Map &&
          p2.data[0].containsKey('id') &&
          p2.data[0].containsKey('other_read_idx')) {
        final msgIdx = p2.data[0]['other_read_idx'];
        final chatId = p2.data[0]['id'];

        if (mentionMessageMap.containsKey(chatId) &&
            mentionMessageMap[chatId]!.isNotEmpty) {
          final copiedMsgList = mentionMessageMap[chatId]!.values.toList();
          for (final msg in copiedMsgList) {
            if (msg.chat_idx == msgIdx) {
              mentionMessageMap[chatId]!.remove(msg.id);
              break;
            }
          }
        }
      } else if (p2.data[0] is Map &&
          p2.data[0].containsKey('id') &&
          p2.data[0].containsKey('other_read_idx')) {}
      event(this, eventReadMessage, data: p2.data[0]);
    }
  }

  void _onChatInput(sender, type, data) {
    ChatInput inputData = ChatInput()..applyJson(jsonDecode(data));
    if (inputData.state != ChatInputState.noTyping) {
      /// 如果是自己输入就不显示
      if (objectMgr.userMgr.isMe(inputData.sendId)) {
        return;
      }
      inputData.currentTimestamp =
          DateTime.now().millisecondsSinceEpoch ~/ 1000;
      ChatTypingTask.addTypingData(inputData);
    } else {
      ChatTypingTask.removeTypingData(inputData);
    }

    event(this, eventChatIsTyping, data: inputData);
  }

  List<Chat> getAllChats({bool needProcess = true}) {
    List<Chat> chats = [];
    if (_chatTable != null) {
      chats.addAll(_chatTable!.getList());
    }

    if (needProcess) {
      chats = preProcessChats(chats);
    }
    return chats;
  }

  Future<List<Chat>> getLocalChats() async {
    List<Chat> chats = getAllChats();

    List<Map<String, dynamic>> localChatRows = [];
    for (int i = 0; i < 20 && _chatTable == null; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    if (chats.isEmpty && _chatTable != null) {
      localChatRows = await _localDB.loadChatList();
      await _sharedDB.applyUpdateBlock(
        UpdateBlockBean.created(
          blockOptReplace,
          DBChat.tableName,
          localChatRows,
        ),
        save: false,
        notify: false,
      );
      chats.addAll(_chatTable!.getList());
    }

    return chats;
  }

  Future<void> processTmpGroup(List<Chat> chats) async {
    List<Chat> chatsToRemove = [];
    for (var chat in chats) {
      if (chat.isDisband || chat.isKick) {
        if (chat.isTmpGroup) {
          chatsToRemove.add(chat);
        }
      }

      if (chat.isTmpGroup && !chat.isDisband && !chat.isKick) {
        Group? group = await objectMgr.myGroupMgr.getLocalGroup(chat.id);
        if (group != null) {
           if(group.expireTime != 0 && group.expireTime < DateTime.now().millisecondsSinceEpoch ~/ 1000)
           {
             objectMgr.chatMgr.clearMessages(group.uid);
             var chat = objectMgr.chatMgr.getChatById(group.uid);
             if (chat != null) {
               objectMgr.chatMgr.chatGroupDeleteProcess(chat);
             }
           }else{
             objectMgr.scheduleMgr.temporaryGroupTask.addTempGroupTask(group);
           }
        }
      }
    }

    // 删除所有需要删除的聊天
    for (var chat in chatsToRemove) {
      chats.remove(chat);
    }
  }

  Future<List<Chat>> loadAllLocalChats({bool needProcess = true}) async {
    if (objectMgr.loginMgr.isLogin) {
      List<Chat> chats = await getLocalChats();
      if (needProcess) {
        chats = preProcessChats(chats);
      }
      await processTmpGroup(chats);
      return chats;
    }
    return [];
  }

  Future<void> loadChatCategory() async {
    String chatCategoryFetchTime =
        "${LocalStorageMgr.APP_STORES_FETCH_TIME}${objectMgr.userMgr.mainUser.uid}";
    try {
      bool isFirstLoad = await _localDB.isChatCategoryEmpty();

      final int fetchTime =
          objectMgr.localStorageMgr.read<int?>(chatCategoryFetchTime) ?? 0;

      final rep = await getStores(
        isFirstLoad ? 0 : fetchTime,
      );

      final GetStoreData? data = rep.stores.firstWhereOrNull(
        (e) => e.key == DBChatCategory.tableName,
      );

      if (data != null && data.value != '[]') {
        final chatCategoryValue = jsonDecode(data.value);
        if (chatCategoryValue is List) {
          objectMgr.localStorageMgr.write<int>(
            chatCategoryFetchTime,
            data.updateTime,
          );

          if (chatCategoryValue.isEmpty) return;

          final List<ChatCategory> categoryList = chatCategoryValue
              .map<ChatCategory>((e) => ChatCategory()..init(e))
              .toList();

          final Set<int> duplicatesCheck = <int>{};

          // 差异化更新
          for (int i = 0; i < categoryList.length; i++) {
            final category = categoryList[i];
            final foundIdx = chatCategoryList.indexWhere(
              (c) => c.id == category.id,
            );

            if (foundIdx != -1) {
              if (duplicatesCheck.contains(category.id)) {
                chatCategoryList.removeAt(foundIdx);
                continue;
              }

              chatCategoryList[foundIdx] = category;
            }
            duplicatesCheck.add(category.id);

            await updateChatCategory(
              category,
              isCategoryFound: foundIdx != -1,
              updateRemote: i == categoryList.length - 1,
              shouldBroadcast: false,
            );
          }

          if (categoryList.length != chatCategoryList.length) {
            final List<ChatCategory> diffCategories = chatCategoryList
                .where(
                    (oldC) => !categoryList.any((newC) => oldC.id == newC.id))
                .toList();

            deleteChatCategory(diffCategories);
          }

          event(this, eventChatCategoryLoaded);
        } else {
          throw (Exception('Chat category value error'));
        }
      } else {
        int foundIdx = -1;
        if (chatCategoryList.isNotEmpty) {
          foundIdx = chatCategoryList.indexWhere((c) => c.isAllChatRoom);
        }

        if (foundIdx == -1) {
          final category = ChatCategory()
            ..id = 1
            ..name = localized(chatCategoryAllChatRoom)
            ..includedChatIds = []
            ..excludedChatIds = []
            ..seq = 1
            ..createTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          updateChatCategory(category);
        }
      }
    } catch (e) {
      pdebug('Get chat category list error : ${e.toString()}');
    }
  }

  Future<bool> updateChatCategory(
    ChatCategory category, {
    List<int>? unreadChatListIds,
    bool isCategoryFound = false,
    bool updateRemote = true,
    bool shouldBroadcast = true,
  }) async {
    if (!Config().enableChatCategory) return false;
    try {
      final List<ChatCategory> copiedCategoryList =
          chatCategoryList.map<ChatCategory>((e) => e.copyWith()).toList();

      if (!isCategoryFound) {
        copiedCategoryList.add(category);
      } else {
        final foundC = copiedCategoryList.firstWhereOrNull(
          (c) => category.id == c.id,
        );
        if (foundC != null) {
          foundC
            ..name = category.name
            ..includedChatIds = category.includedChatIds
            ..excludedChatIds = category.excludedChatIds
            ..seq = category.seq;
        }
      }

      if (updateRemote) {
        // 1. invoke update-store
        await updateStore(
          DBChatCategory.tableName,
          jsonEncode(copiedCategoryList),
          isBroadcast: shouldBroadcast,
          shouldRetry: true,
        );
      }

      chatCategoryList.assignAll(copiedCategoryList);

      if (unreadChatListIds != null) {
        chatCategoryUnreadCount[category.id] = unreadChatListIds.toSet();
      }

      await _sharedDB.applyUpdateBlock(
        UpdateBlockBean.created(
          blockOptReplace,
          DBChatCategory.tableName,
          [category.toJson()],
        ),
        notify: false,
      );

      event(this, ChatMgr.eventChatCategoryChanged, data: category);
      return true;
    } catch (_) {
      // Toast.showToast(localized(noNetworkPleaseTryAgainLater));

      return false;
    }
  }

  void replaceChatCategory(
    List<ChatCategory> newCategoryList, {
    bool updateRemote = true,
    bool needBroadcast = true,
  }) async {
    try {
      chatCategoryList.assignAll(newCategoryList);

      await _sharedDB.applyUpdateBlock(
        UpdateBlockBean.created(
          blockOptReplace,
          DBChatCategory.tableName,
          newCategoryList.map<Map>((e) => e.toJson()).toList(),
        ),
        notify: false,
      );

      if (updateRemote) {
        // 2. invoke update-store
        updateStore(
          DBChatCategory.tableName,
          jsonEncode(newCategoryList),
          isBroadcast: needBroadcast,
          shouldRetry: true,
        );
      }

      final List<Chat> chats = getAllChats();
      Set<int> allChatUnreadCount = <int>{};

      if (newCategoryList.isNotEmpty) {
        for (final category in newCategoryList) {
          if (!category.isAllChatRoom && category.includedChatIds.isEmpty) {
            if (chatCategoryUnreadCount.containsKey(category.id)) {
              chatCategoryUnreadCount.remove(category.id);
            }
            continue;
          }

          chatCategoryUnreadCount.remove(category.id);
          final tempChats = chats
              .where((c) =>
                  category.isAllChatRoom ||
                  category.includedChatIds.contains(c.id))
              .toList();

          for (final chat in tempChats) {
            if (chat.unread_count > 0) {
              allChatUnreadCount.add(chat.id);

              if (category.includedChatIds.contains(chat.id)) {
                if (chatCategoryUnreadCount[category.id] == null) {
                  chatCategoryUnreadCount[category.id] = <int>{chat.id};
                } else {
                  chatCategoryUnreadCount[category.id]!.add(chat.id);
                }
              }
            }
          }
        }
      }

      // add all chats category unread count
      chatCategoryUnreadCount[1] = allChatUnreadCount;

      event(this, eventChatCategoryChanged);
    } on AppException catch (_) {
      // Toast.showToast(localized(noNetworkPleaseTryAgainLater));
    }
  }

  void onEventUpdateChatCategory(List<ChatCategory> newCategoryList) async {
    chatCategoryList.assignAll(newCategoryList);

    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBChatCategory.tableName,
        newCategoryList.map<Map>((e) => e.toJson()).toList(),
      ),
      notify: false,
    );

    final List<Chat> chatList = getAllChats();

    final unreadChatIdx = chatList
        .where((c) => c.unread_count > 0)
        .map((c) => c.chat_id)
        .toList();

    for (final category in newCategoryList) {
      if (category.isAllChatRoom) {
        chatCategoryUnreadCount[category.id] = unreadChatIdx.toSet();
        continue;
      }

      chatCategoryUnreadCount[category.id] = unreadChatIdx
          .where((id) => category.includedChatIds.contains(id))
          .toSet();
    }

    event(this, eventChatCategoryChanged);
  }

  Future<bool> deleteChatCategory(
    List<ChatCategory> removeList, {
    bool updateRemote = true,
  }) async {
    try {
      final List<ChatCategory> copiedCategoryList =
          chatCategoryList.map<ChatCategory>((c) => c.copyWith()).toList();
      for (final category in removeList) {
        copiedCategoryList.removeWhere((c) => c.id == category.id);
      }

      if (updateRemote) {
        // 2. invoke update-store
        await updateStore(
          DBChatCategory.tableName,
          jsonEncode(copiedCategoryList),
          isBroadcast: true,
          shouldRetry: true,
        );
      }

      chatCategoryList.assignAll(copiedCategoryList);

      for (final category in removeList) {
        chatCategoryUnreadCount.remove(category.id);
      }

      await _sharedDB.applyUpdateBlock(
        UpdateBlockBean.created(
          blockOptDelete,
          DBChatCategory.tableName,
          removeList.map<int>((e) => e.id).toList(),
        ),
        notify: false,
      );

      event(this, eventChatCategoryChanged);
      return true;
    } catch (_) {
      // Toast.showToast(localized(noNetworkPleaseTryAgainLater));
      return false;
    }
  }

  void onChatCategoryRequestCallback(Retry retry, bool isSuccess) {}

  Future<List<Chat>?> loadChats() async {
    String chatListFetchTimeName =
        "${LocalStorageMgr.CHAT_LIST_FETCH_TIME}${objectMgr.userMgr.mainUser.uid}";

    int start = DateTime.now().millisecondsSinceEpoch;
    // 添加chat_list获取开始日志
    _log.updateInfo(MessageModule.chat_list_normal, startTime: start);

    // 记录聊天室数量
    int chatCount = 0;

    List<Chat> chats = [];
    try {
      bool isFirstLoad = await _localDB.isChatEmpty();

      final int? fetchTime =
          objectMgr.localStorageMgr.read<int?>(chatListFetchTimeName);

      final rep = await chat_api.list(
        objectMgr.userMgr.mainUser.uid,
        startTime: isFirstLoad ? null : fetchTime,
      );
      var chatList = ChatList.fromJson(rep.data);
      chatCount = chatList.data.length;

      await updateChatReadIdx(chatList.data);
      await checkAndUpdateChatEncryption(chatList.data);
      await _sharedDB
          .applyUpdateBlock(
        UpdateBlockBean.created(
          blockOptReplace,
          DBChat.tableName,
          chatList.data,
        ),
        save: true,
        notify: false,
      )
          .then((value) {
        if (value != null && value >= 1) {
          objectMgr.localStorageMgr
              .write<int>(chatListFetchTimeName, chatList.serverTime);
        } else {
          return null;
        }
      }).catchError((e) {
        pdebug("save chats failed, isFirstLoad: $isFirstLoad, error: $e");
      });

      if (chatList.data.length > 0) {
        event(this, eventChatListLoaded);
        updateLocalTotalUnreadNumFromDB();
      }

      chats = getAllChats(needProcess: false);

      // 记录开始处理消息日志
      _log.updateInfo(
        MessageModule.message_normal,
        startTime: start,
        endTime: DateTime.now().millisecondsSinceEpoch,
        shouldAddLog: true,
      );
      objectMgr.messageManager.loadMsg(chats, addLog: true);

      getPinnedMessageByRemote(chats);
      return chats;
    } on AppException catch (e) {
      final List<Map<String, dynamic>> localChats =
          await _localDB.loadChatList();
      chats = localChats.map((e) => Chat()..init(e)).toList();

      getPinnedMessageByRemote(chats);
      Toast.showToast(e.getMessage());
    } finally {
      _log.updateInfo(
        MessageModule.chat_list_normal,
        endTime: DateTime.now().millisecondsSinceEpoch,
        chatCount: chatCount,
        shouldAddLog: true,
      );
    }
    return [];
  }

  checkAndUpdateChatEncryption(List data) async {
    if (!notBlank(objectMgr.encryptionMgr.encryptionPrivateKey)) return;
    List<Chat> chatItems = [];

    for (var item in data) {
      Chat? chat = getChatById(item['id']);
      if (chat != null &&
          item['flag'] == chat.flag &&
          item['round'] == chat.round) {
        continue;
      }
      if (chat == null) {
        await _sharedDB.applyUpdateBlock(
          UpdateBlockBean.created(blockOptReplace, DBChat.tableName, [item]),
          save: true,
          notify: false,
        );
        chat = getChatById(item['id']);
        if (chat == null) {
          continue;
        }
      } else {
        chat.flag = item['flag'];
        chat.round = item['round'];
        if (item['flag'] != chat.flag) {
          event(this, eventChatEncryptionUpdate, data: chat);
        }
      }
      int flag = item['flag'];
      int round = item['round'];
      if (flag == 0 || !chat.isVisible) {
        continue;
      }

      if (chat.isActiveChatKeyValid) {
        // round > active
        //若是有active key，但round小于后端传递，那就进位算+更新
        String key = objectMgr.encryptionMgr.getCalculatedKey(chat, round);
        if (notBlank(key)) {
          chat.updateActiveChatKey(key, round);
        }
        continue;
      }
      chatItems.add(chat);
    }
    if (chatItems.isNotEmpty) {
      await objectMgr.encryptionMgr.checkAndUpdateChatCiphers(chatItems);
    }
  }

  updateChatReadIdx(List data) async {
    final futures = data.map((item) async {
      Chat? chat = getChatById(item['id']);
      if (chat != null) {
        if (item['read_chat_msg_idx'] > chat.read_chat_msg_idx) {
          updateUnread(chat, item['read_chat_msg_idx'], isForceDB: true);
        }else if (item['read_chat_msg_idx'] < chat.read_chat_msg_idx){
          sendReadMessageIdx(chat.chat_id, chat.read_chat_msg_idx);
        }
        if (chat.last_pos == 0 && !chat.isSpecialChat) {
          downloadMgrV2.download(
            chat.isSingle ? chat.profile : chat.icon,
            mini: Config().messageMin,
            downloadType: DownloadType.background,
          );
        }
      }
    });
    await Future.wait(futures);
  }

  Future<bool> loadLocalLastMessages() async {
    final latestMessageListData = await _localDB.findLatestMessages();
    for (final latestMessageData in latestMessageListData) {
      Message message = Message()..init(latestMessageData);
      _lastChatMessageMap[message.chat_id] = message;
    }
    event(this, eventAllLastMessageLoaded);
    return true;
  }

  loadChatExpireMessages(int expire) async {
    final expireMessages = await _localDB.getChatExpireMessages(expire);
    for (final expireMessage in expireMessages) {
      Message message = Message()..init(expireMessage);
      ExpireMessageTask.addIncomingExpireMessages(message);
    }
  }

  Future<void> loadLocalMentions() async {
    final mentions = await objectMgr.localDB.getChatMentionChatIdx();
    List<Message> mList =
        mentions.map<Message>((e) => Message()..init(e)).toList();
    for (var message in mList) {
      if (message.isMentionMessage(objectMgr.userMgr.mainUser.uid)) {
        if (mentionMessageMap[message.chat_id] == null) {
          mentionMessageMap[message.chat_id] = {};
        }
        mentionMessageMap[message.chat_id]![message.message_id] = message;
      }
    }
    event(this, eventChatListLoaded);
  }

  Future<bool> countLocalUnreadNum(List<Chat> chats) async {
    int totalUnread = 0;
    List<Map<String, dynamic>> unreadList =
        await _localDB.getListOfUnreadChats();

    Set<int> allChatUnreadCount = <int>{};

    for (Chat chat in chats) {
      Map<String, dynamic>? unreadInfo =
          unreadList.firstWhereOrNull((info) => info['id'] == chat.id);
      if (unreadInfo != null) {
        allChatUnreadCount.add(chat.id);
        chat.unread_count = unreadInfo['unreadTotal'] as int;
        if (chat.isCountUnread) {
          totalUnread += unreadInfo['unreadTotal'] as int;
        }
        if (chat.unread_count > 0 && chatCategoryList.isNotEmpty) {
          // 1. check chat exist in which chat category
          final List<ChatCategory?> found = chatCategoryList
              .where(
                (category) => category.includedChatIds.contains(chat.id),
              )
              .toList();

          for (final category in found) {
            if (category != null) {
              if (chatCategoryUnreadCount[category.id] == null) {
                chatCategoryUnreadCount[category.id] = <int>{chat.id};
              } else {
                chatCategoryUnreadCount[category.id]!.add(chat.id);
              }
            }
          }
        }
      } else {
        chat.unread_count = 0;
      }
      event(this, eventUpdateUnread, data: chat);
    }

    // add all chats category unread count
    chatCategoryUnreadCount[1] = allChatUnreadCount;

    totalUnreadCount.value = totalUnread;
    event(this, eventUnreadTotalCount);
    return true;
  }

  updateLocalTotalUnreadNumFromDB() async {
    List<Chat> chats = await loadAllLocalChats();
    countLocalUnreadNum(chats);
  }

  @override
  Future<void> recover() async {
    if (objectMgr.socketMgr.socket == null ||
        !objectMgr.socketMgr.socket!.open) {
      return;
    }
    _loginChat();
    event(this, eventChatReload);
  }

  bool flag = false;

  void handleShareData() async {
    if (Platform.isAndroid) {
      final ShareImage? data = await objectMgr.shareMgr.getShareFilePath;
      if (data != null) {
        if (flag) return;
        flag = true;
        await requestPermission(data);
      }
    } else if (Platform.isIOS) {
      final List<ShareImage> list =
          await objectMgr.shareMgr.getShareFilePathList;
      await Future.forEach(list, (data) async {
        if (data.dataList.isNotEmpty) {
          objectMgr.shareMgr.shareDataToChat(data);
        }
      });
      objectMgr.shareMgr.clearShare;
    }
  }

  Future<void> requestPermission(data) async {
    if (await requestAssetPickerPermission() == PermissionState.denied) return;

    try {
      HomeController controller;
      if (!Get.isRegistered<HomeController>()) {
        controller = Get.put(HomeController());
      } else {
        controller = Get.find<HomeController>();
      }
      await controller.onForwardMessage(shareImage: data);
      flag = false;
    } catch (e) {
      flag = false;
    }
  }

  getNextIncompleteChatIdx(List<Message> msgs, int current) {
    final idxs = msgs.map((e) => e.chat_idx).toSet();
    while (idxs.contains(current)) {
      current++;
    }
    return current;
  }

  List<Chat> preProcessChats(List<Chat> chats) {
    // 特殊处理
    List<Chat> visibleChats = [];
    for (var chat in chats) {
      if (!chat.isVisible) continue;

      //过滤被删除的临时群组
      if (chat.delete_time > 0 && chat.isGroup) {
        Group? group = objectMgr.myGroupMgr.getGroupById(chat.id);
        if (group?.roomType == GroupType.TMP.num) {
          continue;
        }
      }

      visibleChats.add(chat);

      if (!notBlank(chat.name)) {
        if (chat.typ == chatTypeSaved) {
          chat.name = localized(homeSavedMessage);
        } else if (chat.typ == chatTypeSystem) {
          chat.name = localized(homeSystemMessage);
        } else if (chat.typ == chatTypeSmallSecretary) {
          chat.name = localized(chatSecretary);
        }
      }
    }
    return visibleChats;
  }

  Chat? getChatById(int chatID) {
    var rowObj = _chatTable?.getRow(chatID);
    if (rowObj is Chat) {
      return rowObj;
    }
    return null;
  }

  Chat? getChatByUserId(int uid) {
    var rowObj = _chatTable?.find<Chat>((chat) => chat.friend_id == uid);
    if (rowObj is Chat) {
      return rowObj;
    }
    return null;
  }

  List<Chat> getChatListByUserId(int uid) {
    List<Chat> chatList = _chatTable?.getList() ?? [];
    if (chatList.isNotEmpty) {
      List<Chat> tempList =
          chatList.where((chat) => chat.friend_id == uid).toList();
      return tempList;
    }
    return chatList;
  }

  Chat? getChatByTyp(int typ) {
    List<Chat> chatList = _chatTable?.getList() ?? [];
    if (chatList.isNotEmpty) {
      Chat chat = chatList.where((chat) => chat.typ == typ).first;
      return chat;
    }
    return null;
  }

  Future<Chat?> getGroupChatById(
    int groupId, {
    bool remote = false,
    bool notify = false,
  }) async {
    var chat = getChatById(groupId);
    if (chat == null && remote) {
      try {
        final rep = await loadRemoteGroup(groupId, notify: notify);
        if (rep.data != null) {
          _sharedDB.applyUpdateBlock(
            UpdateBlockBean.created(
              blockOptReplace,
              DBChat.tableName,
              [rep.data],
            ),
            save: true, // 需要保存
            notify: false,
          );

          chat = getChatById(groupId);
        }
      } on ExistException catch (e) {
        Toast.showToast(e.getMessage());
      }
    }

    return chat;
  }

  Future<Chat?> getChatByFriendId(
    int userId, {
    bool remote = false,
    bool notify = false,
  }) async {
    Chat? localChat = getChatById(userId);
    if (localChat != null) {
      return localChat;
    }

    Map<String, dynamic>? chatData = await _localDB.getChatByFriendId(userId);
    if (chatData == null || remote) {
      // 远端请求同时更新数据库
      final rep =
          await loadRemoteChatByFriend(userId, chatTypeSingle, notify: notify);
      if (rep != null) {
        chatData = rep.data;
      }
    }

    if (chatData != null) {
      if (_chatTable != null) {
        Chat? chat = _chatTable?.getRow(chatData['id']);
        return chat;
      } else {
        Chat? chat = Chat.creator();
        chat.init(chatData);
        return chat;
      }
    }
    return null;
  }

  Future<void> updateChatMsgIdx(int chatId, int msgIdx) async {
    return _localDB.updateChatMsgIdx(chatId, msgIdx);
  }

  Future<Chat?> getChatByGroupId(
    int groupId, {
    bool remote = false,
    bool notify = false,
  }) async {
    Map<String, dynamic>? chatData = await _localDB.getChatById(groupId);
    if (chatData == null || remote) {
      // 远端请求同时更新数据库
      final rep = await loadRemoteChatByChatID(groupId, notify: notify);
      if (rep != null) {
        chatData = rep.data;
      }
    }

    if (chatData != null) {
      final Chat chat = Chat()..init(chatData);
      await _sharedDB.applyUpdateBlock(
        UpdateBlockBean.created(
          blockOptReplace,
          DBChat.tableName,
          [chatData],
        ),
      );
      return chat;
    }

    return null;
  }

  Future<dynamic> loadRemoteChatByFriend(
    int friendId,
    int? type, {
    bool notify = false,
  }) async {
    if (!objectMgr.loginMgr.isLogin) return;
    try {
      final chatData = await chat_api.find_chat(friend_id: friendId, typ: type);
      if (chatData.success()) {
        await _sharedDB.applyUpdateBlock(
          UpdateBlockBean.created(
            blockOptReplace,
            DBChat.tableName,
            [chatData.data],
          ),
          save: true,
          notify: notify,
        );
        return chatData;
      }
    } on AppException catch (e) {
      pdebug('Load remote chat failed --> ${e.toString()} chat_mgr.dart');
    }
    return null;
  }

  Future<dynamic> loadRemoteChatByChatID(
    int chatId, {
    bool notify = false,
  }) async {
    if (!objectMgr.loginMgr.isLogin) return;
    try {
      final chatData = await chat_api.get_chat(chatId);
      if (chatData.success()) {
        await _sharedDB.applyUpdateBlock(
          UpdateBlockBean.created(
            blockOptReplace,
            DBChat.tableName,
            [chatData.data],
          ),
          save: true,
          notify: notify,
        );
        return Chat()..init(chatData.data);
      }
    } on AppException catch (e) {
      pdebug('Get remote chat failed --> ${e.toString()} chat_mgr.dart');
    }
    return null;
  }

  Future<dynamic> loadRemoteGroup(int groupId, {bool notify = false}) async {
    try {
      final groupData = await group_api.getGroupInfo(groupId);
      if (groupData.message == 'OK') {
        _sharedDB.applyUpdateBlock(
          UpdateBlockBean.created(
            blockOptReplace,
            DBChat.tableName,
            [groupData.data],
          ),
          save: true,
          notify: notify,
        );
        return groupData;
      }
    } on AppException catch (e) {
      pdebug("loadRemoteGroup failed: $e");
      // if (e.getPrefix() == 20002) {
      //   throw ExistException("您已不在该群里！");
      // } else {
      //   Toast.showToast(e.toString());
      // }
    }
    return null;
  }

  // app init will get all slow mode enabled group
  getAllSlowModeGroup() async {
    List<Map<String, dynamic>>? list = await _localDB.getGroupWithSlowMode();
    if (list != null) {
      for (var item in list) {
        Group group = Group.fromJson(item);

        // only member need to follow slow mode
        if (!objectMgr.userMgr.isMe(group.owner) &&
            !group.admins.contains(objectMgr.userMgr.mainUser.uid)) {
          addSlowMode(group);
        }
      }
    }
  }

  removeSlowMode(int groupID) =>
      groupSlowMode.removeWhere((key, _) => key == groupID);

  addSlowMode(Group group) async {
    Map<String, dynamic>? result =
        await _localDB.getMyLastSendMessage(group.id);
    if (result != null) {
      Message msg = Message.creator()..init(result);
      groupSlowMode[group.id] = {
        'group': group,
        'message': msg,
        'isEnable': false,
      };
    } else {
      groupSlowMode[group.id] = {
        'group': group,
        'message': null,
        'isEnable': false,
      };
    }
  }

  updateSlowMode({Message? message, Group? group}) {
    if (message != null) {
      // update new sent message by me
      if (groupSlowMode[message.chat_id] != null) {
        groupSlowMode[message.chat_id]!['message'] = message;
        groupSlowMode[message.chat_id]!['isEnable'] = false;
      }
    }

    if (group != null) {
      // update group
      if (groupSlowMode[group.id] != null) {
        if (objectMgr.userMgr.isMe(group.owner) ||
            group.admins.contains(objectMgr.userMgr.mainUser.uid) ||
            group.speakInterval == 0) {
          removeSlowMode(group.id); // user are not member anymore
        } else {
          groupSlowMode[group.id]!['group'] = group; // user become member
        }
      } else {
        if (group.speakInterval != 0 &&
            !objectMgr.userMgr.isMe(group.owner) &&
            !group.admins.contains(objectMgr.userMgr.mainUser.uid)) {
          addSlowMode(group); // group added slow mode permission
        }
      }
    }
  }

  /// 群被解散以后的回调
  /// 处理三件事
  /// 清理group本地数据库的数据
  /// 清理message本地数据库的数据
  /// 清理file_info关于message对应的文件
  Future<void> chatGroupDeleteProcess(Chat chat, {bool isDelete = true}) async {
    /// 删除聊天室message
    chat.setValue('hide_chat_msg_idx', chat.msg_idx);
    chat.setValue('cover_idx', chat.msg_idx);
    _removeLocalMessages(chat, chat.msg_idx);

    ///删除该聊天
    if (isDelete) {
      if (chat.isGroup) {
        _sharedDB.applyUpdateBlock(
          UpdateBlockBean.created(
            blockOptDelete,
            DBGroup.tableName,
            chat.id,
          ),
        );
      }

      _sharedDB.applyUpdateBlock(
        UpdateBlockBean.created(blockOptDelete, DBChat.tableName, chat.id),
      );
    } else {
      chat.flag_my = ChatStatus.MyChatFlagHide.value;

      _sharedDB.applyUpdateBlock(
        UpdateBlockBean.created(
          blockOptReplace,
          DBChat.tableName,
          [chat.toJson()],
        ),
        notify: false,
      );
    }

    event(this, eventChatDelete, data: chat);
  }

  void resetUnread() async {
    List<Chat> chats = getAllChats(needProcess: false);
    for (var chat in chats) {
      if (chat.unread_count > 0) {
        await updateUnread(chat, chat.msg_idx);
      }
    }
    totalUnreadCount.value = 0;
    event(this, eventUnreadTotalCount);
  }

  emojiMessageCheck(Message msg, Chat chat) async {
    if (msg.typ != messageTypeRemoveReactEmoji &&
        msg.typ != messageTypeAddReactEmoji) {
      return;
    }
    if (_chatMessageMap[chat.id] == null) {
      return;
    }
    var data = json.decode(msg.content);
    if (data == null || data["message_id"] == null) {
      return;
    }
    int replyMsgId = data["message_id"];
    int replyChatIdx = -1;
    if (data['chat_idx'] != null) {
      replyChatIdx = data['chat_idx'];
    }
    Message? replyMsg;
    var messages = _chatMessageMap[chat.id]!;
    messages.forEach((key, value) {
      if (value.message_id == replyMsgId || value.chat_idx == replyChatIdx) {
        replyMsg = value;
        return;
      }
    });

    if (replyMsg == null) {
      return;
    }

    bool find = false;
    EmojiModel? delEmoji;
    final dataEmoji = data["emoji"];
    final dataClearEmoji = dataEmoji.toString().replaceAll('️', '');
    for (var element in replyMsg!.emojis) {
      final elementEmoji = element.emoji;
      final elementClearEmoji = elementEmoji.toString().replaceAll('️', '');
      if (elementClearEmoji == dataClearEmoji) {
        if (msg.typ == messageTypeAddReactEmoji) {
          if (!element.uidList.contains(msg.send_id)) {
            element.uidList.add(msg.send_id);
          }
        }
        if (msg.typ == messageTypeRemoveReactEmoji) {
          if (element.uidList.contains(msg.send_id)) {
            element.uidList.remove(msg.send_id);
            if (element.uidList.isEmpty) {
              delEmoji = element;
            }
          }
        }
        find = true;
        continue;
      }
    }
    if (delEmoji != null) {
      replyMsg!.delEmoji(delEmoji);
    }
    if (!find && msg.typ == messageTypeAddReactEmoji) {
      var emoji = EmojiModel(emoji: dataClearEmoji, uidList: [msg.send_id]);
      replyMsg!.addEmoji(emoji);
    }
    event(this, eventEmojiChange, data: replyMsg);
  }

  processFileOperateMessage(
      Message msg, Chat chat, ProcessMessageType processMessageType) {
    event(this, eventFileOperateDoMsg, data: msg);
    if (_chatMessageMap[chat.id] == null) {
      return;
    }
    var data = json.decode(msg.content);
    if (data == null || data["message_id"] == null || data["uid"] == null) {
      return;
    }
    bool isMeInReceivers = msg.send_id == objectMgr.userMgr.mainUser.uid ||
        data["uid"] == objectMgr.userMgr.mainUser.uid;
    //如果不是我点击播放的 或者 是我发送的语音消息
    if (!isMeInReceivers) {
      return;
    }
    int msgId = data["message_id"];
    int chatIdx = -1;
    if (data['chat_idx'] != null) {
      chatIdx = data['chat_idx'];
    }
    Message? findMsg;
    var messages = _chatMessageMap[chat.id]!;
    messages.forEach((key, value) {
      if (value.message_id == msgId || value.chat_idx == chatIdx) {
        findMsg = value;
        return;
      }
    });

    if (findMsg == null) {
      return;
    }

    findMsg?.isContentViewed = true;
    if (processMessageType == ProcessMessageType.input) {
      saveMessage(findMsg!);
    }

    event(this, eventFileOperate, data: findMsg);
  }

  doTmpGroupReJoin(Chat chat) {
    chat.delete_time = 0;
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(blockOptUpdate, DBChat.tableName, chat),
      save: true,
      notify: false,
    );
  }

  static Future<List<Message>> loadNetMessages(
    Chat chat, {
    required int count,
    int fromChatIdx = 0,
    int forward = 0,
    int must = 1,
  }) async {
    List<Message> messages = [];

    final res = await chat_api.getMessageByRemote(
      '${chat.id},$fromChatIdx',
      count: count,
      must: must,
      forward: forward,
    );
    if (res.success()) {
      for (final data in res.data) {
        Message message = Message()..init(data);
        data['id'] = message.id;
        messages.add(message);
      }
    }
    return messages;
  }

  /*
    forward = 0意思是 小于fromIdx的count个message
    forward = 1意思是 大于fromIdx的count个message
  */
  Future<List<Message>> loadMessageList(
    Chat chat, {
    int fromIdx = -1,
    int count = 0,
    int extra = 0,
    int forward = 0,
    int fromTime = 0,
  }) async {
    List<Message> list = await loadMessageListSub(
      chat,
      fromIdx: fromIdx,
      count: count,
      forward: forward,
      fromTime: fromTime,
    );
    if (list.isNotEmpty) {
      fromTime = list.last.create_time;
    }
    if (forward == 0 && extra != 0 && fromIdx + 1 <= chat.msg_idx) {
      List<Message> extraList = await loadMessageListSub(
        chat,
        fromIdx: fromIdx + 1,
        count: extra,
        forward: 1,
        fromTime: fromTime,
      );
      list.addAll(extraList);
      sortMessage(list);
    } else if (forward == 1 &&
        extra != 0 &&
        fromIdx - 1 >= chat.hide_chat_msg_idx + 1) {
      List<Message> extraList = await loadMessageListSub(
        chat,
        fromIdx: fromIdx - 1,
        count: extra,
        forward: 0,
        fromTime: fromTime,
      );
      list.addAll(extraList);
      sortMessage(list, ascending: true);
    }

    for (final message in list) {
      if (message.isMediaType &&
          message.message_id == 0 &&
          message.asset == null) {
        switch (message.typ) {
          case messageTypeNewAlbum:
            message.asset = <dynamic>[];
            final NewMessageMedia msgAlbum = message.decodeContent(
              cl: NewMessageMedia.creator,
            );

            if (msgAlbum.albumList?.isNotEmpty ?? false) {
              for (final bean in msgAlbum.albumList!) {
                if (bean.asid == null) {
                  message.asset.add(null);
                  continue;
                }
                message.asset.add(await AssetEntity.fromId(bean.asid!));
              }
            }
            break;
          default:
            break;
        }
      }
    }

    return list;
  }

  Future<List<Message>> loadMessageListSub(
    Chat chat, {
    int fromIdx = -1,
    int count = 0,
    int forward = 0,
    int fromTime = 0,
  }) async {
    List<Message> list = getMemMessages(
      chat,
      fromChatIdx: fromIdx,
      count: count,
      forward: forward,
    );
    if (list.isEmpty ||
        (forward == 0 &&
            list.length < count &&
            list.last.chat_idx > chat.hide_chat_msg_idx + 1) ||
        (forward == 1 &&
            list.length < count &&
            list.last.chat_idx < chat.msg_idx) ||
        (list.first.chat_idx != fromIdx)) {
      list = await loadDBMessages(
        objectMgr.localDB,
        chat,
        fromChatIdx: fromIdx,
        count: count,
        forward: forward,
        fromTime: fromTime,
      );
      await processLocalMessage(list);
      list = getMemMessages(
        chat,
        fromChatIdx: fromIdx,
        count: count,
        forward: forward,
      );
    }
    return list;
  }

  List<Message> getMemMessages(
    Chat chat, {
    int count = 0,
    int fromChatIdx = 0,
    int forward = 0,
  }) {
    if (count == 0) return [];

    if (_chatMessageMap[chat.id] == null) {
      _chatMessageMap[chat.id] = {};
    }

    List<Message> messages = _chatMessageMap[chat.id]?.values.toList() ?? [];
    if (messages.isEmpty) return messages;

    sortMessage(messages);

    // 默认取所有的
    if (count < 0) return messages;

    if (forward == 1) {
      List<Message> messageList = [];
      if (messages.isNotEmpty) {
        bool findIndex = false;
        int visibleCount = 0;
        int endIndex = messages.length - 1;
        int i = 0;
        for (i = endIndex; i >= 0; i--) {
          Message message = messages[i];
          if (message.chat_idx >= fromChatIdx && !findIndex) {
            endIndex = i + 1;
            findIndex = true;
          }
          if (findIndex && message.isChatRoomVisible) {
            visibleCount++;
          }
          if (visibleCount >= count) {
            break;
          }
        }
        if (findIndex && endIndex <= messages.length) {
          messageList
              .addAll(messages.getRange(i >= 0 ? i : 0, endIndex).toList());
        }
      }
      sortMessage(messageList, ascending: true);
      return messageList;
    } else {
      List<Message> messageList = [];
      bool findIndex = false;
      int startIndex = 0;
      int visibleCount = 0;
      int i;
      for (i = 0; i < messages.length; i++) {
        Message message = messages[i];
        if (message.chat_idx <= fromChatIdx && !findIndex) {
          startIndex = i;
          findIndex = true;
        }

        if (message.isChatRoomVisible && findIndex) {
          visibleCount++;
        }

        if (visibleCount >= count) {
          break;
        }
      }

      if (findIndex) {
        messageList.addAll(
          messages
              .getRange(
                startIndex,
                (i + 1) < messages.length ? (i + 1) : messages.length,
              )
              .toList(),
        );
      }

      return messageList;
    }
  }

  static Future<List<Message>> loadDBMessages(
    DBInterface db,
    Chat chat, {
    int count = 0,
    int fromChatIdx = 0,
    int forward = 0,
    int fromTime = 0,
    bool dbLatest = false,
  }) async {
    List<Message> messages = [];
    if (fromTime == 0) {
      messages = await ChatMgr.loadDBMessageHotTable(
        db,
        chat,
        cnt: count,
        fromChatIdx: fromChatIdx,
        forward: forward,
        dbLatest: dbLatest,
      );
    }

    count = count - messages.length;
    if (forward == 0 && count > 0) {
      if (messages.isNotEmpty) {
        fromChatIdx = messages.last.chat_idx - 1;
        fromTime = messages.last.create_time;
      }
      var codeMessages = await loadDBMessageColdTable(
        db,
        chat,
        cnt: count,
        fromChatIdx: fromChatIdx,
        fromTime: fromTime,
        forward: forward,
        dbLatest: dbLatest,
      );
      messages.addAll(codeMessages);
    } else if (forward == 1 && count > 0) {
      if (messages.isNotEmpty) {
        fromChatIdx = messages.last.chat_idx + 1;
        fromTime = messages.last.create_time;
      }
      var codeMessages = await loadDBMessageColdTable(
        db,
        chat,
        cnt: count,
        fromChatIdx: fromChatIdx,
        fromTime: fromTime,
        forward: forward,
        dbLatest: dbLatest,
      );
      messages.addAll(codeMessages);
    }

    return messages;
  }

  static Future<List<Message>> loadDBMessageHotTable(
    DBInterface db,
    Chat chat, {
    required int cnt,
    int fromChatIdx = 0,
    int forward = 0,
    bool dbLatest = false,
  }) async {
    return await loadDBMessageSub(
      db,
      chat,
      cnt: cnt,
      fromChatIdx: fromChatIdx,
      forward: forward,
      dbLatest: dbLatest,
    );
  }

  static Future<List<Message>> loadDBMessageColdTable(
    DBInterface db,
    Chat chat, {
    required int cnt,
    int fromChatIdx = 0,
    int forward = 0,
    int fromTime = 0,
    bool dbLatest = false,
  }) async {
    List<Message> messages = [];
    List<String> tables = await db.getColdMessageTables(fromTime, forward);
    for (int i = 0; cnt > 0 && i < tables.length; i++) {
      if (forward == 0) {
        if (fromChatIdx <= chat.hide_chat_msg_idx) {
          break;
        }
      } else {
        if (fromChatIdx > chat.msg_idx) {
          break;
        }
      }
      List<Message> curMessages = await ChatMgr.loadDBMessageSub(
        db,
        chat,
        cnt: cnt,
        fromChatIdx: fromChatIdx,
        forward: forward,
        tbname: tables[i],
      );
      if (curMessages.isEmpty) {
        continue;
      }
      messages.addAll(curMessages);
      cnt -= curMessages.length;
      if (forward == 0) {
        fromChatIdx = curMessages.last.chat_idx - 1;
      } else {
        fromChatIdx = curMessages.last.chat_idx + 1;
      }
    }
    return messages;
  }

  static Future<List<Message>> loadDBMessageSub(
    DBInterface db,
    Chat chat, {
    required int cnt,
    int fromChatIdx = 0,
    int forward = 0,
    bool dbLatest = false,
    String tbname = "",
  }) async {
    if (cnt == 0) return [];
    List<Message> messageList = [];

    DateTime now = DateTime.now();

    if (dbLatest) {
      final norMessageListData = await db.loadMessagesByWhereClause(
        "chat_id = ? AND chat_idx > ? AND (expire_time == 0 OR expire_time >= ?) AND typ < 12000",
        [chat.id, chat.hide_chat_msg_idx, now.millisecondsSinceEpoch ~/ 1000],
        null,
        cnt,
        null,
        tbname: tbname,
      );

      if (norMessageListData.isNotEmpty) {
        messageList.addAll(
          norMessageListData.map<Message>((e) => Message()..init(e)).toList(),
        );
      }
      return messageList;
    }

    if (forward == 1) {
      final norMessageListData = await db.loadMessagesByWhereClause(
        "chat_id = ? AND chat_idx >= ? AND chat_idx > ?  AND (expire_time == 0 OR expire_time >= ?) AND typ < 12000",
        [
          chat.id,
          fromChatIdx,
          chat.hide_chat_msg_idx,
          now.millisecondsSinceEpoch ~/ 1000,
        ],
        "asc",
        cnt,
        null,
        tbname: tbname,
      );

      if (norMessageListData.isNotEmpty) {
        messageList.addAll(
          norMessageListData.map<Message>((e) => Message()..init(e)).toList(),
        );
      }
      return messageList;
    } else {
      // Q: 假消息出不来
      List<Message> messageList = [];
      final norMessageListData = await db.loadMessagesByWhereClause(
        "chat_id = ? AND chat_idx <= ? AND chat_idx > ?  AND (expire_time == 0 OR expire_time >= ?) AND typ < 12000",
        [
          chat.id,
          fromChatIdx,
          chat.hide_chat_msg_idx,
          now.millisecondsSinceEpoch ~/ 1000,
        ],
        null,
        cnt,
        null,
        tbname: tbname,
      );

      // 新的聊天室不进入这里以防手机性能太好导致重复添加消息
      if (norMessageListData.isNotEmpty) {
        messageList.addAll(
          norMessageListData.map<Message>((e) => Message()..init(e)).toList(),
        );
      }

      return messageList;
    }
  }

  clearMemMessageByChat(Chat chat) async {
    chatMessageMap[chat.id]?.clear();
  }

  onChatDelete(Chat chat) async {
    chat.isSelected = false;
    chatGroupDeleteProcess(chat, isDelete: !chat.isValid);
    await deleteChat(chat.chat_id, chat.msg_idx);
  }

  void chatDeleteRetry(Retry retry, bool isSuccess) {}

  void hideRetryCallback(Retry retry, bool isSuccess) {}

  /// unmute: expireTime = 0
  /// mute permanently: expireTime = -1
  /// mute specific time: expireTime = timeStamp
  onChatMute(
    Chat chat, {
    int expireTime = -1,
    MuteDuration? mType,
    bool isNotHomePage = false,
  }) async {
    try {
      var res = await muteSpecificChat(chat.chat_id, expireTime);
      if (res.success()) {
        chat.mute = expireTime;
        updateNotificationStatus(chat, expireTime);
        if (expireTime == 0) {
          // Toast.showToast(localized(chatInfoUnMuteChatSuccessful));
          if (objectMgr.loginMgr.isDesktop) {
            Toast.showToast(localized(chatInfoUnMuteChatSuccessful));
            chat.isMuteRX.value = false;
          } else {
            imBottomToast(
              navigatorKey.currentContext!,
              title: localized(chatInfoUnMuteChatSuccessful),
              icon: ImBottomNotifType.unmute,
            );
          }
        } else {
          if (mType == null || mType == MuteDuration.forever) {
            if (objectMgr.loginMgr.isDesktop) {
              Toast.showToast(localized(notificationsWillBeMutedForever));
            } else {
              imBottomToast(
                navigatorKey.currentContext!,
                title: localized(notificationsWillBeMutedForever),
                icon: ImBottomNotifType.mute,
              );
            }
          } else {
            String muteText = '';
            switch (mType) {
              case MuteDuration.hour:
                muteText = localized(
                  notificationsWillBeMutedHour,
                  params: [1.toString()],
                );
                break;
              case MuteDuration.eighthHours:
                muteText = localized(
                  notificationsWillBeMutedHours,
                  params: [8.toString()],
                );
                break;
              case MuteDuration.day:
                muteText = localized(
                  notificationsWillBeMutedDay,
                  params: [1.toString()],
                );
                break;
              case MuteDuration.sevenDays:
                muteText = localized(
                  notificationsWillBeMutedDays,
                  params: [7.toString()],
                );
                break;
              case MuteDuration.week:
                muteText = localized(
                  notificationsWillBeMutedWeek,
                  params: [1.toString()],
                );
                break;
              case MuteDuration.month:
                muteText = localized(
                  notificationsWillBeMutedMonth,
                  params: [1.toString()],
                );
                break;
              case MuteDuration.custom:
                muteText = localized(
                  muteUntilWithParam,
                  params: [
                    FormatTime.getYYMMDDhhmm(expireTime),
                  ],
                );
                break;
              case MuteDuration.forever:
            }
            if (objectMgr.loginMgr.isDesktop) {
              Toast.showToast(muteText);
            } else {
              imBottomToast(
                navigatorKey.currentContext!,
                title: muteText,
                icon: ImBottomNotifType.snooze,
              );
            }
          }

          // Toast.showToast(localized(chatInfoMuteChatSuccessful));
        }
      } else {
        Toast.showToast(localized(chatInfoPleaseTryAgainLater));
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
      rethrow;
    }
  }

  Future<Message?> findMessageByChatIdx(int chatId, int chatIdx) async {
    List<Map<String, dynamic>> rows = await _localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx = ?',
      [chatId, chatIdx],
      null,
      1,
      null,
    );
    if (rows.isNotEmpty) {
      Message message = Message()..init(rows.first);
      return message;
    }
    return null;
  }

  Message? getLatestMessage(int chatId) {
    Message? message = _lastChatMessageMap[chatId];

    if (message != null) {
      if (!message.isExpired && !message.isDeleted) {
        return message;
      }
    }

    return null;
  }

  Future<Message?> getLocalLatestMessage(Chat chat) async {
    final data =
        await _localDB.findLatestMessage(chat.chat_id, chat.hide_chat_msg_idx);
    if (data != null) {
      final lastMessage = Message()..init(data);
      return lastMessage;
    }
    return null;
  }

  // 排除表情
  Future<bool> isLastNormalMessageEnd(Chat chat, int fromIdx) async {
    final norMessageListData = await _localDB.loadMessagesByWhereClause(
      "chat_id = ? AND chat_idx > ? AND chat_idx > ? AND typ != ? AND typ != ?",
      [
        chat.id,
        fromIdx,
        chat.read_chat_msg_idx,
        messageTypeAddReactEmoji,
        messageTypeRemoveReactEmoji,
      ],
      null,
      1,
      null,
    );
    return norMessageListData.isEmpty;
  }

  /// 搜索本地消息
  Future<List<Message>> searchMessages(String searchStr) async {
    if (searchStr.isEmpty) {
      return [];
    }
    // 从数据库读取数据
    List<Map<String, dynamic>> rows = await _localDB.searchMessage(searchStr);
    List<Message> list = [];
    for (var e in rows) {
      Message message = Message()..init(e);
      Chat? chat = getChatById(message.chat_id);
      if (chat != null) {
        if (message.typ == messageTypeText && (chat.isSingle || chat.isGroup)) {
          MessageText textData = message.decodeContent(cl: MessageText.creator);
          if (textData.text.contains(searchStr)) {
            list.add(message);
          }
        }
      }
    }
    return list;
  }

  Future<int?> clearMessages(int chatID, {int? chatIdx}) async {
    if (chatMessageMap[chatID] != null) {
      chatMessageMap[chatID] = {};
    }
    return await _localDB.clearMessages(chatID, chatIdx: chatIdx);
  }

  updateNotificationStatus(Chat chat, int mute) async {
    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(blockOptReplace, DBChat.tableName, [
        {"id": chat.id, "mute": mute},
      ]),
      save: true,
      notify: false,
    );
    event(this, eventChatMuteChanged, data: chat);
    Future.delayed(
      const Duration(milliseconds: 300),
      () => updateLocalTotalUnreadNumFromDB(),
    );
  }

  Future<List<Message>> getAlbumMessage(
    int chatId,
    List<int> chatIdxList,
    int referId,
  ) async {
    try {
      final data = await chat_api.lists(
        chatId,
        chatIdxList,
        referID: referId,
      );

      List<Message> albumMessageList = [];
      if (data.success()) {
        data.data.forEach((element) {
          Message msg = Message()..init(element);
          albumMessageList.add(msg);
        });
      }

      return albumMessageList;
    } catch (e) {
      pdebug('getMessagesByRemote error: $e');
      rethrow;
    }
  }

  updateLatestMessage(Message msg) async {
    Chat? chat = getChatById(msg.chat_id);
    if (chat != null) {
      final lastMessage = await getLocalLatestMessage(chat);
      if (lastMessage != null) {
        if (_lastChatMessageMap[chat.chat_id]?.message_id !=
            lastMessage.message_id) {
          _lastChatMessageMap[chat.chat_id] = lastMessage;
          event(this, eventChatLastMessageChanged, data: lastMessage);
        }
      } else {
        _lastChatMessageMap.remove(chat.chat_id);
        event(this, eventChatLastMessageChanged, data: null);
      }
    }
  }

  void reqSignChat(Message msg, Chat? chat) async {
    if (!Config().e2eEncryptionEnabled) {
      return;
    }
    chat ??= getChatById(msg.chat_id);
    if (chat == null) {
      return;
    }
    if (!chat.isValid) {
      //已经离群的聊天室，不处理 （删也删不掉）
      return;
    }
    if (msg.typ != messageTypeReqSignChat) {
      return;
    }
    //清理脏数据，后面此if需要去掉 2024-11-05 02:30:41
    if (msg.create_time < 1730745041) {
      //chat_api.deleteMsg(msg.chat_id, [msg.message_id], isAll: true);
      return;
    }

    SignChatTask.addSignChatMessage(chat, msg);
  }

  void respSignChat(Message msg, Chat chat) async {
    //新方案对该消息不需要做任何处理
  }

  void remotelDelMessage(Message msg, Chat chat) async {
    Map<int, Message>? chatMessageMap = _chatMessageMap[msg.chat_id];
    chatMessageMap ??= {};
    _onProcessMentionMessage(msg);
    if (msg.typ != messageTypeDeleted) {
      return;
    }
    MessageDelete messageDel = msg.decodeContent(cl: MessageDelete.creator);
    if (!objectMgr.userMgr.isMe(messageDel.uid) && messageDel.all == 0) {
      return;
    }

    for (final message_id in messageDel.message_ids) {
      Message? findMessage;
      chatMessageMap.forEach((key, value) {
        if (value.message_id == message_id) {
          value.deleted = 1;
          findMessage = value;
        }
      });
      SignChatTask.delSignChatMessage(chat, message_id);
      if (findMessage != null) {
        if (findMessage!.typ == messageTypeNewAlbum ||
            findMessage!.typ == messageTypeReel ||
            findMessage!.typ == messageTypeVideo) {
          objectMgr.tencentVideoMgr.checkForFloatingPIPClosure(
              [findMessage!]); // 若为视频消息（包括相册，入播放器审查看是否需要关闭）
        }
        chatMessageMap.remove(findMessage!.message_id);
      }
    }
    await updateLatestMessage(msg);
    int unreadNum =
        await _localDB.getUnreadNum(chat.chat_id, chat.read_chat_msg_idx);

    var diffCount = chat.unread_count - unreadNum;
    if (diffCount != 0) {
      chat.unread_count = unreadNum;

      if (unreadNum <= 0) {
        final tempCount = Map.from(chatCategoryUnreadCount);
        tempCount.forEach((key, value) {
          chatCategoryUnreadCount[key]?.remove(chat.id);
        });
      }

      if (chat.isCountUnread) {
        totalUnreadCount.value = max(totalUnreadCount.value - diffCount, 0);
      }
      event(this, eventUpdateUnread, data: chat);
    }

    event(
      this,
      eventDeleteMessage,
      data: {
        'id': msg.chat_id,
        'message': messageDel.message_ids,
        'isClear': false,
      },
    );
  }

  Future<void> localDelMessage(Message msg) async {
    Map<int, Message>? chatMessageMap = _chatMessageMap[msg.chat_id];
    chatMessageMap ??= {};
    String cmid = msg.cmid;
    int id = msg.id;
    _onProcessMentionMessage(msg);
    if (chatMessageMap.containsKey(msg.id)) {
      chatMessageMap[msg.id]!.deleted;
      chatMessageMap.remove(msg.id);
    }
    if (cmid != "") {
      await _localDB.delete(
        DBMessage.tableName,
        where: "chat_id = ? AND cmid = ?",
        whereArgs: [msg.chat_id, cmid],
      );
      String tbname = _localDB.getColdMessageTableName(msg.create_time);
      await _localDB.delete(
        tbname,
        where: "chat_id = ? AND cmid = ?",
        whereArgs: [msg.chat_id, cmid],
      );
    } else {
      await _localDB.delete(
        DBMessage.tableName,
        where: "chat_id = ? AND id = ?",
        whereArgs: [msg.chat_id, id],
      );
      String tbname = _localDB.getColdMessageTableName(msg.create_time);
      await _localDB.delete(
        tbname,
        where: "chat_id = ? AND id = ?",
        whereArgs: [msg.chat_id, id],
      );
    }

    await updateLatestMessage(msg);

    event(
      this,
      eventDeleteMessage,
      data: {
        'id': msg.chat_id,
        'message': [msg],
        'isClear': false,
      },
    );
  }

  void remoteEditMessage(Chat chat, Message msg) async {
    if (msg.typ != messageTypeEdit) {
      return;
    }
    Map<int, Message>? chatMessageMap = _chatMessageMap[msg.chat_id];
    MessageEdit messageEdit = msg.decodeContent(cl: MessageEdit.creator);
    Message? findMessage;
    if (chatMessageMap != null) {
      chatMessageMap.forEach((key, value) {
        if (value.message_id == messageEdit.related_id) {
          findMessage = value;
          return;
        }
      });
    }

    if (findMessage == null) {
      final Message? lastMsg = _lastChatMessageMap[msg.chat_id];
      if (lastMsg != null && lastMsg.chat_idx == messageEdit.chat_idx) {
        findMessage = lastMsg;
      }
    }

    if (findMessage != null) {
      msg.atUser = messageEdit.atUser;
      if (msg.isMentionMessage(objectMgr.userMgr.mainUser.uid)) {
        if (mentionMessageMap[msg.chat_id] == null) {
          mentionMessageMap[msg.chat_id] = {};
        }
        mentionMessageMap[msg.chat_id]![findMessage!.message_id] = findMessage!;
        event(this, eventAddMentionChange, data: findMessage);
      } else {
        if (mentionMessageMap[msg.chat_id] != null &&
            mentionMessageMap[msg.chat_id]!
                .containsKey(findMessage!.message_id)) {
          var mentionMsg =
              mentionMessageMap[msg.chat_id]![findMessage!.message_id];
          mentionMessageMap[msg.chat_id]!.remove(findMessage!.message_id);
          event(this, eventDelMentionChange, data: mentionMsg);
        }
      }
      findMessage!.atUser = msg.atUser;

      findMessage!.content = messageEdit.content;
      findMessage!.edit_time = msg.create_time;
      findMessage!.ref_typ = messageEdit.refTyp;
      if (messageEdit.atUser.isNotEmpty) {
        findMessage!.atUser = messageEdit.atUser.toList();
      }
      findMessage!.sendState = MESSAGE_SEND_SUCCESS;
      if (findMessage!.isEncrypted) {
        MessageMgr.decodeMsg(
            findMessage!, chat, objectMgr.userMgr.mainUser.uid);
      }

      if (_lastChatMessageMap[msg.chat_id] == null) {
        _lastChatMessageMap[msg.chat_id] = findMessage!;
      } else if (_lastChatMessageMap[msg.chat_id]!.message_id ==
          findMessage!.message_id) {
        _lastChatMessageMap[msg.chat_id]!.content = findMessage!.content;
        _lastChatMessageMap[msg.chat_id]!.edit_time = findMessage!.edit_time;
        _lastChatMessageMap[msg.chat_id]!.sendState = findMessage!.sendState;
        _lastChatMessageMap[msg.chat_id]!.atUser = findMessage!.atUser;
      }
      if (pinnedMessageList.isNotEmpty &&
          pinnedMessageList[msg.chat_id] != null) {
        int? index = pinnedMessageList[msg.chat_id]
            ?.indexWhere((item) => item.message_id == findMessage?.message_id);
        if (index != -1) {
          pinnedMessageList[msg.chat_id]?[index!] = findMessage!;
        }
      }
      event(
        this,
        eventEditMessage,
        data: {
          'id': msg.chat_id,
          'message': findMessage,
        },
      );
    }
  }

  void localEditMessage(int chatId, int messageId, String content) async {
    Map<int, Message>? chatMessageMap = _chatMessageMap[chatId];
    Message? findMessage;
    if (chatMessageMap != null) {
      chatMessageMap.forEach((key, value) {
        if (value.message_id == messageId) {
          findMessage = value;
          return;
        }
      });
    }
    if (findMessage != null) {
      findMessage!.content = content;
      findMessage!.edit_time = DateTime.now().microsecondsSinceEpoch ~/ 1000;
      findMessage!.sendState = MESSAGE_SEND_SUCCESS;
      if (_lastChatMessageMap[chatId] == null ||
          _lastChatMessageMap[chatId]!.message_id == findMessage!.message_id) {
        _lastChatMessageMap[chatId] = findMessage;
      }
      event(
        this,
        eventEditMessage,
        data: {
          'id': chatId,
          'message': findMessage,
        },
      );
    }
  }

  /// 删除本地消息
  /// 清除聊天室的时候使用
  void _removeLocalMessages(
    Chat chat,
    int maxIdx, {
    bool isClear = true,
  }) async {
    List<Message> delMessage = [];
    var chatMessages = _chatMessageMap[chat.chat_id];
    mentionMessageMap[chat.chat_id] = {};

    // 清理管理器缓存
    if (chatMessages != null && chatMessages.isNotEmpty) {
      if (isClear) {
        delMessage.addAll(chatMessages.values);
      } else {
        for (var item in chatMessages.values) {
          if (item.chat_idx <= maxIdx) {
            delMessage.add(item);
          }
        }
      }
    }

    await _localDB.delete(
      DBMessage.tableName,
      where: "chat_id = ? AND chat_idx <= ?",
      whereArgs: [chat.chat_id, maxIdx],
    );
    //新增冷表消息的删除
    List<String> tables = await _localDB.getColdMessageTables(0, 0);
    for (int i = 0; i < tables.length; i++) {
      await _localDB.delete(
        tables[i],
        where: "chat_id = ? AND chat_idx <= ?",
        whereArgs: [chat.chat_id, maxIdx],
      );
    }

    updateUnread(chat, maxIdx);

    final lastMessage = await getLocalLatestMessage(chat);
    if (lastMessage != null) {
      _lastChatMessageMap[chat.chat_id] = lastMessage;
    } else {
      _lastChatMessageMap[chat.chat_id] = null;
    }

    // update chat
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(blockOptUpdate, DBChat.tableName, chat),
      notify: false,
    );

    _chatMessageMap[chat.chat_id] = {};

    event(
      this,
      eventDeleteMessage,
      data: {'id': chat.chat_id, 'message': delMessage, 'isClear': isClear},
    );

    if (isClear) {
      //clear代表该聊天室已再无信息
      event(this, eventChatLastMessageChanged, data: null);
    }

    updateLocalTotalUnreadNumFromDB();
  }

  Future<void> showNotification(
    Message msg, {
    List<Message>? messageList,
  }) async {
    if (msg.message_id == 0 || objectMgr.userMgr.isMe(msg.send_id)) {
      if (msg.sendState == MESSAGE_SEND_FAIL &&
          objectMgr.userMgr.isMe(msg.send_id)) {
        // 我发送的，失败的消息，用在线通知的方式提示
      } else {
        return;
      }
    }

    int notificationType = 0;
    String title = '';
    String body = '';
    String sendUser = '';
    bool isShow = true;

    Chat? chat = getChatById(msg.chat_id);

    if (chat != null) {
      title = chat.name;
      notificationType = chat.isSingle ? 1 : 2;

      if (chat.isGroup && msg.send_id > 0) {
        sendUser = await getSender(msg.send_id);
      } else if (chat.typ == chatTypeSmallSecretary) {
        sendUser = localized(chatSecretary);
      }

      if (chat.mute > DateTime.now().millisecondsSinceEpoch ~/ 1000 ||
          chat.mute == -1) {
        isShow = false;
      }
    }

    int typ = 1;
    Map<String, dynamic> payload = {};
    bool isCallMessage = false;

    switch (msg.typ) {
      case messageTypeReply:
      case messageTypeReplyWithdraw:
        if (chat!.isMute ||
            !objectMgr.pushMgr.getChatMuteStatus(chat.isSingle)) {
          final mentionList = msg.atUser.map((e) => e.userId).toList();
          MessageText textData = msg.decodeContent(cl: MessageText.creator);
          try {
            final originalSendID = jsonDecode(textData.reply)['user_id'];
            if (objectMgr.userMgr.isMe(originalSendID) ||
                (mentionList.isNotEmpty &&
                    mentionList.contains(objectMgr.userMgr.mainUser.uid))) {
              isShow = true;
              notificationType = 999;
            } else {
              isShow = false;
            }
          } catch (e) {
            pdebug("$e");
          }
        }

        body = chat.isSingle
            ? ChatHelp.typShowMessage(chat, msg)
            : "$sendUser: ${ChatHelp.typShowMessage(chat, msg)}";
        break;
      case messageTypeVoice:
        MessageVoice messageVoice = msg.decodeContent(cl: MessageVoice.creator);
        if (chat!.isMute ||
            !objectMgr.pushMgr.getChatMuteStatus(chat.isSingle)) {
          if (messageVoice.reply.isNotEmpty) {
            final data = ReplyModel.fromJson(json.decode(messageVoice.reply));
            final mentionList = data.atUser.map((e) => e.userId).toList();

            if (objectMgr.userMgr.isMe(data.userId) ||
                (mentionList.isNotEmpty &&
                    mentionList.contains(objectMgr.userMgr.mainUser.uid))) {
              isShow = true;
              notificationType = 999;
            } else {
              isShow = false;
            }
          }
        }

        body = chat.isSingle
            ? localized(chatTagVoiceCall)
            : "$sendUser: ${localized(chatTagVoiceCall)}";
        break;
      case messageTypeNewAlbum:
        NewMessageMedia messageAlbum =
            msg.decodeContent(cl: NewMessageMedia.creator);
        if (chat!.isMute ||
            !objectMgr.pushMgr.getChatMuteStatus(chat.isSingle)) {
          if (messageAlbum.reply.isNotEmpty) {
            final data = ReplyModel.fromJson(json.decode(messageAlbum.reply));
            final mentionList = data.atUser.map((e) => e.userId).toList();

            if (objectMgr.userMgr.isMe(data.userId) ||
                (mentionList.isNotEmpty &&
                    mentionList.contains(objectMgr.userMgr.mainUser.uid))) {
              isShow = true;
              notificationType = 999;
            } else {
              isShow = false;
            }
          }
        }

        body = chat.isSingle
            ? localized(chatTagAlbum)
            : "$sendUser: ${localized(chatTagAlbum)}";
        break;
      case messageTypeImage:
        MessageImage messageImage = msg.decodeContent(cl: MessageImage.creator);
        if (chat!.isMute ||
            !objectMgr.pushMgr.getChatMuteStatus(chat.isSingle)) {
          if (messageImage.reply.isNotEmpty) {
            final data = ReplyModel.fromJson(json.decode(messageImage.reply));
            final mentionList = data.atUser.map((e) => e.userId).toList();

            if (objectMgr.userMgr.isMe(data.userId) ||
                (mentionList.isNotEmpty &&
                    mentionList.contains(objectMgr.userMgr.mainUser.uid))) {
              isShow = true;
              notificationType = 999;
            } else {
              isShow = false;
            }
          }
        }

        body = chat.isSingle
            ? localized(chatTagPhoto)
            : "$sendUser: ${localized(chatTagPhoto)}";
        break;
      case messageTypeVideo:
      case messageTypeReel:
        MessageVideo messageVideo = msg.decodeContent(cl: MessageVideo.creator);
        if (chat!.isMute ||
            !objectMgr.pushMgr.getChatMuteStatus(chat.isSingle)) {
          if (messageVideo.reply.isNotEmpty) {
            final data = ReplyModel.fromJson(json.decode(messageVideo.reply));
            final mentionList = data.atUser.map((e) => e.userId).toList();

            if (objectMgr.userMgr.isMe(data.userId) ||
                (mentionList.isNotEmpty &&
                    mentionList.contains(objectMgr.userMgr.mainUser.uid))) {
              isShow = true;
              notificationType = 999;
            } else {
              isShow = false;
            }
          }
        }

        body = chat.isSingle
            ? localized(chatTagVideoCall)
            : "$sendUser: ${localized(chatTagVideoCall)}";
        break;
      case messageTypeFace:
        MessageImage messageImage = msg.decodeContent(cl: MessageImage.creator);
        if (chat!.isMute ||
            !objectMgr.pushMgr.getChatMuteStatus(chat.isSingle)) {
          if (messageImage.reply.isNotEmpty) {
            final data = ReplyModel.fromJson(json.decode(messageImage.reply));
            final mentionList = data.atUser.map((e) => e.userId).toList();

            if (objectMgr.userMgr.isMe(data.userId) ||
                (mentionList.isNotEmpty &&
                    mentionList.contains(objectMgr.userMgr.mainUser.uid))) {
              isShow = true;
              notificationType = 999;
            } else {
              isShow = false;
            }
          }
        }

        body = chat.isSingle
            ? localized(chatTagSticker)
            : "$sendUser: ${localized(chatTagSticker)}";
        break;
      case messageTypeFile:
        MessageFile messageFile = msg.decodeContent(cl: MessageFile.creator);
        if (chat!.isMute ||
            !objectMgr.pushMgr.getChatMuteStatus(chat.isSingle)) {
          if (messageFile.reply.isNotEmpty) {
            final data = ReplyModel.fromJson(json.decode(messageFile.reply));
            final mentionList = data.atUser.map((e) => e.userId).toList();

            if (objectMgr.userMgr.isMe(data.userId) ||
                (mentionList.isNotEmpty &&
                    mentionList.contains(objectMgr.userMgr.mainUser.uid))) {
              isShow = true;
              notificationType = 999;
            } else {
              isShow = false;
            }
          }
        }

        body = chat.isSingle
            ? localized(chatTagFile)
            : "$sendUser: ${localized(chatTagFile)}";
        break;
      case messageEndCall:
      case messageRejectCall:
      case messageStartCall:
        return;
      case messageTypeAddReactEmoji:
        final emojiName = jsonDecode(msg.content)['emoji'];
        final recipientID = jsonDecode(msg.content)['recipient_id'];
        final reacter = jsonDecode(msg.content)['user_id'];
        User? data = objectMgr.userMgr.getUserById(reacter);
        sendUser = objectMgr.userMgr.getUserTitle(data);
        bool isMe = objectMgr.userMgr.isMe(recipientID);
        String emoji = '';
        if (isMe) {
          switch (emojiName) {
            case 'thumbs-up-2.json':
              emoji = '👍 ';
              break;
            case 'heart-1.json':
              emoji = '😍 ';
              break;
            case 'beaming-face.json':
              emoji = '👎 ';
              break;
            case 'astonished-face.json':
              emoji = '🔥 ';
              break;
            case 'angry-face.json':
              emoji = '😁 ';
              break;
            case 'anxious-face.json':
              emoji = '❤️ ';
              break;
            default:
              emoji = '';
          }
          body = '$sendUser ${localized(hasReactToAMessage, params: [emoji])}';
        } else {
          return;
        }

        break;
      case messageTypeDeleted:
      case messageTypeRemoveReactEmoji:
      case messageTypeBeingFriend:
      case messageTypeUnPin:
        isShow = false;
        break;
      case messageTypeGetRed:
        MessageRed msgRed = msg.decodeContent(cl: MessageRed.creator);
        String message = '';
        bool isMe = objectMgr.userMgr.isMe(msgRed.senderUid);
        if (isMe && !objectMgr.userMgr.isMe(msgRed.userId)) {
          User? data = objectMgr.userMgr.getUserById(msgRed.userId);

          sendUser = objectMgr.userMgr.getUserTitle(data);

          message = objectMgr.userMgr.isMe(msgRed.userId)
              ? localized(haveReceivedA)
              : localized(hasReceivedA);
        } else {
          isShow = false;
        }

        switch (msgRed.rpType.value) {
          case 'LUCKY_RP':
            body = "$sendUser $message ${localized(luckyRedPacket)}";
            break;

          case 'STANDARD_RP':
            body = "$sendUser $message ${localized(normalRedPacket)}";
            break;

          case 'SPECIFIED_RP':
            body = "$sendUser $message ${localized(exclusiveRedPacket)}";
            break;

          default:
            body = "$sendUser $message ${localized(none)}";
        }
        break;
      case messageTypeKickoutGroup:
        MessageSystem msgKickoutGroup =
            msg.decodeContent(cl: MessageSystem.creator);

        User? data = objectMgr.userMgr.getUserById(msgKickoutGroup.owner);
        bool isMe = objectMgr.userMgr.isMe(msgKickoutGroup.uid);

        // 临时群组不需要推送
        bool isTmp = false;
        if (chat != null && chat.isGroup) {
          Group? group = objectMgr.myGroupMgr.getGroupById(chat.chat_id);
          isTmp = group?.roomType == GroupType.TMP.num;
        }

        if (isMe && !isTmp) {
          String alias = objectMgr.userMgr.getUserTitle(data);
          body = '${localized(you)} ${localized(
            hasBeenRemovedBy,
            params: [
              alias,
            ],
          )}';
        } else {
          isShow = false;
        }

        break;
      case messageTypeGroupJoined:
        MessageSystem messageJoined =
            msg.decodeContent(cl: MessageSystem.creator);
        User? data = objectMgr.userMgr.getUserById(messageJoined.inviter);
        if (messageJoined.uids.contains(objectMgr.userMgr.mainUser.uid)) {
          body = '${data?.nickname ?? ''} ${localized(groupInvitedInGroup)}';
        } else {
          isShow = false;
        }
        break;
      case messageTypeSendRed:
        final curUID = ChatCellContentTextState().getCurUID(msg);
        MessageRed msgRed = msg.decodeContent(cl: MessageRed.creator);
        if (msgRed.rpType.value == "SPECIFIED_RP" &&
            msgRed.recipientIDs.contains(objectMgr.userMgr.mainUser.uid)) {
          body =
              '$sendUser ${ChatCellContentTextState().prepareContentString(msg, curUID)}';
        } else if (msgRed.rpType.value == "SPECIFIED_RP" &&
            !msgRed.recipientIDs.contains(objectMgr.userMgr.mainUser.uid)) {
          isShow = false;
        } else {
          body =
              '$sendUser ${ChatCellContentTextState().prepareContentString(msg, curUID)}';
        }
        break;
      case messageTypeGroupOwner:
        MessageSystem msgMultipleUid =
            msg.decodeContent(cl: MessageSystem.creator);
        bool isMe = objectMgr.userMgr.isMe(msgMultipleUid.owner);
        User? data = objectMgr.userMgr.getUserById(msgMultipleUid.owner);
        String alias = objectMgr.userMgr.getUserTitle(data);
        User? originalOwner = objectMgr.userMgr.getUserById(msgMultipleUid.uid);
        String originalAlias = objectMgr.userMgr.getUserTitle(originalOwner);
        if (isMe) {
          body = "$originalAlias ${localized(
            hasTransferOwnershipTo,
            params: [
              alias,
            ],
          )}";
        } else {
          isShow = false;
        }
        break;
      case messageTypeAutoDeleteInterval:
        MessageInterval msgInterval =
            msg.decodeContent(cl: MessageInterval.creator);
        String tempMessage = '';
        if (msgInterval.interval == 0) {
          tempMessage = ' ${localized(turnOffAutoDeleteMessage)}';
        } else if (msgInterval.interval < 60) {
          bool isSingular = msgInterval.interval == 1;
          tempMessage = ' ${localized(
            turnOnAutoDeleteMessage,
            params: [
              (localized(
                isSingular ? secondParam : secondsParam,
                params: [
                  "${msgInterval.interval}",
                ],
              )),
            ],
          )}';
        } else if (msgInterval.interval < 3600) {
          bool isSingular = msgInterval.interval ~/ 60 == 1;
          tempMessage = ' ${localized(
            turnOnAutoDeleteMessage,
            params: [
              (localized(
                isSingular ? minuteParam : minutesParam,
                params: [
                  "${msgInterval.interval ~/ 60}",
                ],
              )),
            ],
          )}';
        } else if (msgInterval.interval < 86400) {
          bool isSingular = msgInterval.interval ~/ 3600 == 1;
          tempMessage = ' ${localized(
            turnOnAutoDeleteMessage,
            params: [
              (localized(
                isSingular ? hourParam : hoursParam,
                params: [
                  "${msgInterval.interval ~/ 3600}",
                ],
              )),
            ],
          )}';
        } else if (msgInterval.interval < 2592000) {
          bool isSingular = msgInterval.interval ~/ 86400 == 1;
          tempMessage = ' ${localized(
            turnOnAutoDeleteMessage,
            params: [
              (localized(
                isSingular ? dayParam : daysParam,
                params: [
                  "${msgInterval.interval ~/ 86400}",
                ],
              )),
            ],
          )}';
        } else {
          bool isSingular = msgInterval.interval ~/ 2592000 == 1;
          tempMessage = ' ${localized(
            turnOnAutoDeleteMessage,
            params: [
              (localized(
                isSingular ? monthParam : monthsParam,
                params: [
                  "${msgInterval.interval ~/ 2592000}",
                ],
              )),
            ],
          )}';
        }
        bool isMe = objectMgr.userMgr.isMe(msgInterval.owner);

        User? data = objectMgr.userMgr.getUserById(msgInterval.owner);
        String alias = objectMgr.userMgr.getUserTitle(data);
        if (isMe) {
          isShow = false;
        } else {
          body = '$alias$tempMessage';
        }
        break;
      case messageTypePin:
        final curUID = ChatCellContentTextState().getCurUID(msg);
        MessagePin msgPin = msg.decodeContent(cl: MessagePin.creator);
        bool isMe = objectMgr.userMgr.isMe(msgPin.sendId);
        User? data = objectMgr.userMgr.getUserById(msgPin.sendId);
        String alias = objectMgr.userMgr.getUserTitle(data);
        if (isMe) {
          isShow = false;
        } else {
          body = chat!.isSingle
              ? ChatCellContentTextState().prepareContentString(msg, curUID)
              : '$alias ${ChatCellContentTextState().prepareContentString(msg, curUID)}';
        }

        break;
      case messageTypeCreateGroup:
      case messageTypeGroupAddAdmin:
      case messageTypeGroupRemoveAdmin:
        final curUID = ChatCellContentTextState().getCurUID(msg);
        MessageSystem msgSys = msg.decodeContent(cl: MessageSystem.creator);
        bool isMe = objectMgr.userMgr.isMe(msgSys.uid);
        User? data = objectMgr.userMgr.getUserById(msgSys.uid);
        String alias = objectMgr.userMgr.getUserTitle(data);
        if (isMe) {
          body = chat!.isSingle
              ? ChatCellContentTextState().prepareContentString(msg, curUID)
              : '$alias ${ChatCellContentTextState().prepareContentString(msg, curUID)}';
        } else {
          isShow = false;
        }
        break;
      case messageTypeExitGroup:
        isShow = false;
        break;
      case messageTypeChatScreenshot:
        final curUID = ChatCellContentTextState().getCurUID(msg);
        MessageSystem msgSys = msg.decodeContent(cl: MessageSystem.creator);
        bool isMe = objectMgr.userMgr.isMe(msgSys.uid);
        User? data = objectMgr.userMgr.getUserById(msgSys.uid);
        String alias = objectMgr.userMgr.getUserTitle(data);
        if (isMe) {
          isShow = false;
        } else {
          body =
              '$alias ${ChatCellContentTextState().prepareContentString(msg, curUID)}';
        }
        break;
      case messageTypeGroupChangeInfo:
      case messageTypeGroupMute:
      case messageTypeAudioChatOpen:
      case messageTypeAudioChatInvite:
      case messageTypeAudioChatClose:
      case messageTypeSysmsg:
      case messageTypeChatScreenshotEnable:
        if (msg.typ == messageTypeAudioChatOpen ||
            msg.typ == messageTypeAudioChatClose) {
          event(this, eventAudioChat, data: msg);
        }
        final curUID = ChatCellContentTextState().getCurUID(msg);
        MessageSystem msgSys = msg.decodeContent(cl: MessageSystem.creator);
        bool isMe = objectMgr.userMgr.isMe(msgSys.uid);
        User? data = objectMgr.userMgr.getUserById(msgSys.uid);
        String alias = objectMgr.userMgr.getUserTitle(data);
        if (isMe) {
          isShow = false;
        } else {
          body = chat!.isSingle
              ? ChatCellContentTextState().prepareContentString(msg, curUID)
              : '$alias ${ChatCellContentTextState().prepareContentString(msg, curUID)}';
        }
        break;
      case messageBusyCall:
      case messageCancelCall:
      case messageMissedCall:
        isCallMessage = true;
        MessageCall messageCall =
            msg.decodeContent(cl: MessageCall.creator, v: msg.content);
        if (!objectMgr.userMgr.isMe(messageCall.inviter)) {
          body =
              ChatCellContentTextState().prepareContentString(msg, msg.send_id);
          typ = 6;
          payload['is_missed_call'] = 1;
          payload['is_cancel_call'] = 1;
          break;
        } else {
          return;
        }
      case messageTypeEdit:
        return;
      case messageTypeExpiredSoon:
        MessageTempGroupSystem systemMsg =
            msg.decodeContent(cl: MessageTempGroupSystem.creator);
        body = localized(
          thisGroupWillBeAutoDisbanded,
          params: [formatToLocalTime(systemMsg.expire_time)],
        );
        break;
      case messageTypeExpiryTimeUpdate:
        MessageTempGroupSystem systemMsg =
            msg.decodeContent(cl: MessageTempGroupSystem.creator);
        bool isMe = objectMgr.userMgr.isMe(systemMsg.uid);
        if (isMe) {
          isShow = false;
        } else {
          String name = objectMgr.userMgr
              .getUserTitle(objectMgr.userMgr.getUserById(systemMsg.uid));
          body = localized(
            youHaveChangedTheGroupExpiryDate,
            params: [name, formatToLocalTime(systemMsg.expire_time)],
          );
        }
        break;
      default:
        if (chat!.isMute ||
            !objectMgr.pushMgr.getChatMuteStatus(chat.isSingle)) {
          final mentionList = msg.atUser.map((e) => e.userId).toList();
          if (mentionList.isNotEmpty &&
              mentionList.contains(objectMgr.userMgr.mainUser.uid)) {
            notificationType = 999;
            isShow = true;
          } else if (mentionList.isNotEmpty &&
              !mentionList.contains(objectMgr.userMgr.mainUser.uid)) {
            isShow = false;
          }
        }
        body = body = chat.isSingle || chat.isSystem
            ? ChatHelp.lastMsg(chat, msg).breakWord
            : '$sendUser: ${ChatHelp.lastMsg(chat, msg).breakWord}';
    }

    payload.addAll({
      'chat': chat,
      'typ': typ,
      "notification_type": 1,
    });

    if ((!Get.currentRoute.contains(msg.chat_id.toString())) && isShow) {
      objectMgr.pushMgr.showNotification(
        notificationType,
        id: msg.chat_idx,
        title: title,
        body: body,
        payLoad: jsonEncode(payload),
        isCallMessage: isCallMessage,
        chat: chat,
        lastMessage: msg,
      );
    }
  }

  Future<String> getSender(int sendID) async {
    String sendUser = '';
    User? data = objectMgr.userMgr.getUserById(sendID);
    if (data != null) {
      sendUser = objectMgr.userMgr.getUserTitle(data);
    } else if (sendID > 0) {
      final remoteUser = await objectMgr.userMgr.loadUserById2(sendID);
      if (remoteUser != null) {
        sendUser = objectMgr.userMgr.getUserTitle(remoteUser);
      }
    }
    return sendUser;
  }

  void processRedPacketMsg(Message msg) async {
    MessageRed msgRed = msg.decodeContent(cl: MessageRed.creator);
    int status = 0;

    final rpStatus = _redPacketStatusMap[msg.chat_id]
        ?.firstWhereOrNull((element) => element.id == msgRed.id);

    if (rpStatus == null) {
      Map<String, dynamic> redPacketData =
          await _localDB.getSingleRedPacketStatus(msgRed.id);
      status = redPacketData['status'] ?? 0;
      if (redPacketData.isNotEmpty) {
        RedPacketStatus rpStatus = RedPacketStatus.fromJson(redPacketData);

        if (_redPacketStatusMap.containsKey(rpStatus.chatId)) {
          final indexRp =
              _redPacketStatusMap[rpStatus.chatId]!.indexOf(rpStatus);
          if (indexRp != -1) {
            _redPacketStatusMap[rpStatus.chatId]![indexRp] = rpStatus;
          } else {
            _redPacketStatusMap[rpStatus.chatId]!.add(rpStatus);
          }
        } else {
          _redPacketStatusMap.putIfAbsent(
            rpStatus.chatId ?? msg.chat_id,
            () => [rpStatus],
          );
        }
      }
    } else {
      status = rpStatus.status ?? 0;
    }
    if (status != rpExpired &&
        status != rpNotInExclusive &&
        status != rpFullyClaimed) {
      _redPacketRequestList.add([msg, msgRed]);
    }
  }

  void processRemoteRedPacketMsg() async =>
      getRedPacketInfoByRemote(_redPacketRequestList)
          .then((List<RedPacketStatus> rpStatusList) {
        for (var rpStatus in rpStatusList) {
          if (_redPacketStatusMap.containsKey(rpStatus.chatId)) {
            final indexRp =
                _redPacketStatusMap[rpStatus.chatId]!.indexOf(rpStatus);
            if (indexRp != -1) {
              _redPacketStatusMap[rpStatus.chatId]![indexRp] = rpStatus;
            } else {
              _redPacketStatusMap[rpStatus.chatId]!.add(rpStatus);
            }
          } else {
            _redPacketStatusMap.putIfAbsent(rpStatus.chatId!, () => [rpStatus]);
          }

          _sharedDB.applyUpdateBlock(
            UpdateBlockBean.created(blockOptReplace, DBRedPacket.tableName, [
              rpStatus.toJson(),
            ]),
            notify: false,
          );

          event(this, eventRedPacketStatus, data: rpStatus);
        }
        _redPacketRequestList.clear();
      });

  Future<List<RedPacketStatus>> getRedPacketInfoByRemote(
    List<List<dynamic>> redPacketRequestList,
  ) async {
    List<MessageRed> msgRedList =
        redPacketRequestList.map<MessageRed>((e) => e.last).toList();
    List<String> rpIds = msgRedList
        .where((e) => e.id.isNotEmpty)
        .map<String>((e) => e.id)
        .toList();
    List<RedPacketDetail> rpDetailList =
        await walletServices.getRedPacketMultiple(rpID: rpIds);

    List<RedPacketStatus> result = [];

    /// 未过期， 红包领取完毕， 自己的状态不为已领取
    // 判断 领取
    if (redPacketRequestList.isNotEmpty) {
      for (int i = 0; i < rpDetailList.length; i++) {
        if (redPacketRequestList.length - 1 < i) continue;
        Message msg = redPacketRequestList[i].first;
        MessageRed msgRed = redPacketRequestList[i].last;
        final rpDetail = rpDetailList[i];

        bool redPacketIsExpired = false;
        // 判断 过期时间
        if (msgRed.expireTime < DateTime.now().millisecondsSinceEpoch) {
          redPacketIsExpired = true;
        }

        int status = 0;
        if (rpDetail.receiveInfos.isNotEmpty) {
          if (rpDetail.rpType != RedPacketType.exclusiveRedPacket) {
            for (ReceiveInfo info in rpDetail.receiveInfos) {
              if (info.userId! == objectMgr.userMgr.mainUser.uid) {
                // 如果有自己， 判断是否领取， 未领取代表是专属红包
                if (info.receiveFlag!) {
                  status = rpReceived;
                }
              }
            }

            if (status != rpReceived) {
              if (rpDetail.receiveNum == rpDetail.totalNum) {
                if (!redPacketIsExpired) {
                  status = rpYetReceive;
                } else {
                  status = rpFullyClaimed;
                }
              }

              if (redPacketIsExpired) {
                status = rpExpired;
              }
            }

            // 如果上述判断都没有， 代表 红包是可领取状态并且还没被领取
            if (status == 0) {
              status = rpYetReceive;
            }
          } else {
            // 专属红包判断
            // 2) 专属红包是否过期了
            /// 未领取 并且 在专属红包里
            for (ReceiveInfo info in rpDetail.receiveInfos) {
              if (info.userId! == objectMgr.userMgr.mainUser.uid) {
                // 如果有自己， 判断是否领取， 未领取代表是专属红包
                if (info.receiveFlag!) {
                  status = rpReceived;
                } else {
                  status = rpYetReceive;
                }
              }
            }

            if (status != rpReceived) {
              if (redPacketIsExpired) {
                status = rpExpired;
              }

              if (status == 0) {
                status = rpYetReceive;
              }
            }
          }
        } else {
          if (redPacketIsExpired) {
            status = rpExpired;
          } else {
            status = rpYetReceive;
          }
        }

        result.add(
          RedPacketStatus.fromJson({
            'id': rpDetail.id,
            'message_id': msg.message_id,
            'chat_id': msg.chat_id,
            'user_id': msg.send_id,
            'status': status,
          }),
        );
      }
    }

    _redPacketRequestList.clear();

    return result;
  }

  void sortMessage(List<Message> messages, {bool ascending = false}) {
    messages.sort((a, b) {
      if (!ascending) {
        return (b.chat_idx * 10000 + b.create_time * 10 + b.send_time ~/ 100) -
            (a.chat_idx * 10000 + a.create_time * 10 + a.send_time ~/ 100);
      } else {
        return (a.chat_idx * 10000 + a.create_time * 10 + a.send_time ~/ 100) -
            (b.chat_idx * 10000 + b.create_time * 10 + b.send_time ~/ 100);
      }
    });
  }

  /// 清空聊天记录
  Future<ResponseData> clearMessage(
    Chat chat, {
    bool isAll = false,
    bool showToast = true,
    bool isStickBottom = true,
  }) async {
    chat.setValue('hide_chat_msg_idx', chat.msg_idx);
    mentionMessageMap[chat.chat_id] = {};
    _removeLocalMessages(chat, chat.msg_idx);
    if (showToast) {
      Toast.showToast(
        localized(chatInfoClearHistorySuccessful),
      );
    }
    try {
      int? friendId = chat.isSingle ? chat.friend_id : null;

      var rep = await chat_api.clear_message(
        chat.chat_id,
        chat.msg_idx,
        friendId: friendId,
        isAll: isAll,
      );

      return rep;
    } on AppException catch (e) {
      return ResponseData(code: -1, message: e.toString());
    }
  }

  /// 不显示(删除)
  Future<void> setChatHide(Chat chat) async {
    chat.cover_idx = chat.msg_idx;
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBChat.tableName,
        [
          {
            'id': chat.id,
            'cover_idx': chat.cover_idx,
          }
        ],
      ),
      save: true,
      notify: false,
    );
    updateHideChatFlag(chat);
    await chat_api.setCover(chat.id, chat.msg_idx);
  }

  updateHideChatFlag(Chat chat) async {

    event(this, ChatMgr.eventChatHide, data: chat);

    if (!chat.isMute) {
      updateLocalTotalUnreadNumFromDB();
    }
  }

  sortChatList(List<Chat> chats) {
    chats.sort((a, b) {
      /// 置顶
      if (a.sort != b.sort) {
        return b.sort - a.sort;
      }
      Message? lastMessageA = lastChatMessageMap[a.id];
      Message? lastMessageB = lastChatMessageMap[b.id];

      if (lastMessageA != null && lastMessageB != null) {
        return lastMessageB.create_time - lastMessageA.create_time;
      } else if (lastMessageA != null) {
        return -1;
      } else if (lastMessageB != null) {
        return 1;
      } else {
        return b.create_time - a.create_time;
      }
    });
  }

  setChatTop(Chat chat, int sort) async {
    await chat_api.set_sort(objectMgr.userMgr.mainUser.uid, chat.id, sort);
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(blockOptReplace, DBChat.tableName, [
        {"id": chat.id, "sort": sort},
      ]),
      save: true, // 不需要保存
      notify: true,
    );

    /// 在socket连接时，doChatChange会发送event刷新聊天列表排序
    /// 所以在此判断无网络时，才需要发送event，避免重复刷新聊天列表
    if (!objectMgr.socketMgr.isConnect) {
      chatListEvent.event(
        chatListEvent,
        ChatListEvent.eventChatPinnedUpdate,
        data: {
          'chat_id': chat.id,
          'sort': sort,
        },
      );
    }
  }

  /// 获取置顶消息
  void getPinnedMessageByRemote(List<Chat> chats) async {
    try {
      final res =
          await chat_api.get_pin_message(chats.map<int>((e) => e.id).toList());
      if (res.success()) {
        final data = res.data;
        for (int i = 0; i < data.length; i++) {
          final pinData = data[i];

          Chat? chat = getChatById(pinData['id']);
          if (chat != null) {
            if (!chat.isValid) {
              if (notBlank(chat.getValue('pin')) &&
                  chat.getValue('pin', <Message>[]) is! List<Message>) {
                if (chat.getValue('pin') is String) {
                  chat.pin = jsonDecode(chat.getValue('pin'))
                      .map<Message>((e) => Message()..init(e))
                      .toList();
                } else {
                  chat.pin = chat
                      .getValue('pin')
                      .map<Message>((e) => Message()..init(e))
                      .toList();
                }
              }
              if (chat.pin.isEmpty) continue;

              for (int i = 0; i < chat.pin.length; i++) {
                final message = chat.pin[i];
                if (message.isEncrypted && chat.isActiveChatKeyValid) {
                  MessageMgr.decodeMsg(
                      message, chat, objectMgr.userMgr.mainUser.uid);
                }
                if (message.typ == messageTypeSendRed) {
                  processRedPacketMsg(message);
                }
              }

              pinnedMessageList[chat.id] = chat.pin;
              continue;
            }
          }

          List<Message> filteredPinnedMessageList =
              pinData['pin'].map<Message>((e) => Message()..init(e)).toList();
          for (int i = 0; i < filteredPinnedMessageList.length; i++) {
            final message = filteredPinnedMessageList[i];
            if (chat != null &&
                message.isEncrypted &&
                chat.isActiveChatKeyValid) {
              MessageMgr.decodeMsg(
                  message, chat, objectMgr.userMgr.mainUser.uid);
            }
            if (message.typ == messageTypeSendRed) {
              processRedPacketMsg(message);
            }
          }

          pinnedMessageList[pinData['id']] = filteredPinnedMessageList;
          _sharedDB.applyUpdateBlock(
            UpdateBlockBean.created(
              blockOptUpdate,
              DBChat.tableName,
              {
                'id': pinData['id'],
                'pin': jsonEncode(filteredPinnedMessageList),
              },
            ),
            save: true,
            notify: false,
          );
        }
      }
    } on AppException catch (_) {
      for (int i = 0; i < chats.length; i++) {
        final chat = chats[i];
        if (!chat.isValid) {
          if (notBlank(chat.getValue('pin')) &&
              chat.getValue('pin', <Message>[]) is! List<Message>) {
            if (chat.getValue('pin') is String) {
              chat.pin = jsonDecode(chat.getValue('pin'))
                  .map<Message>((e) => Message()..init(e))
                  .toList();
            } else {
              chat.pin = chat
                  .getValue('pin')
                  .map<Message>((e) => Message()..init(e))
                  .toList();
            }
          }
          if (!notBlank(chat.pin)) continue;

          for (int i = 0; i < chat.pin.length; i++) {
            final message = chat.pin[i];
            if (message.typ == messageTypeSendRed) {
              processRedPacketMsg(message);
            }
          }

          pinnedMessageList[chat.id] = chat.pin;
          continue;
        }

        for (int i = 0; i < chat.pin.length; i++) {
          final message = chat.pin[i];
          if (message.isEncrypted && chat.isActiveChatKeyValid) {
            MessageMgr.decodeMsg(message, chat, objectMgr.userMgr.mainUser.uid);
          }
          if (message.typ == messageTypeSendRed) {
            processRedPacketMsg(message);
          }
        }

        if (!notBlank(chat.pin)) continue;
        pinnedMessageList[chat.id] = chat.pin;
      }
    }

    if (_redPacketRequestList.isNotEmpty) {
      processRemoteRedPacketMsg();
    }
  }

  /// 置顶消息
  void onPinMessage(int chatId, int messageId) async {
    final res = await chat_api.pin_message(chatId, messageId);
    if (res.message == 'OK') {
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(msgPinSucceeded),
        icon: ImBottomNotifType.pin,
      );
    }
  }

  void onUnpinMessage(int chatId, int messageId) async {
    try {
      await chat_api.unpin_message(chatId, messageId);
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  void onUnpinAllMessage(int chatId, List<int> messageIds) async {
    try {
      await chat_api.unpin_all(chatId, messageIds);

      for (final msgId in messageIds) {
        pinnedMessageList[chatId]?.removeWhere(
          (element) => element.id == msgId,
        );
      }

      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(toastUnpinAllMessage),
        icon: ImBottomNotifType.pin,
      );
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  void localPinMessage(bool isPin, int chatId, Message message) {
    if (isPin) {
      pinnedMessageList[chatId]?.add(message);
    } else {
      pinnedMessageList[chatId]?.removeWhere(
        (element) => element.id == message.id,
      );
    }

    event(this, ChatMgr.eventChatLocalPinnedMessage, data: {
      "isPin": isPin,
      "chatId": chatId,
      "msg": message,
    });
  }

  void onLocalPinFail(Retry retry, bool isSuccess) {
    if (!isSuccess) {
      final data = RequestData.fromJson(jsonDecode(retry.requestData) ?? {});
      if (data.data is Map<String, dynamic> &&
          data.data.containsKey('chat_id') &&
          data.data.containsKey('message_id')) {
        int chatId = data.data['chat_id']!;
        int messageId = data.data['message_id'];

        pinnedMessageList[chatId]?.removeWhere(
          (element) => element.message_id == messageId,
        );

        event(this, ChatMgr.eventChatLocalPinnedMessage, data: {
          "isPin": false,
          "isFail": true,
          "chatId": data.data['chat_id'],
          "message_id": data.data['message_id'],
        });
      }
    }
  }

  /// 消息免打扰
  Future<ResponseData> setMsgMute(int chatID, int mute) async {
    var rep = await chat_api.set_msg_mute(
      objectMgr.userMgr.mainUser.uid,
      chatID,
      mute,
    );
    if (!rep.success()) {
      Toast.showToast(rep.message, code: rep.code);
    } else {
      _sharedDB.applyUpdateBlock(
        UpdateBlockBean.created(blockOptReplace, DBChat.tableName, [
          {"id": chatID, "mute": mute, "flag_my": rep.data},
        ]),
        save: true,
        notify: false,
      );
    }
    return rep;
  }

  /// 设置已读
  sendReadMessageIdx(int chatID, int idx) async {
    final data = {
      "user_id": objectMgr.userMgr.mainUser.uid,
      "chat_id": chatID,
      "msg_idx": idx,
    };
    socketSend(ACTION_SETREAD_MSG, data);
  }

  ///获取草稿
  List<DraftModel> draftList = [];

  openChatDraft() async {
    var localDraft = objectMgr.localStorageMgr.getLocalTable(draftMessage);
    if (localDraft != null) {
      draftList = localDraft.map((e) => DraftModel()..applyJson(e)).toList();
    }
  }

  DraftModel? getChatDraft(int chatId) {
    for (var item in draftList) {
      if (chatId == item.chatId) {
        return item;
      }
    }
    return null;
  }

  ///存入草稿
  saveChatDraft(int chatId, String input) {
    bool needUpdate = false;
    DraftModel? draft = getChatDraft(chatId);

    String trimmedInput = input.trim(); // 防止只是空格
    if (trimmedInput.isNotEmpty) {
      trimmedInput = input;
    }

    if (draft != null) {
      if (draft.input != trimmedInput) {
        needUpdate = true;
        draft.input = trimmedInput;
      }
    } else {
      if (trimmedInput.isNotEmpty) {
        needUpdate = true;
        draftList.add(
          DraftModel()..applyJson({'chat_id': chatId, 'input': trimmedInput}),
        );
      }
    }
    if (needUpdate) {
      objectMgr.localStorageMgr.putLocalTable(
        draftMessage,
        jsonEncode(draftList.map((e) => e.toJson()).toList()),
      );
      event(this, '${chatId}_$eventDraftUpdate');
    }
  }

  void reflectDraftStringInstant(int chatId, String text) {
    event(
      this,
      '${chatId}_${eventDraftUpdate}_instant',
      data: <String, dynamic>{
        'chat_id': chatId,
        'text': text,
      },
    );
  }

  /// 发送消息 (语音)
  Future<ResponseData> sendAutoDeleteInterval(int chatID, int interval) async {
    try {
      return await chat_api.setAutoDeleteInterval(chatID, interval);
    } catch (e) {
      rethrow;
    }
  }

  ///输入状态推送
  void chatInput(
    int targetId, //对方id
    ChatInputState state, //true显示 false取消
    int chatId, //会话id
  ) async {
    Map data = {
      'target_id': targetId,
      'state': state.value,
      'chat_id': chatId,
    };
    socketSend(ACTION_SENDINPUT_MSG, data);
  }

  /// 设置截图
  Future<void> setScreenshotEnable(int chatID, int enable) async {
    try {
      var res = await chat_api.setScreenshot(chatID, enable);
      if (res.success()) {
        imBottomToast(
          navigatorKey.currentContext!,
          title: localized(
            enable == 1 ? screenshotTurnedOn : screenshotTurnedOff,
            params: [localized(you)],
          ),
          icon: ImBottomNotifType.success,
          duration: 3,
        );
      }
    } catch (e) {
      if (e is AppException) {
        Toast.showToast(e.getMessage());
      } else {
        Toast.showToast(e.toString());
      }
    }
  }

  Future<Map<String, String>> getMessageTranslation(
    String text, {
    String locale = "EN",
    int? chatId,
    int? chatIdx,
    Message? message,
    int visualType = 0,
  }) async {
    if (message != null) {
      chatId = message.chat_id;
      chatIdx = message.chat_idx;
    }
    String translated = await TranslationMgr()
        .translate(text, locale, chatId: chatId, chatIdx: chatIdx);
    if (message != null && translated != '') {
      Message? newMsg;
      newMsg = message.addTranslation(locale, translated, visualType);
      saveNewMessageContent(newMsg, "eventMessageTranslate");
    }
    return {
      'translation': translated,
      'locale': locale,
    };
  }

  saveNewMessageContent(Message message, String event) async {
    await _localDB.updateMessageContent(message);
    message.event(message, event, data: message);
  }

  saveTranslationToChat(Chat chat) {
    _localDB.updateChatTranslation(chat);
    event(this, "eventChatTranslateUpdate", data: chat);
  }

  Future<String?> updateEditedMsgTranslation(Message message) async {
    TranslationModel? translationModel = message.getTranslationModel();

    if (translationModel == null) return '';

    /// if ain't my msg then check is auto and what is the locale
    String locale = translationModel.currentLocale;
    if (!objectMgr.userMgr.isMe(message.send_id)) {
      Chat? chat = getChatById(message.chat_id);
      if (chat != null && chat.isAutoTranslateIncoming) {
        locale = chat.currentLocaleIncoming == 'auto'
            ? getAutoLocale(chat: chat, isMe: false)
            : chat.currentLocaleIncoming;
      }
    }

    /// don't pass message into api, prevent redis get wrong translation
    if (translationModel.showTranslation) {
      final res = await getMessageTranslation(
        message.messageContent,
        locale: locale,
        visualType: translationModel.visualType,
      );
      if (res['translation'] != '') {
        Message? newMsg;
        newMsg = message.addTranslation(
          locale,
          res['translation']!,
          translationModel.visualType,
        );
        saveNewMessageContent(newMsg, "eventMessageTranslate");
        return res['translation']!;
      }
    }
    return '';
  }

  bool isInCurrentChat(int chatId) {
    return Get.isRegistered<SingleChatController>(tag: chatId.toString()) ||
        Get.isRegistered<GroupChatController>(tag: chatId.toString());
  }

  Future<File?> getTextToVoice(
    String text,
    String locale,
    Message message, {
    bool isMale = false,
  }) async {
    String path = await downloadMgr.getTmpCachePath(
      '${message.message_id}_${message.edit_time}_$locale',
      sub: 'tts',
      create: false,
    );
    final f = File(path);
    if (f.existsSync()) {
      // convert before skip api
      if (f.lengthSync() == 0) {
        // special character can't be convert
        return null;
      } else {
        return f;
      }
    }

    if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
      Toast.showToast(localized(connectionFailedPleaseCheckTheNetwork));
      return null;
    }
    // create file and trigger api
    await File(path).create(recursive: true);

    bool isSuccess = await chat_api.getTextToVoiceAPI(text, isMale, path);
    if (isSuccess) {
      File file = File(path);
      if (file.lengthSync() == 0) {
        // special character can't be convert
        return null;
      } else {
        return file;
      }
    } else {
      // if fail will delete the file
      await File(path).delete();
    }

    return null;
  }

  generateFailSystemMessage(Message message) async {
    int errorCode = message.failMessageErrorCode;
    if (errorCode == ErrorCodeConstant.STATUS_USER_ME_IN_BLACKLIST ||
        errorCode == ErrorCodeConstant.STATUS_USER_HE_IN_BLACKLIST) {
      Message newMsg = Message();
      newMsg.chat_id = message.chat_id;
      newMsg.typ = messageTypeInBlock;
      newMsg.content = message.content;
      newMsg.create_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      newMsg.send_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      newMsg.send_id = objectMgr.userMgr.mainUser.uid;
      newMsg.chat_idx = message.chat_idx;
      newMsg.sendState = MESSAGE_SEND_FAIL;
      saveMessage(newMsg);
      event(objectMgr.chatMgr, ChatMgr.eventMessageSend, data: newMsg);
    } else if (errorCode == ErrorCodeConstant.STATUS_NOT_IN_CHAT) {
      Message newMsg = Message();
      newMsg.chat_id = message.chat_id;
      newMsg.typ = messageTypeNotFriend;
      newMsg.content = message.content;
      newMsg.create_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      newMsg.send_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      newMsg.send_id = objectMgr.userMgr.mainUser.uid;
      newMsg.chat_idx = message.chat_idx;
      newMsg.sendState = MESSAGE_SEND_FAIL;
      saveMessage(newMsg);
      event(objectMgr.chatMgr, ChatMgr.eventMessageSend, data: newMsg);
    }
  }

  void removeMentionCache(int chatId, int chatIdx) {
    if (mentionMessageMap[chatId] != null) {
      final mentionMsgList = mentionMessageMap[chatId]!
          .values
          .where(
            (m) => m.chat_idx <= chatIdx && m.isSendOk && m.message_id != 0,
          )
          .map((m) => m.message_id)
          .toList();

      mentionMessageMap[chatId]!
          .removeWhere((key, value) => mentionMsgList.contains(key));
    }
  }

  Future<bool> sendChatEncryptionSetting(int chatId, int flag) async {
    bool isEncrypted = ChatHelp.hasEncryptedFlag(flag);
    bool success = false;
    try {
      success = await chat_api.setE2E(chatId, isEncrypted ? 1 : 0);
    } catch (e) {
      rethrow;
    }

    return success;
  }

  Future<void> updateDatabaseEncryptionSetting(
    Chat chat,
    int flag, {
    int? round,
    String? chatKey,
    int? chatRound,
    String? activeChatKey,
    int? activeRound,
  }) async {
    chat.flag = flag;
    if (round != null) {
      if (round < chat.round) {
        chat.round = round;
      } else {
        round = chat.round;
      }
    }
    if (notBlank(chatKey) && chatRound != null) {
      chat.updateChatKey(chatKey!, chatRound);
    }
    if (notBlank(activeChatKey) && activeRound != null) {
      chat.updateActiveChatKey(activeChatKey!, activeRound);
    }

    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBChat.tableName,
        [chat.toJson()],
      ),
      notify: false,
    );

    event(this, eventChatEncryptionUpdate, data: chat);
    event(this, eventDecryptChat, data: [chat]);
  }

  //加你自己要的同步参数
  Future<void> updateEncryptionKeys(List<Chat> chats) async {
    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBChat.tableName,
        chats.map((e) => e.toJson()).toList(),
      ),
      notify: false,
    );
    event(this, eventDecryptChat, data: chats);
  }

  void decryptChat(List<Chat> chats) {
    for (Chat chat in chats) {
      List<Message> encryptedMessages = _chatMessageMap[chat.chat_id]
              ?.values
              .where((element) => element.isEncrypted)
              .toList() ??
          [];
      if (encryptedMessages.isNotEmpty) {
        for (var message in encryptedMessages) {
          MessageMgr.decodeMsg(message, chat, objectMgr.userMgr.mainUser.uid);
        }
      }
    }
  }

  Future<bool> onChatCategoryAllMute(
    Chat chat, {
    bool isMute = true,
  }) async {
    try {
      final int expireTime = isMute ? -1 : 0;
      final res = await muteSpecificChat(chat.id, expireTime);
      if (res.success()) {
        chat.mute = expireTime;
        updateNotificationStatus(chat, expireTime);
        return true;
      }

      return false;
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
      rethrow;
    }
  }

  Future<List<Chat>> getRecentChatList() async {
    List<Chat> chats = [];
    final json =
        await objectMgr.localStorageMgr.read(LocalStorageMgr.RECENT_CHAT) ?? '';
    if (notBlank(json)) {
      List<dynamic> jsonList = jsonDecode(json);
      if (jsonList.isNotEmpty) {
        for (int id in jsonList) {
          Chat? chat = objectMgr.chatMgr.getChatById(id);
          if (chat != null) {
            if (!chat.isVisible) {
              if (chat.isSingle) {
                User? user =
                    await objectMgr.userMgr.loadUserById(chat.friend_id);
                if (user?.relationship != Relationship.friend) {
                  continue;
                }
              }
            }
            chats.add(chat);
          }
        }
      }
    }
    return chats;
  }

  // 退出登录
  @override
  Future<void> cleanup() async {
    _chatMessageMap.clear();
    _reactEmojiMap.clear();
    _redPacketStatusMap.clear();
    _lastChatMessageMap.clear();
    chatCategoryList.clear();
    chatCategoryUnreadCount.clear();
    pinnedMessageList.clear();
    mentionMessageMap.clear();
    totalUnreadCount.value = 0;
    _chatTable = null;
    event(this, eventUnreadTotalCount);

    objectMgr.socketMgr.off(SocketMgr.eventSocketClose, _onSocketClosed);
    objectMgr.socketMgr
        .off(SocketMgr.updateChatReadBlock, _onReadMessageUpdate);

    objectMgr.sysOprateMgr.off(SysOprateMgr.eventChatInput, _onChatInput);

    VolumePlayerService.sharedInstance.logout();
    clear();
  }
}
