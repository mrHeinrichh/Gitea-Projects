import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/db_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

class LoadMsgBlock {
  Chat? chat;
  int count = 0;
  int fromChatIdx = 0;
  int forward = 0;
  int fromTime = 0;

  LoadMsgBlock(Chat chat, int count, int fromChatIdx, int forward, int fromTime) {
    this.chat = chat;
    this.count = count;
    this.fromChatIdx = fromChatIdx;
    this.forward = forward;
    this.fromTime = fromTime;
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'fromChatIdx': fromChatIdx,
      'forward': forward,
      'fromTime': fromTime,
      'chat': chat!.toJson()
    };
  }

  factory LoadMsgBlock.fromJson(Map<String, dynamic> json) {
    return LoadMsgBlock(Chat()..init(json['chat']), json['count'],
        json['fromChatIdx'], json['forward'], json['fromTime']);
  }
}

class ChatMessageTask extends ScheduleTask {
  ChatMessageTask({int delay = 1 * 100, bool isPeriodic = true})
      : super(delay, isPeriodic);
  Set<int> _visitedChatItemList = <int>{};
  List<Chat> _chatItemList = <Chat>[];
  List<LoadMsgBlock> _LoadMsgBlockList = <LoadMsgBlock>[];
  static DBInterface? _db;

  @override
  execute() async {
    if (_chatItemList.isEmpty && _LoadMsgBlockList.isEmpty) {
      return;
    }
    RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;

    ReceivePort receivePort = ReceivePort();
    List<Map<String, dynamic>> chatItemJson =
        _chatItemList.map((e) => e.toJson()).toList();
    _chatItemList.clear();
    List<Map<String, dynamic>> loadMsgBlockJson =
        _LoadMsgBlockList.map((e) => e.toJson()).toList();
    _LoadMsgBlockList.clear();

    int uid = objectMgr.userMgr.mainUser.uid;
    final isolate = await Isolate.spawn<List<dynamic>>(executeFuture, [
      uid,
      chatItemJson,
      loadMsgBlockJson,
      receivePort.sendPort,
      rootIsolateToken
    ]);

    final List<Message> messages = await receivePort.first;
    if (messages.isNotEmpty) {
      Map<int, List<Message>> groupedMessages =
          groupBy(messages, (Message message) => message.chat_id);
      groupedMessages.forEach((key, value) {
        objectMgr.chatMgr.processLocalMessage(value);
      });
    }
    
    isolate.kill(priority: Isolate.immediate);
  }

  static Future<void> executeFuture(List<dynamic> args) async {
    final uid = args[0] as int;
    final chatListData = args[1] as List<Map<String, dynamic>>;
    final loadMsgBlockList = args[2] as List<Map<String, dynamic>>;
    final sendPort = args[3] as SendPort;
    final rootIsolateToken = args[4] as RootIsolateToken;
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

    if (_db == null) {
      _db = DBManager();
      await _db!.init(uid, false);
    }

    List<Chat> chats = [];
    for (final chatData in chatListData) {
      Chat chat = Chat()..init(chatData);
      chats.add(chat);
    }
    List<Message> messagesList = await loadLocalMessages(_db!, chats);

    List<LoadMsgBlock> blocks = [];
    for (final loadMsgBlock in loadMsgBlockList) {
      LoadMsgBlock block = LoadMsgBlock.fromJson(loadMsgBlock);
      blocks.add(block);
    }

    List<Future<List<Message>>> messageFuts = [];
    for (final block in blocks) {
      messageFuts.add(loadMessages(_db!, block));
    }

    List<List<Message>> messages = await Future.wait(messageFuts);
    for (final list in messages) {
      messagesList.addAll(list);
    }

    sendPort.send(messagesList);
  }

  static Future<List<Message>> loadMessages(
      DBInterface db, LoadMsgBlock block) async {
    List<Message> messages = await ChatMgr.loadDBMessages(
      _db!,
      block.chat!,
      count: block.count,
      fromChatIdx: block.fromChatIdx,
      forward: block.forward,
      fromTime: block.fromTime,
    );

    //从网络只加载更久的消息暂时不做，先注释掉
    /*if(messages.isEmpty){
      messages = await ChatMgr.loadNetMessages(block.chat!, fromChatIdx: block.fromChatIdx, forward: block.forward, count: block.count);
    }*/
    return messages;
  }

  static Future<List<Message>> loadLocalMessages(
      DBInterface db, List<Chat> chats) async {
    List<Future<List<Message>>> fetchTasks = [];
    for (final chat in chats) {
      if (chat.isVisible) {
        Future<List<Message>> messageDataFuture =
            loadLocalChatMessages(db, chat);
        fetchTasks.add(messageDataFuture);
      }
    }
    List<List<Message>> messages = await Future.wait(fetchTasks);
    return messages.expand((x) => x).toList();
  }

  static Future<List<Message>> loadLocalChatMessages(
      DBInterface db, Chat chat) async {
    List<Map<String, dynamic>> messageListData = [];
    DateTime now = DateTime.now();
    if (chat.msg_idx - chat.read_chat_msg_idx >= messagePreLoadCount) {
      messageListData = await db.loadMessagesByWhereClause(
              "chat_id = ? AND chat_idx > ? AND chat_idx > ? AND typ != ? AND typ != ? AND deleted != 1 AND (expire_time == 0 OR expire_time >= ?)",
              [
                chat.id,
                chat.read_chat_msg_idx <= messagePreLoadCount
                    ? 0
                    : chat.read_chat_msg_idx - messagePreLoadCount,
                chat.hide_chat_msg_idx,
                messageTypeAddReactEmoji,
                messageTypeRemoveReactEmoji,
                now.millisecondsSinceEpoch ~/ 1000
              ],
              "asc",
              messagePreLoadCount * 2) ??
          [];

      /// 上下加载需要x2

      messageListData = messageListData.reversed.toList();
    } else {
      messageListData = await db.loadMessagesByWhereClause(
              "chat_id = ? AND chat_idx > ? AND chat_idx <= ? AND deleted != 1 AND (expire_time == 0 OR expire_time >= ?)",
              [
                chat.id,
                chat.hide_chat_msg_idx,
                chat.msg_idx,
                now.millisecondsSinceEpoch ~/ 1000
              ],
              "desc",
              messagePreLoadCount) ??
          [];
    }

    List<Message> messages = [];
    for (final messageData in messageListData) {
      Message message = Message()..init(messageData);
      messages.add(message);
    }

    return messages;
  }

  void preLoadDBMessages(Chat chat,
      {required int count, int fromChatIdx = 0, int forward = 0, int fromTime = 0}) async {
    LoadMsgBlock block = LoadMsgBlock(chat, count, fromChatIdx, forward, fromTime);
    _LoadMsgBlockList.add(block);
  }

  void addChatItem(Chat chat, {bool force = false}) async {
    if (_visitedChatItemList.contains(chat.id) && !force) return;
    _visitedChatItemList.add(chat.id);
    _chatItemList.add(chat);
  }
}
