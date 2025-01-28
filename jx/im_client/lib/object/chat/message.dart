import 'dart:convert';
import 'dart:typed_data';

import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/data/row_object.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/model/red_packet.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/translation_model.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/link_analyzer/parser.dart';
import 'package:jxim_client/utils/tg_album_util.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

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
const int messageTypeFriendLink = 26; // 好友链接
const int messageTypeGroupLink = 27; // 群组链接
const int messageTypeMarkdown = 28; // Markdown
const int messageTypeNote = 29; //搜藏笔记
const int messageTypeChatHistory = 30; //收藏聊天记录
const int messageTypeShareChat = 31; //小程序分享消息
const int messageTypeMiniAppDetail = 32; //管家工单消息

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
const int messageTypeExpiryTimeUpdate = 10030;
const int messageTypeExpiredSoon = 10031;
const int messageTypeEncryptionSettingChange = 10032;

const int messageStartCall = 11000;
const int messageEndCall = 11001;
const int messageRejectCall = 11002;

//命令类消息（定义范围12001～12999 客户端不可以主动发）
const int messageTypeEdit = 12001; // 编辑消息
const int messageTypeReqSignChat = 12002; // 需要给别的会话好友签会话密钥（请求）
const int messageTypeDeleted = 10023; // 删除消息的特殊消息

//命令类消息（定义范围13000～13999 客户端可以主动发）
const int messageTypeAddReactEmoji = 10008; // 表情react添加
const int messageTypeRemoveReactEmoji = 10009; // 表情react移除
//const int messageTypeAddReactEmoji = 13001; // 表情react添加
//const int messageTypeRemoveReactEmoji = 13002; // 表情react移除
const int messageTypeCommandFileOperate = 13003; // 文件操作命令(如语音消息是否被播放了）

/// 只有前端使用
const int messageTypeUnreadBar = 90000000001; // 未读消息条
const int messageTypeDate = 90000000002; // 未读消息条
const int messageTypeInBlock = 90000000003; // 被加入黑名单
const int messageTypeNotFriend = 90000000004; // 不是好友

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
  messageTypeRecommendFriend,
  messageTypeGroupLink,
  messageTypeSecretaryRecommend,
  messageTypeShareLocationStart,
  messageTypeShareLocationEnd,
  messageTypeSendRed,
  messageTypeTransferMoneySuccess,
  messageTypeReel,
  messageTypeGif,
  messageTypeNote,
  messageTypeChatHistory,
};

enum MessageFlag {
  ContentViewed(1); //内容是否查看

  final int value;

  const MessageFlag(this.value);
}

class Message extends RowObject with EventDispatcher {
  static const String update = 'update';

  int? origin;

  int select = 0;
  bool isFirst = false;
  bool isLast = false;

  @override
  int get id => getValue('id', 0);

  set id(int v) => setValue('id', v);

  int get message_id => getValue('message_id', 0);

  set message_id(int v) => setValue('message_id', v);

  int get chat_id => getValue('chat_id', 0);

  set chat_id(int v) => setValue('chat_id', v);

  int get send_id => getValue('send_id', 0);

  set send_id(int v) => setValue('send_id', v);

  int get typ => getValue('typ', 0);

  set typ(int v) => setValue('typ', v);

  String get content => getValue('content', '');

  set content(String v) => setValue('content', v);

  String get cmid => getValue('cmid', '');

  set cmid(String v) => setValue('cmid', v);

  set atUser(List<MentionModel> v) => setValue('at_users', v);

  List<MentionModel> get atUser => getValue('at_users', <MentionModel>[]);

  set emojis(List<EmojiModel> v) => setValue('emojis', v);

  List<EmojiModel> get emojis => getValue('emojis', <EmojiModel>[]);

  int get send_time => getValue('send_time', 0);

  set send_time(int v) => setValue('send_time', v);

  int get ref_typ => getValue('ref_typ', 0);

  set ref_typ(int v) => setValue('ref_typ', v);

  int get edit_time => getValue('edit_time', 0);

  set edit_time(int v) => setValue('edit_time', v);

  int get expire_time => getValue('expire_time', 0);

  set expire_time(int v) => setValue('expire_time', v);

  bool get isExpired =>
      expire_time > 0 &&
      expire_time <= DateTime.now().millisecondsSinceEpoch ~/ 1000;

  int get create_time => getValue('create_time', 0);

  set create_time(int v) => setValue('create_time', v);

  int get chat_idx => getValue('chat_idx', 0);

  set chat_idx(int v) => setValue('chat_idx', v);

  bool get isReadMore => getValue('isReadMore', true);

  set isReadMore(bool v) => setValue('isReadMore', v);

  int get deleted => getValue('deleted', 0);

  set deleted(int v) => setValue('deleted', v);

  int get flag => getValue('flag', 0);

  set flag(int v) => setValue('flag', v);

  /// 内容是否已查看
  bool get isContentViewed =>
      (flag & MessageFlag.ContentViewed.value) ==
      MessageFlag.ContentViewed.value;

  set isContentViewed(bool v) => setValue(
      'flag',
      v
          ? (flag | MessageFlag.ContentViewed.value)
          : (flag & ~MessageFlag.ContentViewed.value));

  get isDeleted => deleted == 1;

  get isEncrypted => ref_typ != 0;

  bool get isSystemMsg {
    if (typ > 10000) {
      return true;
    }
    return false;
  }

