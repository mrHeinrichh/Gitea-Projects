/// API model
class CipherKey {
  int? id;
  int? uid;
  String? public;
  String? encPrivate;

  CipherKey({
    this.id,
    this.uid,
    this.public,
    this.encPrivate,
  });

  factory CipherKey.fromJson(Map<String, dynamic> json) {
    return CipherKey(
      id: json['id'] ?? 0,
      uid: json['uid'] ?? 0,
      public: json['public'] ?? "",
      encPrivate: json['enc_private'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'public': public,
      'enc_private': encPrivate,
    };
  }
}


class ChatSession {
  List<ChatKey> chatKeys;
  int chatId;

  ChatSession({
    required this.chatKeys,
    required this.chatId,
  });
}

class ChatKey { //用于传递加密后的会话密钥 只用于传递，不用于保存
  int? uid;
  String? session;
  int? id;
  int? chatId;

  ChatKey({
    this.uid,
    this.session,
    this.id,
    this.chatId,
  });

  factory ChatKey.fromJson(Map<String, dynamic> json) {
    return ChatKey(
      id: json['id'] ?? 0,
      uid: json['uid'] ?? 0,
      chatId: json['chat_id'] ?? 0,
      session: json['session'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid ?? 0,
      'session': session ?? "",
      'id': id ?? 0,
      'chat_id':chatId ?? 0,
    };
  }
}

class FriendAssistData{
  int? channelGroupId;
  int? channelId;
  String? code;
  int? count;
  int? createdAt;
  int? event;
  int? expiredAt;
  int? status;
  int? updatedAt;
  int? userId;
  int? verified;

  FriendAssistData({
    this.channelGroupId,
    this.channelId,
    this.code,
    this.count,
    this.createdAt,
    this.event,
    this.expiredAt,
    this.status,
    this.updatedAt,
    this.userId,
    this.verified,
  });

  factory FriendAssistData.fromJson(Map<String, dynamic> json) {
    return FriendAssistData(
      channelGroupId: json['channel_group_id'] ?? 0,
      channelId: json['channel_id'] ?? 0,
      code: json['code'] ?? '',
      count: json['count'] ?? 0,
      createdAt: json['created_at'] ?? 0,
      event: json['event'] ?? 0,
      expiredAt: json['expired_at'] ?? 0,
      status: json['status'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
      userId: json['user_id'] ?? 0,
      verified: json['verified'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel_group_id': channelGroupId ?? 0,
      'channel_id': channelId ?? 0,
      'code': code ?? '',
      'count':count ?? 0,
      'created_at': createdAt ?? 0,
      'event': event ?? 0,
      'expired_at': expiredAt ?? 0,
      'status':status ?? 0,
      'updated_at': updatedAt ?? 0,
      'user_id': userId ?? 0,
      'verified': verified ?? 0,
    };
  }
}