//
//  Generated code. Do not modify.
//  source: push_client_message.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class Chat extends $pb.GeneratedMessage {
  factory Chat({
    $core.int? autoDeleteInterval,
    $core.int? id,
    $core.int? msgIdx,
    $core.int? otherReadIdx,
    $core.int? typ,
    $core.int? flagMy,
    $core.int? sort,
    $core.Iterable<ChatMessage>? pin,
    $core.int? hideChatMsgIdx,
    $core.int? readChatMsgIdx,
    $core.int? chatId,
    $core.int? userId,
    $core.int? unreadNum,
    $fixnum.Int64? mute,
    $core.int? startIdx,
    $core.int? createTime,
    $core.int? friendId,
    $core.String? lastMsg,
    $fixnum.Int64? lastId,
    $core.int? lastTime,
    $core.int? lastTyp,
    $core.int? verified,
    $core.String? icon,
    $core.String? name,
    $core.String? profile,
  }) {
    final $result = create();
    if (autoDeleteInterval != null) {
      $result.autoDeleteInterval = autoDeleteInterval;
    }
    if (id != null) {
      $result.id = id;
    }
    if (msgIdx != null) {
      $result.msgIdx = msgIdx;
    }
    if (otherReadIdx != null) {
      $result.otherReadIdx = otherReadIdx;
    }
    if (typ != null) {
      $result.typ = typ;
    }
    if (flagMy != null) {
      $result.flagMy = flagMy;
    }
    if (sort != null) {
      $result.sort = sort;
    }
    if (pin != null) {
      $result.pin.addAll(pin);
    }
    if (hideChatMsgIdx != null) {
      $result.hideChatMsgIdx = hideChatMsgIdx;
    }
    if (readChatMsgIdx != null) {
      $result.readChatMsgIdx = readChatMsgIdx;
    }
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (userId != null) {
      $result.userId = userId;
    }
    if (unreadNum != null) {
      $result.unreadNum = unreadNum;
    }
    if (mute != null) {
      $result.mute = mute;
    }
    if (startIdx != null) {
      $result.startIdx = startIdx;
    }
    if (createTime != null) {
      $result.createTime = createTime;
    }
    if (friendId != null) {
      $result.friendId = friendId;
    }
    if (lastMsg != null) {
      $result.lastMsg = lastMsg;
    }
    if (lastId != null) {
      $result.lastId = lastId;
    }
    if (lastTime != null) {
      $result.lastTime = lastTime;
    }
    if (lastTyp != null) {
      $result.lastTyp = lastTyp;
    }
    if (verified != null) {
      $result.verified = verified;
    }
    if (icon != null) {
      $result.icon = icon;
    }
    if (name != null) {
      $result.name = name;
    }
    if (profile != null) {
      $result.profile = profile;
    }
    return $result;
  }
  Chat._() : super();
  factory Chat.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Chat.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Chat', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'auto_delete_interval', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'msg_idx', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'other_read_idx', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'typ', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'flag_my', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'sort', $pb.PbFieldType.OU3)
    ..pc<ChatMessage>(9, _omitFieldNames ? '' : 'pin', $pb.PbFieldType.PM, subBuilder: ChatMessage.create)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'hide_chat_msg_idx', $pb.PbFieldType.OU3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'read_chat_msg_idx', $pb.PbFieldType.OU3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'chat_id', $pb.PbFieldType.OU3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'user_id', $pb.PbFieldType.OU3)
    ..a<$core.int>(14, _omitFieldNames ? '' : 'unread_num', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(15, _omitFieldNames ? '' : 'mute', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(16, _omitFieldNames ? '' : 'start_idx', $pb.PbFieldType.OU3)
    ..a<$core.int>(17, _omitFieldNames ? '' : 'create_time', $pb.PbFieldType.OU3)
    ..a<$core.int>(18, _omitFieldNames ? '' : 'friend_id', $pb.PbFieldType.OU3)
    ..aOS(19, _omitFieldNames ? '' : 'last_msg')
    ..a<$fixnum.Int64>(20, _omitFieldNames ? '' : 'last_id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(21, _omitFieldNames ? '' : 'last_time', $pb.PbFieldType.OU3)
    ..a<$core.int>(22, _omitFieldNames ? '' : 'last_typ', $pb.PbFieldType.OU3)
    ..a<$core.int>(23, _omitFieldNames ? '' : 'verified', $pb.PbFieldType.OU3)
    ..aOS(24, _omitFieldNames ? '' : 'icon')
    ..aOS(25, _omitFieldNames ? '' : 'name')
    ..aOS(26, _omitFieldNames ? '' : 'profile')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  Chat clone() => Chat()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  Chat copyWith(void Function(Chat) updates) => super.copyWith((message) => updates(message as Chat)) as Chat;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Chat create() => Chat._();
  Chat createEmptyInstance() => create();
  static $pb.PbList<Chat> createRepeated() => $pb.PbList<Chat>();
  @$core.pragma('dart2js:noInline')
  static Chat getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Chat>(create);
  static Chat? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get autoDeleteInterval => $_getIZ(0);
  @$pb.TagNumber(1)
  set autoDeleteInterval($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAutoDeleteInterval() => $_has(0);
  @$pb.TagNumber(1)
  void clearAutoDeleteInterval() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get id => $_getIZ(1);
  @$pb.TagNumber(2)
  set id($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get msgIdx => $_getIZ(2);
  @$pb.TagNumber(3)
  set msgIdx($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMsgIdx() => $_has(2);
  @$pb.TagNumber(3)
  void clearMsgIdx() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get otherReadIdx => $_getIZ(3);
  @$pb.TagNumber(4)
  set otherReadIdx($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasOtherReadIdx() => $_has(3);
  @$pb.TagNumber(4)
  void clearOtherReadIdx() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get typ => $_getIZ(4);
  @$pb.TagNumber(5)
  set typ($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTyp() => $_has(4);
  @$pb.TagNumber(5)
  void clearTyp() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get flagMy => $_getIZ(5);
  @$pb.TagNumber(6)
  set flagMy($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasFlagMy() => $_has(5);
  @$pb.TagNumber(6)
  void clearFlagMy() => clearField(6);

  @$pb.TagNumber(8)
  $core.int get sort => $_getIZ(6);
  @$pb.TagNumber(8)
  set sort($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(8)
  $core.bool hasSort() => $_has(6);
  @$pb.TagNumber(8)
  void clearSort() => clearField(8);

  @$pb.TagNumber(9)
  $core.List<ChatMessage> get pin => $_getList(7);

  @$pb.TagNumber(10)
  $core.int get hideChatMsgIdx => $_getIZ(8);
  @$pb.TagNumber(10)
  set hideChatMsgIdx($core.int v) { $_setUnsignedInt32(8, v); }
  @$pb.TagNumber(10)
  $core.bool hasHideChatMsgIdx() => $_has(8);
  @$pb.TagNumber(10)
  void clearHideChatMsgIdx() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get readChatMsgIdx => $_getIZ(9);
  @$pb.TagNumber(11)
  set readChatMsgIdx($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(11)
  $core.bool hasReadChatMsgIdx() => $_has(9);
  @$pb.TagNumber(11)
  void clearReadChatMsgIdx() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get chatId => $_getIZ(10);
  @$pb.TagNumber(12)
  set chatId($core.int v) { $_setUnsignedInt32(10, v); }
  @$pb.TagNumber(12)
  $core.bool hasChatId() => $_has(10);
  @$pb.TagNumber(12)
  void clearChatId() => clearField(12);

  @$pb.TagNumber(13)
  $core.int get userId => $_getIZ(11);
  @$pb.TagNumber(13)
  set userId($core.int v) { $_setUnsignedInt32(11, v); }
  @$pb.TagNumber(13)
  $core.bool hasUserId() => $_has(11);
  @$pb.TagNumber(13)
  void clearUserId() => clearField(13);

  @$pb.TagNumber(14)
  $core.int get unreadNum => $_getIZ(12);
  @$pb.TagNumber(14)
  set unreadNum($core.int v) { $_setUnsignedInt32(12, v); }
  @$pb.TagNumber(14)
  $core.bool hasUnreadNum() => $_has(12);
  @$pb.TagNumber(14)
  void clearUnreadNum() => clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get mute => $_getI64(13);
  @$pb.TagNumber(15)
  set mute($fixnum.Int64 v) { $_setInt64(13, v); }
  @$pb.TagNumber(15)
  $core.bool hasMute() => $_has(13);
  @$pb.TagNumber(15)
  void clearMute() => clearField(15);

  @$pb.TagNumber(16)
  $core.int get startIdx => $_getIZ(14);
  @$pb.TagNumber(16)
  set startIdx($core.int v) { $_setUnsignedInt32(14, v); }
  @$pb.TagNumber(16)
  $core.bool hasStartIdx() => $_has(14);
  @$pb.TagNumber(16)
  void clearStartIdx() => clearField(16);

  @$pb.TagNumber(17)
  $core.int get createTime => $_getIZ(15);
  @$pb.TagNumber(17)
  set createTime($core.int v) { $_setUnsignedInt32(15, v); }
  @$pb.TagNumber(17)
  $core.bool hasCreateTime() => $_has(15);
  @$pb.TagNumber(17)
  void clearCreateTime() => clearField(17);

  @$pb.TagNumber(18)
  $core.int get friendId => $_getIZ(16);
  @$pb.TagNumber(18)
  set friendId($core.int v) { $_setUnsignedInt32(16, v); }
  @$pb.TagNumber(18)
  $core.bool hasFriendId() => $_has(16);
  @$pb.TagNumber(18)
  void clearFriendId() => clearField(18);

  @$pb.TagNumber(19)
  $core.String get lastMsg => $_getSZ(17);
  @$pb.TagNumber(19)
  set lastMsg($core.String v) { $_setString(17, v); }
  @$pb.TagNumber(19)
  $core.bool hasLastMsg() => $_has(17);
  @$pb.TagNumber(19)
  void clearLastMsg() => clearField(19);

  @$pb.TagNumber(20)
  $fixnum.Int64 get lastId => $_getI64(18);
  @$pb.TagNumber(20)
  set lastId($fixnum.Int64 v) { $_setInt64(18, v); }
  @$pb.TagNumber(20)
  $core.bool hasLastId() => $_has(18);
  @$pb.TagNumber(20)
  void clearLastId() => clearField(20);

  @$pb.TagNumber(21)
  $core.int get lastTime => $_getIZ(19);
  @$pb.TagNumber(21)
  set lastTime($core.int v) { $_setUnsignedInt32(19, v); }
  @$pb.TagNumber(21)
  $core.bool hasLastTime() => $_has(19);
  @$pb.TagNumber(21)
  void clearLastTime() => clearField(21);

  @$pb.TagNumber(22)
  $core.int get lastTyp => $_getIZ(20);
  @$pb.TagNumber(22)
  set lastTyp($core.int v) { $_setUnsignedInt32(20, v); }
  @$pb.TagNumber(22)
  $core.bool hasLastTyp() => $_has(20);
  @$pb.TagNumber(22)
  void clearLastTyp() => clearField(22);

  @$pb.TagNumber(23)
  $core.int get verified => $_getIZ(21);
  @$pb.TagNumber(23)
  set verified($core.int v) { $_setUnsignedInt32(21, v); }
  @$pb.TagNumber(23)
  $core.bool hasVerified() => $_has(21);
  @$pb.TagNumber(23)
  void clearVerified() => clearField(23);

  @$pb.TagNumber(24)
  $core.String get icon => $_getSZ(22);
  @$pb.TagNumber(24)
  set icon($core.String v) { $_setString(22, v); }
  @$pb.TagNumber(24)
  $core.bool hasIcon() => $_has(22);
  @$pb.TagNumber(24)
  void clearIcon() => clearField(24);

  @$pb.TagNumber(25)
  $core.String get name => $_getSZ(23);
  @$pb.TagNumber(25)
  set name($core.String v) { $_setString(23, v); }
  @$pb.TagNumber(25)
  $core.bool hasName() => $_has(23);
  @$pb.TagNumber(25)
  void clearName() => clearField(25);

  @$pb.TagNumber(26)
  $core.String get profile => $_getSZ(24);
  @$pb.TagNumber(26)
  set profile($core.String v) { $_setString(24, v); }
  @$pb.TagNumber(26)
  $core.bool hasProfile() => $_has(24);
  @$pb.TagNumber(26)
  void clearProfile() => clearField(26);
}

class ChatMessage extends $pb.GeneratedMessage {
  factory ChatMessage({
    $core.String? atUser,
    $core.int? chatId,
    $core.int? chatIdx,
    $core.String? content,
    $core.int? createTime,
    $core.int? deleteTime,
    $core.int? deleted,
    $core.int? expireTime,
    $fixnum.Int64? id,
    $core.int? refId,
    $core.int? refOpt,
    $core.int? refTyp,
    $core.int? sendId,
    $fixnum.Int64? seq,
    $core.int? typ,
    $core.int? updateTime,
    $fixnum.Int64? sendTime,
  }) {
    final $result = create();
    if (atUser != null) {
      $result.atUser = atUser;
    }
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (chatIdx != null) {
      $result.chatIdx = chatIdx;
    }
    if (content != null) {
      $result.content = content;
    }
    if (createTime != null) {
      $result.createTime = createTime;
    }
    if (deleteTime != null) {
      $result.deleteTime = deleteTime;
    }
    if (deleted != null) {
      $result.deleted = deleted;
    }
    if (expireTime != null) {
      $result.expireTime = expireTime;
    }
    if (id != null) {
      $result.id = id;
    }
    if (refId != null) {
      $result.refId = refId;
    }
    if (refOpt != null) {
      $result.refOpt = refOpt;
    }
    if (refTyp != null) {
      $result.refTyp = refTyp;
    }
    if (sendId != null) {
      $result.sendId = sendId;
    }
    if (seq != null) {
      $result.seq = seq;
    }
    if (typ != null) {
      $result.typ = typ;
    }
    if (updateTime != null) {
      $result.updateTime = updateTime;
    }
    if (sendTime != null) {
      $result.sendTime = sendTime;
    }
    return $result;
  }
  ChatMessage._() : super();
  factory ChatMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChatMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChatMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'at_user')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'chat_id', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'chat_idx', $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'content')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'create_time', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'delete_time', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'deleted', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'expire_time', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'ref_id', $pb.PbFieldType.OU3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'ref_opt', $pb.PbFieldType.OU3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'ref_typ', $pb.PbFieldType.OU3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'send_id', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(15, _omitFieldNames ? '' : 'seq', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(16, _omitFieldNames ? '' : 'typ', $pb.PbFieldType.OU3)
    ..a<$core.int>(17, _omitFieldNames ? '' : 'update_time', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(18, _omitFieldNames ? '' : 'send_time', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  ChatMessage clone() => ChatMessage()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  ChatMessage copyWith(void Function(ChatMessage) updates) => super.copyWith((message) => updates(message as ChatMessage)) as ChatMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatMessage create() => ChatMessage._();
  ChatMessage createEmptyInstance() => create();
  static $pb.PbList<ChatMessage> createRepeated() => $pb.PbList<ChatMessage>();
  @$core.pragma('dart2js:noInline')
  static ChatMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChatMessage>(create);
  static ChatMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get atUser => $_getSZ(0);
  @$pb.TagNumber(1)
  set atUser($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAtUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearAtUser() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get chatId => $_getIZ(1);
  @$pb.TagNumber(2)
  set chatId($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasChatId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChatId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get chatIdx => $_getIZ(2);
  @$pb.TagNumber(3)
  set chatIdx($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasChatIdx() => $_has(2);
  @$pb.TagNumber(3)
  void clearChatIdx() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get content => $_getSZ(3);
  @$pb.TagNumber(4)
  set content($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasContent() => $_has(3);
  @$pb.TagNumber(4)
  void clearContent() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get createTime => $_getIZ(4);
  @$pb.TagNumber(5)
  set createTime($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasCreateTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreateTime() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get deleteTime => $_getIZ(5);
  @$pb.TagNumber(6)
  set deleteTime($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasDeleteTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeleteTime() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get deleted => $_getIZ(6);
  @$pb.TagNumber(7)
  set deleted($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasDeleted() => $_has(6);
  @$pb.TagNumber(7)
  void clearDeleted() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get expireTime => $_getIZ(7);
  @$pb.TagNumber(8)
  set expireTime($core.int v) { $_setUnsignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasExpireTime() => $_has(7);
  @$pb.TagNumber(8)
  void clearExpireTime() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get id => $_getI64(8);
  @$pb.TagNumber(9)
  set id($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasId() => $_has(8);
  @$pb.TagNumber(9)
  void clearId() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get refId => $_getIZ(9);
  @$pb.TagNumber(10)
  set refId($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasRefId() => $_has(9);
  @$pb.TagNumber(10)
  void clearRefId() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get refOpt => $_getIZ(10);
  @$pb.TagNumber(11)
  set refOpt($core.int v) { $_setUnsignedInt32(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasRefOpt() => $_has(10);
  @$pb.TagNumber(11)
  void clearRefOpt() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get refTyp => $_getIZ(11);
  @$pb.TagNumber(12)
  set refTyp($core.int v) { $_setUnsignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasRefTyp() => $_has(11);
  @$pb.TagNumber(12)
  void clearRefTyp() => clearField(12);

  @$pb.TagNumber(13)
  $core.int get sendId => $_getIZ(12);
  @$pb.TagNumber(13)
  set sendId($core.int v) { $_setUnsignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasSendId() => $_has(12);
  @$pb.TagNumber(13)
  void clearSendId() => clearField(13);

  @$pb.TagNumber(15)
  $fixnum.Int64 get seq => $_getI64(13);
  @$pb.TagNumber(15)
  set seq($fixnum.Int64 v) { $_setInt64(13, v); }
  @$pb.TagNumber(15)
  $core.bool hasSeq() => $_has(13);
  @$pb.TagNumber(15)
  void clearSeq() => clearField(15);

  @$pb.TagNumber(16)
  $core.int get typ => $_getIZ(14);
  @$pb.TagNumber(16)
  set typ($core.int v) { $_setUnsignedInt32(14, v); }
  @$pb.TagNumber(16)
  $core.bool hasTyp() => $_has(14);
  @$pb.TagNumber(16)
  void clearTyp() => clearField(16);

  @$pb.TagNumber(17)
  $core.int get updateTime => $_getIZ(15);
  @$pb.TagNumber(17)
  set updateTime($core.int v) { $_setUnsignedInt32(15, v); }
  @$pb.TagNumber(17)
  $core.bool hasUpdateTime() => $_has(15);
  @$pb.TagNumber(17)
  void clearUpdateTime() => clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get sendTime => $_getI64(16);
  @$pb.TagNumber(18)
  set sendTime($fixnum.Int64 v) { $_setInt64(16, v); }
  @$pb.TagNumber(18)
  $core.bool hasSendTime() => $_has(16);
  @$pb.TagNumber(18)
  void clearSendTime() => clearField(18);
}

class CmdTopic extends $pb.GeneratedMessage {
  factory CmdTopic({
    $core.int? id,
    $core.String? cmd,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (cmd != null) {
      $result.cmd = cmd;
    }
    return $result;
  }
  CmdTopic._() : super();
  factory CmdTopic.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CmdTopic.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CmdTopic', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'cmd')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  CmdTopic clone() => CmdTopic()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  CmdTopic copyWith(void Function(CmdTopic) updates) => super.copyWith((message) => updates(message as CmdTopic)) as CmdTopic;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CmdTopic create() => CmdTopic._();
  CmdTopic createEmptyInstance() => create();
  static $pb.PbList<CmdTopic> createRepeated() => $pb.PbList<CmdTopic>();
  @$core.pragma('dart2js:noInline')
  static CmdTopic getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CmdTopic>(create);
  static CmdTopic? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get cmd => $_getSZ(1);
  @$pb.TagNumber(2)
  set cmd($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCmd() => $_has(1);
  @$pb.TagNumber(2)
  void clearCmd() => clearField(2);
}

class SysOp extends $pb.GeneratedMessage {
  factory SysOp({
    $core.int? typ,
    $core.int? subType,
    $core.String? data,
  }) {
    final $result = create();
    if (typ != null) {
      $result.typ = typ;
    }
    if (subType != null) {
      $result.subType = subType;
    }
    if (data != null) {
      $result.data = data;
    }
    return $result;
  }
  SysOp._() : super();
  factory SysOp.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SysOp.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SysOp', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'typ', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'sub_type', $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'data')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  SysOp clone() => SysOp()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  SysOp copyWith(void Function(SysOp) updates) => super.copyWith((message) => updates(message as SysOp)) as SysOp;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SysOp create() => SysOp._();
  SysOp createEmptyInstance() => create();
  static $pb.PbList<SysOp> createRepeated() => $pb.PbList<SysOp>();
  @$core.pragma('dart2js:noInline')
  static SysOp getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SysOp>(create);
  static SysOp? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get typ => $_getIZ(0);
  @$pb.TagNumber(1)
  set typ($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTyp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTyp() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get subType => $_getIZ(1);
  @$pb.TagNumber(2)
  set subType($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSubType() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get data => $_getSZ(2);
  @$pb.TagNumber(3)
  set data($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => clearField(3);
}

class ChatReadMessage extends $pb.GeneratedMessage {
  factory ChatReadMessage({
    $core.int? id,
    $core.int? otherReadIdx,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (otherReadIdx != null) {
      $result.otherReadIdx = otherReadIdx;
    }
    return $result;
  }
  ChatReadMessage._() : super();
  factory ChatReadMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChatReadMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChatReadMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'other_read_idx', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  ChatReadMessage clone() => ChatReadMessage()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  ChatReadMessage copyWith(void Function(ChatReadMessage) updates) => super.copyWith((message) => updates(message as ChatReadMessage)) as ChatReadMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatReadMessage create() => ChatReadMessage._();
  ChatReadMessage createEmptyInstance() => create();
  static $pb.PbList<ChatReadMessage> createRepeated() => $pb.PbList<ChatReadMessage>();
  @$core.pragma('dart2js:noInline')
  static ChatReadMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChatReadMessage>(create);
  static ChatReadMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get otherReadIdx => $_getIZ(1);
  @$pb.TagNumber(2)
  set otherReadIdx($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOtherReadIdx() => $_has(1);
  @$pb.TagNumber(2)
  void clearOtherReadIdx() => clearField(2);
}

class ChatDelMessage extends $pb.GeneratedMessage {
  factory ChatDelMessage({
    $core.int? chatId,
    $core.Iterable<$fixnum.Int64>? id,
  }) {
    final $result = create();
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (id != null) {
      $result.id.addAll(id);
    }
    return $result;
  }
  ChatDelMessage._() : super();
  factory ChatDelMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChatDelMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChatDelMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'chat_id', $pb.PbFieldType.OU3)
    ..p<$fixnum.Int64>(2, _omitFieldNames ? '' : 'id', $pb.PbFieldType.KU6)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  ChatDelMessage clone() => ChatDelMessage()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  ChatDelMessage copyWith(void Function(ChatDelMessage) updates) => super.copyWith((message) => updates(message as ChatDelMessage)) as ChatDelMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatDelMessage create() => ChatDelMessage._();
  ChatDelMessage createEmptyInstance() => create();
  static $pb.PbList<ChatDelMessage> createRepeated() => $pb.PbList<ChatDelMessage>();
  @$core.pragma('dart2js:noInline')
  static ChatDelMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChatDelMessage>(create);
  static ChatDelMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get chatId => $_getIZ(0);
  @$pb.TagNumber(1)
  set chatId($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$fixnum.Int64> get id => $_getList(1);
}

class GroupMember extends $pb.GeneratedMessage {
  factory GroupMember({
    $core.int? userId,
    $core.String? userName,
    $core.String? groupAlias,
    $core.String? icon,
    $core.int? lastOnline,
    $core.int? deleteTime,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (userName != null) {
      $result.userName = userName;
    }
    if (groupAlias != null) {
      $result.groupAlias = groupAlias;
    }
    if (icon != null) {
      $result.icon = icon;
    }
    if (lastOnline != null) {
      $result.lastOnline = lastOnline;
    }
    if (deleteTime != null) {
      $result.deleteTime = deleteTime;
    }
    return $result;
  }
  GroupMember._() : super();
  factory GroupMember.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupMember.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GroupMember', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'user_id', $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'user_name')
    ..aOS(3, _omitFieldNames ? '' : 'group_alias')
    ..aOS(4, _omitFieldNames ? '' : 'icon')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'last_online', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'delete_time', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  GroupMember clone() => GroupMember()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  GroupMember copyWith(void Function(GroupMember) updates) => super.copyWith((message) => updates(message as GroupMember)) as GroupMember;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GroupMember create() => GroupMember._();
  GroupMember createEmptyInstance() => create();
  static $pb.PbList<GroupMember> createRepeated() => $pb.PbList<GroupMember>();
  @$core.pragma('dart2js:noInline')
  static GroupMember getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupMember>(create);
  static GroupMember? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get userId => $_getIZ(0);
  @$pb.TagNumber(1)
  set userId($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get userName => $_getSZ(1);
  @$pb.TagNumber(2)
  set userName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUserName() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get groupAlias => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupAlias($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasGroupAlias() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupAlias() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get icon => $_getSZ(3);
  @$pb.TagNumber(4)
  set icon($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasIcon() => $_has(3);
  @$pb.TagNumber(4)
  void clearIcon() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get lastOnline => $_getIZ(4);
  @$pb.TagNumber(5)
  set lastOnline($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasLastOnline() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastOnline() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get deleteTime => $_getIZ(5);
  @$pb.TagNumber(6)
  set deleteTime($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasDeleteTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeleteTime() => clearField(6);
}

class ChatGroup extends $pb.GeneratedMessage {
  factory ChatGroup({
    $core.int? id,
    $core.String? name,
    $core.String? profile,
    $core.String? icon,
    $core.int? permission,
    $core.int? speakInterval,
    $core.int? visible,
    $core.int? groupType,
    $core.int? roomType,
    $core.int? maxMember,
    $core.int? createTime,
    $core.int? updateTime,
    $core.int? owner,
    $core.Iterable<$core.int>? admins,
    $core.Iterable<GroupMember>? members,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    if (profile != null) {
      $result.profile = profile;
    }
    if (icon != null) {
      $result.icon = icon;
    }
    if (permission != null) {
      $result.permission = permission;
    }
    if (speakInterval != null) {
      $result.speakInterval = speakInterval;
    }
    if (visible != null) {
      $result.visible = visible;
    }
    if (groupType != null) {
      $result.groupType = groupType;
    }
    if (roomType != null) {
      $result.roomType = roomType;
    }
    if (maxMember != null) {
      $result.maxMember = maxMember;
    }
    if (createTime != null) {
      $result.createTime = createTime;
    }
    if (updateTime != null) {
      $result.updateTime = updateTime;
    }
    if (owner != null) {
      $result.owner = owner;
    }
    if (admins != null) {
      $result.admins.addAll(admins);
    }
    if (members != null) {
      $result.members.addAll(members);
    }
    return $result;
  }
  ChatGroup._() : super();
  factory ChatGroup.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChatGroup.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChatGroup', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'profile')
    ..aOS(4, _omitFieldNames ? '' : 'icon')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'permission', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'speak_interval', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'visible', $pb.PbFieldType.OU3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'group_type', $pb.PbFieldType.OU3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'room_type', $pb.PbFieldType.OU3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'max_member', $pb.PbFieldType.OU3)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'create_time', $pb.PbFieldType.OU3)
    ..a<$core.int>(12, _omitFieldNames ? '' : 'update_time', $pb.PbFieldType.OU3)
    ..a<$core.int>(13, _omitFieldNames ? '' : 'owner', $pb.PbFieldType.OU3)
    ..p<$core.int>(14, _omitFieldNames ? '' : 'admins', $pb.PbFieldType.KU3)
    ..pc<GroupMember>(15, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PM, subBuilder: GroupMember.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  ChatGroup clone() => ChatGroup()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  ChatGroup copyWith(void Function(ChatGroup) updates) => super.copyWith((message) => updates(message as ChatGroup)) as ChatGroup;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatGroup create() => ChatGroup._();
  ChatGroup createEmptyInstance() => create();
  static $pb.PbList<ChatGroup> createRepeated() => $pb.PbList<ChatGroup>();
  @$core.pragma('dart2js:noInline')
  static ChatGroup getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChatGroup>(create);
  static ChatGroup? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get profile => $_getSZ(2);
  @$pb.TagNumber(3)
  set profile($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasProfile() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfile() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get icon => $_getSZ(3);
  @$pb.TagNumber(4)
  set icon($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasIcon() => $_has(3);
  @$pb.TagNumber(4)
  void clearIcon() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get permission => $_getIZ(4);
  @$pb.TagNumber(5)
  set permission($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPermission() => $_has(4);
  @$pb.TagNumber(5)
  void clearPermission() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get speakInterval => $_getIZ(5);
  @$pb.TagNumber(6)
  set speakInterval($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasSpeakInterval() => $_has(5);
  @$pb.TagNumber(6)
  void clearSpeakInterval() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get visible => $_getIZ(6);
  @$pb.TagNumber(7)
  set visible($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasVisible() => $_has(6);
  @$pb.TagNumber(7)
  void clearVisible() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get groupType => $_getIZ(7);
  @$pb.TagNumber(8)
  set groupType($core.int v) { $_setUnsignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasGroupType() => $_has(7);
  @$pb.TagNumber(8)
  void clearGroupType() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get roomType => $_getIZ(8);
  @$pb.TagNumber(9)
  set roomType($core.int v) { $_setUnsignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasRoomType() => $_has(8);
  @$pb.TagNumber(9)
  void clearRoomType() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get maxMember => $_getIZ(9);
  @$pb.TagNumber(10)
  set maxMember($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasMaxMember() => $_has(9);
  @$pb.TagNumber(10)
  void clearMaxMember() => clearField(10);

  @$pb.TagNumber(11)
  $core.int get createTime => $_getIZ(10);
  @$pb.TagNumber(11)
  set createTime($core.int v) { $_setUnsignedInt32(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasCreateTime() => $_has(10);
  @$pb.TagNumber(11)
  void clearCreateTime() => clearField(11);

  @$pb.TagNumber(12)
  $core.int get updateTime => $_getIZ(11);
  @$pb.TagNumber(12)
  set updateTime($core.int v) { $_setUnsignedInt32(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasUpdateTime() => $_has(11);
  @$pb.TagNumber(12)
  void clearUpdateTime() => clearField(12);

  @$pb.TagNumber(13)
  $core.int get owner => $_getIZ(12);
  @$pb.TagNumber(13)
  set owner($core.int v) { $_setUnsignedInt32(12, v); }
  @$pb.TagNumber(13)
  $core.bool hasOwner() => $_has(12);
  @$pb.TagNumber(13)
  void clearOwner() => clearField(13);

  @$pb.TagNumber(14)
  $core.List<$core.int> get admins => $_getList(13);

  @$pb.TagNumber(15)
  $core.List<GroupMember> get members => $_getList(14);
}

class Friend extends $pb.GeneratedMessage {
  factory Friend({
    $core.int? uid,
    $core.int? chatId,
    $core.String? profilePic,
    $core.bool? isAcceptor,
  }) {
    final $result = create();
    if (uid != null) {
      $result.uid = uid;
    }
    if (chatId != null) {
      $result.chatId = chatId;
    }
    if (profilePic != null) {
      $result.profilePic = profilePic;
    }
    if (isAcceptor != null) {
      $result.isAcceptor = isAcceptor;
    }
    return $result;
  }
  Friend._() : super();
  factory Friend.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Friend.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Friend', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'uid', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'chat_id', $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'profile_pic')
    ..aOB(4, _omitFieldNames ? '' : 'is_acceptor')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  Friend clone() => Friend()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  Friend copyWith(void Function(Friend) updates) => super.copyWith((message) => updates(message as Friend)) as Friend;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Friend create() => Friend._();
  Friend createEmptyInstance() => create();
  static $pb.PbList<Friend> createRepeated() => $pb.PbList<Friend>();
  @$core.pragma('dart2js:noInline')
  static Friend getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Friend>(create);
  static Friend? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get uid => $_getIZ(0);
  @$pb.TagNumber(1)
  set uid($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUid() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get chatId => $_getIZ(1);
  @$pb.TagNumber(2)
  set chatId($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasChatId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChatId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get profilePic => $_getSZ(2);
  @$pb.TagNumber(3)
  set profilePic($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasProfilePic() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfilePic() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isAcceptor => $_getBF(3);
  @$pb.TagNumber(4)
  set isAcceptor($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasIsAcceptor() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsAcceptor() => clearField(4);
}

class FriendRequest extends $pb.GeneratedMessage {
  factory FriendRequest({
    $core.int? uid,
  }) {
    final $result = create();
    if (uid != null) {
      $result.uid = uid;
    }
    return $result;
  }
  FriendRequest._() : super();
  factory FriendRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FriendRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FriendRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'uid', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  FriendRequest clone() => FriendRequest()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  FriendRequest copyWith(void Function(FriendRequest) updates) => super.copyWith((message) => updates(message as FriendRequest)) as FriendRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FriendRequest create() => FriendRequest._();
  FriendRequest createEmptyInstance() => create();
  static $pb.PbList<FriendRequest> createRepeated() => $pb.PbList<FriendRequest>();
  @$core.pragma('dart2js:noInline')
  static FriendRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FriendRequest>(create);
  static FriendRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get uid => $_getIZ(0);
  @$pb.TagNumber(1)
  set uid($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUid() => clearField(1);
}

class Auth extends $pb.GeneratedMessage {
  factory Auth({
    $core.int? uid,
    $core.String? action,
    $core.String? sessionId,
    $core.String? code,
  }) {
    final $result = create();
    if (uid != null) {
      $result.uid = uid;
    }
    if (action != null) {
      $result.action = action;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    if (code != null) {
      $result.code = code;
    }
    return $result;
  }
  Auth._() : super();
  factory Auth.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Auth.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Auth', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'uid', $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'action')
    ..aOS(3, _omitFieldNames ? '' : 'session_id')
    ..aOS(4, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  Auth clone() => Auth()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  Auth copyWith(void Function(Auth) updates) => super.copyWith((message) => updates(message as Auth)) as Auth;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Auth create() => Auth._();
  Auth createEmptyInstance() => create();
  static $pb.PbList<Auth> createRepeated() => $pb.PbList<Auth>();
  @$core.pragma('dart2js:noInline')
  static Auth getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Auth>(create);
  static Auth? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get uid => $_getIZ(0);
  @$pb.TagNumber(1)
  set uid($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get action => $_getSZ(1);
  @$pb.TagNumber(2)
  set action($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAction() => $_has(1);
  @$pb.TagNumber(2)
  void clearAction() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get code => $_getSZ(3);
  @$pb.TagNumber(4)
  set code($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCode() => $_has(3);
  @$pb.TagNumber(4)
  void clearCode() => clearField(4);
}

class Notification extends $pb.GeneratedMessage {
  factory Notification({
    $core.Iterable<$core.int>? recipientIds,
    $core.String? title,
    $core.String? message,
    $core.String? hiddenMessage,
    $core.String? groupKey,
  }) {
    final $result = create();
    if (recipientIds != null) {
      $result.recipientIds.addAll(recipientIds);
    }
    if (title != null) {
      $result.title = title;
    }
    if (message != null) {
      $result.message = message;
    }
    if (hiddenMessage != null) {
      $result.hiddenMessage = hiddenMessage;
    }
    if (groupKey != null) {
      $result.groupKey = groupKey;
    }
    return $result;
  }
  Notification._() : super();
  factory Notification.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Notification.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Notification', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..p<$core.int>(1, _omitFieldNames ? '' : 'recipient_ids', $pb.PbFieldType.KU3)
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aOS(4, _omitFieldNames ? '' : 'hidden_message')
    ..aOS(5, _omitFieldNames ? '' : 'group_key')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  Notification clone() => Notification()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  Notification copyWith(void Function(Notification) updates) => super.copyWith((message) => updates(message as Notification)) as Notification;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notification create() => Notification._();
  Notification createEmptyInstance() => create();
  static $pb.PbList<Notification> createRepeated() => $pb.PbList<Notification>();
  @$core.pragma('dart2js:noInline')
  static Notification getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Notification>(create);
  static Notification? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get recipientIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get hiddenMessage => $_getSZ(3);
  @$pb.TagNumber(4)
  set hiddenMessage($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasHiddenMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearHiddenMessage() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get groupKey => $_getSZ(4);
  @$pb.TagNumber(5)
  set groupKey($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasGroupKey() => $_has(4);
  @$pb.TagNumber(5)
  void clearGroupKey() => clearField(5);
}

class GroupMemberChange extends $pb.GeneratedMessage {
  factory GroupMemberChange({
    $core.int? gid,
    $core.int? uid,
    $core.int? changeType,
    $core.int? operator,
  }) {
    final $result = create();
    if (gid != null) {
      $result.gid = gid;
    }
    if (uid != null) {
      $result.uid = uid;
    }
    if (changeType != null) {
      $result.changeType = changeType;
    }
    if (operator != null) {
      $result.operator = operator;
    }
    return $result;
  }
  GroupMemberChange._() : super();
  factory GroupMemberChange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupMemberChange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GroupMemberChange', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'gid', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'uid', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'change_type', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'operator', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  GroupMemberChange clone() => GroupMemberChange()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  GroupMemberChange copyWith(void Function(GroupMemberChange) updates) => super.copyWith((message) => updates(message as GroupMemberChange)) as GroupMemberChange;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GroupMemberChange create() => GroupMemberChange._();
  GroupMemberChange createEmptyInstance() => create();
  static $pb.PbList<GroupMemberChange> createRepeated() => $pb.PbList<GroupMemberChange>();
  @$core.pragma('dart2js:noInline')
  static GroupMemberChange getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupMemberChange>(create);
  static GroupMemberChange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get gid => $_getIZ(0);
  @$pb.TagNumber(1)
  set gid($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGid() => $_has(0);
  @$pb.TagNumber(1)
  void clearGid() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get uid => $_getIZ(1);
  @$pb.TagNumber(2)
  set uid($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUid() => $_has(1);
  @$pb.TagNumber(2)
  void clearUid() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get changeType => $_getIZ(2);
  @$pb.TagNumber(3)
  set changeType($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasChangeType() => $_has(2);
  @$pb.TagNumber(3)
  void clearChangeType() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get operator => $_getIZ(3);
  @$pb.TagNumber(4)
  set operator($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasOperator() => $_has(3);
  @$pb.TagNumber(4)
  void clearOperator() => clearField(4);
}

class ClientAction extends $pb.GeneratedMessage {
  factory ClientAction({
    $core.int? action,
    $core.String? requestId,
    $core.int? code,
    $core.String? message,
  }) {
    final $result = create();
    if (action != null) {
      $result.action = action;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (code != null) {
      $result.code = code;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  ClientAction._() : super();
  factory ClientAction.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ClientAction.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ClientAction', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'action', $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'request_Id', protoName: 'request_Id')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'code', $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  ClientAction clone() => ClientAction()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  ClientAction copyWith(void Function(ClientAction) updates) => super.copyWith((message) => updates(message as ClientAction)) as ClientAction;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientAction create() => ClientAction._();
  ClientAction createEmptyInstance() => create();
  static $pb.PbList<ClientAction> createRepeated() => $pb.PbList<ClientAction>();
  @$core.pragma('dart2js:noInline')
  static ClientAction getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClientAction>(create);
  static ClientAction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get action => $_getIZ(0);
  @$pb.TagNumber(1)
  set action($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get code => $_getIZ(2);
  @$pb.TagNumber(3)
  set code($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get message => $_getSZ(3);
  @$pb.TagNumber(4)
  set message($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessage() => clearField(4);
}

class VideoCall extends $pb.GeneratedMessage {
  factory VideoCall({
    $core.String? message,
  }) {
    final $result = create();
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  VideoCall._() : super();
  factory VideoCall.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory VideoCall.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'VideoCall', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  VideoCall clone() => VideoCall()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  VideoCall copyWith(void Function(VideoCall) updates) => super.copyWith((message) => updates(message as VideoCall)) as VideoCall;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VideoCall create() => VideoCall._();
  VideoCall createEmptyInstance() => create();
  static $pb.PbList<VideoCall> createRepeated() => $pb.PbList<VideoCall>();
  @$core.pragma('dart2js:noInline')
  static VideoCall getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VideoCall>(create);
  static VideoCall? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => clearField(1);
}

class LeaveChat extends $pb.GeneratedMessage {
  factory LeaveChat({
    $core.int? chatId,
  }) {
    final $result = create();
    if (chatId != null) {
      $result.chatId = chatId;
    }
    return $result;
  }
  LeaveChat._() : super();
  factory LeaveChat.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LeaveChat.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LeaveChat', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'chat_id', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  LeaveChat clone() => LeaveChat()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  LeaveChat copyWith(void Function(LeaveChat) updates) => super.copyWith((message) => updates(message as LeaveChat)) as LeaveChat;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LeaveChat create() => LeaveChat._();
  LeaveChat createEmptyInstance() => create();
  static $pb.PbList<LeaveChat> createRepeated() => $pb.PbList<LeaveChat>();
  @$core.pragma('dart2js:noInline')
  static LeaveChat getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LeaveChat>(create);
  static LeaveChat? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get chatId => $_getIZ(0);
  @$pb.TagNumber(1)
  set chatId($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChatId() => clearField(1);
}

class PushClientMessage extends $pb.GeneratedMessage {
  factory PushClientMessage({
    Chat? chat,
    ChatMessage? message,
    CmdTopic? cmdTopic,
    SysOp? sysOp,
    ChatReadMessage? chatReadMsg,
    ChatDelMessage? chatDelMsg,
    ChatGroup? chatGroup,
    Friend? friend,
    FriendRequest? friendRequest,
    Auth? auth,
    Notification? notification,
    GroupMemberChange? groupMemberChange,
    $core.Iterable<ChatMessage>? messageHistory,
    ClientAction? clientAction,
    VideoCall? videoCall,
    LeaveChat? leaveChat,
  }) {
    final $result = create();
    if (chat != null) {
      $result.chat = chat;
    }
    if (message != null) {
      $result.message = message;
    }
    if (cmdTopic != null) {
      $result.cmdTopic = cmdTopic;
    }
    if (sysOp != null) {
      $result.sysOp = sysOp;
    }
    if (chatReadMsg != null) {
      $result.chatReadMsg = chatReadMsg;
    }
    if (chatDelMsg != null) {
      $result.chatDelMsg = chatDelMsg;
    }
    if (chatGroup != null) {
      $result.chatGroup = chatGroup;
    }
    if (friend != null) {
      $result.friend = friend;
    }
    if (friendRequest != null) {
      $result.friendRequest = friendRequest;
    }
    if (auth != null) {
      $result.auth = auth;
    }
    if (notification != null) {
      $result.notification = notification;
    }
    if (groupMemberChange != null) {
      $result.groupMemberChange = groupMemberChange;
    }
    if (messageHistory != null) {
      $result.messageHistory.addAll(messageHistory);
    }
    if (clientAction != null) {
      $result.clientAction = clientAction;
    }
    if (videoCall != null) {
      $result.videoCall = videoCall;
    }
    if (leaveChat != null) {
      $result.leaveChat = leaveChat;
    }
    return $result;
  }
  PushClientMessage._() : super();
  factory PushClientMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PushClientMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PushClientMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'proto'), createEmptyInstance: create)
    ..aOM<Chat>(1, _omitFieldNames ? '' : 'chat', subBuilder: Chat.create)
    ..aOM<ChatMessage>(2, _omitFieldNames ? '' : 'message', subBuilder: ChatMessage.create)
    ..aOM<CmdTopic>(3, _omitFieldNames ? '' : 'cmd_topic', subBuilder: CmdTopic.create)
    ..aOM<SysOp>(4, _omitFieldNames ? '' : 'sys_op', subBuilder: SysOp.create)
    ..aOM<ChatReadMessage>(5, _omitFieldNames ? '' : 'chat_read_msg', subBuilder: ChatReadMessage.create)
    ..aOM<ChatDelMessage>(6, _omitFieldNames ? '' : 'chat_del_msg', subBuilder: ChatDelMessage.create)
    ..aOM<ChatGroup>(7, _omitFieldNames ? '' : 'chat_group', subBuilder: ChatGroup.create)
    ..aOM<Friend>(8, _omitFieldNames ? '' : 'friend', subBuilder: Friend.create)
    ..aOM<FriendRequest>(9, _omitFieldNames ? '' : 'friend_request', subBuilder: FriendRequest.create)
    ..aOM<Auth>(10, _omitFieldNames ? '' : 'auth', subBuilder: Auth.create)
    ..aOM<Notification>(11, _omitFieldNames ? '' : 'notification', subBuilder: Notification.create)
    ..aOM<GroupMemberChange>(12, _omitFieldNames ? '' : 'group_member_change', subBuilder: GroupMemberChange.create)
    ..pc<ChatMessage>(13, _omitFieldNames ? '' : 'message_history', $pb.PbFieldType.PM, subBuilder: ChatMessage.create)
    ..aOM<ClientAction>(14, _omitFieldNames ? '' : 'client_action', subBuilder: ClientAction.create)
    ..aOM<VideoCall>(15, _omitFieldNames ? '' : 'video_call', subBuilder: VideoCall.create)
    ..aOM<LeaveChat>(16, _omitFieldNames ? '' : 'leave_chat', subBuilder: LeaveChat.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
          'Will be removed in next major version')
  PushClientMessage clone() => PushClientMessage()..mergeFromMessage(this);
  @$core.Deprecated(
      'Using this can add significant overhead to your binary. '
          'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
          'Will be removed in next major version')
  PushClientMessage copyWith(void Function(PushClientMessage) updates) => super.copyWith((message) => updates(message as PushClientMessage)) as PushClientMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushClientMessage create() => PushClientMessage._();
  PushClientMessage createEmptyInstance() => create();
  static $pb.PbList<PushClientMessage> createRepeated() => $pb.PbList<PushClientMessage>();
  @$core.pragma('dart2js:noInline')
  static PushClientMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PushClientMessage>(create);
  static PushClientMessage? _defaultInstance;

  @$pb.TagNumber(1)
  Chat get chat => $_getN(0);
  @$pb.TagNumber(1)
  set chat(Chat v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasChat() => $_has(0);
  @$pb.TagNumber(1)
  void clearChat() => clearField(1);
  @$pb.TagNumber(1)
  Chat ensureChat() => $_ensure(0);

  @$pb.TagNumber(2)
  ChatMessage get message => $_getN(1);
  @$pb.TagNumber(2)
  set message(ChatMessage v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => clearField(2);
  @$pb.TagNumber(2)
  ChatMessage ensureMessage() => $_ensure(1);

  @$pb.TagNumber(3)
  CmdTopic get cmdTopic => $_getN(2);
  @$pb.TagNumber(3)
  set cmdTopic(CmdTopic v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasCmdTopic() => $_has(2);
  @$pb.TagNumber(3)
  void clearCmdTopic() => clearField(3);
  @$pb.TagNumber(3)
  CmdTopic ensureCmdTopic() => $_ensure(2);

  @$pb.TagNumber(4)
  SysOp get sysOp => $_getN(3);
  @$pb.TagNumber(4)
  set sysOp(SysOp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasSysOp() => $_has(3);
  @$pb.TagNumber(4)
  void clearSysOp() => clearField(4);
  @$pb.TagNumber(4)
  SysOp ensureSysOp() => $_ensure(3);

  @$pb.TagNumber(5)
  ChatReadMessage get chatReadMsg => $_getN(4);
  @$pb.TagNumber(5)
  set chatReadMsg(ChatReadMessage v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasChatReadMsg() => $_has(4);
  @$pb.TagNumber(5)
  void clearChatReadMsg() => clearField(5);
  @$pb.TagNumber(5)
  ChatReadMessage ensureChatReadMsg() => $_ensure(4);

  @$pb.TagNumber(6)
  ChatDelMessage get chatDelMsg => $_getN(5);
  @$pb.TagNumber(6)
  set chatDelMsg(ChatDelMessage v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasChatDelMsg() => $_has(5);
  @$pb.TagNumber(6)
  void clearChatDelMsg() => clearField(6);
  @$pb.TagNumber(6)
  ChatDelMessage ensureChatDelMsg() => $_ensure(5);

  @$pb.TagNumber(7)
  ChatGroup get chatGroup => $_getN(6);
  @$pb.TagNumber(7)
  set chatGroup(ChatGroup v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasChatGroup() => $_has(6);
  @$pb.TagNumber(7)
  void clearChatGroup() => clearField(7);
  @$pb.TagNumber(7)
  ChatGroup ensureChatGroup() => $_ensure(6);

  @$pb.TagNumber(8)
  Friend get friend => $_getN(7);
  @$pb.TagNumber(8)
  set friend(Friend v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasFriend() => $_has(7);
  @$pb.TagNumber(8)
  void clearFriend() => clearField(8);
  @$pb.TagNumber(8)
  Friend ensureFriend() => $_ensure(7);

  @$pb.TagNumber(9)
  FriendRequest get friendRequest => $_getN(8);
  @$pb.TagNumber(9)
  set friendRequest(FriendRequest v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasFriendRequest() => $_has(8);
  @$pb.TagNumber(9)
  void clearFriendRequest() => clearField(9);
  @$pb.TagNumber(9)
  FriendRequest ensureFriendRequest() => $_ensure(8);

  @$pb.TagNumber(10)
  Auth get auth => $_getN(9);
  @$pb.TagNumber(10)
  set auth(Auth v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasAuth() => $_has(9);
  @$pb.TagNumber(10)
  void clearAuth() => clearField(10);
  @$pb.TagNumber(10)
  Auth ensureAuth() => $_ensure(9);

  @$pb.TagNumber(11)
  Notification get notification => $_getN(10);
  @$pb.TagNumber(11)
  set notification(Notification v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasNotification() => $_has(10);
  @$pb.TagNumber(11)
  void clearNotification() => clearField(11);
  @$pb.TagNumber(11)
  Notification ensureNotification() => $_ensure(10);

  @$pb.TagNumber(12)
  GroupMemberChange get groupMemberChange => $_getN(11);
  @$pb.TagNumber(12)
  set groupMemberChange(GroupMemberChange v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasGroupMemberChange() => $_has(11);
  @$pb.TagNumber(12)
  void clearGroupMemberChange() => clearField(12);
  @$pb.TagNumber(12)
  GroupMemberChange ensureGroupMemberChange() => $_ensure(11);

  @$pb.TagNumber(13)
  $core.List<ChatMessage> get messageHistory => $_getList(12);

  @$pb.TagNumber(14)
  ClientAction get clientAction => $_getN(13);
  @$pb.TagNumber(14)
  set clientAction(ClientAction v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasClientAction() => $_has(13);
  @$pb.TagNumber(14)
  void clearClientAction() => clearField(14);
  @$pb.TagNumber(14)
  ClientAction ensureClientAction() => $_ensure(13);

  @$pb.TagNumber(15)
  VideoCall get videoCall => $_getN(14);
  @$pb.TagNumber(15)
  set videoCall(VideoCall v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasVideoCall() => $_has(14);
  @$pb.TagNumber(15)
  void clearVideoCall() => clearField(15);
  @$pb.TagNumber(15)
  VideoCall ensureVideoCall() => $_ensure(14);

  @$pb.TagNumber(16)
  LeaveChat get leaveChat => $_getN(15);
  @$pb.TagNumber(16)
  set leaveChat(LeaveChat v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasLeaveChat() => $_has(15);
  @$pb.TagNumber(16)
  void clearLeaveChat() => clearField(16);
  @$pb.TagNumber(16)
  LeaveChat ensureLeaveChat() => $_ensure(15);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