  bool get isInvisibleMsg {
    if (typ > 12000 ||
        typ == messageTypeDeleted ||
        typ == messageTypeEdit ||
        typ == messageTypeAddReactEmoji ||
        typ == messageTypeRemoveReactEmoji ||
        deleted == 1) {
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
        typ != 20002 &&
        typ != 20003;
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
        !isExpired;
  }

  bool get isMediaType =>
      typ == messageTypeImage ||
      typ == messageTypeVideo ||
      typ == messageTypeReel ||
      typ == messageTypeNewAlbum ||
      typ == messageTypeFile ||
      typ == messageTypeMarkdown ||
      typ == messageTypeLink;

  bool get isTranslatableType =>
      typ == messageTypeImage ||
      typ == messageTypeVideo ||
      typ == messageTypeNewAlbum ||
      typ == messageTypeText ||
      typ == messageTypeVoice ||
      typ == messageTypeReply ||
      typ == messageTypeFile ||
      typ == messageTypeLink;

  bool get isDisableMultiSelect {
    bool isFailedMsg = message_id == 0 && isSendFail;
    bool isSendingMsg = message_id == 0 && isSendSlow;

    // 红包、转账、通话、失败、发送中，下面的 删除和举报 不进入多选
    return (typ == messageTypeSendRed ||
        typ == messageTypeMarkdown ||
        typ == messageTypeTransferMoneySuccess ||
        typ == messageEndCall ||
        typ == messageRejectCall ||
        typ == messageCancelCall ||
        typ == messageMissedCall ||
        typ == messageBusyCall ||
        isFailedMsg ||
        isSendingMsg);
  }

  // original content
  String get messageContent {
    String toTranslate = "";
    final messageContent = jsonDecode(content);
    if (typ == messageTypeImage ||
        typ == messageTypeVideo ||
        typ == messageTypeFile ||
        typ == messageTypeFace ||
        typ == messageTypeGif ||
        typ == messageTypeNewAlbum) {
      toTranslate = messageContent['caption'] ?? '';
    } else if (typ == messageTypeLink || typ == messageTypeReply) {
      toTranslate = messageContent['text'] ?? '';
    } else if (typ == messageTypeVoice) {
      toTranslate = messageContent['transcribe'] ?? '';
    } else if (typ == messageTypeMarkdown) {
      MessageMarkdown msg = decodeContent(cl: MessageMarkdown.creator);
      toTranslate = msg.title + '\n' + msg.text;
    } else if (typ == messageTypeMiniAppDetail) {
      MessageMiniApp messageText = decodeContent(cl: MessageMiniApp.creator);
      toTranslate = messageText.title + "\n" + messageText.info;
    } else if (typ == messageTypeMiniAppDetail) {
      MessageMiniAppShare messageText =
          decodeContent(cl: MessageMiniAppShare.creator);
      toTranslate = messageText.text;
    } else {
      var messageText = decodeContent(cl: MessageText.creator);
      toTranslate = messageText.text;
    }
    return toTranslate;
  }

  /// get caption/text that able to copy
  String get textAfterMentionWithTranslation {
    String text = messageContent;

    if (isTranslatableType) {
      TranslationModel? translationModel = getTranslationModel();
      if (translationModel != null && translationModel.showTranslation) {
        if (translationModel.visualType == TranslationModel.showBoth) {
          text = '$text\n${translationModel.getContent()}';
        } else {
          text = translationModel.getContent();
        }
      }
    }

    return ChatHelp.formalizeMentionContent(text, this);
  }

  String get textAfterMention {
    String text = messageContent;
    return ChatHelp.formalizeMentionContent(text, this);
  }

  String get translationAfterMention {
    String text = '';
    if (isTranslatableType) {
      TranslationModel? translationModel = getTranslationModel();
      if (translationModel != null && translationModel.showTranslation) {
        text = translationModel.getContent();
      }
    }
    return ChatHelp.formalizeMentionContent(text, this);
  }

  int get failMessageErrorCode {
    int errorCode = 0;
    if (content.isEmpty) return errorCode;
    final messageContent = jsonDecode(content);
    if (messageContent.containsKey('error_code')) {
      errorCode = messageContent['error_code'];
    }
    return errorCode;
  }

  bool get isBlackListOrStranger {
    if (failMessageErrorCode == ErrorCodeConstant.STATUS_NOT_IN_CHAT ||
        failMessageErrorCode == ErrorCodeConstant.STATUS_USER_HE_IN_BLACKLIST ||
        failMessageErrorCode == ErrorCodeConstant.STATUS_USER_ME_IN_BLACKLIST) {
      return true;
    }
    return false;
  }

  bool get hasReadView =>
      typ == messageTypeText ||
      typ == messageTypeImage ||
      typ == messageTypeVoice ||
      typ == messageTypeVideo ||
      typ == messageTypeFace ||
      typ == messageTypeFile ||
      typ == messageTypeLocation ||
      typ == messageTypeNewAlbum ||
      typ == messageTypeLink ||
      typ == messageTypeReply ||
      typ == messageTypeForward ||
      typ == messageTypeRecommendFriend ||
      typ == messageTypeShareLocationStart ||
      typ == messageTypeShareLocationEnd ||
      typ == messageTypeSendRed ||
      typ == messageTypeTransferMoneySuccess ||
      typ == messageTypeTaskCreated ||
      typ == messageTypeSubTaskChanged ||
      typ == messageTypeReel ||
      typ == messageTypeGif ||
      typ == messageTypeFriendLink ||
      typ == messageTypeGroupLink;

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
          for (var element in value) {
            atUsers.add(MentionModel.fromJson(element));
          }
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

  TranslationModel? getTranslationModel() {
    if (!isTranslatableType) {
      return null;
    }

    String? translateContent =
        decodeContent(cl: getMessageModel(typ)).translation;
    if (notBlank(translateContent)) {
      return TranslationModel.fromJson(jsonDecode(translateContent!));
    }
    return null;
  }

  String? getTranslationFromMessage() {
    TranslationModel? model = getTranslationModel();
    if (model != null && model.showTranslation) {
      return model.getContent();
    }

    return null;
  }

  // 添加新翻译map
  Message addTranslation(String locale, String text, int visualType) {
    TranslationModel? translationModel = getTranslationModel();
    translationModel ??= TranslationModel();
    translationModel.translation = {locale: text};
    translationModel.showTranslation = true;
    translationModel.currentLocale = locale;
    translationModel.visualType = visualType;

    /// {'reply':"", "translation":"", "transcribe": ""}
    final Map<String, dynamic> content = jsonDecode(this.content);
    if (content.containsKey('translation')) content.remove('translation');
    content.addAll({"translation": jsonEncode(translationModel)});
    this.content = jsonEncode(content);
    return this;
  }

  Message hideTranslation() {
    TranslationModel? translationModel;
    String? translateContent =
        decodeContent(cl: getMessageModel(typ)).translation;
    if (translateContent != null) {
      translationModel =
          TranslationModel.fromJson(jsonDecode(translateContent));
      translationModel.showTranslation = false;

      final Map<String, dynamic> content = jsonDecode(this.content);
      if (content.containsKey('translation')) content.remove('translation');
      content.addAll({"translation": jsonEncode(translationModel)});
      this.content = jsonEncode(content);
    }
    return this;
  }

  Message addTranscribe(String text) {
    final Map<String, dynamic> content = jsonDecode(this.content);
    if (content.containsKey('transcribe')) content.remove('transcribe');
    content.addAll({"transcribe": text});
    this.content = jsonEncode(content);
    return this;
  }

  Message removeTranscribe() {
    final Map<String, dynamic> content = jsonDecode(this.content);
    if (content.containsKey('transcribe')) content.remove('transcribe');
    if (content.containsKey('translation')) content.remove('translation');
    this.content = jsonEncode(content);
    return this;
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
      ..deleted = message?.deleted ?? deleted
      ..edit_time = message?.edit_time ?? edit_time
      ..send_time = message?.send_time ?? send_time
      ..ref_typ = message?.ref_typ ?? ref_typ
      .._sendState = message?._sendState ?? _sendState
      .._uploadProgress = message?._uploadProgress ?? _uploadProgress
      .._totalSize = message?._totalSize ?? _totalSize
      ..atUser = message?.atUser ?? atUser
      ..flag = message?.flag ?? flag
      ..cmid = message?.cmid ?? cmid;
  }

  //内容解析数据
  @override
  dynamic decodeContent({required dynamic cl, String? v}) {
    //判断是否有指定解析字符串  如果没有 就默认content
    v ??= content;
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
        return MessageText.creator;
      case messageTypeLink:
        return MessageLink.creator;
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
        return MessageImage.creator;
      case messageTypeGroupJoined:
        return MessageSystem.creator;
      case messageTypeRecommendFriend:
        return MessageJoinGroup.creator;
      case messageTypeFriendLink:
        return MessageFriendLink.creator;
      case messageTypeGroupLink:
        return MessageGroupLink.creator;
      case messageTypeLocation:
        return MessageMyLocation.creator;
      case messageTypeMarkdown:
        return MessageMarkdown.creator;
      case messageTypeMiniAppDetail:
        return MessageMiniApp.creator;
      case messageTypeShareChat:
        return MessageMiniAppShare.creator;
    }
  }

