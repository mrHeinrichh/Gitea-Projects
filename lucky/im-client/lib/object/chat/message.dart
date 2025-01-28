import 'dart:convert';

import 'package:events_widget/event_dispatcher.dart';
import 'package:im/im_plugin.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/data/row_object.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/signaling_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';

/// 消息类型
const int messageTypeText = 1; // 文本
const int messageTypeImage = 2; // 图片
const int messageTypeVoice = 3; // 语音
const int messageTypeVideo = 4; // 视频
const int messageTypeFace = 5; // 贴图
const int messageTypeFile = 6; // 文件
const int messageTypeLocation = 7; // 位置
const int messageTypeNewAlbum = 8; // 新相册
const int messageTypeLink = 9; // 带链接的文本
const int messageTypeCustom = 10; // 自定义扩展
const int messageTypeReply = 11; //回复消息
const int messageTypeForward = 12;
const int messageTypeLiveVideo = 13; //圆形视频

const int messageTypeRecommendFriend = 15; //推荐好友
const int messageTypeSecretaryRecommend = 16; //小秘书推广信息
const int messageTypeShareLocationStart = 17; //开始位置信息共享
const int messageTypeShareLocationEnd = 18; //结束位置信息共享
const int messageTypeSendRed = 20; // 发红包消息

const int messageTypeTransferMoneySuccess = 23; // 轉帳成功

const int messageTypeTaskCreated = 21; // 创建任务
const int messageTypeSubTaskChanged = 22; // 更新任务状态
const int messageTypeReel = 24; // 视频号消息
const int messageTypeGif = 25; // gif消息

const int messageDiscussCall = 1000; // 讨论组发起通话
const int messageCloseDiscussCall = 1001; // 讨论组结束通话

const int messageBusyCall = 1002;
const int messageCancelCall = 1003;
const int messageMissedCall = 1004;

/// Not counted as unread
const int messageTypeAutoDeleteInterval = 10001;
const int messageTypeBeingFriend = 10002; // 添加好友成功
const int messageTypeBlack = 10003; //黑名单
const int messageTypeRecall = 10004; // 撤回消息
const int messageTypeReplyWithdraw = 10005; //回复消息撤回
const int messageTypePin = 10006; // 置顶消息
const int messageTypeUnPin = 10007; // 取消置顶消息
const int messageTypeGetRed = 10010; // 收红包消息
const int messageTypeSysmsg = 10011; // 系统消息
const int messageTypeCreateGroup = 10012; //用户建群
const int messageTypeGroupJoined = 10013; // 邀请入群
const int messageTypeExitGroup = 10014; //用户退群
const int messageTypeKickoutGroup = 10015; //用户被踢
const int messageTypeGroupMute = 10016; //群禁言
const int messageTypeGroupAddAdmin = 10017; //添加群管理
const int messageTypeGroupRemoveAdmin = 10018; //移除群管理
const int messageTypeGroupOwner = 10019; //添加群主
const int messageTypeGroupChangeInfo = 10020; //更新群基本信息
const int messageTypeGroupJoinedLink = 10022; // 使用链接邀请入群
const int messageTypeAudioChatOpen = 10024; // 語音聊天訊息開啟
const int messageTypeAudioChatInvite = 10025; // 語音聊天訊息邀請人加入
const int messageTypeAudioChatClose = 10026; // 語音聊天訊息關閉
const int messageTypeChatScreenshot = 10027; // 截图提示
const int messageTypeChatScreenshotEnable = 10028; // 截图开启关闭
const int messageTypeChatScreenRecording = 10029; // 录屏提示

const int messageStartCall = 11000;
const int messageEndCall = 11001;
const int messageRejectCall = 11002;

//命令类消息（定义范围12001～12999，其中之前的暂时保持原编码）
const int messageTypeEdit = 12001; // 编辑消息
const int messageTypeAddReactEmoji = 10008; // 表情react添加
const int messageTypeDeleted = 10023; // 删除消息的特殊消息
const int messageTypeRemoveReactEmoji = 10009; // 表情react移除

const List<int> messageBetTypes = [
  messageTypeFollowBet,
  messageTypeOpenLottery,
  messageTypeWinLottery,
  messageTypeBetOpening,
  messageTypeBetStatistics,
  messageTypeBetClosed,
];

///跟投
const int messageTypeFollowBet = 20001; //跟投
///开奖信息
const int messageTypeOpenLottery = 20002; //开奖信息
///中奖信息
const int messageTypeWinLottery = 20003; //中奖信息
/// 开盘通知
const int messageTypeBetOpening = 20004; //开盘通知
/// 下注统计
const int messageTypeBetStatistics = 20005; //下注统计
/// 封盘通知
const int messageTypeBetClosed = 20006; //封盘通知

/// 增加股东
const int messageTypeAddShareholders = 20007;
/// 清退股东
const int messageTypeKickShareholders = 20008;
/// 购买股份
const int messageTypeAddShareholder= 20009;
/// 减持股份
const int messageTypeReduceShareholder = 20010;
/// 转入应用
const int messageTypeTransferToApp = 20011;
/// 转出应用
const int messageTypeTransferToGroup = 20012;
/// 追加投资
const int messageTypeIpo = 20013;
/// 追加投资某用户同意/不同意
const int messageTypeIpoUser = 20014;
/// 分红
const int messageTypeProfit = 20015;
/// 增加运营
const int messageTypeAddOperator = 20016;
/// 删除运营
const int messageTypeDelOperator = 20017;
/// 增加财务
const int messageTypeAddFinancier = 20018;
/// 删除财务
const int messageTypeDelFinancier = 20019;
/// 应用开启/关闭
const int messageTypeGroupAppStateChange = 20020;
/// 游戏消息开启/关闭
const int messageTypeGroupMessageChange = 20021;
/// 东方彩票自动转单开启/关闭
const int messageTypeGroupAutoTurnChange = 20022;

/// 只有前端使用
const int messageTypeUnreadBar = 90000000001; // 未读消息条
const int messageTypeDate = 90000000002; // 未读消息条

/// 系统消息操作类型
const int sysmsgOptNone = 0; // 无
const int sysmsgOptFollow = 1; //关注
const int sysmsgOptKick = 2; // 踢人
const int sysmsgOptAddManager = 3; //添加管理员
const int sysmsgOptOutManager = 4; // 移除管理员
const int sysmsgOptChangeAdmin = 5; // 管理员变更

///共享位置消息类型
const int locationTypeBeginVoice = 1; //开始录音
const int locationTypeEndVoice = 2; //结束播放
const int locationTypeReceiveVoice = 3; //语音包消息

//消息发送状态枚举
const int MESSAGE_SEND_ING = 0; //发送中
const int MESSAGE_SEND_SUCCESS = 1; //发送成功
const int MESSAGE_SEND_FAIL = 2; //发送失败

const int isSecretary = 1001;
const int isSystem = 1002;

const int originReal = 1; // 实时消息
const int originHistory = 2; // 历史消息

enum ProcessMessageType { db, net, input, done }

