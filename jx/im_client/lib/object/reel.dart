import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/reel/reel_page/reel_follow_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

enum ReelType {
  REELS_VIDEO(1),
  REELS_ALBUM(2);

  const ReelType(this.value);

  final int value;
}

enum ProfileRelationship {
  stranger(0),
  follower(1),
  followee(2),
  friend(3),
  self(4);

  const ProfileRelationship(this.value);

  final int value;
}

//批量管理頁面type
enum ReelPostType {
  post, //貼文
  draftRepost, //已發貼文存草稿
  draft, //草稿
  save, //收藏
  liked //點讚
}

enum ReelIconDataType {
  liked, //点赞
  saved, //收藏
  share, //分享
  comment, //评论
}

enum ReelProfileStatisticsDataType {
  totalLike, //总点赞
  totalFollows, //已关注的对象数
  totalFollowers, //关注我的对象数
}

class ReelPost {
  Rxn<ReelCreator> creator = Rxn<ReelCreator>();
  Rxn<bool> isLiked = Rxn<bool>();
  Rxn<bool> isSaved = Rxn<bool>();
  Rxn<int> id = Rxn<int>();
  Rxn<int> userid = Rxn<int>();
  Rxn<String> title = Rxn<String>();
  Rxn<String> description = Rxn<String>();
  Rxn<String> thumbnail = Rxn<String>();
  Rxn<int> type = Rxn<int>();
  Rxn<ReelVideoInfo> file = Rxn<ReelVideoInfo>();
  RxList<String> tags = RxList<String>();
  RxList<ReelComment> comments = RxList<ReelComment>();
  Rxn<int> duration = Rxn<int>();
  Rxn<int> likedCount = Rxn<int>();
  Rxn<int> savedCount = Rxn<int>();
  Rxn<int> sharedCount = Rxn<int>();
  Rxn<int> viewedCount = Rxn<int>();
  Rxn<int> commentCount = Rxn<int>();
  Rxn<int> fullViewedCount = Rxn<int>();
  Rxn<int> allowDownload = Rxn<int>();
  Rxn<int> allowShare = Rxn<int>();
  Rxn<int> allowComment = Rxn<int>();
  Rxn<int> allowPublic = Rxn<int>();
  Rxn<int> createAt = Rxn<int>();
  Rxn<int> updateAt = Rxn<int>();
  Rxn<int> deleteAt = Rxn<int>();
  Rxn<String> gausPath = Rxn<String>();

  bool isSelected = false;

  ReelPost({
    ReelCreator? creator,
    bool? isLiked,
    bool? isSaved,
    int? id,
    int? userid,
    String? title,
    String? description,
    String? thumbnail,
    int? type,
    ReelVideoInfo? file,
    List<String>? tags,
    int? duration,
    int? likedCount,
    int? savedCount,
    int? sharedCount,
    int? viewedCount,
    int? fullViewedCount,
    int? allowDownload,
    int? allowShare,
    int? allowComment,
    int? allowPublic,
    int? createAt,
    int? updateAt,
    int? deleteAt,
    int? commentCount,
    Map<String, dynamic>? settings,
  }) {
    this.creator.value = creator;
    this.isLiked.value = isLiked;
    this.isSaved.value = isSaved;
    this.id.value = id;
    this.userid.value = userid;
    this.title.value = title;
    this.description.value = description;
    this.thumbnail.value = thumbnail;
    this.type.value = type;
    this.file.value = file;
    this.tags.value = tags ?? [];
    this.duration.value = duration;
    this.likedCount.value = likedCount;
    this.savedCount.value = savedCount;
    this.sharedCount.value = sharedCount;
    this.viewedCount.value = viewedCount;
    this.commentCount.value = commentCount;
    this.fullViewedCount.value = fullViewedCount;
    this.allowDownload.value = allowDownload;
    this.allowShare.value = allowShare;
    this.allowComment.value = allowComment;
    this.allowPublic.value = allowPublic;
    this.createAt.value = createAt;
    this.updateAt.value = updateAt;
    this.deleteAt.value = deleteAt;

    // Map<String, dynamic> replyData = jsonDecode(message.content);
    if (settings != null) {
      if (settings['gausPath'] != null && settings['gausPath'] is String) {
        gausPath.value = settings['gausPath'];
      }
    }
  }