  bool get hasReply => typ == messageTypeReply;

  String? get replyModel =>
      hasReply ? decodeContent(cl: getMessageModel(typ)).reply : null;

  bool isMentionMessage(int uid) {
    bool find = false;
    if (atUser.isEmpty) {
      return find;
    }
    String searchText = "⅏⦃$uid@jx❦⦄";
    String searchAllText = "⅏⦃0@jx❦⦄";
    for (var user in atUser) {
      if (user.userId == 0 &&
          content.contains(searchAllText) &&
          user.role == Role.all &&
          !objectMgr.userMgr.isMe(send_id)) {
        find = true;
        continue;
      }
      if (user.userId == uid && content.contains(searchText)) {
        find = true;
        continue;
      }
    }
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
  static const String eventAlbumUploadProgress = "eventAlbumUploadProgress";

  static const String eventAlbumBeanUpdate = "eventAlbumBeanUpdate";
  static const String eventAlbumAssetProcessComplete =
      "eventAlbumAssetProcessComplete";
  static const String eventConvertText = 'eventConvertText';
  static const String eventDownloadProgress = 'eventDownloadProgress';
  static const String eventReadMoreText = 'eventReadMoreText';

  int _sendState = MESSAGE_SEND_SUCCESS;

  int get sendState {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (getValue('message_id', 0) == 0) {
      if (send_time ~/ 1000 + 600 < nowTime) {
        _sendState = MESSAGE_SEND_FAIL;
      } else {
        _sendState = MESSAGE_SEND_ING;
      }
    }
    return getValue("sendState", _sendState);
  }

  set sendState(int v) {
    if (v != MESSAGE_SEND_ING) {
      _uploadProgress = 0.0;
    }
    _sendState = v;
    setValue("sendState", v);
    event(this, Message.eventSendState, data: this);
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

  // @Deprecated
  // 0: Display Duration, 1: Preparing | Compressing (40%), 2: Md5 Checksum (45%), 3: Uploading (90%), 4: Polling (95%), 5: Complete(100%)
  // New Status
  // 0: Display Duration, 1: Preparing (0.0), 2: Compressing (0.05) - No Progress | Md5 Checksum, 3: Uploading (Real Progress), 4: Complete(100%)
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
    albumUpdateStatus = {};
    albumUpdateProgress = {};
  }

  ////////////////////////////////////////

  static Message creator() {
    return Message();
  }

  @override
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
      "expire_time": expire_time,
      "at_users": jsonEncode(atUser).toString(),
      "emojis": jsonEncode(emojis).toString(),
      "send_time": send_time,
      "ref_typ": ref_typ,
      "edit_time": edit_time,
      "flag": flag,
      'cmid': cmid,
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
    ref_typ: $ref_typ, 
    chat_idx: $chat_idx, 
    origin: $origin, 
    create_time: $create_time, 
    edit_time: $edit_time, 
    expire_time: $expire_time, 
    atUser: $atUser, 
    emojis: $emojis, 
    flag: $flag, 
    sendState: $sendState, 
    uploadProgress: $uploadProgress, 
    totalSize: $totalSize,
    albumUpdateStatus: $albumUpdateStatus, 
    albumUpdateProgress: $albumUpdateProgress, 
    isHideShow: $isHideShow, 
    _sendState: $_sendState,
    select: $select, 
    isDeleted: $isDeleted, 
    isSystemMsg: $isSystemMsg, 
    isChatRoomVisible: $isChatRoomVisible, 
    isMediaType: $isMediaType, 
    hasReply: $hasReply,
    isMentionMessage: $isMentionMessage, 
    isExpired: $isExpired, 
    isCalling: $isCalling, 
    isSwipeToReply: $isSwipeToReply, 
    isDeleted: $isDeleted, 
    isExpired: $isExpired, 
    isSystemMsg: $isSystemMsg, 
    canCountDate: $canCountDate, 
    isValidLastMessage: $isValidLastMessage,
    isHideShow: $isHideShow,
    cmid: $cmid,
    }
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
      messageRejectCall,
    ];
    return callingType.contains(typ);
  }

  bool get isSwipeToReply => swipeToReplyTypes.contains(typ);
}

