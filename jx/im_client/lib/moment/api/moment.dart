part of '../index.dart';

/// 获取好友的朋友圈
///
/// @params:\
/// **[start]** - 时间戳, 起始为0, 后续为上次请求返回的最后一条数据的时间戳\
/// [limit] - 每次请求的数据条数, 默认30
Future<List<MomentPosts>> getMomentStories({
  required String starts,
  int limit = 30,
}) async {
  final Map<String, dynamic> dataBody = {
    "starts": starts,
    "limit": limit,
  };

  try {
    final ResponseData res = await req.CustomRequest.doGet(
        '/app/api/moment/stories',
        data: dataBody,
        duration: const Duration(seconds: 5));
    if (res.success()) {
      if (res.data['posts'] != null) {
        return (res.data['posts'] as List)
            .map((e) => MomentPosts.fromJson(e))
            .toList();
      } else {
        return [];
      }
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

/// 获取特定用户的朋友圈帖子
///
/// @params:\
/// **[userId]** - 用户id\
/// **[startIdx]** - 起始序号index, 起始为0, 后续为上次请求返回的最后一条数据的序号Post Id\
/// [limit] - 每次请求的数据条数, 默认30
/// [commentLimit] - 每次请求的评论条数, 默认30
Future<List<MomentPosts>> getMomentPost({
  required int userId,
  required int startIdx,
  int limit = 30,
  int commentLimit = 30,
}) async {
  final Map<String, dynamic> dataBody = {
    "user_id": userId,
    "start_idx": startIdx,
    "limit": limit,
    "comment_limit": commentLimit,
  };

  try {
    final ResponseData res =
        await req.CustomRequest.doGet('/app/api/moment/posts', data: dataBody);
    if (res.success()) {
      if (res.data['posts'] != null) {
        return (res.data['posts'] as List)
            .map((e) => MomentPosts.fromJson(e))
            .toList();
      } else {
        return [];
      }
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<MomentPosts> getPostDetail({required int postId}) async {
  final Map<String, dynamic> dataBody = {
    "post_id": postId,
  };

  try {
    final ResponseData res = await req.CustomRequest.doGet(
        '/app/api/moment/post-details',
        data: dataBody);
    if (res.success()) {
      return MomentPosts.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

/// 创建朋友圈帖子
///
/// @params:\
/// **[content]** - 帖子内容\
/// **[visibility]** - 帖子可见性\
/// **[targets]** - 帖子可见/不可见对象\
/// **[target_tags]** - 帖子可见/不可见標籤
/// **[mentions]** - 帖子提及对象
/// Server visibility:  1: all friend, 2: only for specific friends, 3: hide from specific friends, 4: only me
Future<MomentPosts> createPost(
  MomentContent content,
  MomentVisibility visibility,
  List<int> targets,
  List<int> target_tags,
  List<int> mentions,
) async {
  final Map<String, dynamic> dataBody = {
    "content": content.toJson(),
    "visibility": visibility.value,
    "targets": targets,
    "target_tags": target_tags,
    "mentions": mentions,
  };

  try {
    final ResponseData res = await req.CustomRequest.doPost(
        '/app/api/moment/create-post',
        data: dataBody);
    return MomentPosts.fromJson(res.data);
  } catch (e) {
    rethrow;
  }
}

/// 更新朋友圈帖子
///
/// @params:\
/// **[content]** - 帖子内容\
/// **[visibility]** - 帖子可见性\
/// **[targets]** - 帖子可见/不可见对象\
/// **[target_tags]** - 帖子可见/不可见標籤
/// **[mentions]** - 帖子提及对象
/// Server visibility:  1: all friend, 2: only for specific friends, 3: hide from specific friends, 4: only me
Future<bool> updatePost(
    int post_id,
    MomentVisibility visibility,
    List<int> targets,
    List<int> target_tags,
    ) async {
  final Map<String, dynamic> dataBody = {
    "post_id": post_id,
    "visibility": visibility.value,
    "targets": targets,
    "target_tags": target_tags,
  };

  try {
    final ResponseData res = await req.CustomRequest.doPost(
        '/app/api/moment/update-post',
        data: dataBody);
    return res.success();
  } catch (e) {
    rethrow;
  }
}

/// 删除朋友圈帖子
///
/// @params:\
/// **[postId]** - 帖子id
Future<bool> deletePost({required int postId}) async {
  final Map<String, dynamic> dataBody = {
    "post_id": postId,
  };

  try {
    final ResponseData res = await req.CustomRequest.doPost(
        '/app/api/moment/delete-post',
        data: dataBody);
    return res.success();
  } catch (e) {
    rethrow;
  }
}

Future<MomentSetting> getMomentSetting({int targetId = 0}) async {
  //為了在MyPosts中取得朋友的封面,targetId = 0 代表取得自己的封面
  final Map<String, dynamic> dataBody = {
    "target_id": targetId,
  };

  try {
    final ResponseData res = await req.CustomRequest.doGet(
        '/app/api/moment/setting',
        data: dataBody);
    if (res.success()) {
      return MomentSetting.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

/// 更新朋友圈设置
///
/// @params:\she
/// [availableDay] - 设置朋友圈可见天数 (单位 天)\
Future<bool> updateMomentSetting({
  int availableDay = 0,
  String? coverPath,
}) async {
  final Map<String, dynamic> dataBody = {
    "available_day": availableDay,
  };

  if (coverPath != null) {
    dataBody['background_pic'] = coverPath;
  }

  try {
    final ResponseData res = await req.CustomRequest.doPost(
      '/app/api/moment/update-setting',
      data: dataBody,
    );
    return res.success();
  } catch (e) {
    rethrow;
  }
}

Future<MomentNotificationLastInfo> getMomentLatestNotificationInfo() async {
  try {
    final ResponseData res =
        await req.CustomRequest.doGet('/app/api/moment/notification-info');
    if (res.success()) {
      return MomentNotificationLastInfo.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<MomentNotificationResponse> getMomentNotification({
  required int startIdx,
  int limit = 10,
}) async {
  Map<String, dynamic> data = {
    "start_idx": startIdx,
    "limit": limit,
  };

  try {
    final ResponseData res = await req.CustomRequest.doGet(
        '/app/api/moment/notifications',
        data: data);
    if (res.success()) {
      return MomentNotificationResponse.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> updateLastNotification({
  required int notificationId,
  int? hideNotificationId,
}) async {
  Map<String, dynamic> data = {
    "notification_id": notificationId,
  };

  if (hideNotificationId != null) {
    data['hide_notification_id'] = hideNotificationId;
  }

  try {
    final ResponseData res = await req.CustomRequest.doPost(
      '/app/api/moment/update-last-notification',
      data: data,
    );
    return res.success();
  } catch (e) {
    rethrow;
  }
}

/// 获取朋友圈帖子赞详情
Future<MomentLikes> getPostLikeDetail(int postId) async {
  final Map<String, dynamic> dataBody = {
    "post_id": postId,
  };

  try {
    final ResponseData res = await req.CustomRequest.doPost(
      '/app/api/moment/like',
      data: dataBody,
    );
    if (res.success()) {
      return MomentLikes.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

/// 点赞朋友圈帖子
Future<LikePost?> likePost(int postId, bool flag) async {
  ///自己定義的過期時間：
  ///發起時間為2024/09/12 12:00:00，過期時間為2024/09/12 12:02:00
  ///重新啟動app，會被判定為過期，不再請求，並返回失敗至[RequestFunctionMap]的registerCallback
  int customizeExpiredTime = 3;

  final Map<String, dynamic> dataBody = {"post_id": postId, "flag": flag};

  List<Retry> endPointRetry = await objectMgr.retryMgr.getAllEndPointRetry(
      RetryEndPointCallback.MOMENT_POST_LIKE_RETRY_CALLBACK);

  bool isUnderRetry = false;
  int replaceUUID = 0;
  if (endPointRetry.isNotEmpty) {
    for (var item in endPointRetry) {
      final Map<String, dynamic> data = jsonDecode(item.requestData);
      final int undertakingPostId = data['data']['post_id'];
      //如果有，取消重試任務
      if (undertakingPostId == postId) {
        isUnderRetry = true;
        replaceUUID = item.uid;
      }
    }
  }

  if (isUnderRetry) {
    await requestQueue.replacedRequest(replaceUUID);
    return null;
  } else {
    try {
      var retryParameter = RetryParameter(
          expireTime: customizeExpiredTime,
          isReplaced: RetryReplace.NO_REPLACE,
          callbackFunctionName:
              RetryEndPointCallback.MOMENT_POST_LIKE_RETRY_CALLBACK,
          apiPath: RetryEndPointCallback.MOMENT_POST_LIKE_RETRY_CALLBACK,
          data: dataBody,
          methodType: CustomRequest.methodTypePost);

      requestQueue.addRetry(retryParameter);
      //You can get the uuid for cancel the retry-request.
      // int uuid = retryParameter.getUuid();
      return null;
    } catch (e) {
      rethrow;
    }
  }
}

/// 添加朋友圈评论
Future<bool> createComment(
  int postId,
  String content, {
  int replyUserId = 0,
}) async {
  final Map<String, dynamic> dataBody = {
    "post_id": postId,
    "content": content,
  };

  if (replyUserId != 0) {
    dataBody['reply_user_id'] = replyUserId;
  }

  try {
    final ResponseData res = await req.CustomRequest.doPost(
      '/app/api/moment/create-comment',
      data: dataBody,
    );
    return res.success();
  } catch (e) {
    rethrow;
  }
}

/// 删除朋友圈评论
Future<bool> deleteComment(int commentId) async {
  final Map<String, dynamic> dataBody = {
    "comment_id": commentId,
  };
  try {
    final ResponseData res = await req.CustomRequest.doPost(
      '/app/api/moment/delete-comment',
      data: dataBody,
    );
    return res.success();
  } catch (e) {
    rethrow;
  }
}

/// 获取朋友圈评论
Future<MomentCommentDetail> getMomentComment({
  required int postId,
  required int page,
  int limit = 30,
}) async {
  final Map<String, dynamic> dataBody = {
    "post_id": postId,
    "page": page,
    "limit": limit,
  };

  try {
    final ResponseData res = await req.CustomRequest.doGet(
        '/app/api/moment/comments',
        data: dataBody);

    if (res.success()) {
      if (res.data != null) {
        return MomentCommentDetail.fromJson(res.data);
      } else {
        throw AppException(res.message);
      }
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

class MomentLikeRetry {
  int postId = 0;
  int uid = 0;

  MomentLikeRetry({required this.postId, required this.uid});

  Map<String, dynamic> toJson() {
    return {
      "post_id": postId,
      "uid": uid,
    };
  }

  factory MomentLikeRetry.fromJson(Map<String, dynamic> json) {
    return MomentLikeRetry(
      postId: json['post_id'],
      uid: json['uid'],
    );
  }
}

/// 获取通知
