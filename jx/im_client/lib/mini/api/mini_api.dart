
import 'package:jxim_client/mini/bean/mini_app_item_bean.dart';
import 'package:jxim_client/mini/bean/mini_app_my_app.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/toast.dart';

/// 小程序相关接口

///聊天列表下拉搜索
///appid int
// name string
// description stri1
// asset_version int
// asset_url string

Future<MiniAppItemBean> miniAppFind(Map<String, dynamic> dataBody) async {
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/openapi/client/miniapp/find",
      data: dataBody,
    );
    if (res.success()) {
      return MiniAppItemBean.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

/// 查询小程序
//openuid string 小程序使用的uid
Future<Apps> miniAppGet(Map<String, dynamic> dataBody) async {
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/openapi/client/miniapp/get",
      data: dataBody,
    );
    if (res.success()) {
      return Apps.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

/// 小程序登陆
//openuid string 小程序使用的uid
// asset_version int 小程序资源版本号
// asset_url string 资源更新地址
Future<Apps> miniAppLogin(Map<String, dynamic> dataBody) async {
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/openapi/client/miniapp/login",
      data: dataBody,
    );
    if (res.success()) {
      return Apps.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}


/// 根据friend_id 查询小程序
Future<Apps> miniAppFriendIdLogin({required int friendId}) async {
  try {
    Map<String,dynamic> map = {
      "app_user_id":friendId,
      "channel_id": Config().orgChannel,
    };
    final ResponseData res = await CustomRequest.doPost(
      "/openapi/client/miniapp/login",
      data:map ,
    );
    if (res.success()) {
      return Apps.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

postMiniAppToken(Map<String, dynamic> map) async {
  try {
    ResponseData res =
    await CustomRequest.doPost("/lucky-unity/open?gameid=union", data: map);
    return res;
  } catch (e) {
    return ResponseData(
      code: -1,
      message: e.toString(),
      data: {
        'success': false,
      },
    );
  }
}

postSpecialMiniAppExit(Map<String, dynamic> map) async {
  ResponseData res = await CustomRequest.doPost('/lucky-unity/down', data: map);
  return res;
}

postSpecialMiniAppJoin(Map<String, dynamic> map) async {
  ResponseData res = await CustomRequest.doPost('/lucky-unity/up', data: map);
  return res;
}

/// 小程序收藏
Future<bool> miniAppAddFavorite(Map<String, dynamic> dataBody) async {
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/openapi/client/miniapp/favorite/add",
      data: dataBody,
    );
    if (res.success()) {
      return res.success();
    } else {
      throw AppException(res.message);
    }
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

/// 小程序删除收藏
Future<bool> miniAppRemoveFavorite(Map<String, dynamic> dataBody) async {
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/openapi/client/miniapp/favorite/del",
      data: dataBody,
    );
    if (res.success()) {
      return res.success();
    } else {
      throw AppException(res.message);
    }
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<bool> miniAppRemoveRecent(Map<String, dynamic> dataBody) async {
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/openapi/client/miniapp/hide",
      data: dataBody,
    );
    if (res.success()) {
      return res.success();
    } else {
      throw AppException(res.message);
    }
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}


/// 我的小程序
Future<MiniAppMyApp> miniAppMy(Map<String, dynamic> dataBody) async {
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/openapi/client/miniapp/my",
      data: dataBody,
    );
    if (res.success()) {
      List<Apps> favoriteList = [];
      List<Apps> recentList = [];
      List favorite = res.data['favorite'] is List ? res.data['favorite'] : [];
      if (favorite.isNotEmpty) {
        for (var v in favorite) {
          favoriteList.add(Apps.fromJson(v));
        }
      }
      List recent = res.data['recent'] is List ? res.data['recent'] : [];
      if (recent.isNotEmpty) {
        for (var v in recent) {
          recentList.add(Apps.fromJson(v));
        }
      }
      return MiniAppMyApp(favoriteList: favoriteList, recentList: recentList);
    } else {
      throw AppException(res.message);
    }
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

///搜索推荐小程序
Future<List<Apps>> recommendMiniAppList() async {
  try {
    Map<String, dynamic> dataBody = {
      "channel_id": Config().orgChannel,
    };
    final ResponseData res = await CustomRequest.doPost(
      "/openapi/client/miniapp/recommend",
      data: dataBody,
    );
    if (res.success()) {
      List<Apps> items = [];
      List list = res.data;
      for(var item in  list){
        items.add(Apps.fromJson(item));
      }
      return items ;
    } else {
      throw AppException(res.message);
    }
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    rethrow;
  }
}