/// 文本消息
class MessageText {
  /// 消息内容
  String _text = '';

  String get text => _text;

  set text(String v) {
    if (v.isNotEmpty) {
      _text = v.trim();
      return;
    }
    _text = v;
  }

  String richText = '';

  String reply = '';

  bool showAll = false;

  ///直播新增用户信息
  String nickName = '';
  int userHead = 0;

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  /// 翻译
  String translation = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('text')) text = json['text'] ?? "";
    if (json.containsKey('rich_text')) richText = json['rich_text'];
    if (json.containsKey('reply')) reply = json['reply'] ?? '';
    if (json.containsKey('nick_name')) nickName = json['nick_name'];
    if (json.containsKey('user_head')) userHead = json['user_head'];
    if (json.containsKey('translation')) {
      translation = json['translation'] ?? '';
    }
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'nick_name': nickName,
      'user_head': userHead,
      'text': text,
      'reply': reply,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
      'translation': translation,
    };
  }

  static MessageText creator() {
    return MessageText();
  }
}

class MessageMiniAppShare {
  /// 消息内容
  String _text = '';

  String get text => _text;

  set text(String v) {
    if (v.isNotEmpty) {
      _text = v.trim();
      return;
    }
    _text = v;
  }

  String richText = '';

  String reply = '';

  bool showAll = false;

  ///直播新增用户信息
  String nickName = '';
  int userHead = 0;

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  /// 翻译
  String translation = '';

  String miniAppAvatar = "";

  String miniAppPicture = "";

  String miniAppPictureGaussian = "";

  String miniAppName = "";

  String miniAppTitle = "";

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('text')) text = json['text'] ?? "";
    if (json.containsKey('rich_text')) richText = json['rich_text'];
    if (json.containsKey('reply')) reply = json['reply'] ?? '';
    if (json.containsKey('nick_name')) nickName = json['nick_name'];
    if (json.containsKey('user_head')) userHead = json['user_head'];
    if (json.containsKey('translation')) {
      translation = json['translation'] ?? '';
    }
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }

    if (json.containsKey('mini_app_avatar')) {
      miniAppAvatar = json['mini_app_avatar'];
    }

    if (json.containsKey('mini_app_picture')) {
      miniAppPicture = json['mini_app_picture'];
    }

    if (json.containsKey('mini_app_picture_gaussian')) {
      miniAppPictureGaussian = json['mini_app_picture_gaussian'];
    }
    if (json.containsKey('mini_app_name')) {
      miniAppName = json['mini_app_name'];
    }
    if (json.containsKey('mini_app_title')) {
      miniAppTitle = json['mini_app_title'];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'nick_name': nickName,
      'user_head': userHead,
      'text': text,
      'reply': reply,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
      'translation': translation,
      'mini_app_avatar': miniAppAvatar,
      'mini_app_picture': miniAppPicture,
      'mini_app_picture_gaussian': miniAppPictureGaussian,
      'mini_app_name': miniAppName,
      'mini_app_title': miniAppTitle,
    };
  }

  static MessageMiniAppShare creator() {
    return MessageMiniAppShare();
  }
}

class MessageLink {
  String text = '';
  Metadata? linkPreviewData;

  String linkImageSrc = '';
  String linkImageSrcGaussian = '';

  String reply = '';

  ///转发信息
  int forwardUserId = 0;
  String forwardUserName = '';

  /// 翻译
  String translation = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('text')) text = json['text'];
    if (json.containsKey('link_metadata')) {
      linkPreviewData = Metadata.fromJson(json['link_metadata']!);
    }

    if (json.containsKey('link_image_src')) {
      linkImageSrc = json['link_image_src'];
    }

    if (json.containsKey('link_image_src_gaussian')) {
      linkImageSrcGaussian = json['link_image_src_gaussian'];
    }

    if (json.containsKey('reply')) reply = json['reply'] ?? '';

    if (json.containsKey('translation')) {
      translation = json['translation'] ?? '';
    }
    if (json.containsKey('forward_user_id')) {
      forwardUserId = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forwardUserName = json['forward_user_name'];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'link_metadata': linkPreviewData,
      'link_image_src': linkImageSrc,
      'link_image_src_gaussian': linkImageSrcGaussian,
      'reply': reply,
      'translation': translation,
      'forward_user_id': forwardUserId,
      'forward_user_name': forwardUserName,
    };
  }

  static MessageLink creator() {
    return MessageLink();
  }
}

class MessageMiniApp {
  String _text = '';

  String get text => _text;

  set text(String v) {
    if (v.isNotEmpty) {
      _text = v.trim();
      return;
    }
    _text = v;
  }

