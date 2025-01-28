import 'package:jxim_client/managers/tags_mgr.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart' as req;
import 'package:jxim_client/utils/net/response_data.dart';

/// 新增標籤
/// {
///    "code": 0,
///    "message": "OK",
///    "data": {
///        "tags": [
///            {
///                "id": 60,
///                "user_id": 2137750,
///                "tag": "123",
///                "updated_at": 1733221411
///            },
///            {
///                "id": 61,
///                "user_id": 2137750,
///                "tag": "456",
///                "updated_at": 1733221411
///            }
///        ]
///    }
/// }
Future<Map<String, dynamic>?> createFriendTags(List<Tags> tags) async {
  final List<String> tagsNameList = tags.map((tag) => tag.tagName).toList();
  final Map<String, dynamic> dataBody = {
    "names": tagsNameList,
  };

  try {
    final ResponseData res = await req.CustomRequest.doPost(
        '/app/api/contact/create-friend-tag',
        data: dataBody);
    if(res.success()) {
      return res.data;
    }
    else{
      return null;
    }
  } catch (e) {
    rethrow;
  }
}

/// 修改標籤
/// request body
/// {
///     "tags": [
///         {
///             "id": 1,
///             "name": "abc"
///         }
///     ]
/// }
///
/// {
///     "code": 0,
///     "message": "OK",
///     "data": {
///         "tags": []  成功的會返回跟修改時一樣的Tag
///     }
/// }
Future<bool> editFriendTags(List<Tags> tags) async {
  final List<Map<String, dynamic>> tagsNameList = tags.map((tag) => tag.toEditFriendJson()).toList();

  final Map<String, dynamic> dataBody = {
    "tags": tagsNameList,
  };

  try {
    final ResponseData res = await req.CustomRequest.doPost(
        '/app/api/contact/edit-friend-tag',
        data: dataBody);
    return res.success();
  } catch (e) {
    rethrow;
  }
}

/// 刪除標籤
Future<bool> deleteFriendTags(List<Tags> tags) async {
  final List<int> tagsNameList = tags.map((tag) => tag.uid).toList();

  /// id from server
  final Map<String, dynamic> dataBody = {
    "ids": tagsNameList,
  };

  try {
    final ResponseData res = await req.CustomRequest.doPost(
        '/app/api/contact/delete-friend-tag',
        data: dataBody);
    return res.success();
  } catch (e) {
    rethrow;
  }
}

/// 获取標籤
/// response:
/// {
///     "code": 0,
///     "message": "OK",
///     "data": {
///         "tags": [
///             {
///                 "id": 60,
///                 "user_id": 2137750,
///                 "tag": "123",
///                 "updated_at": 1733221411
///             },
///             {
///                 "id": 61,
///                 "user_id": 2137750,
///                 "tag": "456",
///                 "updated_at": 1733221411
///             }
///         ]
///     }
/// }
Future<List<Tags>> retrieveFriendTags() async {
  try {
    final ResponseData res = await req.CustomRequest.doGet('/app/api/contact/retrieve-friend-tag');
    if (res.success()) {
      if (res.data['tags'] != null) {
        List<Tags> tagResults = (res.data["tags"] as List<dynamic>).map((e) => Tags(
        )..uid = e['id']
         ..tagName= e['tag']
         ..type=TagsMgr.TAG_TYPE_MOMENT
          ..createAt=e['created_at']
          ..updatedAt=e['created_at'],).toList();
        return tagResults;
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