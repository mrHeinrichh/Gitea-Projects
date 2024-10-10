import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';

Future<List> getPresetStickers() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/sticker/preset-collections",
      needToken: false,
    );
    return res.data["collections"];
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    rethrow;
  }
}

Future<List> getMyStickerCollection() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/sticker/my-collections",
    );
    return res.data["collections"];
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    rethrow;
  }
}

Future<List> getMyFavStickers() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/sticker/my-favourite-stickers",
    );
    return res.data["favourite_stickers"];
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    rethrow;
  }
}

Future<bool> addFavSticker(int stickerId) async {
  Map<String, dynamic> dataBody = {};
  dataBody["sticker_id"] = stickerId;
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/sticker/add-favourite-sticker",
      data: dataBody,
    );
    if (res.success()) {
      return true;
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<bool> deleteFavSticker(int stickerId) async {
  Map<String, dynamic> dataBody = {};
  dataBody["sticker_id"] = stickerId;
  try {
    final ResponseData res = await CustomRequest.doPost(
      "/app/api/sticker/remove-favourite-sticker",
      data: dataBody,
    );
    if (res.success()) {
      return true;
    } else {
      throw AppException(res.code, res.message);
    }
  } on AppException catch (e) {
    // 请求过程中的异常处理
    Toast.showToast(e.getMessage());
    rethrow;
  }
}

Future<List> getStickerGif({int page = 1, int limit = 50}) async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/sticker/gif",
      data: {
        "page": page,
        "limit": limit,
      },
    );
    return res.data['gifs'];
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    rethrow;
  }
}

Future<bool> requestAddCollection(int id) async {
  try {
    await CustomRequest.doPost(
      "/app/api/sticker/add-collection",
      data: {
        "collection_id": id,
      },
    );
    return true;
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    return false;
  }
}

Future<bool> requestRemoveCollections(List<int> collectionIds) async {
  try {
    await CustomRequest.doPost(
      "/app/api/sticker/remove-collections",
      data: {
        "collection_ids": collectionIds,
      },
    );
    return true;
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    Toast.showToast(e.getMessage());
    return false;
  }
}

Future<void> requestUpdateMyCollectionOrder(List<int> collectionIds) async {
  try {
    await CustomRequest.doPost(
      "/app/api/sticker/update-my-collection-order",
      data: {
        "cid_order": collectionIds,
      },
    );
    // return res.data['gifs'];
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    rethrow;
  }
}

enum OrderField {
  totalRecentUsed,
  dailyRecentUsed,
  monthlyRecentUsed;

  String get value => switch (this) {
        OrderField.totalRecentUsed => "total_recent_used",
        OrderField.dailyRecentUsed => "daily_recent_used",
        OrderField.monthlyRecentUsed => "monthly_recent_used",
      };
}

enum OrderType {
  asc,
  desc;
}

Future<List> requestGetStickerCollections({
  int page = 1,
  int limit = 50,
  OrderField orderField = OrderField.monthlyRecentUsed,
  OrderType orderType = OrderType.desc,
  String? keyword,
}) async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      "/app/api/sticker/collections",
      data: {
        "page": page,
        "limit": limit,
        "order_field": orderField.value,
        "order": orderType.name,
        if (keyword != null) "keyword": keyword,
      },
    );
    return res.data['collections'];
  } on CodeException catch (e) {
    // 请求过程中的异常处理
    pdebug('${e.getPrefix()}: ${e.getMessage()}');
    rethrow;
  }
}
