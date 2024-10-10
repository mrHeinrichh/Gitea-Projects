import 'dart:convert';

import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/object/chat/message.dart';

class ReplyModel {
  // 本地唯一id
  int id = 0;

  // 消息id
  int messageId = 0;

  // 聊天室源消息id
  int chatIdx = 0;

  // 用户昵称
  String nickName = '';

  // 消息类型
  int typ = 0;

  // 发送者id
  int userId = 0;

  String text = '';

  // 资源远端路径
  String url = '';

  // 资源本地路径
  String filePath = '';

  // 艾特人员
  List<MentionModel> atUser = <MentionModel>[];

  ReplyModel();

  ReplyModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] != null) {
      id = json['id'];
    }

    if (json['chat_idx'] != null) {
      chatIdx = json['chat_idx'];
    }

    if (json['messageId'] != null) {
      messageId = json['messageId'];
    }

    if (json['nick_name'] != null) {
      nickName = json['nick_name'];
    }

    if (json['typ'] != null) {
      typ = json['typ'];
    }

    if (json['user_id'] != null) {
      userId = json['user_id'];
    }

    if (json['text'] != null) {
      text = json['text'];
    }

    if (json['url'] != null) {
      url = json['url'];
    }

    if (json['file_path'] != null) {
      filePath = json['file_path'];
    }

    if (json['atUser'] != null) {
      atUser = json['atUser']
          .map<MentionModel>((e) => MentionModel.fromJson(e))
          .toList();
    }

    if (json['content'] != null) {
      final content = jsonDecode(json['content']);
      url = content['url'] ?? '';
      filePath = content['file_path'] ?? '';
      text = content['caption'] ?? content['text'] ?? '';
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['file_path'] = filePath;
    data['id'] = id;
    data['message_id'] = messageId;
    data['chat_idx'] = chatIdx;
    data['user_id'] = userId;
    data['nick_name'] = nickName;
    data['typ'] = typ;
    data['text'] = text;
    data['url'] = url;
    data['atUser'] = atUser;

    return data;
  }

  ReplyModel copyWith({
    int? id,
    int? chatIdx,
    String? nickName,
    int? messageId,
    int? typ,
    int? userId,
    List<MentionModel>? atUser,
    String? text,
    String? url,
    String? filePath,
    String? messageContent,
  }) {
    return ReplyModel()
      ..id = id ?? this.id
      ..chatIdx = chatIdx ?? this.chatIdx
      ..messageId = messageId ?? this.messageId
      ..nickName = nickName ?? this.nickName
      ..typ = typ ?? this.typ
      ..userId = userId ?? this.userId
      ..atUser = atUser ?? this.atUser
      ..text = text ?? this.text
      ..url = url ?? this.url
      ..filePath = filePath ?? this.filePath;
  }

  bool get isMediaType =>
      typ == messageTypeImage ||
      typ == messageTypeVideo ||
      typ == messageTypeReel ||
      typ == messageTypeNewAlbum;
}