  //
  factory ReelPost.fromJson(Map<String, dynamic> json) {
    if (json['post'] != null) {
      //remote
      var post = Post.fromJson(json['post']);
      Map<String, dynamic> settings = {};
      if (post.settings != null && post.settings!.isNotEmpty) {
        settings = jsonDecode(post.settings!);
      }

      return ReelPost(
        creator: ReelCreator.fromJson(json['creator']),
        isLiked: json['is_liked'] ?? false,
        isSaved: json['is_saved'] ?? false,
        id: post.id,
        userid: post.userid,
        title: post.title,
        description: post.description,
        thumbnail: post.thumbnail,
        type: post.type,
        file: ReelVideoInfo.fromJson(post.files!.first.toJson()),
        tags: post.tags,
        duration: post.duration,
        likedCount: post.likedCount,
        savedCount: post.savedCount,
        sharedCount: post.sharedCount,
        viewedCount: post.viewedCount,
        fullViewedCount: post.fullViewedCount,
        allowDownload: post.allowDownload,
        allowShare: post.allowShare,
        allowComment: post.allowComment,
        allowPublic: post.allowPublic,
        createAt: post.createAt,
        updateAt: post.updateAt,
        deleteAt: post.deleteAt,
        commentCount: post.commentCount,
        settings: settings,
      );
    } else {
      Map<String, dynamic>? settings;
      if (json['settings'] != null && json['settings'] is String && json['settings'].isNotEmpty) {
        settings = jsonDecode(json['settings']);
      }
      //json取出
      return ReelPost(
        creator: ReelCreator.fromJson(json['creator']),
        isLiked: json['is_liked'] ?? false,
        isSaved: json['is_saved'] ?? false,
        id: json['id'],
        userid: json['user_id'],
        title: json['title'],
        description: json['description'],
        thumbnail: json['thumbnail'],
        type: json['type'],
        file: ReelVideoInfo.fromJson(json['file']),
        tags: json['tags'].cast<String>(),
        duration: json['duration'],
        likedCount: json['liked_count'],
        savedCount: json['saved_count'],
        sharedCount: json['shared_count'],
        viewedCount: json['viewed_count'],
        fullViewedCount: json['full_viewed_count'],
        allowDownload: json['allow_download'],
        allowShare: json['allow_share'],
        allowComment: json['allow_comment'],
        allowPublic: json['allow_public'],
        createAt: json['create_at'],
        updateAt: json['update_at'],
        deleteAt: json['delete_at'],
        commentCount: json['comment_count'],
        settings: settings,
      );
    }
  }

//
  Map<String, dynamic> toJson() {
    Map<String, dynamic> settings = {};
    if (gausPath.value != null) {
      settings['guasPath'] = gausPath.value;
    }

    String settingString = "";
    if (settings.isNotEmpty) {
      settingString = jsonEncode(settings);
    }

    return {
      'creator': creator.value?.toJson(),
      'is_liked': isLiked.value,
      'is_saved': isSaved.value,
      'id': id.value,
      'userid': userid.value,
      'title': title.value,
      'description': description.value,
      'thumbnail': thumbnail.value,
      'type': type.value,
      'file': file.value?.toJson(),
      'tags': tags.toList(),
      'duration': duration.value,
      'liked_count': likedCount.value,
      'saved_count': savedCount.value,
      'shared_count': sharedCount.value,
      'viewed_count': viewedCount.value,
      'full_viewed_count': fullViewedCount.value,
      'allow_download': allowDownload.value,
      'allow_share': allowShare.value,
      'allow_comment': allowComment.value,
      'allow_public': allowPublic.value,
      'create_at': createAt.value,
      'update_at': updateAt.value,
      'delete_at': deleteAt.value,
      'comment_count': commentCount.value,
      'settings': settingString,
    };
  }

