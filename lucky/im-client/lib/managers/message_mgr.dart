import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:jxim_client/managers/metrics_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/log.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:path/path.dart';
import 'package:jxim_client/im/model/emoji_model.dart';

import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

import 'package:jxim_client/data/db_message.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/api/socket.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/socket_mgr.dart';

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

  // 加载消息请求通道
  static SendPort? _fetchingChatSendPort;

  // 消息处理通道
  static SendPort? _msgContentSendPort;

  // 下拉消息拉取通道
  static SendPort? _dropDownMsgFetchSendPort;

  // 消息处理回调方法
  static Function? _consumeMsgFunc;

  // 下来消息处理回调方法
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

  static Map<int, int>? _chatLastIdxMap;

  bool _isInit = false;

  static DateTime initTime = DateTime.now();

  int _loadStartTime = 0;

  int _msgCnt = 0;

  Map<String, int> _msgReqSendTimeMap = {};

  /**
   * 触发加载下拉消息
   */
  void LoadDropDownMsg(int chatId, int lastPos, int count) async {
    try {
      while (true) {
        if (_dropDownMsgFetchSendPort != null) {
          FetchingMsgChat fetchingMsgChat =
              FetchingMsgChat.newDropDown(chatId, lastPos, count);
          _dropDownMsgFetchSendPort!.send(fetchingMsgChat);
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100), () {
          MyLog.info('_dropDownMsgFetchSendPort is null, wait 100ms');
        });
      }
    } catch (e, trace) {
      MyLog.info(e);
      MyLog.info(trace);
    }
  }

  /**
   * 触发加载消息
   */
  void LoadMsg(List<Chat> chats) async {
    if (objectMgr.socketMgr.socket == null ||
        !objectMgr.socketMgr.socket!.open) {
      MyLog.info("objectMgr.socketMgr.socket is NOT open, but call LoadMsg");
      _onLoadStatusChangeFunc!(LOAD_STATUS_DONE);
      return;
    }

    if (chats.length == 0) {
      return;
    }

    if (_loadStartTime == 0) {
      _loadStartTime = DateTime.now().millisecondsSinceEpoch;
    }

    if (_isInit == false) {
      if (_uid != null && _token != null) {
        MyLog.info("message mgr not init, but call LoadMsg, try to init");
        await init(_uid!, _token!);
      } else {
        MyLog.info("message mgr not init, but call LoadMsg");
      }
    }

    List<FetchingMsgChat> tryChats = chats.map((e) {
      return FetchingMsgChat(e.chat_id, e.msg_idx, e.last_pos,
          e.read_chat_msg_idx, e.hide_chat_msg_idx, e.first_pos);
    }).toList();
    MyLog.info("try to load message, chat: " + json.encode(tryChats));

    try {
      while (true) {
        if (_fetchingChatSendPort != null) {
          _fetchingChatSendPort!.send(tryChats);
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100), () {
          MyLog.info('_fetchingChatSendPort is null, wait 100ms');
        });
      }
    } catch (e, trace) {
      MyLog.info(e);
      MyLog.info(trace);
    }
  }

  /**
   * 注册消费消息回调方法
   * 回调方法入参是：List<Message>
   */
  void RegisterConsumeMsgFunc(Function consumeMsgFunc) {
    _consumeMsgFunc = consumeMsgFunc;
  }

  /**
   * 注册消费消息回调方法
   * 回调方法入参是：List<Message>
   */
  void RegisterDropDownConsumeMsgFunc(Function consumeDropDownMsgFunc) {
    _consumeDropDownMsgFunc = consumeDropDownMsgFunc;
  }

  /**
   * 注册加载状态变更回调方法
   * 回调方法入参是：int
   * 枚举值：@see LOAD_STATUS_LOADING / LOAD_STATUS_DONE
   */
  void RegisterOnLoadStatusChangeFunc(Function onLoadStatusChangeFunc) {
    _onLoadStatusChangeFunc = onLoadStatusChangeFunc;
  }

  /**
   * 注册消息预处理回调方法
   * 回调方法入参是：List<Message>
   */
  void RegisterMsgPreHandleFunc(Function msgPreHandleFunc) {
    _msgPreHandleFunc = msgPreHandleFunc;
  }

  void onSocketMessage(dynamic content) async {
    try {
      _msgContentSendPort!.send(content);
    } catch (e, trace) {
      MyLog.info(e);
      MyLog.info(trace);
    }
  }

  String? _token;

  int? _uid;

  Lock initLock = Lock();

  SendPort? _logSendPort;

  Future<void> init(int uid, String token) async {
    try {
      await initLock.synchronized(() async {
        MyLog.info("start to init message mgr, uid: ${uid}, token: ${token}");
        if (_isInit && this._token == token) {
          MyLog.info("not init message mgr");
          return;
        }

        _isInit = false;
        this._token = token;
        this._uid = uid;

        RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
        ReceivePort fetchingChatSpReceivePort = ReceivePort();
        ReceivePort msgContentSpReceivePort = ReceivePort();
        ReceivePort historyMsgReqReceivePort = ReceivePort();
        ReceivePort msgConsumeReceivePort = ReceivePort();
        ReceivePort otherMsgReceivePort = ReceivePort();
        ReceivePort loadStatusReceivePort = ReceivePort();
        ReceivePort dropDownMsgFetchSpReceivePort = ReceivePort();
        ReceivePort dropDownMsgConsumeReceivePort = ReceivePort();
        ReceivePort logSpReceivePort = ReceivePort();
        _chatLastIdxMap = {};

        historyMsgReqReceivePort.listen((message) async {
          try {
            if (message is Map<String, dynamic>) {
              MyLog.info("start to send history message req, data: ${message}");
              var requestId = message['uuid'] as String;
              var loadChats = message['loadChats'] as List<Map>;
              // 发送拉取消息ws请求
              int startTime = DateTime.now().millisecondsSinceEpoch;
              _msgReqSendTimeMap[requestId] = startTime;
              await socketSend(ACTION_HISTORY_MSG, loadChats,
                  requestId: requestId, isBatchExecute: false);
              int endTime = DateTime.now().millisecondsSinceEpoch;
              logMgr.metricsMgr.addMetrics(Metrics(
                  type: MetricsMgr.METRICS_TYPE_REQ_HISTORY,
                  startTime: startTime,
                  endTime: endTime,
                  reqID: requestId));
              MyLog.info("send history message req: $message");
            }
          } catch (e, trace) {
            MyLog.info(e);
            MyLog.info(trace);
          }
        });
        MyLog.info("historyMsgReqReceivePort init success");

        msgConsumeReceivePort.listen((message) async {
          List<Message> messages = message;
          _msgCnt += messages.length;

          if (_consumeMsgFunc != null) {
            try {
              Message firstMessage = messages[0];
              Message lastMessage = messages[messages.length - 1];
              int chatId = firstMessage.chat_id;

              int? lastChatIdx = _chatLastIdxMap![chatId];
              while (lastChatIdx == null ||
                  lastChatIdx + 1 < firstMessage.chat_idx) {
                await Future.delayed(const Duration(milliseconds: 500));
                MyLog.info(
                    "chatIdx not continuous, wait 500ms, lastChatIdx: ${lastChatIdx}"
                    ", chatId: ${firstMessage.chat_id}, [${firstMessage.chat_idx}, ${lastMessage.chat_idx}], len: ${messages.length}");

                int? newLastIdx = _chatLastIdxMap![chatId];
                if (lastChatIdx == newLastIdx) {
                  break;
                } else {
                  lastChatIdx = newLastIdx;
                }
              }

              MyLog.info(
                  "consume message, chatId: ${firstMessage.chat_id}, [${firstMessage.chat_idx}, ${lastMessage.chat_idx}], len: ${messages.length}");
              _consumeMsgFunc!(messages);
              _chatLastIdxMap![chatId] = lastMessage.chat_idx;
            } catch (e, trace) {
              MyLog.info(e);
              MyLog.info(trace);
            }
          }
        });
        MyLog.info("msgConsumeReceivePort init success");

        otherMsgReceivePort.listen((message) {
          try {
            handleMsgContent(message);
          } catch (e, trace) {
            MyLog.info(e);
            MyLog.info(trace);
          }
        });
        MyLog.info("otherMsgReceivePort init success");

        loadStatusReceivePort.listen((message) {
          if (_onLoadStatusChangeFunc != null) {
            MyLog.info("[slow loading debug]load status change to ${message}");
            try {
              _onLoadStatusChangeFunc!(message);
            } catch (e, trace) {
              MyLog.info(e);
              MyLog.info(trace);
            }
          } else {
            MyLog.info(
                "_onLoadStatusChangeFunc is null, loadStatus: ${message}");
          }
        });
        MyLog.info("loadStatusReceivePort init success");

        dropDownMsgConsumeReceivePort.listen((message) {
          if (_consumeDropDownMsgFunc != null) {
            try {
              MyLog.info("consume drop down message, len: ${message.length}");
              _consumeDropDownMsgFunc!(message);
            } catch (e, trace) {
              MyLog.info(e);
              MyLog.info(trace);
            }
          }
        });
        MyLog.info("dropDownMsgConsumeReceivePort init success");

        var isolate = null;
        int retry = 0;
        while (isolate == null && retry <= 3) {
          MsgLoadIsolate msgLoadIsolate = MsgLoadIsolate();
          isolate = await Isolate.spawn(msgLoadIsolate.handle, [
            fetchingChatSpReceivePort.sendPort,
            historyMsgReqReceivePort.sendPort,
            msgConsumeReceivePort.sendPort,
            msgContentSpReceivePort.sendPort,
            rootIsolateToken,
            uid,
            otherMsgReceivePort.sendPort,
            loadStatusReceivePort.sendPort,
            dropDownMsgFetchSpReceivePort.sendPort,
            dropDownMsgConsumeReceivePort.sendPort,
            Config().host,
            token,
            logSpReceivePort.sendPort,
            logMgr.metricsMgr.sendPort
          ]);
          if (isolate != null) {
            break;
          }
          MyLog.info("Isolate init failed, retry again, retry: ${retry++}");
        }
        MyLog.info("Isolate init success");

        if (isolate == null) {
          MyLog.info("isolate init failed");
          return Future(() => null);
        }

        _fetchingChatSendPort = await fetchingChatSpReceivePort.first;
        _msgContentSendPort = await msgContentSpReceivePort.first;
        _dropDownMsgFetchSendPort = await dropDownMsgFetchSpReceivePort.first;
        _logSendPort = await logSpReceivePort.first;

        changeLog(logOpen);

        _isInit = true;
        MyLog.info("message_mgr init succeeded");
      });
    } catch (e, trace) {
      MyLog.info("message_mgr init failed");
      MyLog.info(e);
      MyLog.info(trace);
    }
  }

  bool logOpen = false;

  void changeLog(bool open) {
    logOpen = open;
    MyLog.change(open);
    if (_logSendPort != null) {
      _logSendPort!.send(open);
    }
  }

  String generateHistoryReqId() {
    final datetime = DateTime.now().millisecondsSinceEpoch.toString();
    String reqId = makeMD5(
        '${datetime.substring(6, datetime.length)}${objectMgr.userMgr.mainUser.uid}');
    return reqId;
  }

  void handleMsgContent(UpdateBlockParser parser) {
    for (var item in parser.clientActions) {
      if (item.action == ACTION_HISTORY_MSG) {
        int now = DateTime.now().millisecondsSinceEpoch;
        int? startTime = _msgReqSendTimeMap.remove(item.request_id);
        if (startTime == null) {
          startTime = 0;
        }

        logMgr.metricsMgr.addMetrics(Metrics(
            type: MetricsMgr.METRICS_TYPE_END_MSG,
            startTime: startTime,
            endTime: now,
            reqID: item.request_id));
      } else {
        objectMgr.socketMgr.sendEvent(SocketMgr.updateClientActionBlock, item);
      }
    }

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

    // 对象更新
    for (var item in parser.updateBlockBeans) {
      if (item.ctl != DBMessage.tableName) {
        objectMgr.socketMgr.sendEvent(SocketMgr.updateBlock, item);
      }
    }
  }
}

