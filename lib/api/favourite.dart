import 'dart:convert';

import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/toast.dart';

Future<List<dynamic>> getRemoteFavouriteList(int page, int? timestamp) async {
  try {
    Map<String, dynamic> data = {};
    data["page"] = page;
    if (timestamp != null) {
      data["timestamp"] = timestamp;
    }

    final ResponseData res = await CustomRequest.doGet(
      '/app/api/favorite/favorites',
      data: data,
    );
    if (res.success()) {
      return res.data;
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

Future<ResponseData> createFavouriteItem(FavouriteData favouriteData,
    {List<String>? urls}) async {
  try {
    Map<String, dynamic> data = {};
    data['data'] = jsonEncode(favouriteData.content);
    data['source'] = favouriteData.source;
    data['typ'] = favouriteData.typ;
    data['tag'] = favouriteData.tag;
    data['is_pin'] = favouriteData.isPin;
    data['urls'] = urls ?? [];
    data['parent_id'] = favouriteData.parentId;
    data['author_id'] = favouriteData.authorId;
    data['chat_typ'] = favouriteData.chatTyp;

    final ResponseData res = await CustomRequest.doPost(
      '/app/api/favorite/create',
      data: data,
    );
    return res;
  } on AppException catch (e) {
    Toast.showToast(e.getMessage());
    rethrow;
  } catch (e) {
    rethrow;
  }
}

Future<ResponseData> updateFavouriteItem(FavouriteData favouriteData,
    {bool ignoreUpdate = false}) async {
  try {
    Map<String, dynamic> data = {};
    data['id'] = favouriteData.id;
    data['data'] = jsonEncode(favouriteData.content);
    data['source'] = favouriteData.source;
    data['typ'] = favouriteData.typ;
    data['tag'] = favouriteData.tag;
    data['is_pin'] = favouriteData.isPin;
    data['urls'] = favouriteData.urls ?? [];

    if (ignoreUpdate) {
      data['is_not_update'] = 1;
    }

    final ResponseData res = await CustomRequest.doPost(
      '/app/api/favorite/update',
      data: data,
    );
    return res;
  } on AppException catch (e) {
    Toast.showToast(e.getMessage());
    rethrow;
  } catch (e) {
    rethrow;
  }
}

Future<ResponseData> deleteFavouriteItem(int id) async {
  try {
    Map<String, dynamic> data = {};
    data['id'] = id;

    final ResponseData res = await CustomRequest.doPost(
      '/app/api/favorite/delete',
      data: data,
    );
    if (res.success()) {
      return res;
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

Future<List<String>> getFavouriteTagList() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      '/app/api/favorite/tags',
    );
    if (res.success()) {
      return res.data.map<String>((e) => e.toString()).toList();
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

Future<bool> updateFavouriteTagList(List<String> tag) async {
  Map<String, dynamic> data = {};
  data['data'] = tag;

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/app/api/favorite/tag/update',
      data: data,
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

Future<List<FavouriteData>> getFavouriteById(List<int> ids) async {
  try {
    Map<String, dynamic> data = {};
    data["ids"] = ids.join(',');

    final ResponseData res = await CustomRequest.doGet(
      '/app/api/favorite/favorite',
      data: data,
    );
    if (res.success()) {
      return res.data
          .map<FavouriteData>((e) => FavouriteData.fromJson(e))
          .toList();
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