  String get commentTitle => localized(
        reelCommentCountTitle,
        params: [((commentCount.value ?? 0).toString())],
      );

  void sync(ReelPost item) {
    isLiked.value = item.isLiked.value;
    isSaved.value = item.isSaved.value;
    id.value = item.id.value;
    userid.value = item.userid.value;
    title.value = item.title.value;
    description.value = item.description.value;
    thumbnail.value = item.thumbnail.value;
    type.value = item.type.value;
    file.value!.sync(item.file.value!);
    tags.assignAll(item.tags);
    duration.value = item.duration.value;
    likedCount.value = item.likedCount.value;
    savedCount.value = item.savedCount.value;
    sharedCount.value = item.sharedCount.value;
    viewedCount.value = item.viewedCount.value;
    commentCount.value = item.commentCount.value;
    fullViewedCount.value = item.fullViewedCount.value;
    allowDownload.value = item.allowDownload.value;
    allowShare.value = item.allowShare.value;
    allowComment.value = item.allowComment.value;
    allowPublic.value = item.allowPublic.value;
    createAt.value = item.createAt.value;
    updateAt.value = item.updateAt.value;
    deleteAt.value = item.deleteAt.value;
    gausPath.value = item.gausPath.value;
  }
}

class Post {
  int? id;
  int? userid;
  String? title;
  String? description;
  String? thumbnail;
  int? type;

  List<PostInfo>? files;
  List<String>? tags;
  List<ReelComment>? comments;

  int? duration;

  int? likedCount;
  int? savedCount;
  int? sharedCount;
  int? viewedCount;
  int? commentCount;
  int? fullViewedCount;
  int? allowDownload;
  int? allowShare;
  int? allowComment;
  int? allowPublic;
  int? createAt;
  int? updateAt;
  int? deleteAt;
  String? settings;

