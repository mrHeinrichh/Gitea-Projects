import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/reel/utils/reel_utils.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/lang_util.dart';

Future<bool> createPost(
  int type,
  String title,
  String description,
  int duration,
  List<Map<String, dynamic>> videoUrls,
  List<String> tagList,
  String coverUrl,
  String settings,
) async {
  final Map<String, dynamic> dataBody = {
    "typ": type,
    "title": title,
    'description': description,
    'duration': duration,
    'files': videoUrls,
    'tags': tagList,
    "thumbnail": coverUrl,
    "allow_public": 1,
    "setting": settings,
  };

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/reels/post/create-post',
      data: dataBody,
    );

    return res.success();
  } catch (e) {
    rethrow;
  }
}

Future<List<ReelPost>> getSuggestedPosts({
  int limit = 6,
}) async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      '/reels/post/suggested-posts',
      data: {'limit': limit},
    );
    if (res.success()) {
      return res.data.map<ReelPost>((e) => ReelPost.fromJson(e)).toList(); //new
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<ReelPost> getReelDetail(int reelId) async {
  try {
    final ResponseData res = await CustomRequest.doGet('/reels/post/get-post',
        data: {"post_id": reelId});
    if (res.success()) {
      return ReelPost.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<TagData> suggestedTag() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      '/reels/post/suggested-tags',
    );
    if (res.success()) {
      return TagData.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } on AppException catch (e) {
    Toast.showToast(e.getMessage());
    rethrow;
  } catch (e) {
    rethrow;
  }
}

Future<SearchTagData> searchTag(String tag) async {
  final Map<String, dynamic> dataBody = {
    "keyword": tag,
    "offset": 0,
    "limit": 10,
  };
  try {
    final ResponseData res = await CustomRequest.doPost(
      '/reels/post/search-tags',
      data: dataBody,
    );
    if (res.success()) {
      return SearchTagData.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<List<String>> searchCompletion(String text) async {
  final Map<String, dynamic> dataBody = {
    "keyword": text,
    "offset": 0,
    "limit": 10,
  };

  try {
    final ResponseData res = await CustomRequest.doPost(
        '/reels/post/search-headlines',
        data: dataBody);
    if (res.success()) {
      return List<String>.from(
        res.data['datas'] != null ? res.data['datas'].map((x) => x) : [],
      );
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<List<String>> suggestedSearches() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      '/reels/post/suggested-searches',
    );
    if (res.success()) {
      return List<String>.from(
        res.data['tags'] != null ? res.data['tags'].map((x) => x) : [],
      );
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<List<ReelPost>> searchPost(
  String value, {
  int offset = 0,
}) async {
  final Map<String, dynamic> dataBody = {
    "keyword": value,
    "offset": offset,
    "limit": 10,
  };
  try {
    final ResponseData res = await CustomRequest.doPost(
      '/reels/post/search-posts',
      data: dataBody,
    );
    if (res.success()) {
      return res.data.map<ReelPost>((e) => ReelPost.fromJson(e)).toList();
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<ReelProfile> getProfile(int userId) async {
  final Map<String, dynamic> dataBody = {
    "target_user_id": userId,
  };
  try {
    final ResponseData res = await CustomRequest.doGet(
      '/reels/profile/get-profile',
      data: dataBody,
    );
    if (res.success()) {
      return ReelProfile.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<List<ReelPost>> getPost(
  int userId,
  int? startIdx,
  int? limit,
  int? allowPublic,
) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["user_id"] = userId;

  dataBody["start_idx"] = startIdx ?? 0;
  if (limit != null) {
    dataBody["limit"] = limit;
  }
  if (allowPublic != null) {
    dataBody["allow_public"] = allowPublic;
  }

  try {
    final ResponseData res = await CustomRequest.doGet(
      '/reels/post/posts',
      data: dataBody,
    );
    if (res.success()) {
      return res.data.map<ReelPost>((e) => ReelPost.fromJson(e)).toList();
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<List<ReelPost>> getSavePost(
  int userId,
  int? startIdx,
  int? limit,
) async {
  final Map<String, dynamic> dataBody = {};

  dataBody["user_id"] = userId;

  dataBody["offset"] = startIdx ?? 0;
  if (limit != null) {
    dataBody["limit"] = limit;
  }

  try {
    final ResponseData res = await CustomRequest.doGet(
      '/reels/post/saved-posts',
      data: dataBody,
    );
    if (res.success()) {
      return res.data.map<ReelPost>((e) => ReelPost.fromJson(e)).toList();
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<List<ReelPost>> getLikePost(
  int userId,
  int? startIdx,
  int? limit,
) async {
  final Map<String, dynamic> dataBody = {};

  dataBody["user_id"] = userId;

  dataBody["offset"] = startIdx ?? 0;
  if (limit != null) {
    dataBody["limit"] = limit;
  }

  try {
    final ResponseData res = await CustomRequest.doGet(
      '/reels/post/liked-posts',
      data: dataBody,
    );
    if (res.success()) {
      return res.data.map<ReelPost>((e) => ReelPost.fromJson(e)).toList();
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> sharePost(int postId) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["post_id"] = postId;

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/reels/post/share-post',
      data: dataBody,
    );
    if (res.success()) {
      return true;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> updateProfileInfo({
  String? name,
  String? bio,
  String? backgroundPic,
  String? profilePic,
}) async {
  final Map<String, dynamic> dataBody = {};
  if (name != null) dataBody['name'] = name;
  if (bio != null) dataBody['bio'] = bio;
  if (profilePic != null) dataBody['profile_pic'] = profilePic;
  if (backgroundPic != null) dataBody['background_pic'] = backgroundPic;

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/reels/profile/update-profile',
      data: dataBody,
    );
    if (res.success()) {
      return true;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> followProfile(int followerId, int isFollow) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["follower_id"] = followerId;
  dataBody["is_follow"] = isFollow;

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/reels/profile/follow-profile',
      data: dataBody,
    );
    if (res.success()) {
      if (isFollow == 1) {
        imBottomToast(
          navigatorKey.currentContext!,
          title: localized(reelFollowSuccessfully),
          alignment: reelUtils.getToastAlignment(),
          icon: ImBottomNotifType.success,
          backgroundColor: colorWhite,
          textColor: colorTextPrimary,
        );
      }
      return true;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> likePosts(List<int> postIds, int isLike) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["post_ids"] = postIds;
  dataBody["is_like"] = isLike;

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/reels/post/like-post',
      data: dataBody,
    );
    if (res.success()) {
      return true;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> deletePosts(List<int> postIds) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["post_ids"] = postIds;

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/reels/post/delete-post',
      data: dataBody,
    );
    if (res.success()) {
      return true;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> savePosts(List<int> postIds, int isSave) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["post_ids"] = postIds;
  dataBody["is_save"] = isSave;

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/reels/post/save-post',
      data: dataBody,
    );
    if (res.success()) {
      return true;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<CommentData> getComments({
  required int postId,
  int? lastId = 0,
  int? limit = 30,
  int? action = 1,
  int? layer = 0,
}) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["post_id"] = postId;
  dataBody["last_id"] = lastId ?? 0;
  dataBody["limit"] = limit;
  dataBody["action"] = action;
  dataBody["layer"] = layer;

  try {
    final ResponseData res = await CustomRequest.doGet(
      '/reels/comment/list',
      data: dataBody,
    );
    pdebug('----getReelComments---${res.data}');
    if (res.success()) {
      return CommentData.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<ReelComment?> createComments({
  int? replyId,
  int? replyUserId,
  required String comment,
  required int postId,
  int? typ,
}) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["reply_id"] = replyId;
  dataBody["reply_user_id"] = replyUserId;
  dataBody["comment"] = comment;
  dataBody["post_id"] = postId;
  dataBody["typ"] = typ ?? 0;

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/reels/comment/create-v2',
      data: dataBody,
    );
    if (res.success()) {
      return ReelComment.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}
