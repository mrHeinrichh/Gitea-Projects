enum ReelType {
  REELS_VIDEO(1),
  REELS_ALBUM(2);

  const ReelType(this.value);

  final int value;
}

class ReelData {
  Post? post;
  Creator? creator;

  ReelData({this.post, this.creator});

  factory ReelData.fromJson(Map<String, dynamic> json) => ReelData(
        post: Post.fromJson(json['post']),
        creator: Creator.fromJson(json['creator']),
      );
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

  int? duration;

  int? likedCount;
  int? savedCount;
  int? sharedCount;
  int? viewedCount;
  int? fullViewedCount;
  int? allowDownload;
  int? allowShare;
  int? allowComment;
  int? allowPublic;
  int? createAt;
  int? updateAt;
  int? deleteAt;

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
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'],
        userid: json['user_id'],
        title: json['title'],
        description: json['description'],
        thumbnail: json['thumbnail'] ?? "",
        type: json['typ'],
        files: json['files'] != null
            ? json['files'].map<PostInfo>((x) => PostInfo.fromJson(x)).toList()
            : null,
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
      };
}

class Creator {
  int? id;
  String? name;

  Creator({this.id, this.name});

  factory Creator.fromJson(Map<String, dynamic> json) => Creator(
        id: json['id'],
        name: json['name'],
      );
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
            json['tags'] != null ? json['tags'].map((x) => x) : []),
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
            json['datas'] != null ? json['datas'].map((x) => x) : []),
      );

  Map<String, dynamic> toJson() => {
        'datas': datas,
      };
}

class ProfileData {
  Profile? profile;
  int? relationship;

  ProfileData({this.profile, this.relationship});

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
        profile: Profile.fromJson(json['profile']),
        relationship: json['relationship'],
      );
}

class Profile {
  int? userid;
  String? name;
  String? profilePic;
  String? backgroundPic;
  String? bio;
  int? createdAt;
  int? updatedAt;
  int? deletedAt;
  int? channelId;
  int? channelGroundId;

  Profile({
    this.userid,
    this.name,
    this.profilePic,
    this.backgroundPic,
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.channelId,
    this.channelGroundId,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        userid: json['user_id'],
        name: json['name'],
        profilePic: json['profile_pic'],
        backgroundPic: json['background_pic'],
        bio: json['bio'] ?? "",
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
        deletedAt: json['deleted_at'],
        channelId: json['channel_id'],
        channelGroundId: json['channel_ground_id'],
      );

  Map<String, dynamic> toJson() => {
        'user_id': userid,
        'name': name,
        'profile_pic': profilePic,
        'background_pic': backgroundPic,
        'bio': bio,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'channel_id': channelId,
        'channel_ground_id': channelGroundId,
      };
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
        "total_followee_count": totalFolloweeCount
      };
}
