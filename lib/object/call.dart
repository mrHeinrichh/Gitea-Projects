class Call {
  String channelId;
  int callerId;
  int receiverId;
  int chatId;
  int duration; //in seconds
  int createdAt;
  int updatedAt;
  int endedAt;
  int status;
  int deletedAt;
  int isRead;
  int isVideoCall;

  Call({
    required this.channelId,
    required this.callerId,
    required this.receiverId,
    required this.chatId,
    required this.duration,
    required this.createdAt,
    required this.updatedAt,
    required this.endedAt,
    required this.status,
    this.isRead = 0,
    this.deletedAt = 0,
    this.isVideoCall = 0,
  });

  factory Call.fromJson(
    Map<String, dynamic> json, {
    bool fromLocalDB = false,
  }) =>
      Call(
        channelId:
            fromLocalDB ? json["id"] ?? '' : json["rtc_channel_id"] ?? '',
        callerId: json["inviter_id"] ?? json["caller_id"] ?? 0,
        receiverId: json["receiver_id"] ?? 0,
        chatId: json["chat_id"] ?? 0,
        duration: json["duration"] ?? 0,
        createdAt:
            json["created_at"] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt:
            json["updated_at"] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        endedAt: json["ended_at"] ?? 0,
        status: json["status"] ?? 0,
        deletedAt: json["deleted_at"] ?? 0,
        isRead: json["is_read"] ?? 0,
        isVideoCall: json["video_call"] ?? 0,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': channelId,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'chat_id': chatId,
      'duration': duration,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'ended_at': endedAt,
      'status': status,
      "deleted_at": deletedAt,
      'is_read': isRead,
      "video_call": isVideoCall,
    };
  }
}

class CallInviteList {
  int? id;
  String? channelId;
  String? sessionId;
  int? userId;
  int? inviterId;
  int? chatId;
  int? status;
  int? duration;
  int? createdAt;
  int? connectedAt;
  int? updatedAt;
  int? endedAt;
  int? deletedAt;
  int? expiredAt;
  int? reason;
  int? isVideoCall;

  CallInviteList({
    this.id,
    this.channelId,
    this.sessionId,
    this.userId,
    this.inviterId,
    this.chatId,
    this.status,
    this.duration,
    this.createdAt,
    this.connectedAt,
    this.updatedAt,
    this.endedAt,
    this.deletedAt,
    this.expiredAt,
    this.reason,
    this.isVideoCall = 0,
  });

  factory CallInviteList.fromJson(Map<String, dynamic> json) => CallInviteList(
        id: json["id"] ?? 0,
        channelId: json["rtc_channel_id"] ?? '',
        sessionId: json["session_id"] ?? '',
        userId: json["user_id"] ?? 0,
        inviterId: json["inviter_id"] ?? 0,
        chatId: json["chat_id"] ?? 0,
        status: json["status"] ?? 0,
        duration: json["duration"] ?? 0,
        createdAt: json["created_at"] ?? 0,
        connectedAt: json["connected_at"] ?? 0,
        updatedAt: json["updated_at"] ?? 0,
        endedAt: json["ended_at"] ?? 0,
        deletedAt: json["deleted_at"] ?? 0,
        expiredAt: json["expired_at"] ?? 0,
        reason: json["reason"] ?? 0,
        isVideoCall: json["video_call"] ?? 0,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'session_id': sessionId,
      'user_id': userId,
      'inviter_id': inviterId,
      'chat_id': chatId,
      'status': status,
      'duration': duration,
      'created_at': createdAt,
      'connected_at': connectedAt,
      'updated_at': updatedAt,
      'ended_at': endedAt,
      'deleted_at': deletedAt,
      'expired_at': expiredAt,
      'reason': reason,
      'video_call': isVideoCall,
    };
  }
}

class CallRtcToken {
  String? rtcToken;
  String? rtcChannelId;
  String? rtcAppID;
  String? rtcEncryptKey;

  CallRtcToken({
    this.rtcToken,
    this.rtcChannelId,
    this.rtcAppID,
    this.rtcEncryptKey,
  });

  factory CallRtcToken.fromJson(Map<String, dynamic> json) => CallRtcToken(
        rtcToken: json["rtc_token"] ?? '',
        rtcChannelId: json["rtc_channel_id"] ?? '',
        rtcAppID: json["app_id"] ?? '',
        rtcEncryptKey: json["encrypt_key"] ?? '',
      );

  Map<String, dynamic> toJson() {
    return {
      'rtc_token': rtcToken,
      'rtc_channel_id': rtcChannelId,
      'app_id': rtcAppID,
      'encrypt_key': rtcEncryptKey,
    };
  }
}