  Post({
    this.id,
    this.userid,
    this.title,
    this.description,
    this.thumbnail,
    this.type,
    this.files,
    this.tags,
    this.duration,
    this.likedCount,
    this.savedCount,
    this.sharedCount,
    this.viewedCount,
    this.fullViewedCount,
    this.allowDownload,
    this.allowShare,
    this.allowComment,
    this.allowPublic,
    this.createAt,
    this.updateAt,
    this.deleteAt,
    this.commentCount,
    this.settings,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'],
        userid: json['user_id'],
        title: json['title'],
        description: json['description'],
        thumbnail: json['thumbnail'] ?? "",
        type: json['typ'],
        files:
            json['files']?.map<PostInfo>((x) => PostInfo.fromJson(x)).toList(),
        tags: json['tags'].cast<String>(),
        duration: json['duration'],
        likedCount: json['liked_count'],
        savedCount: json['saved_count'],
        sharedCount: json['shared_count'],
        viewedCount: json['viewed_count'],
        fullViewedCount: json['full_viewed_count'],
        allowDownload: json['allow_download'],
        allowShare: json['allow_share'],
        allowComment: json['allow_comment'],
        allowPublic: json['allow_public'],
        createAt: json['created_at'],
        updateAt: json['updated_at'],
        deleteAt: json['deleted_at'],
        commentCount: json['comment_count'],
        settings: json['settings'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userid': userid,
        'title': title,
        'description': description,
        'thumbnail': thumbnail,
        'typ': type,
        'files': files,
        'tags': tags,
        'liked_count': likedCount,
        'saved_count': savedCount,
        'shared_count': sharedCount,
        'viewed_count': viewedCount,
        'full_viewed_count': fullViewedCount,
        'allow_download': allowDownload,
        'allow_share': allowShare,
        'allow_comment': allowComment,
        'allow_public': allowPublic,
        'create_date': createAt,
        'update_date': updateAt,
        'delete_date': deleteAt,
        'comment_count': commentCount,
        'settings': settings,
      };

  String get commentTitle => localized(
        reelCommentCountTitle,
        params: [((commentCount ?? 0).toString())],
      );
}

class ReelCreator with ProfileRs {
  Rxn<int> id = Rxn<int>();
  Rxn<String> name = Rxn<String>();
  Rxn<String> profilePic = Rxn<String>();

  ReelCreator({int? id, String? name, int? rs, String? profilePic}) {
    this.id.value = id;
    this.name.value = name;
    this.profilePic.value = profilePic;
    this.rs.value = rs;
  }

  factory ReelCreator.fromJson(Map<String, dynamic> json) {
    return ReelCreator(
      id: json['id'],
      name: json['name'],
      rs: json['relationship'],
      profilePic: json['profile_pic'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id.value ?? 0,
        'name': name.value ?? "",
        'relationship': rs.value ?? 0,
        'profile_pic': profilePic.value ?? "",
      };

  void sync(ReelCreator item) {
    id.value = item.id.value;
    name.value = item.name.value;
    profilePic.value = item.profilePic.value;
    rs.value = item.rs.value;
  }
}

class Creator with ProfileRs {
  int? id;
  String? name;
  String? profilePic;

  Creator({this.id, this.name, int? rs, this.profilePic}) {
    this.rs.value = rs;
  }

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'],
      name: json['name'],
      rs: json['relationship'],
      profilePic: json['profile_pic'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id ?? 0,
        'name': name ?? "",
        'relationship': rs.value ?? 0,
        'profile_pic': profilePic ?? "",
      };
}

class ReelCommentUser with ProfileRs {
  int? id;
  String? name;
  String? profilePic;

  ReelCommentUser({this.id, this.name, this.profilePic, int? rs}) {
    this.rs.value = rs;
  }

  factory ReelCommentUser.fromJson(Map<String, dynamic> json) {
    return ReelCommentUser(
      id: json['user_id'],
      name: json['name'],
      rs: json['relationship'],
      profilePic: json['profile_pic'],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': id ?? 0,
        'name': name ?? "",
        'relationship': rs.value ?? 0,
        'profile_pic': profilePic ?? "",
      };
}

class ReelVideoInfo {
  Rxn<String> path = Rxn<String>();
  Rxn<int> width = Rxn<int>();
  Rxn<int> height = Rxn<int>();
  Rxn<int> size = Rxn<int>();

  ReelVideoInfo({
    String? path,
    int? width,
    int? height,
    int? size,
  }) {
    this.path.value = path;
    this.width.value = width;
    this.height.value = height;
    this.size.value = size;
  }

  factory ReelVideoInfo.fromJson(Map<String, dynamic> json) => ReelVideoInfo(
        path: json['path'],
        width: json['width'],
        height: json['height'],
        size: json['size'],
      );

  Map<String, dynamic> toJson() => {
        'path': path.value ?? "",
        'width': width.value ?? 0,
        'height': height.value ?? 0,
        'size': size.value ?? 0,
      };

  void sync(ReelVideoInfo item) {
    path.value = item.path.value;
    width.value = item.width.value;
    height.value = item.height.value;
    size.value = item.size.value;
  }
}

class PostInfo {
  String? path;
  int? width;
  int? height;
  int? size;

  PostInfo({
    this.path,
    this.width,
    this.height,
    this.size,
  });

  factory PostInfo.fromJson(Map<String, dynamic> json) => PostInfo(
        path: json['path'],
        width: json['width'],
        height: json['height'],
        size: json['size'],
      );

  Map<String, dynamic> toJson() => {
        'path': path,
        'width': width,
        'height': height,
        'size': size,
      };
}

class TagData {
  List<String>? tags;

  TagData({
    this.tags,
  });

  factory TagData.fromJson(Map<String, dynamic> json) => TagData(
        tags: List<String>.from(
          json['tags'] != null ? json['tags'].map((x) => x) : [],
        ),
      );

  Map<String, dynamic> toJson() => {
        'tags': tags,
      };
}

class SearchTagData {
  List<String>? datas;

  SearchTagData({
    this.datas,
  });

  factory SearchTagData.fromJson(Map<String, dynamic> json) => SearchTagData(
        datas: List<String>.from(
          json['datas'] != null ? json['datas'].map((x) => x) : [],
        ),
      );

  Map<String, dynamic> toJson() => {
        'datas': datas,
      };
}

class ReelProfile with ProfileRs {
  Rxn<int> totalLikesReceived = Rxn<int>();
  Rxn<int> totalPostCount = Rxn<int>();
  Rxn<int> totalFriendCount = Rxn<int>();
  Rxn<int> totalFollowerCount = Rxn<int>();
  Rxn<int> totalFolloweeCount = Rxn<int>();

  Rxn<int> userid = Rxn<int>();
  Rxn<String> name = Rxn<String>();
  Rxn<String> profilePic = Rxn<String>();
  Rxn<String> backgroundPic = Rxn<String>();
  Rxn<String> bio = Rxn<String>();
  Rxn<int> createdAt = Rxn<int>();
  Rxn<int> updatedAt = Rxn<int>();
  Rxn<int> deletedAt = Rxn<int>();
  Rxn<int> channelId = Rxn<int>();
  Rxn<int> channelGroundId = Rxn<int>();

  ReelProfile({
    int? totalLikesReceived,
    int? totalPostCount,
    int? totalFriendCount,
    int? totalFollowerCount,
    int? totalFolloweeCount,
    int? rs,
    int? userid,
    String? name,
    String? profilePic,
    String? backgroundPic,
    String? bio,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    int? channelId,
    int? channelGroundId,
  }) {
    this.totalLikesReceived.value = totalLikesReceived;
    this.totalPostCount.value = totalPostCount;
    this.totalFriendCount.value = totalFriendCount;
    this.totalFollowerCount.value = totalFollowerCount;
    this.totalFolloweeCount.value = totalFolloweeCount;
    this.rs.value = rs;
    this.userid.value = userid;
    this.name.value = name;
    this.profilePic.value = profilePic;
    this.backgroundPic.value = backgroundPic;
    this.bio.value = bio;
    this.createdAt.value = createdAt;
    this.updatedAt.value = updatedAt;
    this.deletedAt.value = deletedAt;
    this.channelId.value = channelId;
    this.channelGroundId.value = channelGroundId;
  }

  factory ReelProfile.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> profileJson = json['profile'];
    return ReelProfile(
      totalLikesReceived: json['total_likes_received'] ?? 0,
      totalPostCount: json['total_post_count'] ?? 0,
      totalFriendCount: json['total_friend_count'] ?? 0,
      totalFollowerCount: json['total_follower_count'] ?? 0,
      totalFolloweeCount: json['total_followee_count'] ?? 0,
      rs: json['relationship'],
      userid: profileJson['user_id'],
      name: profileJson['name'],
      profilePic: profileJson['profile_pic'],
      backgroundPic: profileJson['background_pic'],
      bio: profileJson['bio'] ?? "",
      createdAt: profileJson['created_at'],
      updatedAt: profileJson['updated_at'],
      deletedAt: profileJson['deleted_at'],
      channelId: profileJson['channel_id'],
      channelGroundId: profileJson['channel_ground_id'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> profile = {
      'user_id': userid.value,
      'name': name.value,
      'profile_pic': profilePic.value,
      'background_pic': backgroundPic.value,
      'bio': bio.value,
      'created_at': createdAt.value,
      'updated_at': updatedAt.value,
      'deleted_at': deletedAt.value,
      'channel_id': channelId.value,
      'channel_ground_id': channelGroundId.value,
    };
    return {
      'profile': profile,
      'relationship': rs.value,
      'total_likes_received': totalLikesReceived.value,
      'total_post_count': totalPostCount.value,
      'total_friend_count': totalFriendCount.value,
      'total_follower_count': totalFollowerCount.value,
      'total_followee_count': totalFolloweeCount.value,
    };
  }

  String get profilePercentage {
    return _inputPercentage;
  }

  String get _inputPercentage {
    int itemsInput = 0;
    if (notBlank(name.value)) itemsInput++;
    if (notBlank(bio.value)) itemsInput++;
    if (notBlank(profilePic.value)) itemsInput++;
    return itemsInput >= 3 ? "" : (itemsInput == 2 ? "60%" : "30%");
  }

  void sync(ReelProfile item) {
    totalLikesReceived.value = item.totalLikesReceived.value;
    totalPostCount.value = item.totalPostCount.value;
    totalFriendCount.value = item.totalFriendCount.value;
    totalFollowerCount.value = item.totalFollowerCount.value;
    totalFolloweeCount.value = item.totalFolloweeCount.value;
    rs.value = item.rs.value;
    userid.value = item.userid.value;
    name.value = item.name.value;
    profilePic.value = item.profilePic.value;
    backgroundPic.value = item.backgroundPic.value;
    bio.value = item.bio.value;
    createdAt.value = item.createdAt.value;
    updatedAt.value = item.updatedAt.value;
    deletedAt.value = item.deletedAt.value;
    channelId.value = item.channelId.value;
    channelGroundId.value = item.channelGroundId.value;
  }
}

class CommentData {
  int? postId;
  int? totalCount;
  List<ReelComment>? comments;

  CommentData({
    this.postId,
    this.comments,
    this.totalCount,
  });

  factory CommentData.fromJson(Map<String, dynamic> json) => CommentData(
        postId: json['post_id'],
        totalCount: json['total_count'],
        comments: json['comments']
            ?.map<ReelComment>((x) => ReelComment.fromJson(x))
            .toList(),
      );
}

class ReelComment with ProfileRs {
  Rxn<int> commentId = Rxn<int>();
  Rxn<int> creatorId = Rxn<int>();
  Rxn<int> userId = Rxn<int>();
  Rxn<int> postId = Rxn<int>();
  Rxn<int> replyId = Rxn<int>();
  Rxn<int> replyUserId = Rxn<int>();
  Rxn<int> typ = Rxn<int>();
  Rxn<String> comment = Rxn<String>();
  Rxn<int> createdAt = Rxn<int>();
  Rxn<int> updatedAt = Rxn<int>();
  Rxn<int> deletedAt = Rxn<int>();
  Rxn<int> id = Rxn<int>();
  Rxn<String> name = Rxn<String>();
  Rxn<String> profilePic = Rxn<String>();

  ReelComment({
    int? commentId,
    int? creatorId,
    int? userId,
    int? postId,
    int? replyId,
    int? replyUserId,
    int? typ,
    String? comment,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    int? id,
    String? name,
    String? profilePic,
    int? rs,
  }) {
    this.commentId.value = commentId;
    this.creatorId.value = creatorId;
    this.userId.value = userId;
    this.postId.value = postId;
    this.replyId.value = replyId;
    this.replyUserId.value = replyUserId;
    this.typ.value = typ;
    this.comment.value = comment;
    this.createdAt.value = createdAt;
    this.updatedAt.value = updatedAt;
    this.deletedAt.value = deletedAt;
    this.id.value = id;
    this.name.value = name;
    this.profilePic.value = profilePic;
    this.rs.value = rs;
  }

  factory ReelComment.fromJson(Map<String, dynamic> commentJson) {
    var json = commentJson['comment'];
    var userJson = commentJson['user'];

    var s = ReelComment(
      commentId: json['id'],
      creatorId: json['creator_id'],
      userId: json['user_id'],
      postId: json['post_id'],
      replyId: json['reply_id'],
      replyUserId: json['reply_user_id'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      typ: json['typ'],
      createdAt: json['created_at'],
      comment: json['comment'] ?? "",
      id: userJson['user_id'],
      // user
      name: userJson['name'],
      rs: userJson['relationship'],
      profilePic: userJson['profile_pic'],
    );

    return s;
  }
}

class StatisticsData {
  int? totalLikesReceived;
  int? totalPostCount;
  int? totalFriendCount;
  int? totalFollowerCount;
  int? totalFolloweeCount;

  StatisticsData({
    this.totalLikesReceived,
    this.totalPostCount,
    this.totalFriendCount,
    this.totalFollowerCount,
    this.totalFolloweeCount,
  });

  factory StatisticsData.fromJson(Map<String, dynamic> json) => StatisticsData(
        totalLikesReceived: json['total_likes_received'] ?? 0,
        totalPostCount: json['total_post_count'] ?? 0,
        totalFriendCount: json['total_friend_count'] ?? 0,
        totalFollowerCount: json['total_follower_count'] ?? 0,
        totalFolloweeCount: json['total_followee_count'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "total_likes_received": totalLikesReceived,
        "total_post_count": totalPostCount,
        "total_friend_count": totalFriendCount,
        "total_follower_count": totalFollowerCount,
        "total_followee_count": totalFolloweeCount,
      };
}

mixin ProfileRs {
  Rxn<int> rs = Rxn<int>();

  static bool canFollowWithRs(int rs) {
    ProfileRelationship r = getRelationShipWithValue(rs);
    return r == ProfileRelationship.follower ||
        r == ProfileRelationship.stranger;
  }

  static getRelationShipWithValue(int rsInt) {
    if (ProfileRelationship.stranger.value == rsInt) {
      return ProfileRelationship.stranger;
    } else if (ProfileRelationship.follower.value == rsInt) {
      return ProfileRelationship.follower;
    } else if (ProfileRelationship.followee.value == rsInt) {
      return ProfileRelationship.followee;
    } else if (ProfileRelationship.friend.value == rsInt) {
      return ProfileRelationship.friend;
    } else if (ProfileRelationship.self.value == rsInt) {
      return ProfileRelationship.self;
    } else {
      return ProfileRelationship.stranger;
    }
  }

  ProfileRelationship get relationship {
    if (ProfileRelationship.stranger.value == rs.value) {
      return ProfileRelationship.stranger;
    } else if (ProfileRelationship.follower.value == rs.value) {
      return ProfileRelationship.follower;
    } else if (ProfileRelationship.followee.value == rs.value) {
      return ProfileRelationship.followee;
    } else if (ProfileRelationship.friend.value == rs.value) {
      return ProfileRelationship.friend;
    } else if (ProfileRelationship.self.value == rs.value) {
      return ProfileRelationship.self;
    } else {
      return ProfileRelationship.stranger;
    }
  }

  void unfollowUser(int userId) {
    switch (relationship) {
      case ProfileRelationship.friend:
        rs.value = ProfileRelationship.follower.value;
        break;
      case ProfileRelationship.followee:
        rs.value = ProfileRelationship.stranger.value;
        break;
      default: //self = automatic return
        return;
    }

    ReelFollowMgr.instance.updateFollow(userId, rs.value!, false);
  }

  void followUser(int userId) {
    switch (relationship) {
      case ProfileRelationship.follower:
        rs.value = ProfileRelationship.friend.value;
        break;
      case ProfileRelationship.stranger:
        rs.value = ProfileRelationship.followee.value;
        break;
      default: //self = automatic return
        return;
    }

    ReelFollowMgr.instance.updateFollow(userId, rs.value!, true);
  }

  bool get canFollow =>
      relationship == ProfileRelationship.follower ||
      relationship == ProfileRelationship.stranger;
}

class ReelUploadTag {
  final String tag;
  int count;
  DateTime? uploadDate;

  ReelUploadTag({required this.tag, this.count = 0, this.uploadDate});

  factory ReelUploadTag.fromJson(Map<String, dynamic> json) => ReelUploadTag(
        tag: json['tag'] ?? "",
        count: json['count'] ?? 0,
        uploadDate: json['uploadDate'] != null
            ? DateTime.parse(json['uploadDate'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "tag": tag,
        "count": count,
        'uploadDate': uploadDate?.toIso8601String(),
      };
}

// 存取動畫與位置的Class
class AnimationPosition {
  final Offset position;
  final Widget animation;

  AnimationPosition({required this.position, required this.animation});
}
