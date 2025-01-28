import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/services.dart';
import 'package:jxim_client/api/socket.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_message.dart';
import 'package:jxim_client/data/db_thread.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/encryption_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/encryption/aes_encryption.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

class MessageMgr extends EventDispatcher {
  // 最大批量拉取消息数量
  static const int MAX_BATCH_FETCH_MSG_SIZE = 500;

  // 最大批量保存消息数量
  static const int MSG_BATCH_SAVE_SIZE = 1000;

  // 最大消息重复拉取次数
  static const int MAX_FETCH_RETRY_TIMES = 3;

  // 拉取消息每批睡眠间隔
  static const int FETCH_INTERVAL_SLEEP = 1;

  // 下拉消息最大重试次数
  static const int DROP_DOWN_MSG_FETCH_RETRY_TIMES = 3;

  // 加载消息请求发送端口
  static SendPort? _fetchingChatSendPort;

  // 解密消息请求发送端口
  static SendPort? _decryptChatSendPort;

  static SendPort? _dbSendPort;

  // 消息处理发送端口
  static SendPort? _msgContentSendPort;

  // 下拉消息拉取请求发送端口
  static SendPort? _dropDownMsgFetchSendPort;

  // 消息处理回调方法
  static Function? _consumeMsgFunc;

  // 下拉消息处理回调方法（暂未使用）
  static Function? _consumeDropDownMsgFunc;

  // 消息状态变更回调方法
  static Function? _onLoadStatusChangeFunc;

  // 消息预处理回调方法
  static Function? _msgPreHandleFunc;

  // 消息加载完毕
  static const int LOAD_STATUS_DONE = 2;

  // 新设备历史消息拉取最大条数
  static const int MAX_FETCH_SIZE = 10000;

  // 在第一条未读消息前拉取的消息条数
  static const int FETCH_BEFORE_UNREAD_SIZE = 1000;

  // 最大数据库重试次数
  static const int MAX_DB_RETRY_TIMES = 3;

  // 定时检查间隔
  static const int CHECK_DURATION_MS = 1000;

  // 最大消息延迟
  static const int MAX_MSG_LATENCY = 2000;

  // 消息冷表分表月份数
  static const int COLD_MESSAGE_SUB_MONTH = 1;

  // 记录每个聊天室最新的消息idx
  static Map<int, int>? _chatLastIdxMap;

  bool _isInit = false;

  // 记录后端推送了多少batch消息次数
  int _batchCount = 0;

  Isolate? _isolate;

  ReceivePort? _fetchingChatSpReceivePort;
  ReceivePort? _msgContentSpReceivePort;
  ReceivePort? _historyMsgReqReceivePort;
  ReceivePort? _msgConsumeReceivePort;
  ReceivePort? _otherMsgReceivePort;
  ReceivePort? _loadStatusReceivePort;
  ReceivePort? _dropDownMsgFetchSpReceivePort;
  ReceivePort? _dropDownMsgConsumeReceivePort;

  ReceivePort? _decryptChatReceivePort;
  ReceivePort? _dbReceivePort;