class MsgLoadIsolate {
  Database? _db;

  // 后台加载的历史消息缓存
  Map<int, ChatAndMessage> _msgCache = {};

  // 下拉消息缓存
  Map<int, ChatAndMessage> _dropDownMsgCache = {};

  String? host;

  String? token;

  SendPort? _historyMsgReqSendPort;

  SendPort? _msgConsumeSendPort;

  SendPort? metricsSendPort;

  int? channel;

  int requestHistoryMessageTime = 0;

  int uid = 0;

  void handle(List<dynamic> args) async {
    try {
      channel = const int.fromEnvironment("ORG_CHANNEL", defaultValue: 1);

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
      SendPort logSpSendPort = args[12];
      metricsSendPort = args[13];

      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
      await MyLog.init(host: host!, token: token!);

      // 初始化数据库
      await _initDb(uid);

      // 监听下拉聊天室消息事件
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

        FetchingMsgChat chat = chatAndMessage.chat;
        while (chat.lastPosAndCount.length > 2) {
          await Future.delayed(Duration(milliseconds: 100), () {
            MyLog.info(
                'another drop down msg fetching running, wait 100ms, firstAndLastPos len: ${chat.lastPosAndCount.length}');
          });
        }

        List<Message> messages = await _getDropDownMsg(
            chat.chatId, chat.lastPosAndCount[0], chat.lastPosAndCount[1]);
        await _saveMessage(messages);
        dropDownMsgConsumeSendPort.send(messages);

        int msgIdx = chat.lastPosAndCount.removeAt(0);
        int count = chat.lastPosAndCount.removeAt(0);

        MyLog.info(
            "finished fetch drop down msg, chatId: ${chat.chatId}, msgIdx: ${msgIdx}, count: ${count}");
      });
      dropDownMsgFetchingSpSendPort
          .send(dropDownMsgFetchingReceivePort.sendPort);
      MyLog.info("dropDownMsgFetchingReceivePort init success");