const Set swipeToReplyTypes = {
  messageTypeText,
  messageTypeImage,
  messageTypeVoice,
  messageTypeVideo,
  messageTypeFace,
  messageTypeFile,
  messageTypeLocation,
  messageTypeNewAlbum,
  messageTypeLink,
  messageTypeCustom,
  messageTypeReply,
  messageTypeForward,
  messageTypeLiveVideo,
  messageTypeRecommendFriend,
  messageTypeSecretaryRecommend,
  messageTypeShareLocationStart,
  messageTypeShareLocationEnd,
  messageTypeSendRed,
  messageTypeGif,
};
//聊天訊息所有種類
final List<int> chatMsgList = [
  messageTypeText,
  messageTypeImage,
  messageTypeVoice,
  messageTypeVideo,
  messageTypeFace,
  messageTypeFile,
  messageTypeLocation,
  messageTypeNewAlbum,
  messageTypeLink,
  messageTypeCustom,
  messageTypeReply,
  messageTypeForward,
  messageTypeLiveVideo,
  messageTypeRecommendFriend,
  messageTypeSecretaryRecommend,
  messageTypeShareLocationStart,
  messageTypeShareLocationEnd,
  messageTypeSendRed,
];

//檢查是否設置了消息過濾需要隱藏該消息
bool checkIsHiddenMsg(Message message) {
  //檢查是否設置了消息過濾需要隱藏該消息
  if (message.typ == messageTypeFollowBet) {
    //投注
    Map content = jsonDecode(message.content);
    return gameManager.checkIsHiddenMsg(content['game_id'], dataCenter.betMsgType);
  } else if (message.typ == messageTypeOpenLottery) {
    //開獎
    Map content = jsonDecode(message.content);
    return gameManager.checkIsHiddenMsg(content['game_id'], dataCenter.resultMsgType);
  } else if (message.typ == messageTypeWinLottery) {
    //中獎
    Map content = jsonDecode(message.content);
    return gameManager.checkIsHiddenMsg(content['game_id'], dataCenter.winMsgType);
  } else if (chatMsgList.contains(message.typ)) {
    //一般聊天
    return gameManager.checkIsHiddenMsg("", dataCenter.chatMsgType);
  }
  return false;
}

// ignore_for_file: non_constant_identifier_names
class Message extends RowObject with EventDispatcher {
  static const String update = 'update';

  int? _origin;

  int? get origin => _origin;

  set origin(int? value) {
    _origin = value;
  }

  int select = 0;

  int get id => getValue('id', 0);

  set id(int v) => setValue('id', v);

  int get message_id => getValue('message_id', 0);

  set message_id(int v) => setValue('message_id', v);

  int get secretary_id => getValue('secretary_id', 0);

  set secretary_id(int v) => setValue('secretary_id', v);

  int get chat_id => getValue('chat_id', 0);

  set chat_id(int v) => setValue('chat_id', v);

  int get send_id => getValue('send_id', 0);

  set send_id(int v) => setValue('send_id', v);

  int get typ => getValue('typ', 0);

  set typ(int v) => setValue('typ', v);

  String get content => getValue('content', '');

  set content(String v) => setValue('content', v);

  set atUser(List<MentionModel> v) => setValue('at_users', v);

  List<MentionModel> get atUser => getValue('at_users', <MentionModel>[]);

  set emojis(List<EmojiModel> v) => setValue('emojis', v);

  List<EmojiModel> get emojis => getValue('emojis', <EmojiModel>[]);

  int get send_time => getValue('send_time', 0);

  set send_time(int v) => setValue('send_time', v);

  int get edit_time => getValue('edit_time', 0);

  set edit_time(int v) => setValue('edit_time', v);

  int get expire_time => getValue('expire_time', 0);

  set expire_time(int v) => setValue('expire_time', v);

  bool get isExpired =>
      expire_time > 0 &&
      expire_time <= DateTime.now().millisecondsSinceEpoch ~/ 1000;

  int get create_time => getValue('create_time', 0);

  set create_time(int v) => setValue('create_time', v);

  int get update_time => getValue('update_time', 0);

  int get chat_idx => getValue('chat_idx', 0);

  set chat_idx(int v) => setValue('chat_idx', v);

  int get is_opt => getValue('is_opt', 0);

  int get read_num => getValue('read_num', 0);

  set read_num(int v) => setValue('read_num', v);

  bool get isShow => getValue('isShow', true);

  set isShow(bool v) => setValue('isShow', v);

  String get msg => getValue('msg', '');

  // 是否自定义消息
  bool get isCustom => typ == messageTypeCustom;

  Signaling? _signaling;

  Signaling get signaling {
    _signaling ??= Signaling()..init(this);
    return _signaling!;
  }

  void setSignaling(Signaling v) {
    _signaling = v;
  }

  int get deleted => getValue('deleted', 0);

  set deleted(int v) => setValue('deleted', v);

  get isDeleted => deleted == 1;

  bool get isSystemMsg {
    if (this.typ > 10000) {
      return true;
    }
    return false;
  }

  // 聊天室可显示的类型（待补充）
  bool get isChatRoomVisible {
    return typ != messageTypeDate &&
        typ != messageTypeUnreadBar &&
        typ != messageTypeDeleted &&
        typ != messageTypeEdit &&
        typ != messageTypeAudioChatOpen &&
        typ != messageTypeAudioChatInvite &&
        typ != messageTypeAudioChatClose &&
        typ != messageTypeAddReactEmoji &&
        typ != messageTypeRemoveReactEmoji &&
        typ != messageTypeGetRed &&
        typ != messageStartCall &&
        typ != messageTypePin &&
        typ != messageTypeUnPin &&
        (typ != messageEndCall ||
            (typ == messageEndCall && !objectMgr.userMgr.isMe(send_id))) &&
        (typ != messageRejectCall ||
            (typ == messageRejectCall && !objectMgr.userMgr.isMe(send_id))) &&
        !isDeleted &&
        !isExpired &&
        isShow &&
        typ != 20002
        // &&
        // typ != 20003
    ;
  }

  bool get canCountDate {
    return !isDeleted && !isExpired && typ != messageTypeDeleted;
  }

  bool get isValidLastMessage {
    return typ != messageTypeDate &&
        typ != messageTypeUnreadBar &&
        typ != messageTypeDeleted &&
        typ != 20002 &&
        typ != 20003 &&
        !isDeleted &&
        !isExpired &&
        isShow;
  }

  setRead(Chat chat, {bool force = false}) {
    if (typ != messageTypeUnreadBar && typ != messageTypeDate) {
      if (read_num == 0) {
        /// 小于或等于已读idx
        if (chat.read_chat_msg_idx >= chat_idx) {
          read_num = 1;
        } else {
          if (isDeleted || isExpired || force || isSystemMsg) {
            read_num = 1;
          }
        }
      }
    }
  }

  bool get isMediaType =>
      typ == messageTypeImage ||
      typ == messageTypeVideo ||
      typ == messageTypeReel ||
      typ == messageTypeNewAlbum;