  String _title = '';

  String get title => _title;

  String get replaceSpaceTitle {
    String result = _title.replaceAll(RegExp(r'\s+'), ' ');
    List<String> list = result.split(r'\s+');
    String t = "";
    for (int i = 0; i < list.length; i++) {
      if (i == list.length - 1) {
        t += list[i];
      } else {
        t += list[i] + " ";
      }
    }
    return t;
  }

  set title(String v) {
    if (v.isNotEmpty) {
      _title = v.trim();
      return;
    }
    _title = v;
  }

  String _info = '';

  String get info => _info;

  String get showInfo {
    String result = _info.replaceAll("所属家", "\n所属家");
    return result;
  }

  set info(String v) {
    if (v.isNotEmpty) {
      _info = v.trim();
      return;
    }
    _info = v;
  }

  String _link = '';

  String get link => _link;

  set link(String v) {
    if (v.isNotEmpty) {
      _link = v.trim();
      return;
    }
    _link = v;
  }

  String richText = '';

  String reply = '';

  bool showAll = false;

  ///直播新增用户信息
  String nickName = '';
  int userHead = 0;

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  /// 翻译
  String translation = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('text')) text = json['text'] ?? "";
    if (json.containsKey('title')) title = json['title'] ?? "";
    if (json.containsKey('info')) info = json['info'] ?? "";
    if (json.containsKey('link')) link = json['link'] ?? "";
    if (json.containsKey('rich_text')) richText = json['rich_text'];
    if (json.containsKey('reply')) reply = json['reply'] ?? '';
    if (json.containsKey('nick_name')) nickName = json['nick_name'];
    if (json.containsKey('user_head')) userHead = json['user_head'];
    if (json.containsKey('translation')) {
      translation = json['translation'] ?? '';
    }
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'nick_name': nickName,
      'user_head': userHead,
      'text': text,
      'reply': reply,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
      'translation': translation,
    };
  }

  static MessageMiniApp creator() {
    return MessageMiniApp();
  }
}

class MessageDelete {
  int uid = 0;
  List<int> message_ids = <int>[];

  // if delete for me is 0 else 1
  int all = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('uid')) uid = json['uid'];
    if (json.containsKey('message_ids')) {
      message_ids = json['message_ids'].cast<int>();
    }
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
  List<MentionModel> atUser = <MentionModel>[];
  int refTyp = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('chat_id')) chat_id = json['chat_id'];
    if (json.containsKey('chat_idx')) chat_idx = json['chat_idx'];
    if (json.containsKey('related_id')) related_id = json['related_id'];
    if (json.containsKey('content')) content = json['content'];
    if (json.containsKey('at_user')) {
      List<MentionModel> atUsers = [];
      if (json['at_user'] is List) {
        for (var element in json['at_user']) {
          atUsers.add(MentionModel.fromJson(element));
        }
      }

      if (json['at_user'] is String &&
          json['at_user'] != '[]' &&
          json['at_user'].isNotEmpty) {
        atUsers = jsonDecode(json['at_user'])
            .map<MentionModel>((e) => MentionModel.fromJson(e))
            .toList();
      }

      atUser = atUsers;
    }
    if (json.containsKey('ref_typ')) refTyp = json['ref_typ'];
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chat_id,
      'chat_idx': chat_idx,
      'related_id': related_id,
      'content': content,
      'at_user': atUser,
      'ref_typ': refTyp,
    };
  }

  static MessageEdit creator() {
    return MessageEdit();
  }

  bool isMentionMessage(int uid) {
    bool find = false;
    if (atUser.isEmpty) {
      return find;
    }
    String searchText = "⅏⦃$uid@jx❦⦄";
    String searchAllText = "⅏⦃0@jx❦⦄";
    for (var user in atUser) {
      if (user.userId == 0 &&
          content.contains(searchAllText) &&
          user.role == Role.all) {
        find = true;
        continue;
      }
      if (user.userId == uid && content.contains(searchText)) {
        find = true;
        continue;
      }
    }
    return find;
  }
}