      // 监听拉取聊天室历史消息事件
      ReceivePort fetchingChatReceivePort = ReceivePort();
      Lock fetchingChatLock = Lock();
      fetchingChatReceivePort.listen((message) async {
        await fetchingChatLock.synchronized(() async {
          try {
             _sendFetchMsgWs(message, _historyMsgReqSendPort!, false);
            // 没有可处理的拉取请求，通知消息加载结束
            if (_isLoadAllDone()) {
              loadStatusChangeSendPort.send(MessageMgr.LOAD_STATUS_DONE);
            }
          } catch (e, trace) {
            MyLog.info(e);
            MyLog.info(trace);
          }
        });
      });
      fetchingChatSpSendPort.send(fetchingChatReceivePort.sendPort);
      MyLog.info("fetchingChatReceivePort init success");

      // 监听消息事件，收取消息，同时获取下一批消息
      ReceivePort msgContentReceivePort = ReceivePort();
      msgContentReceivePort.listen((message) async {
        UpdateBlockParser parser = UpdateBlockParser.created(message);
        otherMsgSendPort.send(parser);

        await fetchingChatLock.synchronized(() async {
          try {
            await _doHandleMsgContent(uid, parser);
            await _throwMsg();
            _sendFetchMsgWs(null, _historyMsgReqSendPort!, false);
            // 没有可处理的拉取请求，通知消息加载结束
            if (_isLoadAllDone()) {
              loadStatusChangeSendPort.send(MessageMgr.LOAD_STATUS_DONE);
            }
          } catch (e, trace) {
            MyLog.info(e);
            MyLog.info(trace);
          }
        });
      });

      //定时检查是否有聊天室，超时没有获取到消息，进行重试
      const duration =
          const Duration(milliseconds: MessageMgr.CHECK_DURATION_MS);
      Timer.periodic(duration, (Timer t) {
        fetchingChatLock.synchronized(() {
          try {
            _sendFetchMsgWs(null, _historyMsgReqSendPort!, true);
          } catch (e, trace) {
            MyLog.info(e);
            MyLog.info(trace);
          }
        });
      });

      msgContentSpSendPort.send(msgContentReceivePort.sendPort);
      MyLog.info("msgContentReceivePort init success");

