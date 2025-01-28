part of '../index.dart';

class MomentPosts {
  //當發生異常時，設為true.
  bool networkError = false;

  MomentPost? post;
  MomentLikes? likes;
  MomentCommentDetail? commentDetail;

  MomentPosts({this.post, this.likes, this.commentDetail});

  factory MomentPosts.fromJson(Map<String, dynamic> json) {
    return MomentPosts(
      post: json["post"] != null
          ? MomentPost.fromJson(json["post"] as Map<String, dynamic>)
          : null,
      likes: json["likes"] != null
          ? MomentLikes.fromJson(json["likes"] as Map<String, dynamic>)
          : null,
      commentDetail: json["comment_detail"] != null
          ? MomentCommentDetail.fromJson(
              json["comment_detail"] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "post": post!.toJson(),
        "likes": likes!.toJson(),
        "comment_detail": commentDetail!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MomentPosts &&
          runtimeType == other.runtimeType &&
          "${post!.id}${post!.userId}" ==
              "${other.post!.id}${other.post!.userId}";

  @override
  int get hashCode => "${post!.id}${post!.userId}".hashCode;
}

class MomentPost {
  int? id;
  int? userId;
  MomentContent? content;
  int? visibility;
  List<int>? targets;
  List<String>? targetTags;
  List<int>? mentions;
  int? createdAt;
  int? deletedAt;
  int? channelId;
  int? channelGroupId;

  MomentPost({
    this.id,
    this.userId,
    this.content,
    this.visibility,
    this.targets,
    this.targetTags,
    this.mentions,
    this.createdAt,
    this.deletedAt,
    this.channelId,
    this.channelGroupId,
  });

  factory MomentPost.fromJson(Map<String, dynamic> json) {
    return MomentPost(
      id: json["id"],
      userId: json["user_id"],
      content: MomentContent.fromJson(
        json["content"] is String
            ? jsonDecode(json["content"])
            : json["content"],
      ),
      visibility: json["visibility"],
      targets: json["targets"] != null ? List<int>.from(json["targets"]) : null,
      targetTags: json["target_tags"] != null ? List<String>.from(json["target_tags"]) : null,
      mentions:
          json["mentions"] != null ? List<int>.from(json["mentions"]) : null,
      createdAt: json["created_at"],
      deletedAt: json["deleted_at"],
      channelId: json["channel_id"],
      channelGroupId: json["channel_group_id"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "content": content!.toJson(),
        "visibility": visibility,
        "targets": targets,
        "target_tags": targetTags,
        "mentions": mentions,
        "created_at": createdAt,
        "deleted_at": deletedAt,
        "channel_id": channelId,
        "channel_group_id": channelGroupId,
      };
}

class MomentLikes {
  int? count;
  List<int>? list;

  MomentLikes({this.count, this.list});

  factory MomentLikes.fromJson(Map<String, dynamic> json) => MomentLikes(
        count: json["count"],
        list: json["list"] != null ? List<int>.from(json["list"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "count": count,
        "list": list,
      };
}

class MomentCommentDetail {
  int? totalCount;
  int? count;
  List<MomentComment>? comments;

  MomentCommentDetail({this.totalCount, this.count, this.comments});

  factory MomentCommentDetail.fromJson(Map<String, dynamic> json) =>
      MomentCommentDetail(
        totalCount: json["total_count"],
        count: json["count"],
        comments: json["comments"] != null
            ? List<MomentComment>.from(
                json["comments"].map((x) => MomentComment.fromJson(x)),
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        "total_count": totalCount,
        "count": count,
        "comments": comments!.map((e) => e.toJson()).toList(),
      };
}

class MomentComment {
  int? id;
  int? userId;
  int? postId;
  int? replyUserId;
  String? content;
  int? createdAt;
  int? updateAt;
  int? deletedAt;

  MomentComment({
    this.id,
    this.userId,
    this.postId,
    this.replyUserId,
    this.content,
    this.createdAt,
    this.updateAt,
    this.deletedAt,
  });

  factory MomentComment.fromJson(Map<String, dynamic> json) => MomentComment(
        id: json["id"],
        userId: json["user_id"],
        postId: json["post_id"],
        replyUserId: json["reply_user_id"],
        content: json["content"],
        createdAt: json["created_at"],
        updateAt: json["update_at"],
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "post_id": postId,
        "reply_user_id": replyUserId,
        "content": content,
        "created_at": createdAt,
        "update_at": updateAt,
        "deleted_at": deletedAt,
      };
}

class MomentContent {
  String? text;
  Metadata? metadata;
  String? metadataGausBlurHash;
  List<MomentContentDetail>? assets;

  MomentContent({
    this.text,
    this.metadata,
    this.metadataGausBlurHash,
    this.assets,
  });

  String toJson() => jsonEncode({
        "text": text,
        "metadata": metadata?.toJson(),
        "metadataGausBlurHash": metadataGausBlurHash,
        "assets": assets?.map((e) => e.toJson()).toList(),
      });

  factory MomentContent.fromJson(Map<String, dynamic> json) {
    return MomentContent(
      text: json['text'],
      metadata: json['metadata'] != null
          ? Metadata.fromJson(json['metadata'])
          : null,
      metadataGausBlurHash: json['metadataGausBlurHash'],
      assets: json['assets'] != null
          ? List<MomentContentDetail>.from(
              json['assets'].map((x) => MomentContentDetail.fromJson(x)),
            )
          : null,
    );
  }
}

class MomentContentDetail {
  // 资源类型
  String type;

  // 上传的资源地址
  String url;

  // 视频封面图
  String? cover;

  //高斯模糊圖
  String? gausPath;

  // 资源宽高
  int width;
  int height;

  // 唯一屬性
  final String uniqueId;

  MomentContentDetail({
    required this.type,
    required this.url,
    required this.width,
    required this.height,
    this.cover,
    this.gausPath,
  }) : uniqueId = const Uuid().v4();

  factory MomentContentDetail.fromJson(Map<String, dynamic> json) {
    return MomentContentDetail(
      type: json['type'],
      url: json['url'],
      width: json['width'],
      height: json['height'],
      cover: json['cover'],
      gausPath: json['gausPath'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['url'] = url;
    data['cover'] = cover;
    data['width'] = width;
    data['height'] = height;
    data['gausPath'] = gausPath;
    return data;
  }
}

class LikePost {
  int? userId;
  int? postId;
  bool? flag;
  int? updatedAt;

  LikePost({
    this.userId,
    this.postId,
    this.flag,
    this.updatedAt,
  });

  factory LikePost.fromJson(Map<String, dynamic> json) {
    return LikePost(
      userId: json["user_id"],
      postId: json["post_id"],
      flag: json["flag"],
      updatedAt: json["updated_at"],
    );
  }
}