class MessageReqSignChat {
  int uid = 0;
  int round = 0;
  String publicKey = '';
  bool newSession = false; //true:代表之前没有session false:代表之前有session
  bool reset = false;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('uid')) uid = json['uid'];
    if (json.containsKey('round')) round = json['round'];
    if (json.containsKey('public_key')) publicKey = json['public_key'];
    if (json.containsKey('new_session')) newSession = json['new_session'];
    if (json.containsKey('reset')) reset = json['reset'];
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'round': round,
      'public_key': publicKey,
      'new_session': newSession,
      'reset': reset,
    };
  }

  static MessageReqSignChat creator() {
    return MessageReqSignChat();
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
  String reply = "";
  bool showOriginal = false;

  String _caption = '';

  String get caption => _caption;

  set caption(String v) {
    if (v.isNotEmpty) {
      _caption = v.trim();
      return;
    }
    _caption = v;
  }

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';
  int forward_original_message_id = 0;
  int forward_original_chat_id = -1;
  String translation = '';

  int errorCode = -1;

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
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
    if (json.containsKey('forward_original_message_id')) {
      forward_original_message_id = json['forward_original_message_id'];
    }
    if (json.containsKey('forward_original_chat_id')) {
      forward_original_chat_id = json['forward_original_chat_id'];
    }
    if (json.containsKey('translation')) {
      translation = json['translation'] ?? '';
    }

    if (json.containsKey('error_code')) {
      errorCode = json['error_code'] ?? '';
    }
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
      'translation': translation,
      'error_code': errorCode,
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

  /// 文件名 图片或者视频
  String fileName = '';
  String filePath = '';

  //封面图片
  String cover = '';
  String coverPath = '';

  // 高斯模糊图片
  String gausPath = '';

  String? mimeType;

  /// 文件大小
  int size = 0;

  /// 视频 时长
  int seconds = 0;

  /// 图片顺序
  String? index_id = "";

  String caption = '';

  int resolution = 480;

  /// 临时存储
  Message? _currentMessage;
  dynamic asset;

  bool showOriginal = false;

  int sendTime = 0;

  String translation = '';

  bool get isVideo {
    if (mimeType != null && mimeType!.contains('video')) return true;
    if (asset is AssetEntity && asset.type == AssetType.video) return true;
    return false;
  }

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
    mimeType = json['mimeType'];
    seconds = json['seconds'] ?? 0;
    size = json['size'] ?? 0;
    cover = json['cover'] ?? "";
    coverPath = json['coverPath'] ?? "";
    caption = json['caption'] ?? "";
    fileName = json['fileName'] ?? "";
    filePath = json['filePath'] ?? "";
    gausPath = json['gausPath'] ?? "";
    sendTime = json['sendTime'] ?? 0;
    showOriginal = json['showOriginal'] ?? false;
    translation = json['translation'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['index_id'] = index_id;
    data['asid'] = asid;
    data['astypeint'] = astypeint;
    data['aswidth'] = aswidth;
    data['asheight'] = asheight;
    data['url'] = url;
    data['mimeType'] = mimeType;
    data['size'] = size;
    data['seconds'] = seconds;
    data['cover'] = cover;
    data['coverPath'] = coverPath;
    data['caption'] = caption;
    data['fileName'] = fileName;
    data['filePath'] = filePath;
    data['gausPath'] = gausPath;

    data['sendTime'] = sendTime;

    data['showOriginal'] = showOriginal;
    data['translation'] = translation;
    return data;
  }

////////////////////////////////////
  /// 最小宽度 宽大于高
  double getMinWidth(double h) {
    if (aspectRatio > 1) {
      return h;
    }
    return TgAlbumUtil.minWidth;
  }

  /// 当前行数
  int currentLine = 0;

  /// 最小高度， 高大于宽
  double getMinHeight(double w) {
    if (aspectRatio < 1) {
      return w * 0.66;
    }
    return TgAlbumUtil.minHeight;
  }

  /// 计算宽高比 实际的
  double get aspectRatio {
    if (aswidth == null || asheight == null || asheight == 0 || aswidth == 0) {
      return 1;
    }
    double k = aswidth! / asheight!;
    return k;
  }

  /// 方便UI显示的宽高比，避免超级长图和超级扁图
  double get uiAspectRatio {
    if (aspectRatio > 1.25) {
      return 1.25;
    }
    if (aspectRatio < 0.8) {
      return 0.8;
    }
    return aspectRatio;
  }

  bool get forceCalc {
    if (aspectRatio > 2.0) return true;
    return false;
  }

  /// 图片形状归类
  String get proportion {
    if (aspectRatio > 1.2) {
      return 'w'; //宽图
    } else if (aspectRatio < 0.8) {
      return 'n'; // 竖图
    } else {
      return 'q'; //接近正方形
    }
  }

  AlbumRect _layoutFrame = AlbumRect(0, 0, 0, 0);

  void setLayoutFrame(AlbumRect rect) {
    _layoutFrame = rect;
  }

  AlbumRect get layoutFrame {
    return _layoutFrame;
  }

  Set<MosaicItemPosition> position = {};

  /// 当前照片所在的索引位置
  int index = 0;

////////////////////////////////////
}

class AlbumRect {
  /// 相册排列的宽度
  double width = 0.1;

  /// 相册排列的高度
  double height = 0.1;

  /// 对应的X坐标
  double x = 0.1;

  ///对应的Y坐标
  double y = 0.1;

  AlbumRect(this.x, this.y, this.width, this.height);

  @override
  String toString() {
    String str = "Rect: width:$width, height:$height, x:$x, y:$y";
    return str;
  }
}

class MosaicItemPosition {
  final int rawValue;

  const MosaicItemPosition(this.rawValue);

  static const top = MosaicItemPosition(1);
  static const bottom = MosaicItemPosition(2);
  static const left = MosaicItemPosition(4);
  static const right = MosaicItemPosition(8);
  static const inside = MosaicItemPosition(16);
  static const unknown = MosaicItemPosition(65536);

  bool contains(MosaicItemPosition other) {
    return (rawValue & other.rawValue) != 0;
  }

  bool get isWide {
    return contains(left) &&
        contains(right) &&
        (contains(top) || contains(bottom));
  }