      ReceivePort logReceivePort = ReceivePort();
      logReceivePort.listen((message) {
        MyLog.change(message);
      });
      logSpSendPort.send(logReceivePort.sendPort);
      MyLog.info("Timer init success");
    } catch (e, trace) {
      MyLog.info(e);
      MyLog.info(trace);
    }
  }

  Future<List<Message>> _getDropDownMsg(
      int chatId, int chatIdx, int count) async {
    List<Message> allMessages = [];
    int curChatIdx = chatIdx;
    int curCount = count;
    while (curChatIdx >= 0 && allMessages.length < count) {
      List<Message> curMessages =
          await _doGetDropDownMsg(chatId, curChatIdx, curCount);
      allMessages.addAll(curMessages);

      curChatIdx = curChatIdx - count;
      curCount = count - allMessages.length;

      MyLog.info(
          "get cur drop down msg finished, chatId: ${chatId}, curChatIdx: ${curChatIdx}"
          ", curCount: ${curCount}, len: ${curMessages.length}, allLen: ${allMessages.length}");
    }

    return Future.value(allMessages);
  }

  Future<List<Message>> _doGetDropDownMsg(
      int chatId, int chatIdx, int count) async {
    ResponseData? responseData = null;
    for (int i = 0; i < MessageMgr.DROP_DOWN_MSG_FETCH_RETRY_TIMES; i++) {
      Map<String, dynamic> data = {
        "chat_id": chatId,
        "chat_idx": chatIdx,
        "count": count
      };

      try {
        HttpClient httpClient = getHttpClient();
        Uri uri = Uri.parse(host! + "/im/message/history_old");
        HttpClientRequest request = await httpClient.postUrl(uri);
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
            data: jsonMap["data"]);
      } catch (e, trace) {
        MyLog.info(e);
        MyLog.info(trace);
      }

      if (responseData != null && responseData.code == 0) {
        break;
      }

      MyLog.info(
          "send /im/message/history req err, retry: ${i}, req: ${data}, code: ${responseData?.code}, msg: ${responseData?.message}");
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

  Future<ChatAndMessage?> getChatAndMessage(int chat_id) async {
    ChatAndMessage? chatAndMessage = _msgCache[chat_id];
    if (chatAndMessage == null) {
      FetchingMsgChat? chat = await _queryChat(chat_id);
      if (chat == null) {
        return null;
      }
      chatAndMessage = ChatAndMessage(chat);
      _msgCache[chat_id] = chatAndMessage;
    }
    return chatAndMessage;
  }

  /**
   * 处理消息包
   */
  Future<void> _doHandleMsgContent(int uid, UpdateBlockParser parser) async {
    String loadUuid = "";
    // 历史消息推送更新
    for (var item in parser.messageHistoryBeans) {
      Message message = Message()..init(item.data[0]);
      message.origin = originHistory;
      var chatAndMessage = await getChatAndMessage(message.chat_id);
      if (chatAndMessage == null || chatAndMessage.loadStatus != ChatAndMessage.LOAD_STATUS_RUNNIG) {
        break;
      }
      chatAndMessage.addHistoryMessage(message);
      loadUuid = chatAndMessage.loadUuid;
      //if(loadUuid == "") {
      //pdebug("---------message_mgr-----history chat id:${chatAndMessage.chat.chatId} len: ${parser.messageHistoryBeans.length}");
      //}
    }

    // 对象更新
    for (var item in parser.updateBlockBeans) {
      if (item.ctl == DBMessage.tableName ||
          item.ctl == pbRealTimeMessageHistory) {
        Message message = Message()..init(item.data[0]);
        message.origin = originReal;
        var chatAndMessage = await getChatAndMessage(message.chat_id);
        if(chatAndMessage == null){
          continue;
        }
        chatAndMessage.addRealMessage(message);
        //pdebug("---------message_mgr-----DBMessage chat id:${chatAndMessage.chat.chatId} chat idx:${chatAndMessage.chat.msgIdx} chat pos:${chatAndMessage.chat.lastPos}");
        if (chatAndMessage.chat.msgIdx < message.chat_idx) {
          chatAndMessage.chat.msgIdx = message.chat_idx;
        }
        MyLog.info(
            "rcv real msg, chatId: ${message.chat_id}, chatIdx: ${message.chat_idx}");
      } else if (item.ctl == DBChat.tableName) {
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
          if (chatMessage.loadUuid == item.request_id &&
              chatMessage.loadStatus == ChatAndMessage.LOAD_STATUS_RUNNIG) {
            chatMessage.loadStatus = ChatAndMessage.LOAD_STATUS_DONE;
          }
        }
      }
    }
  }

  Future<void> _initDb(int uid) async {
    MyLog.info("start init db, uid: ${uid}");
    var dbName = "data_v014_$uid.db";

    // 获取数据库文件的存储路径
    var databasesPath = "";
    if (Platform.isMacOS) {
      final path = await getApplicationSupportDirectory();
      databasesPath = path.path.toString();
    } else {
      databasesPath = await getDatabasesPath();
    }
    var dbPath = join(databasesPath, dbName);

    // 根据数据库文件路径和数据库版本号创建数据库表
    try {
      _db = await openDatabase(
        dbPath,
        version: 1,
      );
    } catch (e, trace) {
      MyLog.info(e);
      MyLog.info(trace);
    }

    MyLog.info("db init success, uid: ${uid}");
  }

  bool _isLoadAllDone() {
    bool isAllLoadDone = true;
    for (ChatAndMessage chatMessage in _msgCache.values) {
      if (chatMessage.chat.msgIdx > chatMessage.chat.lastPos) {
        isAllLoadDone = false;
      }
    }
    return isAllLoadDone;
  }

  void _sendFetchMsgWs(List<FetchingMsgChat>? fetchingMsgChats,
      SendPort sendPort, bool forRetry) {
    if (fetchingMsgChats != null) {
      for (FetchingMsgChat fetchingMsgChat in fetchingMsgChats) {
        ChatAndMessage? chatAndMessage = _msgCache[fetchingMsgChat.chatId];
        if (chatAndMessage == null) {
          chatAndMessage = ChatAndMessage(fetchingMsgChat);
          _msgCache[fetchingMsgChat.chatId] = chatAndMessage;
          MyLog.info(
              "add chat to cache, chatId: ${fetchingMsgChat.chatId}, lastPos: ${fetchingMsgChat.lastPos}, msgIdx: ${fetchingMsgChat.msgIdx}");
        } else if (chatAndMessage.chat.lastPos == -1) {
          FetchingMsgChat chat = chatAndMessage.chat;

          // 如果之前的聊天室信息是空的，那么用新进的聊天室信息更新它，这种情况存在于实时消息进入早于聊天室在本地被创建
          chat.msgIdx = max(fetchingMsgChat.msgIdx, chatAndMessage.chat.msgIdx);
          chat.lastPos = fetchingMsgChat.lastPos;
          chat.oldLastPos = fetchingMsgChat.lastPos;
          chat.readChatMsgIdx = max(fetchingMsgChat.readChatMsgIdx,
              chatAndMessage.chat.readChatMsgIdx);
          chatAndMessage.loadTime = 0;
          MyLog.info(
              "update new chat, chatId: ${chat.chatId}, lastPos: ${chat.lastPos}, msgIdx: ${chat.msgIdx}");
        } else {
          FetchingMsgChat chat = chatAndMessage.chat;
          chat.msgIdx = max(fetchingMsgChat.msgIdx, chatAndMessage.chat.msgIdx);
          chat.readChatMsgIdx = max(fetchingMsgChat.readChatMsgIdx,
              chatAndMessage.chat.readChatMsgIdx);
          chatAndMessage.loadTime = 0;
          MyLog.info(
              "update chat, chatId: ${chat.chatId}, lastPos: ${chat.lastPos}, msgIdx: ${chat.msgIdx}");
        }
      }
      requestHistoryMessageTime = 0;
    }

    if (requestHistoryMessageTime != 0) {
      var nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowTime - requestHistoryMessageTime < 5) {
        return;
      }
    }

    requestHistoryMessageTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
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
    Map<String, dynamic> params = {};
    params["uuid"] = uuid;
    params["loadChats"] = loadChats;
    sendPort.send(params);
  }

  Future<void> _throwMsg() async {
    for (ChatAndMessage chatAndMessage in _msgCache.values) {
      if (chatAndMessage.loadStatus == ChatAndMessage.LOAD_STATUS_RUNNIG) {
        continue;
      }
      FetchingMsgChat chat = chatAndMessage.chat;
      List<Message> throwMsg = [];
      int toIdx = chat.lastPos + chatAndMessage.loadCount;
      if (toIdx > chat.lastPos) {
        chat.lastPos = toIdx;
      }
      throwMsg.addAll(chatAndMessage.historyMessage);
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
      if (throwMsg.length != 0 ||
          chatAndMessage.saveFailedMessage.length != 0) {
        // 标记消息是否已读
        for (Message message in throwMsg) {
          if (message.chat_idx <= chat.readChatMsgIdx) {
            message.read_num = 1;
          }
        }
        if (await _saveMessage(chatAndMessage.saveFailedMessage) &&
            await _saveMessage(throwMsg) == true) {
          chatAndMessage.saveFailedMessage = [];
          //pdebug("---------message_mgr----chat id:${chat.chatId} lastPos:${chat.lastPos} throwMsg len:${throwMsg.length} from:${throwMsg.first.chat_idx} to:${throwMsg.last.chat_idx}");
          //只有message写成功了，才会更新lastPos
          await _updateChat();
        } else {
          //pdebug("---------message_mgr---failed-chat id:${chat.chatId} lastPos:${chat.lastPos} throwMsg len:${throwMsg.length} from:${throwMsg.first.chat_idx} to:${throwMsg.last.chat_idx}");
          //如果三次存储失败，暂时先放内存，下次再存
          chatAndMessage.saveFailedMessage.addAll(throwMsg);
        }
        throwMsg = filterMessages(throwMsg);
        if (throwMsg.length > 0) {
          _msgConsumeSendPort!.send(throwMsg);
        }
      }
      //pdebug("---------message_mgr----clean chat id:${chat.chatId} lastPos:${chat.lastPos} throwMsg len:${throwMsg.length} from:${throwMsg.first.chat_idx} to:${throwMsg.last.chat_idx}");
      chatAndMessage.historyMessageMap = {};
      chatAndMessage.historyMessage = [];
      chatAndMessage.loadCount = 0;
      chatAndMessage.loadUuid = "";
      chatAndMessage.loadStatus = ChatAndMessage.LOAD_STATUS_IDLE;
    }
  }

  Future<void> updateFirstPost(FetchingMsgChat chat, int firstPos) async {
    if (chat.firstPos == -1) {
      chat.firstPos = firstPos;
      await _db!.update("chat", {"first_pos": chat.firstPos},
          where: "id = ?", whereArgs: [chat.chatId]);
      MyLog.info(
          "update chat firstPos, chatID: ${chat.chatId}, firstPos: ${chat.firstPos}");
    }
  }

  Future<List<String>> getColdMessageTables(int fromTime, int forward) async {
    String sort = "desc";
    if(forward == 1){
      sort = "asc";
    }
    List<Map<String, dynamic>> tables = await _db!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'message_%'  order by name ${sort}");

    List<String> find_tbnames = [];
    String tbname =  getColdMessageTableName(fromTime);
    var tbnames = tables.map((map) => map['name'] as String).toList();
    bool flag = false;
    for(int i = 0; i < tbnames.length; i++) {
      if(tbnames[i] == tbname){
        flag = true;
      }
      if(!flag){
        continue;
      }
      find_tbnames.add(tbnames[i]);
    }
    if(fromTime == 0){
      find_tbnames = tbnames;
    }

    return find_tbnames;
  }

  Future<Message?> loadDBMessageFromMessageId( int chat_id, int message_id) async {
    List<Map<String, dynamic>> messageRaws = [];
    messageRaws = await _db!.query(
      "message",
      where: "chat_id = ? and message_id = ?", 
      whereArgs: [chat_id, message_id],
    );

    if(messageRaws.isEmpty){
      List<String> tables = await getColdMessageTables(0, 0);
      for (int i = 0; messageRaws.isEmpty && i < tables.length; i++) {
        messageRaws = messageRaws = await _db!.query(
          tables[i],
          where: "chat_id = ? and message_id = ?",
          whereArgs: [chat_id, message_id],
        );
      }
    }

    if(messageRaws.isNotEmpty){
      return Message.creator()..init(messageRaws.first);
    }
    return null;
  }

  Future<Message?> loadDBMessageFromChatIdx( int chat_id, int chat_idx) async {
    List<Map<String, dynamic>> messageRaws = [];
    messageRaws = await _db!.query(
      "message",
      where: "chat_id = ? and chat_idx = ?", 
      whereArgs: [chat_id, chat_idx],
    );

    if(messageRaws.isEmpty){
      List<String> tables = await getColdMessageTables(0, 0);
      for (int i = 0; messageRaws.isEmpty && i < tables.length; i++) {
        messageRaws = await _db!.query(
          tables[i],
          where: "chat_id = ? and chat_idx = ?",
          whereArgs: [chat_id, chat_idx],
        );
      }
    }

    if(messageRaws.isNotEmpty){
      return Message.creator()..init(messageRaws.first);
    }
    return null;
  }

  safeDeleteMessageProcess(Message msg, List<Message> list) async {
    try{
      await deleteMessageProcess(msg, list);
    }catch(e){
      return;
    }
  }
  
  deleteMessageProcess(Message msg, List<Message> list) async {
    if (msg.typ == messageTypeDeleted) {
      MessageDelete messageDel = msg.decodeContent(cl: MessageDelete.creator);
      if (uid != messageDel.uid && messageDel.all == 0)
        return;
      int chat_id = msg.chat_id;
      Map<String, List<int>> delMessageMap = {};
      delMessageMap["message"] = [];
      for (final message_id in messageDel.message_ids) {
        bool find = false;
        list.forEach((element) {
          if(element.message_id == message_id){
            if(element.deleted == 0){
              element.deleted = 1;
            }
            find = true;
            return;
          }
        });
        if(find){
          continue;
        }
        var del_msg = await loadDBMessageFromMessageId(msg.chat_id, message_id);
        if(del_msg != null){
          String coldName = getColdMessageTableName(del_msg.create_time);
          if(delMessageMap[coldName] == null){
            delMessageMap[coldName] = [];
          }
          delMessageMap[coldName]!.add(del_msg.message_id);
          delMessageMap["message"]!.add(del_msg.message_id);
        }
      }
      for (String tableName in delMessageMap.keys) {
        if(delMessageMap[tableName]!.length <= 0){
          continue;
        }
        String idList = delMessageMap[tableName]!.join(', ');
        String sql = 'DELETE FROM $tableName WHERE chat_id = ${chat_id} and message_id IN ($idList);';
        await _db!.rawDelete(sql);
      }
    }
  }

  safeEditMessageProcess(Message msg, List<Message> list) async {
    try{
      await editMessageProcess(msg, list);
    }catch(e){
      return;
    }
  }

  editMessageProcess(Message msg, List<Message> list) async {
    if (msg.typ != messageTypeEdit) {
      return;
    }
    MessageEdit messageDel = msg.decodeContent(cl: MessageEdit.creator);
    Message? findMessage = null;
    list.forEach((element) {
      if (element.message_id == messageDel.related_id &&
          element.chat_id == messageDel.chat_id) {
        findMessage = element;
        return;
      }
    });
    if (findMessage != null) {
      findMessage!.content = messageDel.content;
      findMessage!.edit_time = msg.create_time;
      return;
    }
    var edit_msg =
        await loadDBMessageFromMessageId(msg.chat_id, messageDel.related_id);
    if (edit_msg != null) {
      edit_msg.content = messageDel.content;
      edit_msg.edit_time = msg.create_time;
      list.add(edit_msg);
    }
  }

  emojiMessageProcess(Message msg, List<Message> list) async {
    if(msg.typ != messageTypeRemoveReactEmoji && msg.typ != messageTypeAddReactEmoji){
      return;
    }
    list.remove(msg);
    if(msg.deleted == 1){
      return;
    }
    var data;
    try{
      data = json.decode(msg.content);
    }catch(e){
      return;
    }
    
    if(data == null || data["message_id"] == null){
      return;
    }
    int reply_msg_id = data["message_id"];
    int reply_chat_idx = -1;
    if(data['chat_idx'] != null){
     reply_chat_idx = data['chat_idx'];
    }
    bool replyMsgInDB = true;
    //首先从内存获取，如果获取不到，从数据库获取
    Message? reply_msg = null;
    int index = -1;
    if(reply_chat_idx != -1){
      index = list.indexWhere((element) => element.chat_idx == reply_chat_idx);
    }else{
      index = list.indexWhere((element) => element.message_id == reply_msg_id);
    }
    
    if(index != -1){
      reply_msg = list[index];
      replyMsgInDB = false;
    }
    if(reply_msg == null){
      if(reply_chat_idx != -1){
        reply_msg = await loadDBMessageFromChatIdx(msg.chat_id, reply_chat_idx);
      }else{
        reply_msg = await loadDBMessageFromMessageId(msg.chat_id, reply_msg_id);
      }
      replyMsgInDB = true;
    }
    if(reply_msg == null){
      return;
    }
    bool find = false;
    EmojiModel? delEmoji = null;
    reply_msg.emojis.forEach((element) {
      if(element.emoji == data["emoji"]){
        if(msg.typ == messageTypeAddReactEmoji){
          if(!element.uidList.contains(msg.send_id)){
            element.uidList.add(msg.send_id);
          }
        }
        if(msg.typ == messageTypeRemoveReactEmoji){
          if(element.uidList.contains(msg.send_id)){
            element.uidList.remove(msg.send_id);
            if(element.uidList.length == 0){
              delEmoji = element;
            }
          }
        }
        find = true;
        return;
      }
    });
    if(delEmoji != null){
      reply_msg.delEmoji(delEmoji!);
    }
    if(!find && msg.typ == messageTypeAddReactEmoji){
      var emoji = EmojiModel(emoji: data["emoji"], uidList: [msg.send_id]);
      reply_msg.addEmoji(emoji);
    }
    if(replyMsgInDB){
      list.add(reply_msg);
    }
  }

  List<Message> filterMessages(List<Message> messages) {
    return messages.where((m) {
      return !(m.typ >= 20000 && (channel == 1 || channel == 3));
    }).toList();
  }

  Map<String, bool> coldTableMap = {};

  Future<bool> _saveMessage(List<Message> messages) async {
    if (messages.length == 0) {
      return true;
    }
    List<Message> curBatchMessages = [];
    for (int i = 0; i < messages.length; i++) {
      Message message = messages[i];
      if (message.typ >= 20000 && (channel == 1 || channel == 3)) {
        continue;
      }
      curBatchMessages.add(message);
      await safeDeleteMessageProcess(message, curBatchMessages);
      await safeEditMessageProcess(message, curBatchMessages);
      await emojiMessageProcess(message, curBatchMessages);
      if (curBatchMessages.length >= MessageMgr.MSG_BATCH_SAVE_SIZE ||
          (i == messages.length - 1 && curBatchMessages.length > 0)) {
        int j = 0;
        for (j = 0; j < MessageMgr.MAX_DB_RETRY_TIMES; j++) {
          int begin = DateTime.now().millisecondsSinceEpoch;
          int? origin;
          int? msgCnt;
          try {
            Batch batch = _db!.batch();
            Map<String, Batch> coldBatchMap = {};
            for (Message message in curBatchMessages) {
              origin = message.origin;
              if (message.typ == messageTypeDeleted || 
                  message.typ == messageTypeEdit ||
                  message.deleted == 1) {
                continue;
              }

              batch.insert("message", message.toJson(),
                  conflictAlgorithm: ConflictAlgorithm.replace);

              String coldName = getColdMessageTableName(message.create_time);
              if (coldTableMap[coldName] == null) {
                await _db!.execute(ChatMgr.GetCreateMessageTableSql(coldName));
                coldTableMap[coldName] = true;
              }
              if(coldBatchMap[coldName] == null){
                coldBatchMap[coldName] = _db!.batch();
              }
              coldBatchMap[coldName]!.insert(coldName, message.toJson(),
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
            await batch.commit();

            for (var entry in coldBatchMap.entries) {
              await entry.value.commit();
            }

            msgCnt = batch.length;
            int end = DateTime.now().millisecondsSinceEpoch;
            MyLog.info(
                "save hot message finished, cnt: ${curBatchMessages.length}, cost: ${end - begin}");
            break;
          } catch (e, trace) {
            MyLog.info(e);
            MyLog.info(trace);
            MyLog.info(
                "save message failed, cnt: ${curBatchMessages.length}, retry: ${i}");
            pdebug("Warning database has been locked AAAAA--e:${e}---trace:${trace}");
          } finally {
            int end = DateTime.now().millisecondsSinceEpoch;
            if (origin == originHistory) {
              metricsSendPort!.send(Metrics(
                  type: MetricsMgr.METRICS_TYPE_SAVE_MSG,
                  startTime: begin,
                  endTime: end,
                  msgCnt: msgCnt));
            }
          }
        }
        if (j == MessageMgr.MAX_DB_RETRY_TIMES) {
          return false;
        }
        curBatchMessages = [];
      }
    }

    if (MessageMgr._msgPreHandleFunc != null) {
      try {
        MessageMgr._msgPreHandleFunc!(messages);
      } catch (e, trace) {
        MyLog.info(e);
        MyLog.info(trace);
      }
    }
    return true;
  }

  String getColdMessageTableName(int createTime) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(createTime * 1000);
    int year = date.year;
    int month = date.month;
    month = month ~/
            MessageMgr.COLD_MESSAGE_SUB_MONTH *
            MessageMgr.COLD_MESSAGE_SUB_MONTH +
        (month % MessageMgr.COLD_MESSAGE_SUB_MONTH > 0 ? 1 : 0);
    return "message_" +
        year.toString() +
        (month < 10 ? "0" + month.toString() : month.toString());
  }

  Future<void> _updateChat() async {
    for (int i = 0; i < MessageMgr.MAX_DB_RETRY_TIMES; i++) {
      try {
        Batch batch = _db!.batch();
        for (ChatAndMessage chatMessage in _msgCache.values) {
          FetchingMsgChat fetchingMsgChat = chatMessage.chat;
          if (fetchingMsgChat.lastPos != fetchingMsgChat.oldLastPos) {
            batch.update("chat", {"last_pos": fetchingMsgChat.lastPos},
                where: 'id = ?', whereArgs: [fetchingMsgChat.chatId]);
            MyLog.info(
                "update chat lastPos, chatID: ${fetchingMsgChat.chatId}, lastPos: ${fetchingMsgChat.lastPos}");
            fetchingMsgChat.oldLastPos = fetchingMsgChat.lastPos;
          }
        }

        if (batch.length > 0) {
          await batch.commit();
          MyLog.info("update chat finished, len: ${batch.length}");
        }

        break;
      } catch (e, trace) {
        MyLog.info(e);
        MyLog.info(trace);
        MyLog.info("update chat error, retry: ${i}");
      }
    }
  }

  Future<FetchingMsgChat?> _queryChat(int chatId) async {
    List<Map<String, dynamic>> result =
        await _db!.query('chat', where: 'id = ?', whereArgs: [chatId]);
    if (result.length == 0) {
      return Future(() => null);
    }

    Map<String, dynamic> chatMap = result[0];
    FetchingMsgChat chat = FetchingMsgChat(
        chatId,
        chatMap['msg_idx'],
        chatMap['last_pos'],
        chatMap['read_chat_msg_idx'],
        chatMap['hide_chat_msg_idx'],
        chatMap['first_pos']);
    MyLog.info("query chat from db succeeded, chatId: ${chatId}");

    return Future(() => chat);
  }
}