  /// 触发加载下拉消息
  void loadDropDownMsg(int chatId, int lastPos, int count) async {
    try {
      while (true) {
        if (_dropDownMsgFetchSendPort != null) {
          FetchingMsgChat fetchingMsgChat =
              FetchingMsgChat.newDropDown(chatId, lastPos, count);
          _dropDownMsgFetchSendPort!.send(fetchingMsgChat);
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e, trace) {
      pdebug(e);
      pdebug(trace);
    }
  }

  /// 拉取指定聊天室的历史消息
  /// 触发时机：
  ///   1. 新聊天建立
  ///   2. 重新加入群组
  ///   3. Socket连接建立完成
  ///   4. 消息重发，仅当在该流程中检测到重发消息已存在于服务端时
  void loadMsg(List<Chat> chats, {bool addLog = false}) async {
    // 修改APP状态为“收取中”
    if (objectMgr.socketMgr.socket == null ||
        !objectMgr.socketMgr.socket!.open) {
      //_onLoadStatusChangeFunc!(LOAD_STATUS_DONE);
      return;
    }

    if (chats.isEmpty) {
      return;
    }

    _messageLog.updateInfo(
      MessageModule.message_fetch,
      startTime: DateTime.now().millisecondsSinceEpoch,
    );

    // 等待初始化完成，或者执行初始化
    if (_isInit == false) {
      if (_uid != null && _token != null) {
        await init(_uid!, _token!);
      }
    }

    _messageLog.updateInfo(
      MessageModule.message_fetch,
      startRequestTime: DateTime.now().millisecondsSinceEpoch,
    );

    // 将聊天室对象转换为内部对象（正在拉取消息的聊天室对象），仅保留关键字段
    List<FetchingMsgChat> tryChats = chats.map((e) {
      return FetchingMsgChat(
        e.chat_id,
        e.msg_idx,
        e.last_pos,
        e.read_chat_msg_idx,
        e.hide_chat_msg_idx,
        e.first_pos,
        e.chatKey,
        e.activeChatKey,
        e.activeKeyRound,
        e.chatKeyRound,
      );
    }).toList();

    try {
      // while循环的目的是防止_fetchingChatSendPort为空，需要进行重试。（为空的具体原因未知，理论上不应当出现）
      while (true) {
        if (_fetchingChatSendPort != null) {
          _messageLog.updateInfo(
            MessageModule.message_fetch,
            startReceiveTime: DateTime.now().millisecondsSinceEpoch,
          );
          // 向子线程发送需要收取消息的聊天室对象
          _fetchingChatSendPort!.send(tryChats);
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e, trace) {
      pdebug(e);
      pdebug(trace);
    }
  }

  void decryptChat(List<Chat> chats) async {
    // 等待初始化完成，或者执行初始化
    if (_isInit == false) {
      return;
    }
    List<FetchingMsgChat> tryChats = chats.map((e) {
      return FetchingMsgChat(
          e.chat_id,
          e.msg_idx,
          e.last_pos,
          e.read_chat_msg_idx,
          e.hide_chat_msg_idx,
          e.first_pos,
          e.chatKey,
          e.activeChatKey,
          e.activeKeyRound,
          e.chatKeyRound);
    }).toList();

    try {
      while (true) {
        if (_decryptChatSendPort != null) {
          _decryptChatSendPort!.send(tryChats);
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e, trace) {
      pdebug(e);
      pdebug(trace);
    }
  }

  Future<void> dbSendPortClose() async {
    try {
      if (_dbSendPort != null) {
        _dbSendPort!.send(null);
      }
    } catch (e, trace) {
      pdebug(e);
      pdebug(trace);
    }
  }

  /// 注册消费消息回调方法
  /// 回调方法入参是：List<Message>
  void registerConsumeMsgFunc(Function consumeMsgFunc) {
    _consumeMsgFunc = consumeMsgFunc;
  }

  /// 注册消费消息回调方法
  /// 回调方法入参是：List<Message>
  void registerDropDownConsumeMsgFunc(Function consumeDropDownMsgFunc) {
    _consumeDropDownMsgFunc = consumeDropDownMsgFunc;
  }

  /// 注册加载状态变更回调方法
  /// 回调方法入参是：int
  /// 枚举值：@see LOAD_STATUS_LOADING / LOAD_STATUS_DONE
  void registerOnLoadStatusChangeFunc(Function onLoadStatusChangeFunc) {
    _onLoadStatusChangeFunc = onLoadStatusChangeFunc;
  }

  /// 注册消息预处理回调方法（暂未使用）
  /// 回调方法入参是：List<Message>
  void registerMsgPreHandleFunc(Function msgPreHandleFunc) {
    _msgPreHandleFunc = msgPreHandleFunc;
  }

  void onSocketMessage(dynamic content) async {
    try {
      _msgContentSendPort!.send(content);
    } catch (e, trace) {
      pdebug(e);
      pdebug(trace);
    }
  }

  String? _token;

  int? _uid;

  Lock initLock = Lock();

  final MessageLog _messageLog = MessageLog.sharedInstance;

  static decodeMsg(Message message, Chat chat, int myUid) {
    FetchingMsgChat fetchingChat = FetchingMsgChat(
      chat.chat_id,
      chat.msg_idx,
      chat.last_pos,
      chat.read_chat_msg_idx,
      chat.hide_chat_msg_idx,
      chat.first_pos,
      chat.chatKey,
      chat.activeChatKey,
      chat.activeKeyRound,
      chat.chatKeyRound,
    );
    decodeMessage(message, fetchingChat, myUid);
  }

  static decodeMessage(Message message, FetchingMsgChat chat, int myUid) {
    if (message.ref_typ == 1) {
      if (!chat.isChatKeyValid) {
        return;
      }
      try {
        if (message.content[0] != '{') {
          message.ref_typ = 4;
          return;
        }
        // pdebug("--decodeMessage---chat.chatKey:${chat.chatKey}");
        Map<String, dynamic> content = jsonDecode(message.content);
        int messageRound = content['round'];
        String messageContent = content['data'];
        String? key;
        if (messageRound != chat.activeRound) {
          key = chat.getCalculatedKey(messageRound);
          if (!notBlank(key)) {
            //找不到key，解不开
            message.ref_typ = 4;
            pdebug("message_mgr decode failure no key");
          } else {
            chat.activeRound = messageRound;
            chat.activeChatKey = key;
          }
        } else {
          key = chat.activeChatKey;
        }

        if (key.length == 32) {
          AesEncryption aes = AesEncryption(key);
          message.content = aes.decrypt(messageContent);
          message.ref_typ = 0;
        } else {
          message.ref_typ = 4;
        }
      } catch (e) {
        message.ref_typ = 4;
        pdebug("message_mgr decode err: $e");
      }
      if (message.ref_typ != 0) {
        message.ref_typ = 4;
      }
    } else if (message.ref_typ != 0) {
      message.ref_typ = 4;
    }
  }

  /// 负责收发消息子线程、各类发送/接收端口初始化
  /// 触发时机
  ///   1. 建立Socket连接前
  ///   2. 收取消息时还未进行过初始化（比较少）
  /// 保证幂等性；支持并发调用；保证全局只初始化一次
  Future<void> init(int uid, String token) async {
    while (DatabaseThread.sharedSendPort == null) {
      await Future.delayed(const Duration(milliseconds: 20));
    }

    try {
      await initLock.synchronized(() async {
        if (_isInit && _token != token && _isolate != null) {
          _fetchingChatSpReceivePort?.close();
          _fetchingChatSpReceivePort = null;
          _msgContentSpReceivePort?.close();
          _msgContentSpReceivePort = null;
          _historyMsgReqReceivePort?.close();
          _historyMsgReqReceivePort = null;
          _msgConsumeReceivePort?.close();
          _msgConsumeReceivePort = null;
          _otherMsgReceivePort?.close();
          _otherMsgReceivePort = null;
          _loadStatusReceivePort?.close();
          _loadStatusReceivePort = null;
          _dropDownMsgFetchSpReceivePort?.close();
          _dropDownMsgFetchSpReceivePort = null;
          _dropDownMsgConsumeReceivePort?.close();
          _dropDownMsgConsumeReceivePort = null;
          _decryptChatReceivePort?.close();
          _decryptChatReceivePort = null;
          _dbReceivePort?.close();
          _dbReceivePort = null;
          _isolate?.kill(priority: Isolate.immediate);
          _isolate = null;
        }
        // 保证全局只初始化一次
        if (_isInit && _token == token) {
          return;
        }

        _isInit = false;
        _token = token;
        _uid = uid;

        // 根隔离标识
        RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;

        // 聊天室发送端口的接收端口（用于把子线程中的聊天室发送端口传递给主线程）
        _fetchingChatSpReceivePort = ReceivePort();

        // 消息发送端口的接收端口（同理，把子线程中的消息发送端口传递给主线程）
        _msgContentSpReceivePort = ReceivePort();

        // 历史消息收取请求的接收端口
        _historyMsgReqReceivePort = ReceivePort();

        // 气泡消息的接收端口
        _msgConsumeReceivePort = ReceivePort();

        // 其他类型消息的接口端口
        _otherMsgReceivePort = ReceivePort();

        // APP状态的接收端口
        _loadStatusReceivePort = ReceivePort();

        // 下拉消息收取请求发送端口的接收端口（未使用到）
        _dropDownMsgFetchSpReceivePort = ReceivePort();

        // 下拉消息的接收端口（未使用到）
        _dropDownMsgConsumeReceivePort = ReceivePort();

        // 聊天室消息解密接收端口
        _decryptChatReceivePort = ReceivePort();

        // 聊天室消息解密接收端口
        _dbReceivePort = ReceivePort();

        _chatLastIdxMap = {};

        // 监听历史消息拉取请求
        _historyMsgReqReceivePort?.listen((message) async {
          try {
            if (message is Map<String, dynamic>) {
              var requestId = message['uuid'] as String;
              var loadChats = message['loadChats'] as List<Map>;

              // 发送拉取消息ws请求
              await socketSend(
                ACTION_HISTORY_MSG,
                loadChats,
                requestId: requestId,
              );
            }
          } catch (e, trace) {
            pdebug(e);
            pdebug(trace);
          }
        });

        // 监听消息（包括实时和历史）
        _msgConsumeReceivePort?.listen((message) async {
          // 该数组内的消息发送端口保证均来自同一聊天室
          List<Message> messages = message;

          if (_consumeMsgFunc != null) {
            try {
              Message firstMessage = messages[0];
              Message lastMessage = messages[messages.length - 1];
              int chatId = firstMessage.chat_id;

              // 该while循环等待的目的是，若有更大的未连续的idx对应的消息批次被接收到，持续等待idx连续的消息批次到达；保证向上层传递的消息是连续的
              int? lastChatIdx = _chatLastIdxMap![chatId];
              while (lastChatIdx == null ||
                  lastChatIdx + 1 < firstMessage.chat_idx) {
                await Future.delayed(const Duration(milliseconds: 500));

                int? newLastIdx = _chatLastIdxMap![chatId];
                if (lastChatIdx == newLastIdx) {
                  break;
                } else {
                  lastChatIdx = newLastIdx;
                }
              }

              // 回调上层处理消息的方法
              _consumeMsgFunc!(messages);

              // 记录对应聊天室的最新的消息idx
              _chatLastIdxMap![chatId] = lastMessage.chat_idx;

              // 解析发送方队后在线时间
              objectMgr.onlineMgr.updateOnlineTime(
                  lastMessage.send_id, lastMessage.create_time,
                  onlyUpdateExist: true);
            } catch (e, trace) {
              pdebug(e);
              pdebug(trace);
            }
          }
        });

        // 监听其他类型消息
        _otherMsgReceivePort?.listen((message) {
          try {
            if (objectMgr.appInitState.value == AppInitState.fetching &&
                message is UpdateBlockParser &&
                message.messageHistoryBeans.isNotEmpty) {
              _messageLog.updateInfo(
                MessageModule.message_fetch,
                messageCount: message.messageHistoryBeans.length,
                receiveBatchCount: _batchCount++,
              );
            }

            handleMsgContent(message);
          } catch (e, trace) {
            pdebug(e);
            pdebug(trace);
          }
        });

        // 监听APP状态变更
        _loadStatusReceivePort?.listen((message) {
          if (_onLoadStatusChangeFunc != null) {
            try {
              if (message == LOAD_STATUS_DONE &&
                  objectMgr.appInitState.value != AppInitState.done) {
                // 重置消息接受不了次数
                _batchCount = 0;
                _messageLog.updateInfo(
                  MessageModule.message_fetch,
                  endTime: DateTime.now().millisecondsSinceEpoch,
                  shouldAddLog: true,
                  shouldUpload: true,
                );
              }
              _onLoadStatusChangeFunc!(message);
            } catch (e, trace) {
              pdebug(e);
              pdebug(trace);
            }
          }
        });

        // 监听下拉消息（暂未使用）
        _dropDownMsgConsumeReceivePort?.listen((message) {
          if (_consumeDropDownMsgFunc != null) {
            try {
              _consumeDropDownMsgFunc!(message);
            } catch (e, trace) {
              pdebug(e);
              pdebug(trace);
            }
          }
        });

        // 尝试多次进行创建子线程的原因是，曾出现过调用spawn方法后isolate为空，故而等待一会再重新进行子线程创建。但isolate偶发性为空的原因未知
        for (int i = 0; i < 3; i++) {
          try {
            MsgLoadIsolate msgLoadIsolate = MsgLoadIsolate();
            _isolate = await Isolate.spawn(msgLoadIsolate.handle, [
              _fetchingChatSpReceivePort!.sendPort,
              _historyMsgReqReceivePort!.sendPort,
              _msgConsumeReceivePort!.sendPort,
              _msgContentSpReceivePort!.sendPort,
              rootIsolateToken,
              uid,
              _otherMsgReceivePort!.sendPort,
              _loadStatusReceivePort!.sendPort,
              _dropDownMsgFetchSpReceivePort!.sendPort,
              _dropDownMsgConsumeReceivePort!.sendPort,
              Config().host,
              token,
              _decryptChatReceivePort!.sendPort,
              _dbReceivePort!.sendPort,
            ]);
            if (_isolate != null) {
              break;
            }
          } catch (e, stackTrace) {
            pdebug(e, stackTrace: stackTrace);
          }
          await Future.delayed(const Duration(milliseconds: 200));
        }
        if (_isolate == null) {
          return Future(() => null);
        }

        // 接收从子线程向主线程传递的发送端口
        _fetchingChatSendPort = await _fetchingChatSpReceivePort!.first;
        _msgContentSendPort = await _msgContentSpReceivePort!.first;
        _dropDownMsgFetchSendPort = await _dropDownMsgFetchSpReceivePort!.first;

        _decryptChatSendPort = await _decryptChatReceivePort!.first;
        _dbSendPort = await _dbReceivePort!.first;
        _dbSendPort!.send(DatabaseThread.sharedSendPort);

        // 标记初始化完成
        _isInit = true;
      });
    } catch (e, trace) {
      pdebug("message_mgr init failed",
          error: e, stackTrace: trace, isError: true, writeSentry: true);
    }
  }

  /// 处理其他类型消息
  void handleMsgContent(UpdateBlockParser parser) {
    // 以下几类消息均通过事件机制通知其他业务模块

    // 系统操作更新
    for (var item in parser.updateOprateBeans) {
      objectMgr.socketMgr.sendEvent(SocketMgr.sysOprateBlock, item);
    }

    // 已读消息更新
    for (var item in parser.updateChatReadBeans) {
      objectMgr.socketMgr.sendEvent(SocketMgr.updateChatReadBlock, item);
    }

    // 删除消息更新
    for (var item in parser.updateChatDeleteBeans) {
      objectMgr.socketMgr.sendEvent(SocketMgr.updateChatDeleteBlock, item);
    }

    // 朋友圈消息更新
    for (var item in parser.updateMomentBeans) {
      objectMgr.socketMgr.sendEvent(SocketMgr.updateMomentBlock, item.data);
    }

    // 对象更新
    for (var item in parser.updateBlockBeans) {
      if (item.ctl != DBMessage.tableName) {
        objectMgr.socketMgr.sendEvent(SocketMgr.updateBlock, item);
      }
    }

    // 标签更新
    for (var item in parser.updateTagsBeans) {
      if (item.data == null || item.data is! List) return;
      if (item.data.first["channel"] == "friend_tag" ||
          item.data.first["channel"] == "edit_friend") {
        objectMgr.socketMgr.sendEvent(SocketMgr.updateTagsBlock, item);
      }
    }

    // 朋友圈帖子可見度更新
    for (var item in parser.updateMomentVisibilityBeans) {
      if (item.data == null || item.data is! List) return;
      if (item.data.first["channel"] == "moment") {
        objectMgr.socketMgr
            .sendEvent(SocketMgr.updateMomentNotification, item.data);
      }
    }
  }
}

/// 子线程
class MsgLoadIsolate {
  // 数据库实例对象
  //Database? _db;

  // 后台加载的历史消息缓存
  final Map<int, ChatAndMessage> _msgCache = {};

  // 下拉消息缓存
  final Map<int, ChatAndMessage> _dropDownMsgCache = {};

  String? host;

  // 用户登录凭证
  String? token;

  // 历史消息请求发送端口
  SendPort? _historyMsgReqSendPort;

  // 消息发送端口
  SendPort? _msgConsumeSendPort;

  // 渠道
  int? channel;

  int requestHistoryMessageTime = 0;

  int uid = 0;

  void handle(List<dynamic> args) async {
    try {
      channel = Config().orgChannel;
      SendPort fetchingChatSpSendPort = args[0];
      _historyMsgReqSendPort = args[1];
      _msgConsumeSendPort = args[2];
      SendPort msgContentSpSendPort = args[3];
      RootIsolateToken rootIsolateToken = args[4];
      uid = args[5];
      SendPort otherMsgSendPort = args[6];
      SendPort loadStatusChangeSendPort = args[7];
      SendPort dropDownMsgFetchingSpSendPort = args[8];
      SendPort dropDownMsgConsumeSendPort = args[9];
      host = args[10];
      token = args[11];
      SendPort decryptChatsSendPort = args[12];
      SendPort dbSendPort = args[13];

      // 确保消息传递机制已初始化
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

      // 初始化数据库
      //await _initDb(uid);

      // 接收从主线程向子线程传递的解密聊天室消息
      ReceivePort decryptChatReceivePort = ReceivePort();
      decryptChatReceivePort.listen((message) async {
        _decryptChats(message);
      });
      decryptChatsSendPort.send(decryptChatReceivePort.sendPort);

      // 接收数据库关闭信息
      ReceivePort dbReceivePort = ReceivePort();
      dbReceivePort.listen((message) async {
        DatabaseThread.sharedSendPort = message;
      });
      dbSendPort.send(dbReceivePort.sendPort);

      // 监听下拉聊天室消息事件（暂未使用）
      ReceivePort dropDownMsgFetchingReceivePort = ReceivePort();
      dropDownMsgFetchingReceivePort.listen((message) async {
        FetchingMsgChat fetchingMsgChat = message;
        ChatAndMessage? chatAndMessage =
            _dropDownMsgCache[fetchingMsgChat.chatId];
        if (chatAndMessage == null) {
          chatAndMessage = ChatAndMessage(fetchingMsgChat);
          _dropDownMsgCache[fetchingMsgChat.chatId] = chatAndMessage;
        } else {
          chatAndMessage.chat.lastPosAndCount
              .addAll(fetchingMsgChat.lastPosAndCount);
        }

        // 这里循环等待的目的是，等待其他idx和count对应的拉取请求完成拉取逻辑
        FetchingMsgChat chat = chatAndMessage.chat;
        while (chat.lastPosAndCount.length > 2) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // 通过短连接，获取从某个idx向前指定数量的消息
        List<Message> messages = await _getDropDownMsg(
          chat.chatId,
          chat.lastPosAndCount[0],
          chat.lastPosAndCount[1],
        );

        // 保存消息，并通过发送端口传递给上层
        await _saveMessage(chat, messages);
        dropDownMsgConsumeSendPort.send(messages);

        // 移除已完成消息拉取的idx和count
        int msgIdx = chat.lastPosAndCount.removeAt(0);
        int count = chat.lastPosAndCount.removeAt(0);

        pdebug(
          "finished fetch drop down msg, chatId: ${chat.chatId}, msgIdx: $msgIdx, count: $count",
        );
      });

      // 向主线程发送下拉消息请求发送端口（暂未使用）
      dropDownMsgFetchingSpSendPort
          .send(dropDownMsgFetchingReceivePort.sendPort);

      // 监听拉取聊天室历史消息事件
      ReceivePort fetchingChatReceivePort = ReceivePort();
      Lock fetchingChatLock = Lock();
      fetchingChatReceivePort.listen((message) async {
        await fetchingChatLock.synchronized(() async {
          // 发送收取消息长链接请求
          _sendFetchMsgWs(message, _historyMsgReqSendPort!);

          // 没有可处理的拉取请求，通知消息加载结束
          if (_isLoadAllDone()) {
            loadStatusChangeSendPort.send(MessageMgr.LOAD_STATUS_DONE);
          }
        });
      });

      // 向主线程发送聊天室消息收取请求发送端口
      fetchingChatSpSendPort.send(fetchingChatReceivePort.sendPort);

      // 监听消息事件，收取消息，同时获取下一批消息
      ReceivePort msgContentReceivePort = ReceivePort();
      msgContentReceivePort.listen((message) async {
        // 解析消息
        UpdateBlockParser parser = UpdateBlockParser.created(message);
        // parser.messageHistoryBeans.length
        otherMsgSendPort.send(parser);

        await fetchingChatLock.synchronized(() async {
          // 消息处理，这里主要处理历史消息、实时消息、聊天室更新消息、历史消息推送结束消息
          await _doHandleMsgContent(uid, parser);

          // 将处理完毕后的消息传递给上层
          await _throwMsg();
          _sendFetchMsgWs(null, _historyMsgReqSendPort!);

          // 没有可处理的拉取请求，通知消息加载结束
          if (_msgCache.values.isNotEmpty && _isLoadAllDone()) {
            loadStatusChangeSendPort.send(MessageMgr.LOAD_STATUS_DONE);
          }
        });
      });

      // 向主线程发送消息发送端口
      msgContentSpSendPort.send(msgContentReceivePort.sendPort);

      // 定时检查是否有聊天室，超时没有获取到消息，进行重试
      const duration = Duration(milliseconds: MessageMgr.CHECK_DURATION_MS);
      Timer.periodic(duration, (Timer t) {
        fetchingChatLock.synchronized(() {
          _sendFetchMsgWs(null, _historyMsgReqSendPort!);
        });
      });
    } catch (e, trace) {
      pdebug(e);
      pdebug(trace);
      rethrow;
    }
  }

  /// 获取从某个idx向前指定数量的消息
  Future<List<Message>> _getDropDownMsg(
    int chatId,
    int chatIdx,
    int count,
  ) async {
    List<Message> allMessages = [];
    int curChatIdx = chatIdx;
    int curCount = count;

    // while循环的目的是，后端不一定精准返回所要求的count个数的消息（因为存在不可见消息），所以需要while循环请求，直到符合count条数的消息拉取到
    while (curChatIdx >= 0 && allMessages.length < count) {
      List<Message> curMessages =
          await _doGetDropDownMsg(chatId, curChatIdx, curCount);
      allMessages.addAll(curMessages);

      curChatIdx = curChatIdx - count;
      curCount = count - allMessages.length;

      pdebug(
          "get cur drop down msg finished, chatId: $chatId, curChatIdx: $curChatIdx"
          ", curCount: $curCount, len: ${curMessages.length}, allLen: ${allMessages.length}");
      await Future.delayed(Duration.zero);
    }

    return Future.value(allMessages);
  }

  /// 通过短链接，请求从某个idx向前指定数量的消息
  Future<List<Message>> _doGetDropDownMsg(
    int chatId,
    int chatIdx,
    int count,
  ) async {
    ResponseData? responseData;
    for (int i = 0; i < MessageMgr.DROP_DOWN_MSG_FETCH_RETRY_TIMES; i++) {
      Map<String, dynamic> data = {
        "chat_id": chatId,
        "chat_idx": chatIdx,
        "count": count,
      };

      HttpClient httpClient = getHttpClient();
      try {
        Uri uri = Uri.parse("${host!}/im/message/history_old");
        HttpClientRequest request = await httpClient.postUrl(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Request send timeout'));
        String jsonData = json.encode(data);
        request.headers.add("token", token!);
        request.write(jsonData);
        HttpClientResponse response = await request.close();
        var utf8Stream = response.transform(const Utf8Decoder());
        String body = await utf8Stream.join();
        Map<String, dynamic> jsonMap = jsonDecode(body);
        responseData = ResponseData(
          code: jsonMap["code"],
          message: jsonMap["message"],
          data: jsonMap["data"],
        );
      } catch (e, trace) {
        pdebug(e);
        pdebug(trace);
      } finally {
        httpClient.close();
      }

      if (responseData != null && responseData.code == 0) {
        break;
      }
    }

    if (responseData == null || responseData.code != 0) {
      return Future(() => []);
    }

    List<dynamic> dataList = responseData.data;
    List<Message> messages = dataList.map((e) {
      return Message()..init(e);
    }).toList();
    return Future(() => messages);
  }

  /// 根据聊天室ID，获取缓存中的聊天室对象
  Future<ChatAndMessage?> getChatAndMessage(int chatId) async {
    ChatAndMessage? chatAndMessage = _msgCache[chatId];
    if (chatAndMessage == null) {
      // 缓存中不存在，则从数据库中获取
      FetchingMsgChat? chat = await _queryChat(chatId);
      if (chat == null) {
        return null;
      }
      chatAndMessage = ChatAndMessage(chat);
      _msgCache[chatId] = chatAndMessage;
    }
    return chatAndMessage;
  }

  /// 处理消息包
  Future<void> _doHandleMsgContent(int uid, UpdateBlockParser parser) async {
    String loadUuid = "";

    // 历史消息推送更新
    for (var item in parser.messageHistoryBeans) {
      Message? message;
      try {
        message = Message()..init(item.data[0]);
      } catch (e) {
        pdebug("---------message_mgr-----history err: $e");
      }
      if (message != null) {
        // 标记消息是历史消息
        message.origin = originHistory;
        var chatAndMessage = await getChatAndMessage(message.chat_id);

        // 如果对应聊天室不是正在收取的状态，那么丢弃该消息
        if (chatAndMessage == null ||
            chatAndMessage.loadStatus != ChatAndMessage.LOAD_STATUS_RUNNIG) {
          break;
        }

        // 将消息暂存到历史消息数组变量中
        chatAndMessage.addHistoryMessage(message);
        loadUuid = chatAndMessage.loadUuid;
      }
      //if(loadUuid == "") {
      //pdebug("---------message_mgr-----history chat id:${chatAndMessage.chat.chatId} len: ${parser.messageHistoryBeans.length}");
      //}
    }

    // 对象更新
    for (var item in parser.updateBlockBeans) {
      if (item.ctl == DBMessage.tableName ||
          item.ctl == pbRealTimeMessageHistory) {
        // 处理实时消息
        Message message = Message()..init(item.data[0]);
        message.origin = originReal;

        var chatAndMessage = await getChatAndMessage(message.chat_id);
        if (chatAndMessage == null) {
          continue;
        }
        chatAndMessage.addRealMessage(message);
        //pdebug("---------message_mgr-----DBMessage chat id:${chatAndMessage.chat.chatId} chat idx:${chatAndMessage.chat.msgIdx} chat pos:${chatAndMessage.chat.lastPos}");
        if (chatAndMessage.chat.msgIdx < message.chat_idx) {
          chatAndMessage.chat.msgIdx = message.chat_idx;
        }
      } else if (item.ctl == DBChat.tableName) {
        // 收到聊天室更新消息，更新其消息idx至最新
        if (item.data is List) {
          int? msgIdx = item.data[0]['msg_idx'];
          if (msgIdx != null) {
            ChatAndMessage? chatAndMessage =
                await getChatAndMessage(item.data[0]['id']);
            if (chatAndMessage != null && chatAndMessage.chat.msgIdx < msgIdx) {
              chatAndMessage.chat.msgIdx = msgIdx;
              //pdebug("---------message_mgr-----DBChat chat id:${chatAndMessage.chat.chatId} chat idx:${chatAndMessage.chat.msgIdx} chat pos:${chatAndMessage.chat.lastPos}");
            }
          }
        }
      }
    }

    // 更新同批次消息拉取时间，如果出现同批次消息，说明服务器一直在推流，只是慢，所以，要刷新超时时间
    for (ChatAndMessage chatMessage in _msgCache.values) {
      if (chatMessage.loadUuid == loadUuid &&
          chatMessage.loadStatus == ChatAndMessage.LOAD_STATUS_RUNNIG) {
        chatMessage.loadTime = DateTime.now().millisecondsSinceEpoch;
      }
    }

    // 推历史消息结束的更新
    for (ClientAction item in parser.clientActions) {
      if (item.action == ACTION_HISTORY_MSG) {
        requestHistoryMessageTime = 0;
        for (ChatAndMessage chatMessage in _msgCache.values) {
          if (chatMessage.loadUuid == item.requestId &&
              chatMessage.loadStatus == ChatAndMessage.LOAD_STATUS_RUNNIG) {
            chatMessage.loadStatus = ChatAndMessage.LOAD_STATUS_DONE;
          }
        }
      }
    }
  }

  /// 遍历每一个缓存的聊天室对象，判断历史消息是否均已收取完毕
  bool _isLoadAllDone() {
    bool isAllLoadDone = true;
    for (ChatAndMessage chatMessage in _msgCache.values) {
      if (chatMessage.chat.msgIdx > chatMessage.chat.lastPos) {
        isAllLoadDone = false;
      }
    }
    return isAllLoadDone;
  }

  /// 发送历史消息收取ws请求
  void _sendFetchMsgWs(
    List<FetchingMsgChat>? fetchingMsgChats,
    SendPort sendPort,
  ) {
    if (fetchingMsgChats != null) {
      for (FetchingMsgChat fetchingMsgChat in fetchingMsgChats) {
        ChatAndMessage? chatAndMessage = _msgCache[fetchingMsgChat.chatId];
        if (chatAndMessage == null) {
          // 未找到缓存的聊天室对象，创建并缓存
          chatAndMessage = ChatAndMessage(fetchingMsgChat);
          _msgCache[fetchingMsgChat.chatId] = chatAndMessage;
        } else if (chatAndMessage.chat.lastPos == -1) {
          FetchingMsgChat chat = chatAndMessage.chat;

          // 如果之前的聊天室信息是空的，那么用新进的聊天室信息更新它，这种情况存在于实时消息进入早于聊天室在本地被创建
          chat.msgIdx = max(fetchingMsgChat.msgIdx, chatAndMessage.chat.msgIdx);
          chat.lastPos = fetchingMsgChat.lastPos;
          chat.oldLastPos = fetchingMsgChat.lastPos;
          chat.readChatMsgIdx = max(
            fetchingMsgChat.readChatMsgIdx,
            chatAndMessage.chat.readChatMsgIdx,
          );
          chat.chatKey = fetchingMsgChat.chatKey;
          chat.round = fetchingMsgChat.round;
          chat.activeChatKey = fetchingMsgChat.activeChatKey;
          chat.activeRound = fetchingMsgChat.activeRound;
          chatAndMessage.loadTime = 0;
        } else {
          // 更新对应聊天室最新的消息idx
          FetchingMsgChat chat = chatAndMessage.chat;
          chat.msgIdx = max(fetchingMsgChat.msgIdx, chatAndMessage.chat.msgIdx);
          chat.chatKey = fetchingMsgChat.chatKey;
          chat.round = fetchingMsgChat.round;
          chat.activeChatKey = fetchingMsgChat.activeChatKey;
          chat.activeRound = fetchingMsgChat.activeRound;
          chat.readChatMsgIdx = max(
            fetchingMsgChat.readChatMsgIdx,
            chatAndMessage.chat.readChatMsgIdx,
          );
          chatAndMessage.loadTime = 0;
        }
      }

      // 设置收取时间戳为0，表示即将开始发送新的ws请求
      requestHistoryMessageTime = 0;
    }

    // 如果收取时间戳不为零，表示存在正在进行中的收取请求
    if (requestHistoryMessageTime != 0) {
      var nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 如果正在进行中的收取请求未超时（<5秒），则退出等待其完成，不发送新的ws请求
      if (nowTime - requestHistoryMessageTime < 5) {
        return;
      }
    }

    // 记录发送历史消息收取ws请求的时间戳
    requestHistoryMessageTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 生成请求的唯一标识
    String uuid = const Uuid().v4();
    List<Map> loadChats = [];
    for (ChatAndMessage chatMessage in _msgCache.values) {
      Map req = chatMessage.toHistoryMessageReq(uuid);
      if (req.isEmpty) {
        continue;
      }
      loadChats.add(req);
    }

    if (loadChats.isEmpty) {
      return;
    }

    // 将ws请求参数通过发送端口传递给主线程
    Map<String, dynamic> params = {};
    params["uuid"] = uuid;
    params["loadChats"] = loadChats;
    sendPort.send(params);
  }

  /// 向上层传递已完成收取的消息
  Future<void> _throwMsg() async {
    // 遍历所有的聊天室缓存对象，检测是否存在已完成收取的消息
    for (ChatAndMessage chatAndMessage in _msgCache.values) {
      if (chatAndMessage.loadStatus == ChatAndMessage.LOAD_STATUS_RUNNIG) {
        continue;
      }
      FetchingMsgChat chat = chatAndMessage.chat;
      List<Message> throwMsg = [];
      int toIdx = chat.lastPos + chatAndMessage.loadCount;

      // 更新聊天室最新的已收取消息的idx
      if (toIdx > chat.lastPos) {
        chat.lastPos = toIdx;
      }

      throwMsg.addAll(chatAndMessage.historyMessage);

      // 检查是否存在连续的实时消息需要可以一并返回给上层
      for (; chatAndMessage.realMessageMap[toIdx + 1] != null;) {
        var message = chatAndMessage.getRealMessage(toIdx + 1);
        if (message != null) {
          throwMsg.add(message);
          chatAndMessage.realMessage.remove(message);
          chatAndMessage.realMessageMap.remove(message.chat_idx);
          toIdx++;
          chat.lastPos = toIdx;
        } else {
          break;
        }
      }

      if (throwMsg.isNotEmpty || chatAndMessage.saveFailedMessage.isNotEmpty) {
        if (await _saveMessage(chat, chatAndMessage.saveFailedMessage) &&
            await _saveMessage(chat, throwMsg) == true) {
          chatAndMessage.saveFailedMessage = [];
          //pdebug("---------message_mgr----chat id:${chat.chatId} lastPos:${chat.lastPos} throwMsg len:${throwMsg.length} from:${throwMsg.first.chat_idx} to:${throwMsg.last.chat_idx}");
          //只有message写成功了，才会更新lastPos
          await _updateChat();
        } else {
          //pdebug("---------message_mgr---failed-chat id:${chat.chatId} lastPos:${chat.lastPos} throwMsg len:${throwMsg.length} from:${throwMsg.first.chat_idx} to:${throwMsg.last.chat_idx}");
          //如果三次存储失败，暂时先放内存，下次再存
          chatAndMessage.saveFailedMessage.addAll(throwMsg);
        }

        // 对返回给上层的消息进行过滤
        throwMsg = filterMessages(throwMsg);
        if (throwMsg.isNotEmpty) {
          _msgConsumeSendPort!.send(throwMsg);
        }
      }
      //pdebug("---------message_mgr----clean chat id:${chat.chatId} lastPos:${chat.lastPos} throwMsg len:${throwMsg.length} from:${throwMsg.first.chat_idx} to:${throwMsg.last.chat_idx}");

      // 聊天室完成一次消息拉取后，重置各类缓存变量
      chatAndMessage.historyMessageMap = {};
      chatAndMessage.historyMessage = [];
      chatAndMessage.loadCount = 0;
      chatAndMessage.loadUuid = "";
      chatAndMessage.loadStatus = ChatAndMessage.LOAD_STATUS_IDLE;
    }
  }

  /// 获取从某个时间点往前后往后的所有冷表
  Future<List<String>> getColdMessageTables(int fromTime, int forward) async {
    // 对查询到的冷表名进行排序，控制是返回向前或是向后的冷表名
    String sort = "desc";
    if (forward == 1) {
      sort = "asc";
    }
    List<Map<String, dynamic>> tables = await DatabaseHelper.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'message_%'  order by name $sort",
    );

    List<String> findTbnames = [];
    String tbname = getColdMessageTableName(fromTime);
    var tbnames = tables.map((map) => map['name'] as String).toList();

    // flag用于标记是否找到fromTime对应的冷表名，并将该冷表名后续所有的冷表名一并返回
    bool flag = false;
    for (int i = 0; i < tbnames.length; i++) {
      if (tbnames[i] == tbname) {
        flag = true;
      }
      if (!flag) {
        continue;
      }
      findTbnames.add(tbnames[i]);
    }
    if (fromTime == 0) {
      findTbnames = tbnames;
    }

    return findTbnames;
  }

  /// 根据聊天室ID和消息ID查询消息
  /// 调用时机：
  ///   1. 删除消息
  ///   2. 编辑消息
  ///   3. 回复消息
  Future<Message?> loadDBMessageFromMessageId(
    int chatId,
    int messageId,
  ) async {
    List<Map<String, dynamic>> messageRaws = [];

    // 优先从热表中查询
    messageRaws = await DatabaseHelper.query(
      "message",
      where: "chat_id = ? and message_id = ?",
      whereArgs: [chatId, messageId],
    );

    if (messageRaws.isEmpty) {
      // 热表中未查询到，则依次按照从近到远的顺序从冷表中查找
      List<String> tables = await getColdMessageTables(0, 0);
      for (int i = 0; messageRaws.isEmpty && i < tables.length; i++) {
        messageRaws = messageRaws = await DatabaseHelper.query(
          tables[i],
          where: "chat_id = ? and message_id = ?",
          whereArgs: [chatId, messageId],
        );
      }
    }

    if (messageRaws.isNotEmpty) {
      return Message.creator()..init(messageRaws.first);
    }
    return null;
  }

  /// 根据聊天室ID和消息idx查询消息
  /// 逻辑与上述方法类型
  /// 调用时机：
  ///   1. 回复消息
  Future<Message?> loadDBMessageFromChatIdx(int chatId, int chatIdx) async {
    List<Map<String, dynamic>> messageRaws = [];
    messageRaws = await DatabaseHelper.query(
      "message",
      where: "chat_id = ? and chat_idx = ?",
      whereArgs: [chatId, chatIdx],
    );

    if (messageRaws.isEmpty) {
      List<String> tables = await getColdMessageTables(0, 0);
      for (int i = 0; messageRaws.isEmpty && i < tables.length; i++) {
        messageRaws = await DatabaseHelper.query(
          tables[i],
          where: "chat_id = ? and chat_idx = ?",
          whereArgs: [chatId, chatIdx],
        );
      }
    }

    if (messageRaws.isNotEmpty) {
      return Message.creator()..init(messageRaws.first);
    }
    return null;
  }

  /// 处理删除消息
  safeDeleteMessageProcess(Message msg, List<Message> list) async {
    try {
      await deleteMessageProcess(msg, list);
    } catch (e) {
      return;
    }
  }

  deleteMessageProcess(Message msg, List<Message> list) async {
    if (msg.typ == messageTypeDeleted) {
      MessageDelete messageDel = msg.decodeContent(cl: MessageDelete.creator);

      // 如果不是delete for me和delete for all场景，则不需要删除
      if (uid != messageDel.uid && messageDel.all == 0) return;

      int chatId = msg.chat_id;
      Map<String, List<int>> delMessageMap = {};
      delMessageMap["message"] = [];
      for (final messageId in messageDel.message_ids) {
        bool find = false;

        // 优先从当前批次的消息中获取是否存在需要被删除的消息
        for (var element in list) {
          if (element.message_id == messageId) {
            if (element.deleted == 0) {
              element.deleted = 1;
            }
            find = true;
            continue;
          }
        }
        if (find) {
          continue;
        }

        // 未在当前批次中找到时，需要从数据库中获取
        var delMsg = await loadDBMessageFromMessageId(msg.chat_id, messageId);
        if (delMsg != null) {
          String coldName = getColdMessageTableName(delMsg.create_time);
          if (delMessageMap[coldName] == null) {
            delMessageMap[coldName] = [];
          }

          // 需要删除的消息按照分表名分组记录
          delMessageMap[coldName]!.add(delMsg.message_id);
          delMessageMap["message"]!.add(delMsg.message_id);
        }
      }
      for (String tableName in delMessageMap.keys) {
        if (delMessageMap[tableName]!.isEmpty) {
          continue;
        }

        // 硬删除需要删除的消息
        String idList = delMessageMap[tableName]!.join(', ');
        String sql =
            'DELETE FROM $tableName WHERE chat_id = $chatId and message_id IN ($idList);';
        await DatabaseHelper.execute(sql);
      }
    }
  }

  /// 处理编辑消息
  /// 整体逻辑与消息删除逻辑大致相同
  safeEditMessageProcess(Message msg, List<Message> list) async {
    try {
      await editMessageProcess(msg, list);
    } catch (e) {
      return;
    }
  }

  editMessageProcess(Message msg, List<Message> list) async {
    if (msg.typ != messageTypeEdit) {
      return;
    }
    MessageEdit messageEdit = msg.decodeContent(cl: MessageEdit.creator);
    Message? findMessage;
    for (var element in list) {
      if (element.message_id == messageEdit.related_id &&
          element.chat_id == messageEdit.chat_id) {
        findMessage = element;
        continue;
      }
    }
    if (findMessage != null) {
      if (messageEdit.atUser.isNotEmpty) {
        findMessage.atUser = messageEdit.atUser.toList();
      }
      findMessage.content = messageEdit.content;

      // 标记消息的编辑时间
      findMessage.edit_time = msg.create_time;
      findMessage.ref_typ = messageEdit.refTyp;
      return;
    }
    var editMsg =
        await loadDBMessageFromMessageId(msg.chat_id, messageEdit.related_id);
    if (editMsg != null) {
      editMsg.content = messageEdit.content;
      editMsg.edit_time = msg.create_time;
      editMsg.ref_typ = messageEdit.refTyp;
      editMsg.atUser = messageEdit.atUser.toList();
      list.add(editMsg);
    }
  }

  /// 处理表情回复或表情回复取消的消息
  emojiMessageProcess(Message msg, List<Message> list) async {
    if (msg.typ != messageTypeRemoveReactEmoji &&
        msg.typ != messageTypeAddReactEmoji) {
      return;
    }

    // 表情回复类消息不需要存储，直接在消息批次中删除
    list.remove(msg);
    if (msg.deleted == 1) {
      return;
    }
    dynamic data;
    try {
      data = json.decode(msg.content);
    } catch (e) {
      return;
    }

    if (data == null || data["message_id"] == null) {
      return;
    }
    int replyMsgId = data["message_id"];
    int replyChatIdx = -1;
    if (data['chat_idx'] != null) {
      replyChatIdx = data['chat_idx'];
    }
    bool replyMsgInDB = true;

    // 首先从内存获取，如果获取不到，从数据库获取
    Message? replyMsg;
    int index = -1;
    if (replyChatIdx != -1) {
      index = list.indexWhere((element) => element.chat_idx == replyChatIdx);
    } else {
      index = list.indexWhere((element) => element.message_id == replyMsgId);
    }

    if (index != -1) {
      // 在内存中获取到被表情回复的消息
      replyMsg = list[index];
      replyMsgInDB = false;
    }
    if (replyMsg == null) {
      // 从数据库中获取被表情回复的消息
      if (replyChatIdx != -1) {
        replyMsg = await loadDBMessageFromChatIdx(msg.chat_id, replyChatIdx);
      } else {
        replyMsg = await loadDBMessageFromMessageId(msg.chat_id, replyMsgId);
      }
      replyMsgInDB = true;
    }
    if (replyMsg == null) {
      return;
    }

    bool find = false;
    EmojiModel? delEmoji;
    for (var element in replyMsg.emojis) {
      if (element.emoji == data["emoji"]) {
        if (msg.typ == messageTypeAddReactEmoji) {
          // 若是表情回复，则在表情回复用户中追加该用户
          if (!element.uidList.contains(msg.send_id)) {
            element.uidList.add(msg.send_id);
          }
        }
        if (msg.typ == messageTypeRemoveReactEmoji) {
          if (element.uidList.contains(msg.send_id)) {
            // 若是表情回复取消，则在表情回复用户中移除该用户
            element.uidList.remove(msg.send_id);
            if (element.uidList.isEmpty) {
              // 如果该表情不存在所属用户了，则需要移除该表情
              delEmoji = element;
            }
          }
        }
        find = true;
        continue;
      }
    }

    // 移除不存在所属用户的回复表情
    if (delEmoji != null) {
      replyMsg.delEmoji(delEmoji);
    }

    // 若前序逻辑会找到需要追加回复用户的表情，则添加该表情
    if (!find && msg.typ == messageTypeAddReactEmoji) {
      var emoji = EmojiModel(emoji: data["emoji"], uidList: [msg.send_id]);
      replyMsg.addEmoji(emoji);
    }

    // 若回复消息存在于数据库，则添加到该消息批次中，在后续消息保存逻辑中更新数据
    if (replyMsgInDB) {
      list.add(replyMsg);
    }
  }

  /// 处理文件操作的消息
  fileOperateMessageProcess(
      Message msg, List<Message> list, List<int> delList) async {
    if (msg.typ != messageTypeCommandFileOperate) {
      return;
    }

    // 表情回复类消息不需要存储，直接在消息批次中删除
    list.remove(msg);
    if (msg.deleted == 1) {
      return;
    }
    dynamic data;
    try {
      data = json.decode(msg.content);
    } catch (e) {
      return;
    }

    if (data == null || data["message_id"] == null || data["uid"] == null) {
      return;
    }
    bool isMeInReceivers = msg.send_id == uid || data["uid"] == uid;
    //如果不是我点击播放的 或者 是我发送的语音消息
    if (!isMeInReceivers) {
      return;
    }
    if (msg.send_id == uid) {
      delList.add(msg.getID());
    }
    int fileOperateMsgId = data["message_id"];
    bool fileOperateMsgInDB = true;
    // 首先从内存获取，如果获取不到，从数据库获取
    Message? operatingMsg;
    int index =
        list.indexWhere((element) => element.message_id == fileOperateMsgId);

    if (index != -1) {
      // 在内存中获取到文件操作的消息
      operatingMsg = list[index];
      fileOperateMsgInDB = false;
    }
    if (operatingMsg == null) {
      // 从数据库中获取被表情回复的消息
      operatingMsg =
          await loadDBMessageFromMessageId(msg.chat_id, fileOperateMsgId);
      fileOperateMsgInDB = true;
    }
    if (operatingMsg == null) {
      return;
    }
    operatingMsg.isContentViewed = true;
    // 若回复消息存在于数据库，则添加到该消息批次中，在后续消息保存逻辑中更新数据
    if (fileOperateMsgInDB) {
      list.add(operatingMsg);
    }
  }

  /// 过滤消息
  List<Message> filterMessages(List<Message> messages) {
    return messages.where((m) {
      return !(m.typ >= 20000 && (channel == 1 || channel == 3));
    }).toList();
  }

  Map<String, bool> coldTableMap = {};

  /// 保存消息
  Future<bool> _saveMessage(FetchingMsgChat chat, List<Message> messages,
      {bool isCallBack = true}) async {
    if (messages.isEmpty) {
      return true;
    }
    List<Message> curBatchMessages = [];
    List<int> curBatchDelMsgFromId = [];
    for (int i = 0; i < messages.length; i++) {
      Message message = messages[i];
      if (message.typ >= 20000 && (channel == 1 || channel == 3)) {
        continue;
      }

      // 将消息添加到保存批次中
      curBatchMessages.add(message);

      // 处理删除/编辑/表情回复类消息
      await safeDeleteMessageProcess(message, curBatchMessages);
      await safeEditMessageProcess(message, curBatchMessages);
      await emojiMessageProcess(message, curBatchMessages);
      await fileOperateMessageProcess(
          message, curBatchMessages, curBatchDelMsgFromId);

      // 如果保存批次消息数量超过阈值或已遍历到最后一条消息，则执行消息保存逻辑
      if (curBatchMessages.length >= MessageMgr.MSG_BATCH_SAVE_SIZE ||
          (i == messages.length - 1 && curBatchMessages.isNotEmpty)) {
        int j = 0;
        for (j = 0; j < MessageMgr.MAX_DB_RETRY_TIMES; j++) {
          try {
            Map<String, List<Map<String, dynamic>>> insertMsgList = {};
            for (Message message in curBatchMessages) {
              if (message.isInvisibleMsg &&
                  message.typ != messageTypeReqSignChat) {
                continue;
              }
              MessageMgr.decodeMessage(message, chat, uid);
              if (insertMsgList["message"] == null) {
                insertMsgList["message"] = [];
              }
              insertMsgList["message"]!.add(message.toJson());

              // 将消息根据冷表名分组，保存到对应冷表中
              String coldName = getColdMessageTableName(message.create_time);
              if (insertMsgList[coldName] == null) {
                // 若该冷表名未缓存过，执行冷表创建；该表创建逻辑无副作用，即时冷表已存在也无影响
                await DatabaseHelper.execute(
                    ChatMgr.getCreateMessageTableSql(coldName));
                insertMsgList[coldName] = [];
              }
              insertMsgList[coldName]!.add(message.toJson());
            }
            insertMsgList.forEach((key, value) async {
              if (value.isNotEmpty) {
                await DatabaseHelper.batchReplace(key, value);
              }
            });
            break;
          } catch (e, trace) {
            pdebug(
              "Warning database has been locked AAAAA--e:$e---trace:$trace",
            );
          }
        }
        if (j == MessageMgr.MAX_DB_RETRY_TIMES) {
          return false;
        }
        curBatchMessages = [];
      }
    }

    // 预处理消息（暂未使用）
    if (MessageMgr._msgPreHandleFunc != null && isCallBack) {
      try {
        MessageMgr._msgPreHandleFunc!(messages);
      } catch (e, trace) {
        pdebug(e);
        pdebug(trace);
      }
    }
    return true;
  }

  /// 解密聊天室消息
  _decryptChats(List<FetchingMsgChat> chats) async {
    if (chats.isEmpty) {
      return;
    }
    for (FetchingMsgChat chat in chats) {
      ChatAndMessage? chatAndMessage = _msgCache[chat.chatId];
      if (chatAndMessage != null && chat.isChatKeyValid) {
        chatAndMessage.chat.chatKey = chat.chatKey;
        chatAndMessage.chat.activeChatKey = chat.activeChatKey;
        chatAndMessage.chat.activeRound = chat.activeRound;
        chatAndMessage.chat.round = chat.round;
      }
      _decryptChat(chat);
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  _decryptChat(FetchingMsgChat chat) async {
    if (!chat.isActiveChatKeyValid) {
      return;
    }
    //查询一批加密的消息，然后保存
    var messageTables = await getColdMessageTables(0, 1);
    for (String tableName in messageTables) {
      while (true) {
        List<Map<String, dynamic>> result = await DatabaseHelper.query(
            tableName,
            where: 'chat_id = ? and (ref_typ=1 or ref_typ=2)',
            whereArgs: [chat.chatId],
            limit: 500);
        if (result.isEmpty) {
          break;
        }
        List<Message> messages =
            result.map<Message>((e) => Message()..init(e)).toList();
        _saveMessage(chat, messages, isCallBack: false);
      }
    }
  }

  /// 分表的格式为message_yyyymm。
  /// 如果分表个数为1，一年的分表有：message_202401, message_202402,..., message_202412
  ///	如果分表个数为3，一年的分表有：message_202401, message_202404, message_202407, message_202410
  String getColdMessageTableName(int createTime) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(createTime * 1000);
    int year = date.year;
    int month = date.month;
    month = month ~/
            MessageMgr.COLD_MESSAGE_SUB_MONTH *
            MessageMgr.COLD_MESSAGE_SUB_MONTH +
        (month % MessageMgr.COLD_MESSAGE_SUB_MONTH > 0 ? 1 : 0);
    return "message_$year${month < 10 ? "0$month" : month.toString()}";
  }

  /// 更新聊天室信息
  Future<void> _updateChat() async {
    for (int i = 0; i < MessageMgr.MAX_DB_RETRY_TIMES; i++) {
      try {
        // 遍历所有聊天室缓存对象，如果最新拉取消息的idx有变更，则更新到数据库
        for (ChatAndMessage chatMessage in _msgCache.values) {
          FetchingMsgChat fetchingMsgChat = chatMessage.chat;
          if (fetchingMsgChat.lastPos != fetchingMsgChat.oldLastPos) {
            String sql =
                "UPDATE chat SET last_pos = ${fetchingMsgChat.lastPos} WHERE id = ${fetchingMsgChat.chatId};";
            DatabaseHelper.execute(sql);
            fetchingMsgChat.oldLastPos = fetchingMsgChat.lastPos;
          }
        }

        break;
      } catch (e, trace) {
        pdebug(e);
        pdebug(trace);
      }
    }
  }

  /// 查询聊天室
  Future<FetchingMsgChat?> _queryChat(int chatId) async {
    List<Map<String, dynamic>> result = await DatabaseHelper.query('chat',
        where: 'id = ?', whereArgs: [chatId]);
    if (result.isEmpty) {
      return Future(() => null);
    }

    Map<String, dynamic> chatMap = result[0];
    String? concatenatedKey = chatMap["chat_key"];
    String? chatKey;
    int? round;
    if (notBlank(concatenatedKey) && concatenatedKey!.contains("_")) {
      chatKey = concatenatedKey.split("_").first;
      round = int.parse(concatenatedKey.split("_").last);
    }

    String? concatenatedActiveKey = chatMap["active_chat_key"];
    String? activeChatKey;
    int? activeRound;
    if (notBlank(concatenatedActiveKey) &&
        concatenatedActiveKey!.contains("_")) {
      activeChatKey = concatenatedActiveKey.split("_").first;
      activeRound = int.parse(concatenatedActiveKey.split("_").last);
    }
    FetchingMsgChat chat = FetchingMsgChat(
      chatId,
      chatMap['msg_idx'],
      chatMap['last_pos'],
      chatMap['read_chat_msg_idx'],
      chatMap['hide_chat_msg_idx'],
      chatMap['first_pos'],
      chatKey ?? "",
      activeChatKey ?? "",
      activeRound ?? 0,
      round ?? 0,
    );

    return Future(() => chat);
  }
}

/// 聊天室及其消息，添加消息时保证有序
class ChatAndMessage {
  static const int LOAD_STATUS_IDLE = 1;
  static const int LOAD_STATUS_RUNNIG = 2;
  static const int LOAD_STATUS_DONE = 3;

  //存数据库失败的数据，暂存到这里
  List<Message> saveFailedMessage = [];

  // 历史消息去重
  Map<int, int> historyMessageMap = {};

  // 历史消息
  List<Message> historyMessage = [];

  // 实时消息
  List<Message> realMessage = [];

  // 实时消息去重
  Map<int, int> realMessageMap = {};

  // 聊天室信息
  FetchingMsgChat chat;

  // 当前聊天室拉取状态
  int loadStatus = LOAD_STATUS_IDLE;

  // 当前聊天室拉取时间，做超时用
  int loadTime = 0;

  // 当前聊天室拉取条数
  int loadCount = 0;

  //当前聊天室拉取uuid
  String loadUuid = "";

  ChatAndMessage(this.chat);

  // 将消息添加到历史消息缓存数组中
  void addHistoryMessage(Message message) {
    if (message.chat_idx <= chat.lastPos) {
      return;
    }

    // 去重
    if (historyMessageMap.containsKey(message.chat_idx)) {
      return;
    }

    // 按顺序插入
    int index = historyMessage.indexWhere((m) => m.chat_idx > message.chat_idx);
    if (index == -1) {
      historyMessage.add(message);
    } else {
      historyMessage.insert(index, message);
    }
    historyMessageMap[message.chat_idx] = originHistory;

    // 如果收取的消息数量已达到请求时记录的拉取数量，则标记该聊天时收取完成
    if (historyMessage.length == loadCount &&
        historyMessage.first.chat_idx == chat.lastPos + 1 &&
        historyMessage.last.chat_idx == chat.lastPos + loadCount) {
      loadStatus = LOAD_STATUS_DONE;
    }
  }

  void addRealMessage(Message message) {
    // 已经在拉取中，实时消息不需要存了
    if (message.chat_idx <= chat.lastPos + loadCount) {
      return;
    }

    // 去重
    if (realMessageMap.containsKey(message.chat_idx)) {
      return;
    }

    // 按顺序插入
    int index = realMessage.indexWhere((m) => m.chat_idx > message.chat_idx);
    if (index == -1) {
      realMessage.add(message);
    } else {
      realMessage.insert(index, message);
    }
    realMessageMap[message.chat_idx] = originReal;
  }

  // 获取实时消息
  Message? getRealMessage(int chatIdx) {
    if (!realMessageMap.containsKey(chatIdx)) {
      return null;
    }
    Message? message;
    for (var element in realMessage) {
      if (element.chat_idx == chatIdx) {
        message = element;
      }
    }
    return message;
  }

  /// 生成拉取消息的请求数据
  Map<String, dynamic> toHistoryMessageReq(String uuid) {
    //当聊天室正在拉取消息的时候，不再进行拉取，一种情况除外：距离同批最后推过来的消息已经超过10秒都没有完成
    if (loadStatus != LOAD_STATUS_IDLE) {
      if (!(loadStatus == LOAD_STATUS_RUNNIG &&
          (DateTime.now().millisecondsSinceEpoch - loadTime) > 10 * 1000)) {
        return {};
      }
    }

    if (chat.lastPos >= chat.msgIdx) {
      return {};
    }

    // 计算需要拉取的消息数量
    int count = chat.msgIdx - chat.lastPos;
    if (count > MessageMgr.MAX_BATCH_FETCH_MSG_SIZE) {
      count = MessageMgr.MAX_BATCH_FETCH_MSG_SIZE;
    }
    //pdebug("---------message_mgr-----History chat id:${chat.chatId} chat idx:${chat.msgIdx} chat pos:${chat.lastPos}");
    int fetchIdx = chat.lastPos + 1;
    chat.oldFetchIdx = fetchIdx;
    loadStatus = LOAD_STATUS_RUNNIG;
    loadTime = DateTime.now().millisecondsSinceEpoch;
    loadCount = count;
    loadUuid = uuid;
    return {
      'chat_id': chat.chatId,
      'chat_idx': fetchIdx,
      'count': count,
      'deleted': 0,
    };
  }
}

/// 正在拉取信息的聊天室
class FetchingMsgChat {
  int chatId;

  String chatKey;
  String activeChatKey;

  int round = -1;
  int activeRound = -1;

  String selfKey = "";

  String friendKey = "";

  String selfEncodeKey = "";

  String friendEncodeKey = "";

  // 最新的消息idx
  int msgIdx;

  int firstPos;

  // 连续消息的位置
  int lastPos;

  // 上一次连续消息的位置
  int oldLastPos;

  // 上一次拉取消息的idx
  int oldFetchIdx = -1;

  // 相同拉取消息请求的重试次数
  int retryTimes = 0;

  // 已读消息idx
  int readChatMsgIdx;

  int hideChatMsgIdx;

  // 以上字段是消息向后加载时所需的字段

  // 标记消息向前加载还是向后加载
  bool forward;

  bool get isChatKeyValid =>
      notBlank(chatKey) && chatKey != EncryptionMgr.decryptFailureEmblem;

  bool get isActiveChatKeyValid =>
      notBlank(activeChatKey) &&
      activeChatKey != EncryptionMgr.decryptFailureEmblem;

  // 以下字段是消息向前加载时所需的字段

  List<int> lastPosAndCount = [];

  FetchingMsgChat(
    this.chatId,
    this.msgIdx,
    this.lastPos,
    this.readChatMsgIdx,
    this.hideChatMsgIdx,
    this.firstPos,
    this.chatKey,
    this.activeChatKey,
    this.activeRound,
    this.round,
  )   : oldLastPos = lastPos,
        forward = false {
    if (lastPos == 0) {
      lastPos = maxNum([
        0,
        readChatMsgIdx - MessageMgr.FETCH_BEFORE_UNREAD_SIZE,
        msgIdx - MessageMgr.MAX_FETCH_SIZE,
        hideChatMsgIdx,
      ]);
    } else {
      lastPos =
          maxNum([lastPos, msgIdx - MessageMgr.MAX_FETCH_SIZE, hideChatMsgIdx]);
    }
  }

  // 聊天室不存在时的构造方法
  FetchingMsgChat.notExist(this.chatId)
      : lastPos = 0,
        msgIdx = -1,
        readChatMsgIdx = -1,
        oldLastPos = 0,
        forward = false,
        hideChatMsgIdx = -1,
        firstPos = -1,
        chatKey = "",
        activeChatKey = "",
        activeRound = -1,
        round = -1;

  // 下拉消息时的构造方法
  FetchingMsgChat.newDropDown(this.chatId, int lastPos, int count)
      : msgIdx = -1,
        lastPos = -1,
        oldLastPos = -1,
        readChatMsgIdx = -1,
        forward = true,
        hideChatMsgIdx = -1,
        firstPos = -1,
        chatKey = "",
        activeChatKey = "",
        activeRound = -1,
        round = -1 {
    lastPosAndCount.addAll([lastPos, count]);
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'msg_idx': msgIdx,
      'las_pos': lastPos,
      'chat_key': chatKey,
      "active_chat_key": activeChatKey,
      "active_round": activeRound,
      "round": round,
    };
  }

  int maxNum(List<int> arr) {
    return arr.reduce((value, element) => value > element ? value : element);
  }

  String getCalculatedKey(int roundToCheck) {
    if (roundToCheck == activeRound) return activeChatKey;
    if (!isActiveChatKeyValid) return "";
    if (round > roundToCheck) return "";

    String currentKey = chatKey;
    int currentRound = round;
    var numberOfTimes = roundToCheck - currentRound;
    for (int i = 0; i < numberOfTimes; i++) {
      currentKey = makeMD5(currentKey);
    }

    return currentKey;
  }
}
