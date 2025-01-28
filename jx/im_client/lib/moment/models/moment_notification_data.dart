part of '../index.dart';

class MomentNotificationResponse {
  List<MomentDetailUpdate>? notifications;

  MomentNotificationResponse({
    this.notifications,
  });

  factory MomentNotificationResponse.fromJson(Map<String, dynamic> json) {
    return MomentNotificationResponse(
      notifications: json['notifications'] != null
          ? (json['notifications'] as List)
              .map((i) => MomentDetailUpdate.fromJson(i))
              .toList()
          : null,
    );
  }
}

class MomentDetailUpdate {
  int? id;
  int? userId;
  int? postId;

  // json encode内容
  MomentNotificationContent? content;
  MomentNotificationType? typ;
  int? typId;
  int? createdAt;

  MomentDetailUpdate({
    this.id,
    this.userId,
    this.postId,
    this.content,
    this.typ,
    this.typId,
    this.createdAt,
  });

  factory MomentDetailUpdate.fromJson(Map<String, dynamic> json) {
    return MomentDetailUpdate(
      id: json['id'],
      userId: json['user_id'],
      postId: json['post_id'],
      content: json['content'] != null
          ? MomentNotificationContent.fromJson(json['content'])
          : null,
      typ: json.containsKey('typ')
          ? json['typ']!=0?MomentNotificationType.fromValue(json['typ']):null
          : null,
      typId: json['typ_id'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['post_id'] = postId;
    data['content'] = content?.toJson();
    data['typ'] = typ?.value??0;
    data['typ_id'] = typId;
    data['created_at'] = createdAt;
    return data;
  }
}

class MomentNotificationContent {
  int? postId;
  int? userId;
  String? msg;
  MomentContent? postContent;
  int? replyUserId;

  MomentNotificationContent({
    this.postId,
    this.userId,
    this.msg,
    this.postContent,
    this.replyUserId,
  });

  factory MomentNotificationContent.fromJson(Map<String, dynamic> json) {
    return MomentNotificationContent(
      postId: json['post_id'],
      userId: json['user_id'],
      msg: json['msg'],
      postContent: json['post_content'] != null &&
              json['post_content'] is String &&
              json['post_content'].isNotEmpty
          ? MomentContent.fromJson(jsonDecode(json['post_content']))
          : null,
      replyUserId: json['reply_user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['post_id'] = postId;
    data['user_id'] = userId;
    data['msg'] = msg;
    data['post_content'] = postContent?.toJson();
    data['reply_user_id'] = replyUserId;
    return data;
  }
}

class MomentNotificationLastInfo {
  int? postCreatorId;
  int? unreadNotificationCount;
  int? lastReadNotificationId;
  int? sendTime;

  MomentNotificationLastInfo({
    this.postCreatorId,
    this.unreadNotificationCount,
    this.lastReadNotificationId,
    this.sendTime
  });

  factory MomentNotificationLastInfo.fromJson(Map<String, dynamic> json) {
    return MomentNotificationLastInfo(
      postCreatorId: json['post_creator_id'],
      unreadNotificationCount: json['unread_notification_count'],
      lastReadNotificationId: json['last_read_notification_id'],
      sendTime: json['send_time'],
    );
  }
}