  @override
  init(Map<String, dynamic> json) {
    // 合并模式: 将老对象不存在的key复制到json中,然后盖上
    for (int i = 0; i < json.length; i++) {
      final key = json.keys.toList()[i];
      final value = json[key];

      if (key == 'id') {
        setValue('message_id', value);
      }

      if (key == 'at_user' || key == 'at_users') {
        List<MentionModel> atUsers = [];
        if (value is List) {
          value.forEach((element) {
            atUsers.add(MentionModel.fromJson(element));
          });
        }

        if (value is String && value != '[]' && value.isNotEmpty) {
          atUsers = jsonDecode(value)
              .map<MentionModel>((e) => MentionModel.fromJson(e))
              .toList();
        }
        setValue('at_users', atUsers);
        continue;
      }

      if (key == 'emojis') {
        List<EmojiModel> emojis = [];
        if (value is String && value != '[]' && value.isNotEmpty) {
          emojis = jsonDecode(value)
              .map<EmojiModel>((e) => EmojiModel.fromJson(e))
              .toList();
        }
        setValue('emojis', emojis);
        continue;
      }

      if (value != null) {
        setValue(key, value);
      }
    }
    setValue('id', getID());
  }

  int getID() {
    return (send_id << 48) ^ (chat_id << 24) ^ send_time;
  }

  Message copyWith(Message? message) {
    return Message()
      ..id = message?.id ?? id
      ..message_id = message?.message_id ?? message_id
      ..chat_id = message?.chat_id ?? chat_id
      ..send_id = message?.send_id ?? send_id
      ..typ = message?.typ ?? typ
      ..content = message?.content ?? content
      ..create_time = message?.create_time ?? create_time
      ..expire_time = message?.expire_time ?? expire_time
      ..chat_idx = message?.chat_idx ?? chat_idx
      ..read_num = message?.read_num ?? read_num
      ..deleted = message?.deleted ?? deleted
      ..edit_time = message?.edit_time ?? edit_time
      ..send_time = message?.send_time ?? send_time
      .._sendState = message?._sendState ?? _sendState
      .._uploadProgress = message?._uploadProgress ?? _uploadProgress
      .._totalSize = message?._totalSize ?? _totalSize
      ..atUser = message?.atUser ?? atUser;
  }

  //内容解析数据
  @override
  dynamic decodeContent({required dynamic cl, String? v = null}) {
    //判断是否有指定解析字符串  如果没有 就默认content
    if (v == null) v = content;
    return super.decodeContent(cl: cl, v: v);
  }

  Message removeReplyContent() {
    final Map<String, dynamic> content = jsonDecode(this.content);
    if (content.containsKey('reply')) content.remove('reply');
    this.content = jsonEncode(content);
    return this;
  }

  Message processMentionContent() {
    final Map<String, dynamic> content = jsonDecode(this.content);

    if (content.containsKey('text')) {
      content['text'] = ChatHelp.formalizeMentionContent(content['text'], this);
    } else if (content.containsKey('caption')) {
      if (content['caption'] != null) {
        content['caption'] =
            ChatHelp.formalizeMentionContent(content['caption'], this);
      }
    }

    this.content = jsonEncode(content);
    return this;
  }

  dynamic getMessageModel(int type) {
    switch (type) {
      case messageTypeText:
      case messageTypeReply:
      case messageTypeLink:
        return MessageText.creator;
      case messageTypeImage:
        return MessageImage.creator;
      case messageTypeVideo:
      case messageTypeReel:
        return MessageVideo.creator;
      case messageTypeNewAlbum:
        return NewMessageMedia.creator;
      case messageTypeVoice:
        return MessageVoice.creator;
      case messageTypeFile:
        return MessageFile.creator;
      case messageTypeFace:
        return MessageFace.creator;
      case messageTypeGroupJoined:
        return MessageSystem.creator;
      case messageTypeRecommendFriend:
        return MessageJoinGroup.creator;
      case messageTypeLocation:
        return MessageMyLocation.creator;
    }
  }

  bool get hasReply => typ == messageTypeReply;

  String? get replyModel =>
      hasReply ? this.decodeContent(cl: getMessageModel(typ)).reply : null;

  bool isMentionMessage(int uid) {
    bool find = false;
    if (atUser.isEmpty) {
      return find;
    }
    String searchText = "⅏⦃${uid}@jx❦⦄";
    atUser.forEach((user) {
      if (user.userId == uid && content.contains(searchText)) {
        find = true;
        return;
      }
    });
    return find;
  }

  void addEmoji(EmojiModel emoji) {
    List<EmojiModel> currentList = emojis; // 获取属性中的原始列表
    currentList.add(emoji); // 向列表中添加元素
    emojis = currentList; // 更新属性值
  }

  void delEmoji(EmojiModel emoji) {
    List<EmojiModel> currentList = emojis; // 获取属性中的原始列表
    currentList.remove(emoji); // 向列表中添加元素
    emojis = currentList; // 更新属性值
  }

  //本地图片/视频  (类型有可能是AssetEntity或File)
  dynamic asset;

  /////////////////////发送状态/////////////////////////////////
  static const String eventSendState = "eventSendState";
  static const String eventSendProgress = "eventMessageSendProgress";
  static const String eventAlbumUpdateState = "eventAlbumUpdateState";
  static const String eventAlbumUploadProgress = "eventAlbumUploadProgress";

  static const String eventAssetUpdate = "eventAssetUpdate";

  static const String eventAlbumBeanUpdate = "eventAlbumBeanUpdate";
  static const String eventAlbumAssetProcessComplete =
      "eventAlbumAssetProcessComplete";
  static const String eventConvertText = 'eventConvertText';
  static const String eventDownloadProgress = 'eventDownloadProgress';

  int _sendState = MESSAGE_SEND_SUCCESS;

  int get sendState {
    if (getValue('message_id', 0) == 0) {
      _sendState = MESSAGE_SEND_FAIL;
    }
    return getValue("sendState", _sendState);
  }

  set sendState(int v) {
    if (v != MESSAGE_SEND_ING) {
      _uploadProgress = 0.0;
    }
    bool _needEvent = v != _sendState;
    _sendState = v;
    setValue("sendState", v);
    if (_needEvent) event(this, Message.eventSendState, data: this);
  }

  double _uploadProgress = 0.0;

  double get uploadProgress => getValue("uploadProgress", _uploadProgress);

  set uploadProgress(double val) {
    if (_uploadProgress != val) {
      _uploadProgress = val;
      setValue("uploadProgress", val);
      event(this, Message.eventSendProgress);
    }
  }

  bool showDoneIcon = false;

  // todo: add current upload status
  // 0: Display Duration, 1: Preparing | Compressing (40%), 2: Md5 Checksum (45%), 3: Uploading (90%), 4: Polling (95%), 5: Complete(100%)
  int _uploadStatus = 0;

  int get uploadStatus => getValue("uploadStatus", _uploadStatus);