  @override
  String toString() {
    switch (rawValue) {
      case 1:
        return "top";
      case 2:
        return "bottom";
      case 4:
        return "left";
      case 8:
        return "right";
      case 16:
        return "inside";
      case 65536:
        return "unknown";
      default:
        return "unknown";
    }
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

  // 高斯模糊图片
  String gausPath = '';

  // 高斯模糊 base64字符
  Uint8List? gausBytes;

  /// 图片数据大小，单位：字节
  int size = 0;
  int width = 0;
  int height = 0;

  int sendTime = 0;
  String reply = '';
  bool showOriginal = false;

  String _caption = '';

  String get caption => _caption;

  set caption(String v) {
    if (v.isNotEmpty) {
      _caption = v.trim();
      return;
    }
    _caption = v;
  }

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';
  String translation = '';

  applyJson(Map<String, dynamic> json) {
    if (json.containsKey('url')) url = json['url'].toString();
    if (json.containsKey('size')) size = json['size'];
    if (json.containsKey('width')) width = json['width'];
    if (json.containsKey('height')) height = json['height'];
    if (json.containsKey('sendTime')) sendTime = json['sendTime'];
    if (json.containsKey('fileName') && json['fileName'] != null) {
      fileName = json['fileName'];
    }
    if (json.containsKey('filePath') && json['filePath'] != null) {
      filePath = json['filePath'];
    }
    if (json.containsKey('gausPath') && json['gausPath'] != null) {
      gausPath = json['gausPath'];
    }

    if (json.containsKey('gausBytes') && json['gausBytes'] != null) {
      final String gausBase64 = json['gausBytes'];
      gausBytes = base64Decode(gausBase64);
    }

    if (json.containsKey('caption') && json['caption'] != null) {
      caption = json['caption'];
    }
    if (json.containsKey('reply') && json['reply'] != null) {
      reply = json['reply'];
    }
    if (json.containsKey('showOriginal')) showOriginal = json['showOriginal'];
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
    if (json.containsKey('translation')) {
      translation = json['translation'] ?? '';
    }
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
      'gausPath': gausPath,
      'gausBytes': gausBytes == null ? null : base64.encode(gausBytes!),
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
      'translation': translation,
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
  String? localUrl; //本地地址
  int size = 0; // 图片数据大小，单位：字节
  int second = 0; // 语音长度 单位/秒
  int flag = 0; // 下载方式标记,为1标识需要通过cdn作为前缀， 为2表示可以直接通过url下载
  List decibels = List.empty(growable: true);
  String transcribe = '';
  String translation = '';

  /// 旧版没有这个字段，UI上会处理为已播放过
  bool? isOperated; // 是否已经被操作过（是否已被任何接收方播放过)

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
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
    if (json.containsKey('reply') && json['reply'] != null) {
      reply = json['reply'];
    }
    if (json.containsKey('translation')) {
      translation = json['translation'] ?? '';
    }
    if (json.containsKey('isOperated')) {
      isOperated = json['isOperated'];
    }
    if (json.containsKey('transcribe')) transcribe = json['transcribe'] ?? '';
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
      'translation': translation,
      'transcribe': transcribe,
      if (isOperated != null) 'isOperated': isOperated,
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

  // 高斯模糊图片
  String gausPath = '';

  Uint8List? gausBytes;

  /// 附加消息
  String _caption = '';

  String get caption => _caption;

  set caption(String v) {
    if (v.isNotEmpty) {
      _caption = v.trim();
      return;
    }
    _caption = v;
  }

  String reply = '';

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';
  String translation = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('url')) url = json['url'];
    if (json.containsKey('fileName') && json['fileName'] != null) {
      fileName = json['fileName'];
    }
    if (json.containsKey('filePath') && json['filePath'] != null) {
      filePath = json['filePath'];
    }
    if (json.containsKey('size')) size = json['size'];
    if (json.containsKey('width')) width = json['width'];
    if (json.containsKey('height')) height = json['height'];
    if (json.containsKey('sendTime')) sendTime = json['sendTime'];

    if (json.containsKey('second')) second = json['second'];
    if (json.containsKey('cover')) cover = '${json['cover']}';
    if (json.containsKey('coverPath')) coverPath = '${json['coverPath']}';
    if (json.containsKey('gausPath') && json['gausPath'] != null) {
      gausPath = json['gausPath'];
    }

    if (json.containsKey('gausBytes') && json['gausBytes'] != null) {
      final String gausBase64 = json['gausBytes'];
      gausBytes = base64Decode(gausBase64);
    }

    if (json.containsKey('caption') && json['caption'] != null) {
      caption = json['caption'];
    }
    if (json.containsKey('reply') && json['reply'] != null) {
      reply = json['reply'];
    }
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
    if (json.containsKey('translation')) {
      translation = json['translation'] ?? '';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'size': size,
      'width': width,
      'height': height,
      'sendTime': sendTime,
      'second': second,
      'fileName': fileName,
      'filePath': filePath,
      'cover': cover,
      'coverPath': coverPath,
      'gausPath': gausPath,
      'gausBytes': gausBytes == null ? null : base64.encode(gausBytes!),
      'caption': caption,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
      'translation': translation,
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
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
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
    id = message.id;
    chatIdx = message.chat_idx;
    typ = message.typ;
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
  int size = 0;

  ///文件名称
  String file_name = '';

  String filePath = '';

  ///文件类型 doc,els,ppt
  String suffix = '';

  String _caption = '';

  String get caption => _caption;

  set caption(String v) {
    if (v.isNotEmpty) {
      _caption = v.trim();
      return;
    }
    _caption = v;
  }

  String cover = '';

  // 高斯模糊图片
  String gausPath = '';

  // 高斯模糊 base64字符
  Uint8List? gausBytes;

  // pdf 是否被压缩
  // 0 : 未压缩
  // 1 : 已压缩
  int isEncrypt = 0;

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';
  String translation = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('file_id')) file_id = json['file_id'];
    if (json.containsKey('url')) url = json['url'];
    if (json.containsKey('size')) size = json['size'];
    if (json.containsKey('file_name')) file_name = json['file_name'];
    if (json.containsKey('filePath')) filePath = json['filePath'];
    if (json.containsKey('suffix')) suffix = json['suffix'];

    if (json.containsKey('cover')) cover = json['cover'];
    if (json.containsKey('gausPath') && json['gausPath'] != null) {
      gausPath = json['gausPath'];
    }

    if (json.containsKey('gausBytes') && json['gausBytes'] != null) {
      final String gausBase64 = json['gausBytes'];
      gausBytes = base64Decode(gausBase64);
    }

    if (json.containsKey('isEncrypt')) isEncrypt = json['isEncrypt'];

    if (json.containsKey('caption')) caption = json['caption'];
    if (json.containsKey('reply') && json['reply'] != null) {
      reply = json['reply'];
    }
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
    if (json.containsKey('translation')) {
      translation = json['translation'] ?? '';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'file_id': file_id,
      'url': url,
      'size': size,
      'file_name': file_name,
      'filePath': filePath,
      'suffix': suffix,
      'cover': cover,
      'gausPath': gausPath,
      'gausBytes': gausBytes == null ? null : base64.encode(gausBytes!),
      'isEncrypt': isEncrypt,
      'caption': caption,
      'reply': reply,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
      'translation': translation,
    };
  }