/**
 * 聊天室及其消息，添加消息时保证有序
 */
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

  void addHistoryMessage(Message message) {
    if (message.chat_idx <= chat.lastPos) {
      return;
    }
    if (historyMessageMap.containsKey(message.chat_idx)) {
      return;
    }
    int index = historyMessage.indexWhere((m) => m.chat_idx > message.chat_idx);
    if (index == -1) {
      historyMessage.add(message);
    } else {
      historyMessage.insert(index, message);
    }
    historyMessageMap[message.chat_idx] = originHistory;
    if (historyMessage.length == loadCount &&
        historyMessage.first.chat_idx == chat.lastPos + 1 &&
        historyMessage.last.chat_idx == chat.lastPos + loadCount) {
      loadStatus = LOAD_STATUS_DONE;
    }
  }

  void addRealMessage(Message message) {
    //已经在拉取中，实时消息不需要存了
    if (message.chat_idx <= chat.lastPos + loadCount) {
      return;
    }
    if (realMessageMap.containsKey(message.chat_idx)) {
      return;
    }
    int index = realMessage.indexWhere((m) => m.chat_idx > message.chat_idx);
    if (index == -1) {
      realMessage.add(message);
    } else {
      realMessage.insert(index, message);
    }
    realMessageMap[message.chat_idx] = originReal;
  }

  Message? getRealMessage(int chat_idx) {
    if (!realMessageMap.containsKey(chat_idx)) {
      return null;
    }
    Message? message = null;
    realMessage.forEach((element) {
      if (element.chat_idx == chat_idx) {
        message = element;
      }
    });
    return message;
  }

  /**
   * 生成拉取消息的请求数据
   */
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

    int count = chat.msgIdx - chat.lastPos;
    if (count > MessageMgr.MAX_BATCH_FETCH_MSG_SIZE) {
      count = MessageMgr.MAX_BATCH_FETCH_MSG_SIZE;
    }
    //pdebug("---------message_mgr-----History chat id:${chat.chatId} chat idx:${chat.msgIdx} chat pos:${chat.lastPos}");
    int fetchIdx = this.chat.lastPos + 1;
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