  set uploadStatus(int val) {
    if (_uploadStatus != val) {
      _uploadStatus = val;
      setValue("uploadStatus", val);
      event(this, Message.eventSendProgress);
    }
  }

  int _totalSize = 0;

  int get totalSize => getValue("totalSize", _totalSize);

  set totalSize(int val) {
    if (_totalSize != val) {
      _totalSize = val;
      setValue("totalSize", val);
      event(this, Message.eventSendProgress);
    }
  }

  Map<String, int> _albumFileSize = {};

  Map<String, int> get albumFileSize =>
      getValue("albumFileSize", _albumFileSize);

  set albumFileSize(Map<String, int> sizeMap) {
    _albumFileSize = sizeMap;
    setValue("albumFileSize", _albumFileSize);
    event(this, eventAlbumUpdateState);
  }

  Map<String, int> albumUpdateStatus = {};

  Map<String, double> albumUpdateProgress = {};

  /// 发送成功
  bool get isSendOk {
    return sendState == MESSAGE_SEND_SUCCESS;
  }

  //发送失败
  bool get isSendFail {
    return sendState == MESSAGE_SEND_FAIL;
  }

  //是否发送慢
  bool get isSendSlow {
    return sendState == MESSAGE_SEND_ING;
  }

  bool isHideShow = false;

  void resetUploadStatus() {
    _uploadProgress = 0.0;
    _uploadStatus = 0;
    _totalSize = 0;
    _albumFileSize = {};
    albumUpdateStatus = {};
    albumUpdateProgress = {};
  }

  ////////////////////////////////////////

  static Message creator() {
    return Message();
  }

  Map<String, dynamic> toJson() {
    return {
      "id": getID(),
      "message_id": message_id,
      "chat_id": chat_id,
      "chat_idx": chat_idx,
      "send_id": send_id,
      "content": content,
      "typ": typ,
      "create_time": create_time,
      "update_time": update_time,
      "expire_time": expire_time,
      "read_num": read_num,
      "deleted": deleted,
      "at_users": jsonEncode(atUser).toString(),
      "emojis": jsonEncode(emojis).toString(),
      "send_time": send_time,
      "edit_time": edit_time,
    };
  }

  @override
  String toString() {
    return '''
    Message{id: $id, 
    message_id: $message_id, 
    chat_id: $chat_id, 
    send_id: $send_id, 
    typ: $typ, 
    content: $content, 
    send_time: $send_time, 
    chat_idx: $chat_idx, 
    is_opt: $is_opt, 
    read_num: $read_num, 
    isShow: $isShow, 
    msg: $msg, 
    deleted: $deleted, 
    origin: $origin, 
    create_time: $create_time, 
    update_time: $update_time, 
    edit_time: $edit_time, 
    expire_time: $expire_time, 
    atUser: $atUser, 
    emojis: $emojis, 
    sendState: $sendState, 
    uploadProgress: $uploadProgress, 
    totalSize: $totalSize,
    albumFileSize: $albumFileSize, 
    albumUpdateStatus: $albumUpdateStatus, 
    albumUpdateProgress: $albumUpdateProgress, 
    isHideShow: $isHideShow, 
    _sendState: $_sendState,
    _signaling: $_signaling, 
    select: $select, 
    isDeleted: $isDeleted, 
    isSystemMsg: $isSystemMsg, 
    isChatRoomVisible: $isChatRoomVisible, 
    isMediaType: $isMediaType, 
    hasReply: $hasReply,
    isMentionMessage: $isMentionMessage, 
    isExpired: $isExpired, 
    isCustom: $isCustom, 
    isCalling: $isCalling, 
    isSwipeToReply: $isSwipeToReply, 
    isShow: $isShow, 
    isDeleted: $isDeleted, 
    isExpired: $isExpired, 
    isSystemMsg: $isSystemMsg, 
    canCountDate: $canCountDate, 
    isValidLastMessage: $isValidLastMessage,
    isHideShow: $isHideShow}
    ''';
  }

  createUnReadBarMessage() {
    return Message();
  }

  bool get isCalling {
    const callingType = [
      messageDiscussCall,
      messageCloseDiscussCall,
      messageBusyCall,
      messageCancelCall,
      messageMissedCall,
      messageStartCall,
      messageEndCall,
      messageRejectCall
    ];
    return callingType.contains(typ);
  }

  bool get isSwipeToReply => swipeToReplyTypes.contains(typ);
}

/// 文本消息
class MessageText {
  /// 消息内容
  String text = '';
  String richText = '';

  String reply = '';

  bool showAll = false;

  ///直播新增用户信息
  String nickName = '';
  int userHead = 0;

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('text')) text = json['text'];
    if (json.containsKey('rich_text')) richText = json['rich_text'];
    if (json.containsKey('reply')) reply = json['reply'] ?? '';
    if (json.containsKey('nick_name')) nickName = json['nick_name'];
    if (json.containsKey('user_head')) userHead = json['user_head'];
    if (json.containsKey('forward_user_id'))
      forward_user_id = json['forward_user_id'];
    if (json.containsKey('forward_user_name'))
      forward_user_name = json['forward_user_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'nick_name': nickName,
      'user_head': userHead,
      'text': text,
      'reply': reply,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
    };
  }

  static MessageText creator() {
    return MessageText();
  }
}

class MessageDelete {
  int uid = 0;
  List<int> message_ids = <int>[];

  // if delete for me is 0 else 1
  int all = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('uid')) uid = json['uid'];
    if (json.containsKey('message_ids'))
      message_ids = json['message_ids'].cast<int>();
    if (json.containsKey('all')) all = json['all'];
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'message_ids': message_ids,
      'all': all,
    };
  }

  static MessageDelete creator() {
    return MessageDelete();
  }
}

class MessageEdit {
  int chat_id = 0;
  int chat_idx = 0;
  int related_id = 0;
  String content = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('chat_id')) chat_id = json['chat_id'];
    if (json.containsKey('chat_idx')) chat_idx = json['chat_idx'];
    if (json.containsKey('related_id')) related_id = json['related_id'];
    if (json.containsKey('content')) content = json['content'];
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chat_id,
      'chat_idx': chat_idx,
      'related_id': related_id,
      'content': content,
    };
  }

  static MessageEdit creator() {
    return MessageEdit();
  }
}

class MessageLink {
  String title = '';
  String icon = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('title')) title = json['title'];
    if (json.containsKey('icon')) icon = json['icon'];
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'icon': icon,
    };
  }

  static MessageLink creator() {
    return MessageLink();
  }
}

class MessageTransferMoney {
  String amount = '';
  String currency = '';
  String remark = '恭喜发财，大吉大利';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('amount')) amount = json['amount'];
    if (json.containsKey('currency')) currency = json['currency'];
    if (json.containsKey('remark')) {
      final jsonRemark = json['remark'];
      if (jsonRemark != null && jsonRemark is String && jsonRemark.isNotEmpty) {
        remark = jsonRemark;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'remark': remark,
    };
  }

  static MessageTransferMoney creator() {
    return MessageTransferMoney();
  }
}

