import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/net/request.dart';
import 'package:jxim_client/utils/net/response_data.dart';

Future<List> getPresetStickers() async {
  try {
    final ResponseData res = await Request.doGet(
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
    final ResponseData res = await Request.doGet(
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
    final ResponseData res = await Request.doGet(
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
    final ResponseData res = await Request.doPost(
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
    final ResponseData res = await Request.doPost(
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
    final ResponseData res = await Request.doGet(
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