/**
 * 正在拉取信息的聊天室
 */
class FetchingMsgChat {
  int chatId;

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

  // 以下字段是消息向前加载时所需的字段

  List<int> lastPosAndCount = [];

  FetchingMsgChat(this.chatId, this.msgIdx, lastPos, this.readChatMsgIdx,
      this.hideChatMsgIdx, this.firstPos)
      : this.lastPos = lastPos,
        this.oldLastPos = lastPos,
        this.forward = false {
    if (lastPos == 0) {
      this.lastPos = maxNum([
        0,
        readChatMsgIdx - MessageMgr.FETCH_BEFORE_UNREAD_SIZE,
        msgIdx - MessageMgr.MAX_FETCH_SIZE,
        hideChatMsgIdx
      ]);
    } else {
      this.lastPos =
          maxNum([lastPos, msgIdx - MessageMgr.MAX_FETCH_SIZE, hideChatMsgIdx]);
    }
  }

  // 聊天室不存在时的构造方法
  FetchingMsgChat.notExist(this.chatId)
      : this.lastPos = 0,
        this.msgIdx = -1,
        this.readChatMsgIdx = -1,
        this.oldLastPos = 0,
        this.forward = false,
        this.hideChatMsgIdx = -1,
        this.firstPos = -1;

  // 下拉消息时的构造方法
  FetchingMsgChat.newDropDown(this.chatId, int lastPos, int count)
      : this.msgIdx = -1,
        this.lastPos = -1,
        this.oldLastPos = -1,
        this.readChatMsgIdx = -1,
        this.forward = true,
        this.hideChatMsgIdx = -1,
        this.firstPos = -1 {
    lastPosAndCount.addAll([lastPos, count]);
  }

  Map<String, dynamic> toJson() {
    return {'chat_id': chatId, 'msg_idx': msgIdx, 'las_pos': lastPos};
  }

  int maxNum(List<int> arr) {
    return arr.reduce((value, element) => value > element ? value : element);
  }
}