class NewMessageMedia {
  int? chat_id;
  List<AlbumDetailBean>? albumList;
  String caption = "";
  String reply = "";
  bool showOriginal = false;

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';
  int forward_original_message_id = 0;
  int forward_original_chat_id = -1;

  applyJson(Map<String, dynamic> json) {
    List<AlbumDetailBean> list = List.empty(growable: true);
    if (json.containsKey('albumList')) {
      for (Map<String, dynamic> item in json['albumList']) {
        list.add(AlbumDetailBean.fromJson(item));
      }
    }
    albumList = list;
    if (json.containsKey('chat_id')) chat_id = json['chat_id'];
    if (json.containsKey('caption')) caption = json['caption'] ?? '';
    if (json.containsKey('showOriginal')) showOriginal = json['showOriginal'];
    if (json.containsKey('forward_user_id'))
      forward_user_id = json['forward_user_id'];
    if (json.containsKey('forward_user_name'))
      forward_user_name = json['forward_user_name'];
    if (json.containsKey('forward_original_message_id'))
      forward_original_message_id = json['forward_original_message_id'];
    if (json.containsKey('forward_original_chat_id'))
      forward_original_chat_id = json['forward_original_chat_id'];
  }

  Map<String, dynamic> toJson() {
    return {
      'albumList': albumList,
      'chat_id': chat_id,
      'caption': caption,
      'showOriginal': showOriginal,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
      'forward_original_message_id': forward_original_message_id,
      'forward_original_chat_id': forward_original_chat_id,
    };
  }

  static NewMessageMedia creator() {
    return NewMessageMedia();
  }
}

/// 相册详情
class AlbumDetailBean {
  // 相册创建的时候需要优先设置
  // 方便后续取消, 重传的使用
  String? asid;
  int? astypeint;
  int? aswidth;
  int? asheight;

  ///下载的key
  String url = '';

  // 原始地址
  String source = '';
  String fileHash = '';

  /// 文件名 图片或者视频
  String fileName = '';
  String filePath = '';

  //封面图片
  String cover = '';
  String coverPath = '';

  String? mimeType;

  /// 文件大小
  int size = 0;

  /// 视频 时长
  int seconds = 0;

  /// 图片顺序
  String? index_id = "";

  String caption = '';

  /// 临时存储
  Message? _currentMessage;
  dynamic asset;

  bool showOriginal = false;

  int sendTime = 0;

  Message get currentMessage {
    if (_currentMessage == null) {
      throw "代码出现了未赋值的情况";
    }
    return _currentMessage!;
  }

  set currentMessage(Message msg) {
    _currentMessage = msg;
  }

  AlbumDetailBean({
    required this.url,
    this.asid,
    this.astypeint,
    this.aswidth,
    this.asheight,
    this.mimeType,
    this.index_id,
    this.seconds = 0,
  });

  AlbumDetailBean.fromJson(Map<String, dynamic> json) {
    index_id = json['index_id'];
    asid = json['asid'];
    astypeint = json['astypeint'];
    aswidth = json['aswidth'];
    asheight = json['asheight'];
    url = json['url'] ?? '';
    source = json['source'] ?? '';
    fileHash = json['fileHash'] ?? '';
    mimeType = json['mimeType'];
    seconds = json['seconds'] ?? 0;
    size = json['size'] ?? 0;
    cover = json['cover'] ?? "";
    coverPath = json['coverPath'] ?? "";
    caption = json['caption'] ?? "";
    fileName = json['fileName'] ?? "";
    filePath = json['filePath'] ?? "";

    sendTime = json['sendTime'] ?? 0;

    showOriginal = json['showOriginal'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['index_id'] = this.index_id;
    data['asid'] = this.asid;
    data['astypeint'] = this.astypeint;
    data['aswidth'] = this.aswidth;
    data['asheight'] = this.asheight;
    data['url'] = this.url;
    data['source'] = this.source;
    data['fileHash'] = this.fileHash;
    data['mimeType'] = this.mimeType;
    data['size'] = this.size;
    data['seconds'] = this.seconds;
    data['cover'] = this.cover;
    data['coverPath'] = this.coverPath;
    data['caption'] = this.caption;
    data['fileName'] = this.fileName;
    data['filePath'] = this.filePath;

    data['sendTime'] = this.sendTime;

    data['showOriginal'] = this.showOriginal;
    return data;
  }
}

/// 系统消息
class MessageInterval {
  int interval = 0;
  int owner = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('interval')) interval = json['interval'];
    if (json.containsKey('owner')) owner = json['owner'];
  }

  Map<String, dynamic> toJson() {
    return {
      'interval': interval,
      'owner': owner,
    };
  }

  static MessageInterval creator() {
    return MessageInterval();
  }
}

/// 图片消息
class MessageImage {
  /// 下载地址id
  String url = '';
  String fileName = '';
  String filePath = '';

  /// 图片数据大小，单位：字节
  int size = 0;
  int width = 0;
  int height = 0;

  int sendTime = 0;

  String caption = '';
  String reply = '';

  bool showOriginal = false;

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  applyJson(Map<String, dynamic> json) {
    if (json.containsKey('url')) url = json['url'].toString();
    if (json.containsKey('size')) size = json['size'];
    if (json.containsKey('width')) width = json['width'];
    if (json.containsKey('height')) height = json['height'];
    if (json.containsKey('sendTime')) sendTime = json['sendTime'];
    if (json.containsKey('fileName') && json['fileName'] != null)
      fileName = json['fileName'];
    if (json.containsKey('filePath') && json['filePath'] != null)
      filePath = json['filePath'];
    if (json.containsKey('caption') && json['caption'] != null)
      caption = json['caption'];
    if (json.containsKey('reply') && json['reply'] != null)
      reply = json['reply'];
    if (json.containsKey('showOriginal')) showOriginal = json['showOriginal'];
    if (json.containsKey('forward_user_id'))
      forward_user_id = json['forward_user_id'];
    if (json.containsKey('forward_user_name'))
      forward_user_name = json['forward_user_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'size': size,
      'width': width,
      'height': height,
      'sendTime': sendTime,
      'caption': caption,
      'reply': reply,
      'showOriginal': showOriginal,
      'fileName': fileName,
      'filePath': filePath,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
    };
  }

  static MessageImage creator() {
    return MessageImage();
  }
}

/// 语音消息
class MessageVoice {
  int id = 0;
  String url = ''; // 下载地址
  String? localUrl = null; //本地地址
  int size = 0; // 图片数据大小，单位：字节
  int second = 0; // 语音长度 单位/秒
  int flag = 0; // 下载方式标记,为1标识需要通过cdn作为前缀， 为2表示可以直接通过url下载
  List decibels = List.empty(growable: true);

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';
  String reply = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('id')) id = json['id'];
    if (json.containsKey('vmpath')) localUrl = json['vmpath'];
    if (json.containsKey('url')) url = json['url'];
    if (json.containsKey('size')) size = json['size'];
    if (json.containsKey('second')) second = json['second'];
    if (json.containsKey('flag')) flag = json['flag'];
    if (json.containsKey('decibels')) decibels = json['decibels'];
    if (json.containsKey('forward_user_id'))
      forward_user_id = json['forward_user_id'];
    if (json.containsKey('forward_user_name'))
      forward_user_name = json['forward_user_name'];
    if (json.containsKey('reply') && json['reply'] != null)
      reply = json['reply'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'size': size,
      'second': second,
      'flag': flag,
      'decibels': decibels,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
      'reply': reply,
    };
  }

  static MessageVoice creator() {
    return MessageVoice();
  }
}