  static MessageFile creator() {
    return MessageFile();
  }
}

/// 系统消息
class MessageSystem {
  String _text = '';

  String get text => _text;

  set text(String v) {
    if (v.isNotEmpty) {
      _text = v.trim();
      return;
    }
    _text = v;
  }

  int uid = 0;
  List<int> uids = [];

  String nickname = '';
  int inviter = 0;
  int owner = 0;

  int createTime = 0;
  int isEnabled = 0;
  int flag = 0;

  bool get isEnabledEncryption => flag == 1;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('text')) text = json['text'] ?? "";
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
    if (json.containsKey('flag')) flag = json['flag'];
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
      'flag': flag,
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
    if (json.containsKey('recipient_ids') && json['recipient_ids'] != null) {
      recipientIDs = json['recipient_ids'].toList().cast<int>();
    }
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
    if (json.containsKey('message_id')) {
      messageIds = List.from(json['message_id']);
    }
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
    if (json.containsKey('rtc_channel_id')) {
      rtc_channel_id = json['rtc_channel_id'] ?? "";
    }
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
      'is_videocall': is_videocall,
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
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
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

/// 好友链接
class MessageFriendLink {
  /// 用户id
  int user_id = 0;

  /// 用户昵称
  String nick_name = '';

  /// 用户简介
  String user_profile = '';

  /// 短链接
  String short_link = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('user_id')) user_id = json['user_id'];
    if (json.containsKey('nick_name')) nick_name = json['nick_name'];
    if (json.containsKey('user_profile')) user_profile = json['user_profile'];
    if (json.containsKey('short_link')) short_link = json['short_link'];
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': user_id,
      'nick_name': nick_name,
      'user_profile': user_profile,
      'short_link': short_link,
    };
  }

  static MessageFriendLink creator() {
    return MessageFriendLink();
  }
}

/// 群组链接
class MessageGroupLink {
  /// 用户id
  int user_id = 0;

  /// 用户昵称
  String nick_name = '';

  /// 群组id
  int group_id = 0;

  /// 群组名称
  String group_name = '';

  /// 群组简介
  String group_profile = '';

  /// 短链接
  String short_link = '';

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('user_id')) user_id = json['user_id'];
    if (json.containsKey('nick_name')) nick_name = json['nick_name'];
    if (json.containsKey('group_id')) group_id = json['group_id'];
    if (json.containsKey('group_name')) group_name = json['group_name'];
    if (json.containsKey('group_profile')) {
      group_profile = json['group_profile'];
    }
    if (json.containsKey('short_link')) short_link = json['short_link'];
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': user_id,
      'nick_name': nick_name,
      'group_id': group_id,
      'group_name': group_name,
      'group_profile': group_profile,
      'short_link': short_link,
    };
  }

  static MessageGroupLink creator() {
    return MessageGroupLink();
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
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
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
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
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
      'url': url,
      'filePath': filePath,
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

class MessageTempGroupSystem {
  String _text = '';

  String get text => _text;

  set text(String v) {
    if (v.isNotEmpty) {
      _text = v.trim();
      return;
    }
    _text = v;
  }

  int uid = 0;
  int expire_time = 0;

  applyJson(Map<String, dynamic> json) async {
    if (json.containsKey('text')) text = json['text'] ?? "";
    if (json.containsKey('uid')) uid = json['uid'];
    if (json.containsKey('expire_time')) expire_time = json['expire_time'];
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'uid': uid, 'expire_time': expire_time};
  }

  static MessageTempGroupSystem creator() {
    return MessageTempGroupSystem();
  }
}

/// Markdown
class MessageMarkdown {
  String title = '';
  String text = '';
  String image = '';
  String video = '';
  List<Map<String, String>> links = [];
  int width = 0;
  int height = 0;
  int version = 1;

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  applyJson(Map<String, dynamic> json) {
    if (json.containsKey('title')) title = json['title'];
    if (json.containsKey('text')) text = json['text'];
    if (json.containsKey('image')) image = json['image'];
    if (json.containsKey('video')) video = json['video'];
    if (json.containsKey('width')) width = json['width'];
    if (json.containsKey('height')) height = json['height'];
    if (json.containsKey('links')) {
      List<dynamic> linksJson = json['links'];
      links = linksJson.map((link) => Map<String, String>.from(link)).toList();
    }
    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }
    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
    if (json.containsKey('version')) {
      version = json['version'];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'text': text,
      'image': image,
      'video': video,
      'links': links,
      'width': width,
      'height': height,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
      'version': version,
    };
  }

  static MessageMarkdown creator() {
    return MessageMarkdown();
  }
}

/// 收藏消息
class MessageFavourite {
  int favouriteId = 0;
  String title = "";
  List<String> subTitles = [];
  List<FavouriteDetailData> mediaList = [];

  ///转发信息
  int forward_user_id = 0;
  String forward_user_name = '';

  applyJson(Map<String, dynamic> json) {
    if (json.containsKey('favouriteId')) favouriteId = json['favouriteId'];

    if (json.containsKey('title')) title = json['title'];

    if (json.containsKey('subTitles')) {
      subTitles = List<String>.from(json['subTitles'].map((e) => e as String));
    }

    if (json.containsKey('mediaList')) {
      mediaList = List<FavouriteDetailData>.from(
          json['mediaList'].map((e) => FavouriteDetailData.fromJson(e)));
    }

    if (json.containsKey('forward_user_id')) {
      forward_user_id = json['forward_user_id'];
    }

    if (json.containsKey('forward_user_name')) {
      forward_user_name = json['forward_user_name'];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'favouriteId': favouriteId,
      'title': title,
      'subTitles': subTitles,
      'mediaList': mediaList,
      'forward_user_id': forward_user_id,
      'forward_user_name': forward_user_name,
    };
  }

  static MessageFavourite creator() {
    return MessageFavourite();
  }
}
