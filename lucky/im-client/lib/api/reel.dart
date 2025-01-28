import 'package:jxim_client/object/reel.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/toast.dart';

Future<bool> createPost(
  int type,
  String title,
  String description,
  int duration,
  List<Map<String, dynamic>> videoUrls,
  List<String> tagList,
  String coverUrl,
) async {
  final Map<String, dynamic> dataBody = {
    "typ": type,
    "title": title,
    'description': description,
    'duration': duration,
    'files': videoUrls,
    'tags': tagList,
    "thumbnail": coverUrl,
  };

  try {
    final ResponseData res = await Request.doPost(
      '/reels/post/create-post',
      data: dataBody,
    );

    return res.success();
  } on AppException catch (e) {
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<List<ReelData>> getSuggestedPosts({
  int limit = 5,
}) async {
  try {
    final ResponseData res = await Request.doGet(
      '/reels/post/suggested-posts',
      data: {'limit': limit},
    );
    if (res.success()) {
      return res.data.map<ReelData>((e) => ReelData.fromJson(e)).toList();
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

Future<ReelData> getReelDetail(int reelId) async {
  try {
    final ResponseData res =
        await Request.doGet('/reels/post/get-post', data: {"post_id": reelId});
    if (res.success()) {
      return ReelData.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<TagData> suggestedTag() async {
  try {
    final ResponseData res = await Request.doGet(
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
    "limit": 10
  };
  try {
    final ResponseData res = await Request.doPost(
      '/reels/post/search-tags',
      data: dataBody,
    );
    if (res.success()) {
      return SearchTagData.fromJson(res.data);
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

Future<List<String>> suggestedSearches() async {
  try {
    final ResponseData res = await Request.doGet(
      '/reels/post/suggested-searches',
    );
    if (res.success()) {
      return List<String>.from(
          res.data['tags'] != null ? res.data['tags'].map((x) => x) : []);
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

Future<List<ReelData>> searchPost(
  String value, {
  int offset = 0,
}) async {
  final Map<String, dynamic> dataBody = {
    "keyword": value,
    "offset": offset,
    "limit": 10,
  };
  try {
    final ResponseData res = await Request.doPost(
      '/reels/post/search-posts',
      data: dataBody,
    );
    if (res.success()) {
      return res.data.map<ReelData>((e) => ReelData.fromJson(e)).toList();
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

Future<ProfileData> getProfile(int userId) async {
  final Map<String, dynamic> dataBody = {
    "target_user_id": userId,
  };
  try {
    final ResponseData res = await Request.doGet(
      '/reels/profile/get-profile',
      data: dataBody,
    );
    if (res.success()) {
      return ProfileData.fromJson(res.data);
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

Future<StatisticsData> getMyStatistics() async {
  try {
    final ResponseData res = await Request.doGet(
      '/reels/profile/get-my-statistics',
    );
    if (res.success()) {
      return StatisticsData.fromJson(res.data);
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

Future<List<ReelData>> getMyPost(
    int? offset, int? limit, int? allowPublic) async {
  final Map<String, dynamic> dataBody = {};

  if (offset != null) {
    dataBody["offset"] = offset;
  }
  if (limit != null) {
    dataBody["Limit"] = limit;
  }
  if (allowPublic != null) {
    dataBody["allow_public"] = allowPublic;
  }

  try {
    final ResponseData res = await Request.doGet(
      '/reels/post/my-posts',
      data: dataBody,
    );
    if (res.success()) {
      return res.data.map<ReelData>((e) => ReelData.fromJson(e)).toList();
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

Future<List<ReelData>> getSavePost(int? offset, int? limit) async {
  final Map<String, dynamic> dataBody = {};

  if (offset != null) {
    dataBody["offset"] = offset;
  }
  if (limit != null) {
    dataBody["Limit"] = limit;
  }

  try {
    final ResponseData res = await Request.doGet(
      '/reels/post/my-saved-posts',
      data: dataBody,
    );
    if (res.success()) {
      return res.data.map<ReelData>((e) => ReelData.fromJson(e)).toList();
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

Future<List<ReelData>> getLikePost(int? offset, int? limit) async {
  final Map<String, dynamic> dataBody = {};

  if (offset != null) {
    dataBody["offset"] = offset;
  }
  if (limit != null) {
    dataBody["Limit"] = limit;
  }

  try {
    final ResponseData res = await Request.doGet(
      '/reels/post/my-liked-posts',
      data: dataBody,
    );
    if (res.success()) {
      return res.data.map<ReelData>((e) => ReelData.fromJson(e)).toList();
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

Future<bool> likePost(int postId, int isLike) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["post_id"] = postId;
  dataBody["is_like"] = isLike;

  try {
    final ResponseData res = await Request.doPost(
      '/reels/post/like-post',
      data: dataBody,
    );
    if (res.success()) {
      return true;
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

Future<bool> savePost(int postId, int isSave) async {
  final Map<String, dynamic> dataBody = {};
  dataBody["post_id"] = postId;
  dataBody["is_save"] = isSave;

  try {
    final ResponseData res = await Request.doPost(
      '/reels/post/save-post',
      data: dataBody,
    );
    if (res.success()) {
      return true;
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