/// 视频消息
class MessageVideo {
  // 视频hls地址
  String url = '';

  // 原始地址
  String source = '';
  String fileHash = '';
  String fileName = '';
  String filePath = '';

  // 图片数据大小，单位：字节
  int size = 0;
  int width = 0;
  int height = 0;

  int sendTime = 0;

  // 下载方式标记,为1标识需要通过cdn作为前缀， 为2表示可以直接通过url下载

  int second = 0; // 语音长度 单位/秒

  //封面图片
  String cover = '';
  String coverPath = '';

  /// 附加消息
  String caption = '';

  String reply = '';

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('url')) url = json['url'];
    if (json.containsKey('source')) source = json['source'];
    if (json.containsKey('fileHash')) fileHash = json['fileHash'];
    if (json.containsKey('fileName') && json['fileName'] != null)
      fileName = json['fileName'];
    if (json.containsKey('filePath') && json['filePath'] != null)
      filePath = json['filePath'];
    if (json.containsKey('size')) size = json['size'];
    if (json.containsKey('width')) width = json['width'];
    if (json.containsKey('height')) height = json['height'];
    if (json.containsKey('sendTime')) sendTime = json['sendTime'];

    if (json.containsKey('second')) second = json['second'];
    if (json.containsKey('cover')) cover = '${json['cover']}';
    if (json.containsKey('coverPath')) coverPath = '${json['coverPath']}';

    if (json.containsKey('caption') && json['caption'] != null)
      caption = json['caption'];
    if (json.containsKey('reply') && json['reply'] != null)
      reply = json['reply'];
    if (json.containsKey('forward_user_id'))
      forward_user_id = json['forward_user_id'];
    if (json.containsKey('forward_user_name'))
      forward_user_name = json['forward_user_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'source': source,
      'fileHash': fileHash,
      'size': size,
      'width': width,
      'height': height,
      'sendTime': sendTime,
      'second': second,
      'fileName': fileName,
      'filePath': filePath,
      'cover': cover,
      'coverPath': coverPath,
      'caption': caption,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
    };
  }

  static MessageVideo creator() {
    return MessageVideo();
  }
}

/// 表情消息
class MessageFace {
  /// 表情集名称（例如：表情对应的文件夹名称）
  String category_name = '';

  /// 贴图名称（例如：贴图文件名.扩展名）
  String sticker_name = '';

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('category_name')) {
      category_name = json['category_name'];
    }
    if (json.containsKey('sticker_name')) sticker_name = json['sticker_name'];
    if (json.containsKey('forward_user_id'))
      forward_user_id = json['forward_user_id'];
    if (json.containsKey('forward_user_name'))
      forward_user_name = json['forward_user_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'category_name': category_name,
      'sticker_name': sticker_name,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
    };
  }

  static MessageFace creator() {
    return MessageFace();
  }
}

class MessageReactEmoji {
  int id = 0;
  int chatId = 0;
  int messageId = 0;
  int userId = 0;
  String emoji = '';
  int refId = 0;
  int chatIdx = 0;
  int typ = 0;

  static String emojiNameOldToNew(String emoji) {
    switch (emoji) {
      case 'thumbs-up-2.json':
        return 'emoji_thumb_up.webp';
      case 'heart-1.json':
        return 'emoji_smile_with_heart.webp';
      case 'beaming-face.json':
        return 'emoji_thumb_down.webp';
      case 'astonished-face.json':
        return 'emoji_fire.webp';
      case 'angry-face.json':
        return 'emoji_smile.webp';
      case 'anxious-face.json':
        return 'emoji_heart.webp';
    }
    return 'emoji_thumb_up.webp';
  }

  static String emojiNameNewToOld(String emoji) {
    switch (emoji) {
      case 'emoji_thumb_up.webp':
        return 'thumbs-up-2.json';
      case 'emoji_smile_with_heart.webp':
        return 'heart-1.json';
      case 'emoji_thumb_down.webp':
        return 'beaming-face.json';
      case 'emoji_fire.webp':
        return 'astonished-face.json';
      case 'emoji_smile.webp':
        return 'angry-face.json';
      case 'emoji_heart.webp':
        return 'anxious-face.json';
    }
    return 'thumbs-up-2.json';
  }

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('chat_id')) chatId = json['chat_id'];
    if (json.containsKey('message_id')) messageId = json['message_id'];
    if (json.containsKey('user_id')) userId = json['user_id'];
    if (json.containsKey('emoji')) emoji = json['emoji'];
    if (json.containsKey('ref_id')) refId = json['ref_id'];
    if (json.containsKey('chat_idx')) chatIdx = json['chat_idx'];
    if (json.containsKey("typ")) typ = json["typ"];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'message_id': messageId,
      'user_id': userId,
      'emoji': emoji,
      'ref_id': refId,
      'chat_idx': chatIdx,
      'typ': typ,
    };
  }

  static MessageReactEmoji creator() {
    return MessageReactEmoji();
  }

  initBy(Message message) {
    this.id = message.id;
    this.chatIdx = message.chat_idx;
    this.typ = message.typ;
  }

  bool isSame(dynamic obj) {
    return id == obj.id &&
        chatId == obj.chatId &&
        chatIdx == obj.chatIdx &&
        messageId == obj.messageId &&
        userId == obj.userId &&
        typ == obj.typ;
  }
}

/// 文件消息
class MessageFile {
  /// 下载地址
  String url = '';

  String reply = '';

  ///id
  int file_id = 0;

  ///大小
  int length = 0;

  ///文件名称
  String file_name = '';

  ///文件类型 doc,els,ppt
  String suffix = '';

  String caption = '';

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('file_id')) file_id = json['file_id'];
    if (json.containsKey('url')) url = json['url'];
    if (json.containsKey('length')) length = json['length'];
    if (json.containsKey('file_name')) file_name = json['file_name'];
    if (json.containsKey('suffix')) suffix = json['suffix'];
    if (json.containsKey('caption')) caption = json['caption'];
    if (json.containsKey('reply') && json['reply'] != null)
      reply = json['reply'];
    if (json.containsKey('forward_user_id'))
      forward_user_id = json['forward_user_id'];
    if (json.containsKey('forward_user_name'))
      forward_user_name = json['forward_user_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'file_id': file_id,
      'url': url,
      'length': length,
      'file_name': file_name,
      'suffix': suffix,
      'caption': caption,
      'reply': reply,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
    };
  }

  static MessageFile creator() {
    return MessageFile();
  }
}

/// 系统消息
class MessageSystem {
  String text = '';
  int uid = 0;
  List<int> uids = [];

  String nickname = '';
  int inviter = 0;
  int owner = 0;

  int createTime = 0;
  int isEnabled = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('text')) text = json['text'];
    if (json.containsKey('uid')) {
      if (json['uid'] is List) {
        uids = json['uid']
            .map<int>((e) => e is String ? int.parse(e) : e as int)
            .toList();
      } else {
        uid = json['uid'];
      }
    }

    if (json.containsKey('nick_name')) nickname = json['nick_name'];
    if (json.containsKey('owner')) owner = json['owner'];
    if (json.containsKey('inviter')) inviter = json['inviter'];

    if (json.containsKey('create_time')) createTime = json['create_time'];
    if (json.containsKey('enable')) isEnabled = json['enable'];
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'uid': uid,
      'uids': uids,
      'nick_name': nickname,
      'owner': owner,
      'inviter': inviter,
      'create_time': createTime,
      'enable': isEnabled,
    };
  }

  static MessageSystem creator() {
    return MessageSystem();
  }
}

/// 红包消息
class MessageRed {
  /// 红包id
  String id = '';

  // 红包类型
  RedPacketType rpType = RedPacketType.none;

  // 红包信息
  String remark = '';

  // 过期时间
  int expireTime = 0;

  // 创建时间
  int createTime = 0;

  // 币种类型
  String currency = '';

  // 红包总金额
  String totalAmount = '';

  // 红包总数量
  int totalNum = 0;

  List<int> recipientIDs = [];

  // 被领取数额
  String receiveAmount = '';

  // 被领取数量
  int receiveNum = 0;

  String receiveInfos = '';

  int userId = 0;

  int senderUid = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('id')) id = json['id'];
    if (json.containsKey('rp_type')) {
      if (json['rp_type'] == 'LUCKY_RP') {
        rpType = RedPacketType.luckyRedPacket;
      } else if (json['rp_type'] == 'STANDARD_RP') {
        rpType = RedPacketType.normalRedPacket;
      } else {
        rpType = RedPacketType.exclusiveRedPacket;
      }
    }
    if (json.containsKey('remark')) remark = json['remark'];
    if (json.containsKey('currency')) currency = json['currency'];
    if (json.containsKey('total_num')) totalNum = json['total_num'];
    if (json.containsKey('total_amount')) totalAmount = json['total_amount'];
    if (json.containsKey('recipient_ids') && json['recipient_ids'] != null)
      recipientIDs = json['recipient_ids'].toList().cast<int>();
    if (json.containsKey('expire_time')) expireTime = json['expire_time'];
    if (json.containsKey('create_time')) createTime = json['create_time'];

    if (json.containsKey('user_id')) userId = json['user_id'];
    if (json.containsKey('sender_uid')) senderUid = json['sender_uid'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rpType': rpType,
      'remark': remark,
      'expireTime': expireTime,
      'create_time': createTime,
    };
  }

  static MessageRed creator() {
    return MessageRed();
  }
}

class MessagePin {
  int id = 0;
  int chatId = 0;
  int sendId = 0;
  List<int> messageIds = [];
  int isPin = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('id')) id = json['id'];
    if (json.containsKey('chat_id')) chatId = json['chat_id'];
    if (json.containsKey('send_id')) sendId = json['send_id'];
    if (json.containsKey('message_id'))
      messageIds = List.from(json['message_id']);
    if (json.containsKey('is_pin')) isPin = json['is_pin'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'send_id': sendId,
      'message_id': messageIds,
      'is_pin': isPin,
    };
  }

  static MessagePin creator() {
    return MessagePin();
  }
}

class MessageCall {
  int inviter = 0;

  /// 通话时长
  int time = 0;

  int chat_id = 0;

  String rtc_channel_id = '';

  List receiver = [];

  bool userInCall = false;

  int status = 0;

  int is_videocall = 0;

  void applyJson(Map<String, dynamic> json) {
    if (json.containsKey('time')) time = json['time'];
    if (json.containsKey('chat_id')) chat_id = json['chat_id'];
    if (json.containsKey('inviter')) inviter = json['inviter'];
    if (json.containsKey('rtc_channel_id'))
      rtc_channel_id = json['rtc_channel_id'] ?? "";
    if (json.containsKey('receiver')) receiver = json['receiver'];
    if (json.containsKey('user_in_call')) userInCall = json['user_in_call'];
    if (json.containsKey('status')) status = json['status'];
    if (json.containsKey('is_videocall')) is_videocall = json['is_videocall'];
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'chat_id': chat_id,
      'inviter': inviter,
      'rtc_channel_id': rtc_channel_id,
      'receiver': receiver,
      'user_in_call': userInCall,
      'status': status,
      'is_videocall': is_videocall
    };
  }

  static MessageCall creator() {
    return MessageCall();
  }
}

/// 欢迎进群
class MessageJoinGroup {
  /// 用户id
  int user_id = 0;

  /// 用户昵称
  String nick_name = '';

  /// 用户头像
  int head = 0;

  String countryCode = '';
  String contact = '';

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('user_id')) user_id = json['user_id'];
    if (json.containsKey('nick_name')) nick_name = json['nick_name'];
    if (json.containsKey('head')) head = json['head'];
    if (json.containsKey('country_code')) countryCode = json['country_code'];
    if (json.containsKey('contact')) contact = json['contact'];
    if (json.containsKey('forward_user_id'))
      forward_user_id = json['forward_user_id'];
    if (json.containsKey('forward_user_name'))
      forward_user_name = json['forward_user_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': user_id,
      'nick_name': nick_name,
      'head': head,
      'country_code': countryCode,
      'contact': contact,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
    };
  }

  static MessageJoinGroup creator() {
    return MessageJoinGroup();
  }
}

///直播间设置或语音房设置
class MessageLiveSet {
  /// 弹幕限制
  int barrageLimit = 0;

  /// 发言限制
  int speakLimit = 0;

  /// 弹幕价格
  int barragePrice = 0;

  /// 房间封面
  int icon = 0;

  /// 房间封面
  String title = '';

  /// 房间公告
  String notice = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('barrage_limit')) barrageLimit = json['barrage_limit'];
    if (json.containsKey('speak_limit')) speakLimit = json['speak_limit'];
    if (json.containsKey('barrage_price')) barragePrice = json['barrage_price'];
    if (json.containsKey('icon')) icon = json['icon'];
    if (json.containsKey('title')) title = json['title'];
    if (json.containsKey('notice')) notice = json['notice'];
  }

  Map<String, dynamic> toJson() {
    return {
      'barrage_limit': barrageLimit,
      'speak_limit': speakLimit,
      'barrage_price': barragePrice,
      'icon': icon,
      'title': title,
      'notice': notice,
    };
  }

  static MessageLiveSet creator() {
    return MessageLiveSet();
  }
}

///直播间主播状态
class MessageLiveState {
  /// 0.正常 1.后台
  int state = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('state')) state = json['state'];
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
    };
  }

  static MessageLiveState creator() {
    return MessageLiveState();
  }
}

///直播间金币
class MessageLiveGold {
  int gold = 0;
  int devote = 0;
  int id = 0;
  String top_rank = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('gold')) gold = json['gold'];
    if (json.containsKey('devote')) devote = json['devote'];
    if (json.containsKey('id')) id = json['id'];
    if (json.containsKey('top_rank')) top_rank = json['top_rank'];
  }

  Map<String, dynamic> toJson() {
    return {
      'gold': gold,
      'devote': devote,
      'id': id,
      'top_rank': top_rank,
    };
  }

  static MessageLiveGold creator() {
    return MessageLiveGold();
  }
}

///直播间氛围音效
class MessageLiveAtmosphere {
  /// 音效下标
  int atmosphereIndex = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('atmosphere_index')) {
      atmosphereIndex = json['atmosphere_index'];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'atmosphere_index': atmosphereIndex,
    };
  }

  static MessageLiveAtmosphere creator() {
    return MessageLiveAtmosphere();
  }
}

//直播间分享给好友或群聊
class MessageShareLive {
  /// 直播间id
  int roomId = 0;

  /// 直播间封面
  int cover = 0;

  /// 直播间主题
  String title = '';

  /// 1.语音房 0.直播间
  int type = 0;

  ///主播头像
  int head = 0;

  ///主播昵称
  String nickName = '';

  ///语音房类型 1.多人语聊 2.KTV
  int titleType = 0;

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('room_id')) roomId = json['room_id'];
    if (json.containsKey('cover')) cover = json['cover'];
    if (json.containsKey('title')) title = json['title'];
    if (json.containsKey('type')) type = json['type'];
    if (json.containsKey('head')) head = json['head'];
    if (json.containsKey('nick_name')) nickName = json['nick_name'];
    if (json.containsKey('title_type')) titleType = json['title_type'];
    if (json.containsKey('forward_user_id'))
      forward_user_id = json['forward_user_id'];
    if (json.containsKey('forward_user_name'))
      forward_user_name = json['forward_user_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'cover': cover,
      'title': title,
      'type': type,
      'nick_name': nickName,
      'head': head,
      'title_type': titleType,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
    };
  }

  static MessageShareLive creator() {
    return MessageShareLive();
  }
}

//背景音乐进度
class MessageMusicProgress {
  /// 音乐id
  int musicId = 0;

  /// 音乐名称
  String musicName = '';

  /// 音乐作者
  String author = '';

  /// 状态 //1.开始 2.结束 3.继续 4.暂停
  int status = 0;

  ///开始播放时间（毫秒）
  int beginS = 0;

  ///当前播放进度（秒）
  double currentS = 0.0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('id')) musicId = json['id'];
    if (json.containsKey('status')) status = json['status'];
    if (json.containsKey('beginS')) beginS = json['beginS'];
    if (json.containsKey('musicName')) musicName = json['musicName'];
    if (json.containsKey('author')) author = json['author'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': musicId,
      'status': status,
      'beginS': beginS,
      'musicName': musicName,
      'author': author,
    };
  }

  static MessageMusicProgress creator() {
    return MessageMusicProgress();
  }
}

//开始播放背景音乐
class MessagePlayMusic {
  /// 音乐id
  int musicId = 0;

  /// 点歌人id
  int userId = 0;

  ///当前播放时长（秒）
  String lyric = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('id')) musicId = json['id'];
    if (json.containsKey('user_id')) userId = json['user_id'];
    if (json.containsKey('lyric')) lyric = json['lyric'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': musicId,
      'user_id': userId,
      'lyric': lyric,
    };
  }

  static MessagePlayMusic creator() {
    return MessagePlayMusic();
  }
}

//我的位置
class MessageMyLocation {
  String latitude = '0';

  String longitude = '0';

  int mapSnap = 0;

  String name = '';

  String address = '';

  String city = '';

  String province = '';

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  String data = '';
  String url = '';
  String filePath = '';
  int type = 0; // 0 当前位置 2 共享位置
  int? startTime;
  int? duration;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('latitude')) latitude = json['latitude'];
    if (json.containsKey('longitude')) longitude = json['longitude'];
    if (json.containsKey('map_snap')) mapSnap = json['map_snap'];
    if (json.containsKey('name')) name = json['name'];
    if (json.containsKey('address')) address = json['address'];
    if (json.containsKey('city')) city = json['city'];
    if (json.containsKey('province')) province = json['province'];
    if (json.containsKey('data')) data = json['data'];
    if (json.containsKey('url')) url = json['url'];
    if (json.containsKey('filePath')) filePath = json['filePath'];
    if (json.containsKey('type')) type = json['type'];
    if (json.containsKey('startTime')) startTime = json['startTime'];
    if (json.containsKey('duration')) duration = json['duration'];
    if (json.containsKey('forward_user_id'))
      forward_user_id = json['forward_user_id'];
    if (json.containsKey('forward_user_name'))
      forward_user_name = json['forward_user_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'map_snap': mapSnap,
      'name': name,
      'address': address,
      'city': city,
      'province': province,
      'type': type,
      'startTime': startTime,
      'duration': duration,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
    };
  }

  static MessageMyLocation creator() {
    return MessageMyLocation();
  }
}

//小秘书推广
class MessageSecretaryRecommend {
  int urlIndex = 0;

  List<String> text = [];

  String url = '';

  int urlTyp = 0; //1外部 2内部

  int cover = 0;

  int page_id = 0;

  int page_params = 0;

  applyJson(Map<String, dynamic> json) async {
    urlIndex = (json['urlIndex'] != null) ? json['urlIndex'] : 0;
    if (json['text'] != null) {
      text = (json['text'] as List).map((e) => e.toString()).toList();
    }
    url = (json['url'] != null) ? json['url'] : '';
    urlTyp = (json['urlTyp'] != null) ? json['urlTyp'] : 0;
    cover = (json['cover'] != null) ? json['cover'] : 0;
    page_id = (json['page_id'] != null) ? json['page_id'] : 0;
    page_params = (json['page_params'] != null) ? json['page_params'] : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'urlIndex': urlIndex,
      'text': text,
      'url': url,
      'urlTyp': urlTyp,
      'cover': cover,
      'page_id': page_id,
      'page_params': page_params,
    };
  }

  static MessageSecretaryRecommend creator() {
    return MessageSecretaryRecommend();
  }
}

/// 自定义扩展消息
class MessageCustom {
  /// 自定义消息数据
  String data = '';

  /// 自定义消息描述信息
  String desc = '';

  /// 扩展字段
  String ext = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('data')) data = json['data'];
    if (json.containsKey('desc')) desc = json['desc'];
    if (json.containsKey('ext')) ext = json['ext'];
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'desc': desc,
      'ext': ext,
    };
  }

  static MessageCustom creator() {
    return MessageCustom();
  }
}
