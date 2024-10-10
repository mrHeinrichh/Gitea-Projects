import 'dart:convert';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/stream_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/favourite.dart';
import 'package:jxim_client/data/db_favourite.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';

class FavouriteMgr extends EventDispatcher implements MgrInterface {
  static const String FAVOURITE_LIST_UPDATE = 'FAVOURITE_LIST_UPDATE';
  static const String TAG_UPDATED = 'TAG_UPDATED';

  List<FavouriteData> favouriteList = [];
  List<FavouriteDetailData> favouriteDetailList = [];
  List<FavouriteData> toBeDeleteList = [];
  bool syncing = false;
  List<int> detailToDeleteList = [];

  @override
  Future<void> init() async {
    _getLocalFavouriteList();
  }

  @override
  Future<void> logout() async {
    favouriteList.clear();
    favouriteDetailList.clear();
  }

  @override
  Future<void> register() async {}

  @override
  Future<void> reloadData() async {}

  void addMessageToFavourite(List<Message> msgList, Chat chat) async {
    FavouriteData favouriteData = FavouriteData();

    /// temporary id
    int nowInMilliSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    favouriteData.id = nowInMilliSeconds;
    favouriteData.parentId =
        (nowInMilliSeconds + objectMgr.userMgr.mainUser.uid).toString();
    favouriteData.createAt = nowInMilliSeconds;
    favouriteData.updatedAt = nowInMilliSeconds;
    favouriteData.source =
        msgList.length > 1 ? FavouriteSourceHistory : FavouriteSourceChat;

    if (chat.isGroup) {
      favouriteData.authorId = chat.chat_id;
    } else {
      if (chat.isSingle) {
        favouriteData.authorId = chat.friend_id;
      } else {
        favouriteData.authorId = chat.id;
      }
    }
    favouriteData.chatTyp = chat.typ;

    msgList.sort((a, b) => a.message_id.compareTo(b.message_id));
    List<String> urls = [];
    for (Message msg in msgList) {
      Map<String, dynamic> result = createFavouriteDetailsFromMessage(
          favouriteData, msg, favouriteData.source == FavouriteSourceHistory);
      urls.addAll(result['urls']);
      favouriteData = result['data'];
    }
    imBottomToast(Get.context!,
        title: localized(favouriteAdded),
        icon: ImBottomNotifType.success,
        isStickBottom: false);
    await insertFavourite(favouriteData, urls: urls);
  }

  Map<String, dynamic> createFavouriteDetailsFromMessage(
    FavouriteData data,
    Message msg,
    bool isMoreThanOneMsg,
  ) {
    int type = 0;
    String content = '';
    List<int> detailTypeList = data.typ;
    List<String> urls = [];
    bool needSkip = false;
    switch (msg.typ) {
      case messageTypeText:
      case messageTypeReply:
      case messageTypeLink:
        MessageText messageText = msg.decodeContent(cl: MessageText.creator);
        FavouriteText favouriteText = FavouriteText(
          text: msg.textAfterMention,
          reply: notBlank(messageText.reply) ? messageText.reply : null,
          translation: notBlank(msg.translationAfterMention)
              ? msg.translationAfterMention
              : null,
          forwardUserId: messageText.forward_user_id > 0
              ? messageText.forward_user_id
              : null,
          forwardUsername: notBlank(messageText.forward_user_name)
              ? messageText.forward_user_name
              : null,
        );
        type =
            msg.typ == messageTypeLink ? FavouriteTypeLink : FavouriteTypeText;
        content = jsonEncode(favouriteText);
        break;
      case messageTypeImage:
        type = FavouriteTypeImage;
        MessageImage messageImage = msg.decodeContent(cl: MessageImage.creator);
        FavouriteImage favouriteImage = FavouriteImage(
          filePath: messageImage.filePath,
          size: messageImage.size,
          url: messageImage.url,
          width: messageImage.width,
          height: messageImage.height,
          caption: notBlank(msg.textAfterMention) ? msg.textAfterMention : null,
          reply: notBlank(messageImage.reply) ? messageImage.reply : null,
          translation: notBlank(msg.translationAfterMention)
              ? msg.translationAfterMention
              : null,
          forwardUserId: messageImage.forward_user_id > 0
              ? messageImage.forward_user_id
              : null,
          forwardUsername: notBlank(messageImage.forward_user_name)
              ? messageImage.forward_user_name
              : null,
        );
        urls.add(messageImage.url);
        content = jsonEncode(favouriteImage);
        break;
      case messageTypeVideo:
        type = FavouriteTypeVideo;
        MessageVideo messageVideo = msg.decodeContent(cl: MessageVideo.creator);
        FavouriteVideo favouriteVideo = FavouriteVideo(
          url: messageVideo.url,
          second: messageVideo.second,
          width: messageVideo.width,
          height: messageVideo.height,
          size: messageVideo.size,
          fileName: messageVideo.fileName,
          filePath: messageVideo.filePath,
          cover: messageVideo.cover,
          coverPath: messageVideo.coverPath,
          caption: notBlank(msg.textAfterMention) ? msg.textAfterMention : null,
          reply: notBlank(messageVideo.reply) ? messageVideo.reply : null,
          translation: notBlank(msg.translationAfterMention)
              ? msg.translationAfterMention
              : null,
          forwardUserId: messageVideo.forward_user_id > 0
              ? messageVideo.forward_user_id
              : null,
          forwardUsername: notBlank(messageVideo.forward_user_name)
              ? messageVideo.forward_user_name
              : null,
        );
        urls.add(messageVideo.url);
        content = jsonEncode(favouriteVideo);
        break;
      case messageTypeVoice:
        type = FavouriteTypeAudio;
        MessageVoice messageVoice = msg.decodeContent(cl: MessageVoice.creator);
        FavouriteVoice favouriteVoice = FavouriteVoice(
          localUrl: messageVoice.localUrl,
          decibels: messageVoice.decibels,
          second: messageVoice.second,
          url: messageVoice.url,
          reply: notBlank(messageVoice.reply) ? messageVoice.reply : null,
          translation: notBlank(msg.translationAfterMention)
              ? msg.translationAfterMention
              : null,
          transcribe: notBlank(messageVoice.transcribe)
              ? messageVoice.transcribe
              : null,
          forwardUserId: messageVoice.forward_user_id > 0
              ? messageVoice.forward_user_id
              : null,
          forwardUsername: notBlank(messageVoice.forward_user_name)
              ? messageVoice.forward_user_name
              : null,
        );
        urls.add(messageVoice.url);
        content = jsonEncode(favouriteVoice);
        break;
      case messageTypeFile:
        type = FavouriteTypeDocument;
        MessageFile messageFile = msg.decodeContent(cl: MessageFile.creator);
        FavouriteFile favouriteFile = FavouriteFile(
          fileName: messageFile.file_name,
          length: messageFile.length,
          url: messageFile.url,
          cover: messageFile.cover,
          suffix: messageFile.suffix,
          isEncrypt: messageFile.isEncrypt,
          caption: notBlank(msg.textAfterMention) ? msg.textAfterMention : null,
          reply: notBlank(messageFile.reply) ? messageFile.reply : null,
          translation: notBlank(msg.translationAfterMention)
              ? msg.translationAfterMention
              : null,
          forwardUserId: messageFile.forward_user_id > 0
              ? messageFile.forward_user_id
              : null,
          forwardUsername: notBlank(messageFile.forward_user_name)
              ? messageFile.forward_user_name
              : null,
          gausPath: messageFile.gausPath,
          gausBytes: messageFile.gausBytes,
        );
        urls.add(messageFile.url);
        content = jsonEncode(favouriteFile);
        break;
      case messageTypeLocation:
        type = FavouriteTypeLocation;
        MessageMyLocation messageMyLocation =
            msg.decodeContent(cl: MessageMyLocation.creator);
        FavouriteLocation favouriteLocation = FavouriteLocation(
          name: messageMyLocation.name,
          address: messageMyLocation.address,
          url: messageMyLocation.url,
          filePath: messageMyLocation.filePath,
          city: messageMyLocation.city,
          latitude: messageMyLocation.latitude,
          longitude: messageMyLocation.longitude,
          forwardUserId: messageMyLocation.forward_user_id > 0
              ? messageMyLocation.forward_user_id
              : null,
          forwardUsername: notBlank(messageMyLocation.forward_user_name)
              ? messageMyLocation.forward_user_name
              : null,
        );
        urls.add(messageMyLocation.url);
        content = jsonEncode(favouriteLocation);
        break;
      case messageTypeNewAlbum:
        NewMessageMedia messageMedia =
            msg.decodeContent(cl: NewMessageMedia.creator);
        if (isMoreThanOneMsg) {
          FavouriteAlbum favouriteAlbum = FavouriteAlbum(
            albumList: messageMedia.albumList!,
            caption:
                notBlank(msg.textAfterMention) ? msg.textAfterMention : null,
            reply: notBlank(messageMedia.reply) ? messageMedia.reply : null,
            translation: notBlank(msg.translationAfterMention)
                ? msg.translationAfterMention
                : null,
            forwardUserId: messageMedia.forward_user_id > 0
                ? messageMedia.forward_user_id
                : null,
            forwardUsername: notBlank(messageMedia.forward_user_name)
                ? messageMedia.forward_user_name
                : null,
          );

          if (messageMedia.albumList != null) {
            for (AlbumDetailBean bean in messageMedia.albumList!) {
              urls.add(bean.url);
            }
          }
          content = jsonEncode(favouriteAlbum);
          type = FavouriteTypeAlbum;
        } else {
          needSkip = true;
          List<FavouriteDetailData> mediaList = [];
          if (messageMedia.albumList != null) {
            for (AlbumDetailBean bean in messageMedia.albumList!) {
              urls.add(bean.url);
              if (bean.isVideo) {
                FavouriteVideo favouriteVideo = FavouriteVideo.fromBean(bean);
                if (!detailTypeList.contains(FavouriteTypeVideo)) {
                  detailTypeList.add(FavouriteTypeVideo);
                }
                mediaList.add(
                  FavouriteDetailData(
                    relatedId: data.parentId,
                    typ: FavouriteTypeVideo,
                    content: jsonEncode(favouriteVideo),
                    sendId: msg.send_id,
                    messageId: msg.message_id,
                    chatId: msg.chat_id,
                    sendTime: msg.create_time,
                  ),
                );
              } else {
                FavouriteImage favouriteImage = FavouriteImage.fromBean(bean);
                if (!detailTypeList.contains(FavouriteTypeImage)) {
                  detailTypeList.add(FavouriteTypeImage);
                }
                mediaList.add(
                  FavouriteDetailData(
                    relatedId: data.parentId,
                    typ: FavouriteTypeImage,
                    content: jsonEncode(favouriteImage),
                    sendId: msg.send_id,
                    messageId: msg.message_id,
                    chatId: msg.chat_id,
                    sendTime: msg.create_time,
                  ),
                );
              }
            }

            if (notBlank(msg.textAfterMention)) {
              FavouriteText favouriteText = FavouriteText(
                text: msg.textAfterMention,
                translation: notBlank(msg.translationAfterMention)
                    ? msg.translationAfterMention
                    : null,
              );
              mediaList.add(
                FavouriteDetailData(
                  relatedId: data.parentId,
                  typ: FavouriteTypeText,
                  content: jsonEncode(favouriteText),
                  sendId: msg.send_id,
                  messageId: msg.message_id,
                  chatId: msg.chat_id,
                  sendTime: msg.create_time,
                ),
              );
              if (!detailTypeList.contains(FavouriteTypeText)) {
                detailTypeList.add(FavouriteTypeText);
              }
            }
            data.content.addAll(mediaList);
          }
        }

        break;
    }

    if (!needSkip) {
      FavouriteDetailData favouriteDetailData = FavouriteDetailData(
        relatedId: data.parentId,
        typ: type,
        content: content,
        sendId: msg.send_id,
        messageId: msg.message_id,
        chatId: msg.chat_id,
        sendTime: msg.create_time,
      );
      if (!detailTypeList.contains(type)) {
        detailTypeList.add(type);
      }
      data.content.add(favouriteDetailData);
    }

    data.typ = detailTypeList;
    Map<String, dynamic> result = {
      'urls': urls,
      'data': data,
    };
    return result;
  }

  FavouriteDetailData createTextFavouriteDetailsFromCaption(
    FavouriteData data,
    String content,
  ) {
    Iterable<RegExpMatch> matches = Regular.extractLink(content);
    FavouriteDetailData favouriteDetailData = FavouriteDetailData(
      relatedId: data.parentId,
      typ: matches.isNotEmpty ? FavouriteTypeLink : FavouriteTypeText,
      content: content,
    );
    return favouriteDetailData;
  }

  Future<FavouriteData> insertFavourite(FavouriteData data,
      {List<String>? urls,
      bool needUpload = true,
      bool needCreateDetails = true}) async {
    int existingIndex =
        favouriteList.indexWhere((item) => item.parentId == data.parentId);
    if (existingIndex != -1) {
      // Remove the existing item if found
      favouriteList.removeAt(existingIndex);
    }

    if (detailToDeleteList.isNotEmpty) {
      objectMgr.localDB.deleteFavouriteDetailsById(detailToDeleteList);
      detailToDeleteList.clear();
    }

    if (needUpload) {
      try {
        final res = await createFavouriteItem(data, urls: urls);
        if (res.success()) {
          await objectMgr.localDB.delete(
            DBFavourite.tableName,
            where: "parent_id = ?",
            whereArgs: [data.parentId],
          );
          data = FavouriteData.fromJson(res.data);
        } else {
          // indicate not synced
          data.isUploaded = 0;
        }
      } catch (e) {
        data.isUploaded = 0;
      }
      data.urls = urls;
    }

    if (needCreateDetails) {
      /// save detail into localDB
      for (FavouriteDetailData detail in data.content) {
        detail.id = null;
        int newId = await insertFavouriteDetail(detail);
        detail.id = newId;
      }
    }

    favouriteList.insert(0, data);
    event(this, FAVOURITE_LIST_UPDATE);

    // fail or success we still save into local db
    await objectMgr.sharedRemoteDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBFavourite.tableName,
        [data.toJson()],
      ),
      save: true,
      notify: false,
    );
    return data;
  }

  Future<int> insertFavouriteDetail(FavouriteDetailData data) async {
    int? id = await objectMgr.localDB.getSingleFavouriteDetail(
      int.parse(data.relatedId!),
      data.content ?? "",
    );

    if (id == null) {
      // Insert the data and get the generated ID
      int newId =
          await objectMgr.localDB.insertFavouriteDetailAndGetId(data.toJson());
      return newId;
    } else {
      return id;
    }
  }

  Future<bool> getServerFavouriteList(int page) async {
    if (connectivityMgr.connectivityResult == ConnectivityResult.none) {
      return false;
    }
    bool notLastResult = false;
    int? lastUpdate;
    if (favouriteList.isNotEmpty) {
      lastUpdate = favouriteList.first.updatedAt;
    }

    final List res = await getRemoteFavouriteList(page, lastUpdate);

    if (res.isNotEmpty) {
      // save to db
      await objectMgr.sharedRemoteDB.applyUpdateBlock(
        UpdateBlockBean.created(
          blockOptReplace,
          DBFavourite.tableName,
          res,
        ),
        save: true,
        notify: false,
      );

      // save detail
      List<FavouriteData> list = res.map((e) {
        return FavouriteData.fromJson(e);
      }).toList();
      for (FavouriteData data in list) {
        if (data.deletedAt == 0) {
          for (FavouriteDetailData detail in data.content) {
            insertFavouriteDetail(detail);
          }
        }
      }
      notLastResult = true;
      _getLocalFavouriteList();
    }
    return notLastResult;
  }

  void _getLocalFavouriteList() async {
    final data = await objectMgr.localDB.loadFavouriteList();
    favouriteList = data.map((e) => FavouriteData.fromJson(e)).toList();
    event(this, FAVOURITE_LIST_UPDATE);
  }

  void syncOfflineFavouriteToServer() async {
    if (connectivityMgr.connectivityResult == ConnectivityResult.none ||
        syncing) return;
    syncing = true;
    final res = await objectMgr.localDB.getNotUploadedFavourites();
    List<FavouriteData> dataList =
        res.map((e) => FavouriteData.fromJson(e)).toList();
    if (dataList.isNotEmpty) {
      // update data to server
      for (FavouriteData data in dataList) {
        if (data.deletedAt == 0) {
          await insertFavourite(data, urls: data.urls);
        } else {
          await deleteFavourite([data], showToast: false);
        }
        favouriteList.removeWhere((element) => element.id == data.id);
      }

      // update list
      _getLocalFavouriteList();
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      syncing = false;
    });
  }

  preDeleteFavourite(List<FavouriteData> deleteDataList) async {
    toBeDeleteList = deleteDataList.toList();
    bool isUndo = false;

    for (FavouriteData data in deleteDataList) {
      data.deletedAt = DateTime.now().millisecondsSinceEpoch;
      data.isUploaded = 0;
      await objectMgr.sharedRemoteDB.applyUpdateBlock(
        UpdateBlockBean.created(
          blockOptReplace,
          DBFavourite.tableName,
          [data.toJson()],
        ),
        save: true,
        notify: false,
      );
    }

    imBottomToast(
      Get.context!,
      title: localized(
        deleteParamFavourite,
        params: [toBeDeleteList.length.toString()],
      ),
      icon: ImBottomNotifType.timer,
      duration: 5,
      withCancel: true,
      timerFunction: () async {
        if (!isUndo) {
          await deleteFavourite(toBeDeleteList, showToast: false);
        }
        toBeDeleteList.clear();
      },
      undoFunction: () async {
        isUndo = true;
        BotToast.removeAll(BotToast.textKey);
        toBeDeleteList.clear();
        for (FavouriteData data in deleteDataList) {
          data.deletedAt = 0;
          data.isUploaded = 1;
          await objectMgr.sharedRemoteDB.applyUpdateBlock(
            UpdateBlockBean.created(
              blockOptReplace,
              DBFavourite.tableName,
              [data.toJson()],
            ),
            save: true,
            notify: false,
          );
        }
        event(this, FAVOURITE_LIST_UPDATE);
      },
    );
  }

  Future<void> deleteFavourite(List<FavouriteData> dataList,
      {bool showToast = true}) async {
    for (FavouriteData data in dataList) {
      try {
        ResponseData res = await deleteFavouriteItem(data.id!);
        if (res.success()) {
          data.deletedAt = res.data['deleted_at'];
          data.isUploaded = 1;
        }
      } catch (e) {
        data.deletedAt = DateTime.now().millisecondsSinceEpoch;
        data.isUploaded = 0;
      }

      await objectMgr.sharedRemoteDB.applyUpdateBlock(
        UpdateBlockBean.created(
          blockOptReplace,
          DBFavourite.tableName,
          [data.toJson()],
        ),
        save: true,
        notify: false,
      );
      objectMgr.localDB.deleteFavouriteDetailsByParentId(data.parentId!);
      favouriteList.removeWhere((element) => element.id == data.id);
      event(this, FAVOURITE_LIST_UPDATE);
    }
    if (showToast) {
      imBottomToast(
        Get.context!,
        title: localized(
          deleteParamFavourite,
          params: [dataList.length.toString()],
        ),
        icon: ImBottomNotifType.success,
      );
    }
  }

  Future<int?> getFavouriteDetailID(int relatedId, String url) async {
    int? id = await objectMgr.localDB.getSingleFavouriteDetail(relatedId, url);
    return id;
  }

  Future<void> getFavouriteDetailLocal() async {
    final dataList = await objectMgr.localDB.loadFavouriteDetailList();
    if (dataList != null) {
      favouriteDetailList =
          dataList.map((e) => FavouriteDetailData.fromJson(e)).toList();
    }
  }

  Future<List<FavouriteData>> getFavouriteDetail(
    List<FavouriteKeywordModel> keyWordList, {
    String? searchText,
  }) async {
    int? typ = keyWordList
        .firstWhereOrNull((element) =>
            element.type == FavouriteType || element.type == FavouriteNote)
        ?.subType;
    String? content = keyWordList
            .firstWhereOrNull((element) => element.type == FavouriteCustom)
            ?.title ??
        searchText;
    List<String>? tag = keyWordList
        .where((element) => element.type == FavouriteTag)
        .map((element) => element.title)
        .toList();

    List<FavouriteData> searchFavouriteDataList = [];

    /// get result from localdb
    final dataList = await objectMgr.localDB
        .getFavouriteDetailList(typ: typ, content: content);

    for (final data in dataList ?? []) {
      List<String> dataTag =
          List<String>.from(jsonDecode(data['tag']).map((e) => e as String));

      bool canAdd = true;
      if (tag.isNotEmpty) {
        canAdd = checkTagMatch(tag, dataTag);
      }

      if (canAdd) {
        FavouriteDetailData content = FavouriteDetailData(
          id: data['id'],
          relatedId: data['parent_id'],
          content: data['data'],
          typ: data['typ'],
          sendTime: data['sendTime'],
          sendId: data['sendId'],
          chatId: data['chatId'],
          messageId: data['messageId'],
        );

        FavouriteData item = FavouriteData(
          id: data['id'],
          parentId: data['parent_id'],
          content: [content],
          createAt: data['created_at'],
          updatedAt: data['updated_at'],
          deletedAt: data['deleted_at'],
          source: data['source'],
          authorId: data['author_id'],
          isPin: data['is_pin'],
          typ: [data['typ']],
          tag: dataTag,
          isUploaded: data['is_uploaded'],
          chatTyp: data['chat_typ'],
        );

        searchFavouriteDataList.add(item);
      }
    }

    if (typ == null || typ == FavouriteNote) {
      List<String?> parentIds =
          searchFavouriteDataList.map((e) => e.parentId).toSet().toList();
      return favouriteList
          .where((element) => parentIds.contains(element.parentId))
          .toList();
    } else {
      return searchFavouriteDataList;
    }
  }

  bool checkTagMatch(List<String> searchTag, List<String> tag) {
    return searchTag.any((element) => tag.contains(element));
  }

  /// tag
  Future<List<String>> getRemoteTagList() async {
    List<String> data = await getFavouriteTagList();
    if (data.isNotEmpty) {
      String jsonString = jsonEncode(data);
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.FAVOURITE_TAG, jsonString);
    }
    return data;
  }

  Future<bool> updateTagList(List<String> tag) async {
    bool data = await updateFavouriteTagList(tag);
    return data;
  }

  Future<void> updateFavourite(FavouriteData data,
      {bool ignoreUpdate = false}) async {
    try {
      final res = await updateFavouriteItem(data, ignoreUpdate: ignoreUpdate);
      if (res.success()) {
        if (res.data['updated_at'] > 0) {
          data.updatedAt = res.data['updated_at'];
        }
        data.tag = List<String>.from(
            jsonDecode(res.data['tag']).map((e) => e as String));

        await objectMgr.sharedRemoteDB.applyUpdateBlock(
          UpdateBlockBean.created(
            blockOptReplace,
            DBFavourite.tableName,
            [data.toJson()],
          ),
          save: true,
          notify: false,
        );

        int index =
            favouriteList.indexWhere((element) => element.id == data.id);
        if (index != -1) {
          favouriteList[index] = data;
        }
        event(this, TAG_UPDATED);
      }
    } catch (e) {
      pdebug("error ${e.toString()}");
    }
  }

  List<Map<String, dynamic>> convertStringToQuillDelta(String text) {
    Iterable<RegExpMatch> linkMatches = Regular.extractLink(text);
    Iterable<RegExpMatch> phoneMatches = Regular.extractPhoneNumber(text);

    // Combine matches and sort by their start positions
    List<RegExpMatch> allMatches = [...linkMatches, ...phoneMatches];
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    List<Map<String, dynamic>> deltaData = [];
    int lastMatchEnd = 0;

    for (var match in allMatches) {
      // Add any text between the last match and this one
      if (match.start > lastMatchEnd) {
        String nonMatchText = text.substring(lastMatchEnd, match.start);
        deltaData.add({
          "insert": nonMatchText,
          "attributes": {"normalText": true},
        });
      }

      // Determine whether this match is a link or a phone number
      if (linkMatches.contains(match)) {
        deltaData.add({
          "insert": match.group(0),
          "attributes": {"link": match.group(0)},
        });
      } else if (phoneMatches.contains(match)) {
        deltaData.add({
          "insert": match.group(0),
          "attributes": {"phone": match.group(0)},
        });
      }

      // Update the last match end
      lastMatchEnd = match.end;
    }

    // Add any remaining text after the last match
    if (lastMatchEnd < text.length) {
      String remainingText = text.substring(lastMatchEnd);
      deltaData.add({
        "insert": remainingText,
        "attributes": {"normalText": true},
      });
    }

    // Ensure the last piece of text ends with a newline
    if (deltaData.isNotEmpty &&
        !(deltaData.last['insert'] as String).endsWith('\n')) {
      deltaData.add({"insert": "\n"});
    }

    return deltaData;
  }

  Future<FavouriteData> createFavouriteNote(
    Map<int, FavouriteDetailData> assetToUpload,
    FavouriteDelta favouriteDelta,
    List<String> urls,
    List<String> tagList,
  ) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String relatedID = (timestamp + objectMgr.userMgr.mainUser.uid).toString();
    List<FavouriteDetailData> detailList = [];
    Map<int, FavouriteDetailData> detailMap = {};

    FavouriteDetailData deltaDetail = FavouriteDetailData(
      typ: FavouriteTypeDelta,
      relatedId: relatedID,
      content: jsonEncode(favouriteDelta),
    );
    // Helper function to handle file uploads
    Future<FavouriteDetailData> handleFileUpload<T>(
      FavouriteDetailData detail,
      String filePath,
      T objectToUpload,
      Future<T?> Function(File, T) uploadFunc,
    ) async {
      File? file = File(filePath);
      if (file.existsSync()) {
        final result = await uploadFunc(file, objectToUpload);
        if (result != null) {
          urls.add((result as dynamic).url);
          detail.content = jsonEncode(result);
        }
      }
      return detail;
    }

    detailList =
        getListOfDetailFromDelta(favouriteDelta, relatedID, isFakeNote: true);

    for (var item in detailList) {
      detailMap[item.id!] = item;
    }

    // Collect unique types
    List<int> typList = detailList.map((data) => data.typ).toSet().toList();
    typList.add(FavouriteTypeDelta); // Delta not in yet

    await _createFakeNote(timestamp, detailList, deltaDetail, typList, tagList);
    for (var entry in assetToUpload.entries) {
      FavouriteDetailData detail = entry.value;
      detail.relatedId = relatedID;

      Map<String, dynamic> json = jsonDecode(detail.content!);

      switch (detail.typ) {
        case FavouriteTypeDocument:
          FavouriteFile favouriteFile = FavouriteFile.fromJson(json);
          detail = await handleFileUpload(
              detail, favouriteFile.url, favouriteFile, _uploadFile);
          break;
        case FavouriteTypeLocation:
          FavouriteLocation favouriteLocation =
              FavouriteLocation.fromJson(json);
          detail = await handleFileUpload(detail, favouriteLocation.filePath,
              favouriteLocation, _uploadLocation);
          break;
        case FavouriteTypeImage:
          FavouriteImage favouriteImage = FavouriteImage.fromJson(json);
          detail = await handleFileUpload(
              detail, favouriteImage.filePath, favouriteImage, _uploadImage);
          break;
        case FavouriteTypeVideo:
          FavouriteVideo favouriteVideo = FavouriteVideo.fromJson(json);
          detail = await handleFileUpload(
              detail, favouriteVideo.filePath, favouriteVideo, _uploadVideo);
          break;
      }

      // Update delta with new content
      for (Operation operation in favouriteDelta.delta.toList()) {
        if (operation.value is Map) {
          final decodedData = jsonDecode(operation.value['custom']);
          final innerData = jsonDecode(decodedData.values.first);

          if (innerData['id'] == detail.id) {
            detail.id = null;
            int newId = await insertFavouriteDetail(detail);
            detail.id = newId;
            detailMap[innerData['id']]!.id = newId;
            detailMap[innerData['id']]!.content = detail.content;
            innerData['data'] = jsonEncode(detail);
            innerData['id'] = newId;
            decodedData[decodedData.keys.first] = jsonEncode(innerData);
            operation.value['custom'] = jsonEncode(decodedData);
          }
        }
      }
    }
    deltaDetail.content = jsonEncode(favouriteDelta);

    List<FavouriteDetailData> newDetailList = detailMap.values.toList();
    newDetailList.add(deltaDetail);

    // Create the FavouriteData object
    FavouriteData favouriteData = FavouriteData(
      id: timestamp,
      parentId: relatedID,
      createAt: timestamp,
      updatedAt: timestamp,
      source: FavouriteSourceNote,
      typ: typList,
      authorId: objectMgr.userMgr.mainUser.uid,
      urls: urls,
      content: newDetailList,
      tag: tagList,
    );

    FavouriteData newData = await insertFavourite(favouriteData,
        urls: urls, needCreateDetails: false);
    return newData;
  }

  _createFakeNote(
      int id,
      List<FavouriteDetailData> detailList,
      FavouriteDetailData delta,
      List<int> typList,
      List<String> tagList) async {
    detailList.add(delta);
    List<int> typList = detailList.map((data) => data.typ).toSet().toList();
    FavouriteData data = FavouriteData(
      id: id,
      parentId: delta.relatedId,
      createAt: id,
      updatedAt: id,
      source: FavouriteSourceNote,
      typ: typList,
      authorId: objectMgr.userMgr.mainUser.uid,
      urls: [],
      content: detailList,
      tag: tagList,
    );
    await insertFavourite(data, urls: [], needUpload: false);
    for (FavouriteDetailData detail in detailList) {
      if (detail.typ != FavouriteTypeDelta && detail.typ != FavouriteTypeText) {
        detailToDeleteList.add(detail.id!);
      }
    }
  }

  Future<FavouriteData> updateNote(
    Map<int, FavouriteDetailData> assetToUpload,
    FavouriteDelta favouriteDelta,
    List<String> urls,
    List<String> tagList,
    FavouriteData oldData,
  ) async {
    oldData.isUploaded = 0;
    int temp = favouriteList.indexWhere((element) => element.id == oldData.id);
    if (temp != -1) {
      favouriteList[temp] = oldData;
    }
    event(this, FAVOURITE_LIST_UPDATE);

    List<FavouriteDetailData> detailList = [];
    List<int> detailId = [];

    FavouriteDetailData deltaDetail = FavouriteDetailData(
      typ: FavouriteTypeDelta,
      relatedId: oldData.parentId,
      content: jsonEncode(favouriteDelta),
    );

    // Helper function to handle file uploads
    Future<FavouriteDetailData> handleFileUpload<T>(
      FavouriteDetailData detail,
      String filePath,
      T objectToUpload,
      Future<T?> Function(File, T) uploadFunc,
    ) async {
      File? file = File(filePath);
      if (file.existsSync()) {
        final result = await uploadFunc(file, objectToUpload);
        if (result != null) {
          urls.add((result as dynamic).url);
          detail.content = jsonEncode(result);
        }
      }
      return detail;
    }

    detailList = getListOfDetailFromDelta(favouriteDelta, oldData.parentId!,
        isFakeNote: true);

    for (var entry in assetToUpload.entries) {
      int id = entry.key;
      FavouriteDetailData detail = entry.value;
      detail.relatedId = oldData.parentId;

      Map<String, dynamic> json = jsonDecode(detail.content!);

      switch (detail.typ) {
        case FavouriteTypeDocument:
          FavouriteFile favouriteFile = FavouriteFile.fromJson(json);
          detail = await handleFileUpload(
              detail, favouriteFile.url, favouriteFile, _uploadFile);
          break;
        case FavouriteTypeLocation:
          FavouriteLocation favouriteLocation =
              FavouriteLocation.fromJson(json);
          detail = await handleFileUpload(detail, favouriteLocation.filePath,
              favouriteLocation, _uploadLocation);
          break;
        case FavouriteTypeImage:
          FavouriteImage favouriteImage = FavouriteImage.fromJson(json);
          detail = await handleFileUpload(
              detail, favouriteImage.filePath, favouriteImage, _uploadImage);
          break;
        case FavouriteTypeVideo:
          FavouriteVideo favouriteVideo = FavouriteVideo.fromJson(json);
          detail = await handleFileUpload(
              detail, favouriteVideo.filePath, favouriteVideo, _uploadVideo);
          break;
      }

      // Update delta with new content
      for (Operation operation in favouriteDelta.delta.toList()) {
        if (operation.value is Map) {
          final decodedData = jsonDecode(operation.value['custom']);
          final innerData = jsonDecode(decodedData.values.first);

          if (innerData['id'] == detail.id) {
            int indexOfItem = -1;
            for (int i = 0; i < detailList.length; i++) {
              if (detailList[i].id == detail.id) {
                indexOfItem = i;
              }
            }
            detail.id = null;
            int newId = await insertFavouriteDetail(detail);
            detail.id = newId;
            detailList[indexOfItem].id = newId;
            detailList[indexOfItem].content = detail.content;
            innerData['data'] = jsonEncode(detail);
            innerData['id'] = newId;
            decodedData[decodedData.keys.first] = jsonEncode(innerData);
            operation.value['custom'] = jsonEncode(decodedData);
          }
        }
      }

      // Update the detail list
      int index = detailList.indexWhere((e) => e.id == id);
      if (index != -1) {
        detailList[index] = detail;
      }
    }

    // Add existing data into detailList
    for (Operation operation in favouriteDelta.delta.toList()) {
      if (operation.value is Map) {
        final decodedData = jsonDecode(operation.value['custom']);
        final innerData = jsonDecode(decodedData.values.first);
        detailId.add(innerData['id']);
      }
    }

    // if id not inside oldData.content then delete
    await objectMgr.localDB
        .deleteOldFavouriteDetails(oldData.parentId!, detailId);

    deltaDetail.content = jsonEncode(favouriteDelta);
    detailList.add(deltaDetail);

    insertFavouriteDetail(deltaDetail);
    for (var detail in detailList) {
      if (detail.typ == FavouriteTypeText) {
        insertFavouriteDetail(detail);
      }
    }

    List<int> typList = detailList.map((data) => data.typ).toSet().toList();

    oldData.content = detailList;
    oldData.typ = typList;
    oldData.urls = urls;
    oldData.tag = tagList;

    try {
      final res = await updateFavouriteItem(oldData);
      if (res.success()) {
        if (res.data['updated_at'] > 0) {
          oldData.updatedAt = res.data['updated_at'];
        }
        oldData.tag = List<String>.from(
            jsonDecode(res.data['tag']).map((e) => e as String));
        oldData.isUploaded = 1;
      } else {
        oldData.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
    } catch (e) {
      oldData.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      pdebug("error ${e.toString()}");
    }

    int index = favouriteList.indexWhere((element) => element.id == oldData.id);
    if (index != -1) {
      favouriteList[index] = oldData;
    }

    await objectMgr.sharedRemoteDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBFavourite.tableName,
        [oldData.toJson()],
      ),
      save: true,
      notify: false,
    );

    event(this, FAVOURITE_LIST_UPDATE);
    return oldData;
  }

  List<FavouriteDetailData> getListOfDetailFromDelta(
      FavouriteDelta favouriteDelta, String relatedID,
      {bool isFakeNote = false}) {
    List<FavouriteDetailData> detailList = [];

    for (Operation operation in favouriteDelta.delta.toList()) {
      if (operation.value is String && operation.value.trim().isNotEmpty) {
        FavouriteText favouriteText =
            FavouriteText(text: operation.value.trim());
        FavouriteDetailData detail = FavouriteDetailData(
          id: favouriteText.hashCode,
          typ: FavouriteTypeText,
          relatedId: relatedID,
          content: jsonEncode(favouriteText),
        );
        detailList.add(detail);
        if (!isFakeNote) {
          insertFavouriteDetail(detail);
        }
      } else if (operation.value is Map) {
        final decodedData = jsonDecode(operation.value['custom']);
        if (!decodedData.containsKey('divider')) {
          final innerData = jsonDecode(decodedData.values.first);
          FavouriteDetailData tempDetail =
              FavouriteDetailData.fromJson(jsonDecode(innerData['data']));
          tempDetail.relatedId = relatedID;
          detailList.add(tempDetail);
        }
      }
    }

    return detailList;
  }

  Future<FavouriteFile?> _uploadFile(
      File file, FavouriteFile favouriteFile) async {
    CancelToken cancelToken = CancelToken();
    bool shouldUploadCover = false;
    String coverPath = '';

    try {
      final String? fileUrl = await documentMgr.upload(
        file.path,
        onFileCoverGenerated:
            (String cover, bool isEncrypt, FileType type) async {
          if (cover.isNotEmpty) {
            shouldUploadCover = true;
            coverPath = cover;
          }

          favouriteFile.isEncrypt = isEncrypt ? 1 : 0;
        },
        cancelToken: cancelToken,
      );

      if (shouldUploadCover) {
        String? uploadedCover = await imageMgr.upload(
          coverPath,
          0,
          0,
          cancelToken: cancelToken,
          onGaussianComplete: (String gausPath) {
            favouriteFile.gausPath = gausPath;
          },
        );

        if (uploadedCover != null) {
          favouriteFile.cover = uploadedCover;
        }
      }

      if (notBlank(fileUrl)) {
        favouriteFile.url = fileUrl!;
      }
      return favouriteFile;
    } catch (e) {
      return null;
    }
  }

  Future<FavouriteLocation?> _uploadLocation(
      File file, FavouriteLocation favouriteLocation) async {
    CancelToken cancelToken = CancelToken();

    try {
      final String? imageUrl = await imageMgr.upload(
        file.path,
        0,
        0,
        cancelToken: cancelToken,
        onGaussianComplete: (String gausPath) {
          favouriteLocation.gausPath = gausPath;
        },
      );

      if (notBlank(imageUrl)) {
        favouriteLocation.url = imageUrl!;
      }
      return favouriteLocation;
    } catch (e) {
      return null;
    }
  }

  Future<FavouriteImage?> _uploadImage(
      File file, FavouriteImage favouriteImage) async {
    CancelToken cancelToken = CancelToken();
    if (favouriteImage.width == 0) {
      MediaInformationSession infoSession =
          await FFprobeKit.getMediaInformation(file.path);
      MediaInformation? mediaInformation = infoSession.getMediaInformation();

      final List<StreamInformation> streams =
          mediaInformation?.getStreams() ?? [];

      final imageStream = streams.firstWhere(
        (stream) =>
            double.parse(stream.getAllProperties()?['duration'] ?? 0.0) < 1,
      );

      favouriteImage.width = imageStream.getWidth()!;
      favouriteImage.height = imageStream.getHeight()!;
    }

    Size fileSize = getResolutionSize(
      favouriteImage.width,
      favouriteImage.height,
      MediaResolution.image_standard.minSize,
    );
    favouriteImage.width = fileSize.width.toInt();
    favouriteImage.height = fileSize.height.toInt();

    final String? compressedPath = await imageMgr.compressImage(
      file.path,
      favouriteImage.width,
      favouriteImage.height,
    );

    if (compressedPath == null) {
      return null;
    }

    favouriteImage.size = File(compressedPath).lengthSync();
    favouriteImage.filePath = compressedPath;

    try {
      final String? imageUrl = await imageMgr.upload(
        file.path,
        favouriteImage.width,
        favouriteImage.height,
        cancelToken: cancelToken,
        onGaussianComplete: (String gausPath) {
          favouriteImage.gausPath = gausPath;
        },
      );

      if (notBlank(imageUrl)) {
        favouriteImage.url = imageUrl!;
      }
      return favouriteImage;
    } catch (e) {
      return null;
    }
  }

  Future<FavouriteVideo?> _uploadVideo(
      File file, FavouriteVideo favouriteVideo) async {
    CancelToken cancelToken = CancelToken();
    if (favouriteVideo.width == 0 || favouriteVideo.height == 0) {
      MediaInformationSession infoSession =
          await FFprobeKit.getMediaInformation(file.path);
      MediaInformation? mediaInformation = infoSession.getMediaInformation();

      final List<StreamInformation> streams =
          mediaInformation?.getStreams() ?? [];

      final videoStream =
          streams.firstWhere((stream) => stream.getType() == 'video');

      favouriteVideo.width = videoStream.getWidth()!;
      favouriteVideo.height = videoStream.getHeight()!;
    }

    Size fileSize = getResolutionSize(
      favouriteVideo.width,
      favouriteVideo.height,
      MediaResolution.image_standard.minSize,
    );
    favouriteVideo.width = fileSize.width.toInt();
    favouriteVideo.height = fileSize.height.toInt();
    favouriteVideo.filePath = file.path;

    final String? coverThumbnail = await imageMgr.upload(
      favouriteVideo.coverPath,
      favouriteVideo.width,
      favouriteVideo.height,
      onGaussianComplete: (String gausPath) {
        favouriteVideo.gausPath = gausPath;
      },
      cancelToken: cancelToken,
    );

    try {
      final (String path, String _) = await videoMgr.upload(
        file.path,
        accurateWidth: favouriteVideo.width,
        accurateHeight: favouriteVideo.height,
        showOriginal: false,
        cancelToken: cancelToken,
        onCompressCallback: (String path) {
          favouriteVideo.size = File(path).lengthSync();
          favouriteVideo.filePath = path;
        },
      );

      if (notBlank(path) && notBlank(coverThumbnail)) {
        objectMgr.tencentVideoMgr.moveFile(file.path, path);
        favouriteVideo.url = path;
        favouriteVideo.cover = coverThumbnail!;
      }
      return favouriteVideo;
    } catch (e) {
      return null;
    }
  }

  dynamic getFavouriteContent(int typ, String content) {
    switch (typ) {
      case FavouriteTypeText:
      case FavouriteTypeLink:
        try {
          return FavouriteText.fromJson(jsonDecode(content));
        } catch (e) {
          return content;
        }
      case FavouriteTypeImage:
        return FavouriteImage.fromJson(jsonDecode(content));
      case FavouriteTypeVideo:
        return FavouriteVideo.fromJson(jsonDecode(content));
      case FavouriteTypeAlbum:
        return FavouriteAlbum.fromJson(jsonDecode(content));
      case FavouriteTypeAudio:
        return FavouriteVoice.fromJson(jsonDecode(content));
      case FavouriteTypeDocument:
        return FavouriteFile.fromJson(jsonDecode(content));
      case FavouriteTypeLocation:
        return FavouriteLocation.fromJson(jsonDecode(content));
    }
  }

  String getFavouriteTitle(int chatTyp, int? authorId, int? userId) {
    String title = '';

    if (authorId != null) {
      if (chatTyp == chatTypeGroup) {
        title = localized(favouriteGroupChatHistoryTitle);
      } else if (chatTyp == chatTypeSaved) {
        title = localized(favouriteParamHistoryTitle,
            params: [localized(homeSavedMessage)]);
      } else if (chatTyp == chatTypeSystem) {
        title = localized(favouriteParamHistoryTitle,
            params: [localized(homeSystemMessage)]);
      } else if (chatTyp == chatTypeSmallSecretary) {
        title = localized(favouriteChatHistoryTitle, params: [
          localized(chatSecretary),
          objectMgr.userMgr.getUserTitle(objectMgr.userMgr
              .getUserById(userId ?? objectMgr.userMgr.mainUser.id)),
        ]);
      } else {
        title = localized(favouriteChatHistoryTitle, params: [
          objectMgr.userMgr
              .getUserTitle(objectMgr.userMgr.getUserById(authorId)),
          objectMgr.userMgr.getUserTitle(objectMgr.userMgr
              .getUserById(userId ?? objectMgr.userMgr.mainUser.id)),
        ]);
      }
    }

    return title;
  }

  String getFavouriteAuthorName(FavouriteData data) {
    String authorName = '';
    if (data.authorId != null) {
      if (data.chatTyp == chatTypeGroup) {
        authorName =
            objectMgr.myGroupMgr.getGroupById(data.authorId!)?.name ?? "";
      } else if (data.chatTyp == chatTypeSaved) {
        authorName = localized(homeSavedMessage);
      } else if (data.chatTyp == chatTypeSystem) {
        authorName = localized(homeSystemMessage);
      } else if (data.chatTyp == chatTypeSmallSecretary) {
        authorName = localized(chatSecretary);
      } else {
        authorName = objectMgr.userMgr
            .getUserTitle(objectMgr.userMgr.getUserById(data.authorId!));
      }
    }

    //兼容旧版本的逻辑
    if (!notBlank(authorName)) {
      authorName = objectMgr.userMgr
          .getUserTitle(objectMgr.userMgr.getUserById(data.authorId!));
    }
    return authorName;
  }

  Map<String, dynamic> getContentList(FavouriteData favouriteData,
      {bool isNote = false}) {
    Map<String, dynamic> map = {};

    String title = "";
    List<String> contentList = [];
    List<FavouriteDetailData> mediaList = [];

    List<FavouriteDetailData> favouriteContent = favouriteData.content.toList();
    bool isSort = false;

    for (FavouriteDetailData item in favouriteContent) {
      String username = objectMgr.userMgr
          .getUserTitle(objectMgr.userMgr.getUserById(item.sendId ?? 0));
      if (item.sendId == 0) {
        if (favouriteData.chatTyp == chatTypeSmallSecretary) {
          username = localized(chatSecretary);
        }
      }
      switch (item.typ) {
        case FavouriteTypeText:
        case FavouriteTypeLink:
          FavouriteText data =
              FavouriteText.fromJson(jsonDecode(item.content ?? ""));
          List<String> listOfString = data.text.split('\n');

          if (listOfString.isNotEmpty) {
            // If isNote is true, use the original method.
            if (isNote) {
              for (String item in listOfString) {
                if (item.isNotEmpty) {
                  if (favouriteData.source == FavouriteSourceHistory) {
                    if (!isSort) {
                      contentList.insert(0, "$username: $item");
                      isSort = true;
                    } else {
                      contentList.add("$username: $item");
                    }
                  } else {
                    if (!isSort) {
                      contentList.insert(0, item);
                      isSort = true;
                    } else {
                      contentList.add(item);
                    }
                  }
                }
              }
            } else {
              // If isNote is false, use the new method (split first \n, replace others with space).
              String firstPart = listOfString[0];
              String remainingPart =
                  listOfString.skip(1).join(' ').replaceAll('\n', ' ');
              String combinedText = "$firstPart $remainingPart";

              if (favouriteData.source == FavouriteSourceHistory) {
                if (!isSort) {
                  contentList.insert(0, "$username: $combinedText");
                  isSort = true;
                } else {
                  contentList.add("$username: $combinedText");
                }
              } else {
                if (!isSort) {
                  contentList.insert(0, combinedText);
                  isSort = true;
                } else {
                  contentList.add(combinedText);
                }
              }
            }
          }
          break;
        case FavouriteTypeImage:
          if (favouriteData.source == FavouriteSourceHistory) {
            contentList.add("$username: [${localized(chatTagPhoto)}]");
          } else {
            mediaList.add(item);
          }
          break;
        case FavouriteTypeVideo:
          if (favouriteData.source == FavouriteSourceHistory) {
            contentList.add("$username: [${localized(chatTagVideoCall)}]");
          } else {
            mediaList.add(item);
          }
          break;
        case FavouriteTypeAlbum:
          if (favouriteData.source == FavouriteSourceHistory) {
            contentList.add("$username: [${localized(chatTagAlbum)}]");
          } else {
            contentList.add("[${localized(chatTagAlbum)}]");
          }
          break;
        case FavouriteTypeAudio:
          FavouriteVoice data =
              FavouriteVoice.fromJson(jsonDecode(item.content ?? ""));
          if (favouriteData.source == FavouriteSourceHistory) {
            contentList.add(
                "$username: [${localized(chatTagVoiceCall)}] ${constructTime(
              data.second ~/ 1000,
              showHour: false,
            )}");
          } else {
            contentList.add("[${localized(chatTagVoiceCall)}] ${constructTime(
              data.second ~/ 1000,
              showHour: false,
            )}");
          }
          break;
        case FavouriteTypeDocument:
          FavouriteFile data =
              FavouriteFile.fromJson(jsonDecode(item.content ?? ""));
          if (favouriteData.source == FavouriteSourceHistory) {
            contentList
                .add("$username: [${localized(files)}] ${data.fileName}");
          } else {
            contentList.add("[${localized(files)}] ${data.fileName}");
          }
          break;
        case FavouriteTypeLocation:
          FavouriteLocation data =
              FavouriteLocation.fromJson(jsonDecode(item.content ?? ""));
          if (favouriteData.source == FavouriteSourceHistory) {
            contentList
                .add("$username: ${localized(replyLocation)} ${data.name}");
          } else {
            contentList.add("${localized(replyLocation)} ${data.name}");
          }
          break;
      }
    }

    if (favouriteData.source == FavouriteSourceHistory) {
      title = getFavouriteTitle(
          favouriteData.chatTyp, favouriteData.authorId, favouriteData.userId);
    } else {
      if (contentList.isNotEmpty) {
        title = contentList.first;
        contentList.removeAt(0);
      }
    }

    map['title'] = title;
    map['contentList'] = contentList;
    map['mediaList'] = mediaList;

    return map;
  }

  Future<List<FavouriteData>> getFavouriteRemoteById(List<int> ids) async {
    List<FavouriteData> data = [];

    for (int id in ids) {
      var res = await objectMgr.localDB.getDataByID(id);
      List<FavouriteData> dataList =
          res.map((e) => FavouriteData.fromJson(e)).toList();
      if (dataList.isNotEmpty) {
        data.addAll(dataList);
      } else {
        data = await getFavouriteById(ids);
      }
    }
    return data;
  }

  /// ****************************** 转发 - begin ****************************** ///
  Future<void> forwardFavouriteList(List<FavouriteData> dataList) async {
    List<dynamic> forwardMessage = [];
    for (FavouriteData item in dataList) {
      if (item.id != null) {
        var res = await objectMgr.localDB.getDataByID(item.id!);
        List<FavouriteData> dataList =
            res.map((e) => FavouriteData.fromJson(e)).toList();
        if (dataList.isNotEmpty) {
          FavouriteData data = dataList.first;
          if (data.isUploaded == 1) {
            if (data.source == FavouriteSourceChat) {
              forwardMessage.add(favouriteMessage(data));
            } else if (data.source == FavouriteSourceHistory) {
              forwardMessage.add(favouriteChatMessage(data));
            } else if (data.source == FavouriteSourceNote) {
              forwardMessage.add(favouriteNoteMessage(data));
            }
          } else {
            Toast.showToast(localized(chatInfoPleaseTryAgainLater));
            return;
          }
        }
      }
    }

    if (forwardMessage.isEmpty) return;

    showModalBottomSheet(
      context: Get.context!,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ForwardContainer(
          forwardMsg: forwardMessage,
          showSaveButton: false,
        );
      },
    );
  }

  Message favouriteMessage(FavouriteData data) {
    int? messageType;
    dynamic msg;

    if (data.content.length == 1) {
      FavouriteDetailData firstData = data.content.toList().first;
      switch (firstData.typ) {
        case FavouriteTypeText:
          msg = MessageText();
          FavouriteText content =
              FavouriteText.fromJson(jsonDecode(firstData.content!));
          msg.text = content.text;
          messageType = messageTypeText;
          break;
        case FavouriteTypeLink:
          msg = MessageText();
          FavouriteText content =
              FavouriteText.fromJson(jsonDecode(firstData.content!));
          msg.text = content.text;
          messageType = messageTypeLink;
          break;
        case FavouriteTypeImage:
          msg = MessageImage();
          FavouriteImage content =
              FavouriteImage.fromJson(jsonDecode(firstData.content!));
          msg.url = content.url;
          msg.filePath = content.filePath;
          msg.size = content.size;
          msg.width = content.width;
          msg.height = content.height;
          msg.gausPath = content.gausPath;
          msg.reply = content.reply ?? "";
          msg.caption = content.caption ?? "";
          msg.forward_user_id = content.forwardUserId ?? 0;
          msg.forward_user_name = content.forwardUsername ?? "";
          msg.translation = content.translation ?? "";
          messageType = messageTypeImage;
          break;
        case FavouriteTypeVideo:
          msg = MessageVideo();
          FavouriteVideo content =
              FavouriteVideo.fromJson(jsonDecode(firstData.content!));
          msg.url = content.url;
          msg.fileName = content.fileName;
          msg.filePath = content.filePath;
          msg.size = content.size;
          msg.width = content.width;
          msg.height = content.height;
          msg.second = content.second;
          msg.cover = content.cover;
          msg.coverPath = content.coverPath;
          msg.gausPath = content.gausPath;
          msg.reply = content.reply ?? "";
          msg.caption = content.caption ?? "";
          msg.forward_user_id = content.forwardUserId ?? 0;
          msg.forward_user_name = content.forwardUsername ?? "";
          msg.translation = content.translation ?? "";
          messageType = messageTypeVideo;
          break;
        case FavouriteTypeAudio:
          msg = MessageVoice();
          FavouriteVoice content =
              FavouriteVoice.fromJson(jsonDecode(firstData.content!));
          msg.url = content.url;
          msg.localUrl = content.localUrl;
          msg.second = content.second;
          msg.decibels = content.decibels;
          msg.reply = content.reply ?? "";
          msg.forward_user_id = content.forwardUserId ?? 0;
          msg.forward_user_name = content.forwardUsername ?? "";
          msg.translation = content.translation ?? "";
          msg.transcribe = content.transcribe ?? "";
          messageType = messageTypeVoice;
          break;
        case FavouriteTypeDocument:
          msg = MessageFile();
          FavouriteFile content =
              FavouriteFile.fromJson(jsonDecode(firstData.content!));
          msg.url = content.url;
          msg.length = content.length;
          msg.file_name = content.fileName;
          msg.suffix = content.suffix;
          msg.cover = content.cover;
          msg.isEncrypt = content.isEncrypt;
          msg.gausPath = content.gausPath;
          msg.gausBytes = content.gausBytes;
          msg.reply = content.reply ?? "";
          msg.caption = content.caption ?? "";
          msg.forward_user_id = content.forwardUserId ?? 0;
          msg.forward_user_name = content.forwardUsername ?? "";
          msg.translation = content.translation ?? "";
          messageType = messageTypeFile;
          break;
        case FavouriteTypeLocation:
          msg = MessageMyLocation();
          FavouriteLocation content =
              FavouriteLocation.fromJson(jsonDecode(firstData.content!));
          msg.latitude = content.latitude;
          msg.longitude = content.longitude;
          msg.name = content.name;
          msg.address = content.address;
          msg.city = content.city;
          msg.url = content.url;
          msg.filePath = content.filePath;
          msg.forward_user_id = content.forwardUserId ?? 0;
          msg.forward_user_name = content.forwardUsername ?? "";
          messageType = messageTypeLocation;
          break;
      }
    } else {
      List<FavouriteDetailData> favouriteContent = data.content.toList();
      final textList = favouriteContent
          .where((element) =>
              element.typ == FavouriteTypeText ||
              element.typ == FavouriteTypeLink)
          .toList();
      final mediaList = favouriteContent
          .where((element) =>
              element.typ == FavouriteTypeImage ||
              element.typ == FavouriteTypeVideo)
          .toList();

      msg = generateAlbum(mediaList);
      msg.caption = generateCaption(textList);
      messageType = messageTypeNewAlbum;
    }

    Message message = Message();
    message.content = jsonEncode(msg);
    message.typ = messageType!;

    return message;
  }

  String generateCaption(List<FavouriteDetailData> captionList) {
    String caption = '';
    if (captionList.isNotEmpty) {
      final data = captionList.first;
      if (data.typ == FavouriteTypeText || data.typ == FavouriteTypeLink) {
        FavouriteText content =
            FavouriteText.fromJson(jsonDecode(data.content!));
        caption = content.text;
      }
    }
    return caption;
  }

  NewMessageMedia generateAlbum(List<FavouriteDetailData> dataList) {
    final NewMessageMedia msg = NewMessageMedia();

    List<AlbumDetailBean> assetList = <AlbumDetailBean>[];
    for (int i = 0; i < dataList.length; i++) {
      final FavouriteDetailData item = dataList[i];
      if (item.typ == FavouriteTypeVideo) {
        FavouriteVideo content =
            FavouriteVideo.fromJson(jsonDecode(item.content!));
        AlbumDetailBean bean = AlbumDetailBean(
          url: content.url,
          seconds: content.second,
          aswidth: content.width,
          asheight: content.height,
        );
        bean.coverPath = content.coverPath;
        bean.cover = content.cover;
        bean.filePath = content.filePath;
        bean.fileName = content.fileName;
        bean.gausPath = content.gausPath;
        bean.mimeType = 'video';
        bean.index = i;
        bean.index_id = '$i';
        assetList.add(bean);
      } else {
        FavouriteImage content =
            FavouriteImage.fromJson(jsonDecode(item.content!));
        AlbumDetailBean bean = AlbumDetailBean(
          url: content.url,
          aswidth: content.width,
          asheight: content.height,
        );

        bean.gausPath = content.gausPath;
        bean.filePath = content.filePath;
        bean.size = content.size;
        bean.mimeType = 'image';
        bean.index = i;
        bean.index_id = '$i';

        assetList.add(bean);
      }
    }

    msg.albumList = assetList;
    return msg;
  }

  Message favouriteNoteMessage(FavouriteData data) {
    Map<String, dynamic> map =
        objectMgr.favouriteMgr.getContentList(data, isNote: true);

    MessageFavourite msg = MessageFavourite();
    msg.favouriteId = data.id ?? 0;
    msg.title = map['title'];
    msg.subTitles = map['contentList'];
    msg.mediaList = map['mediaList'];

    Message message = Message();
    message.content = jsonEncode(msg);
    message.typ = messageTypeNote;

    return message;
  }

  Message favouriteChatMessage(FavouriteData data) {
    Map<String, dynamic> map = objectMgr.favouriteMgr.getContentList(data);

    MessageFavourite msg = MessageFavourite();
    msg.favouriteId = data.id ?? 0;
    msg.title = map['title'];
    msg.subTitles = map['contentList'];

    Message message = Message();
    message.content = jsonEncode(msg);
    message.typ = messageTypeChatHistory;

    return message;
  }

  /// ****************************** 转发 - end ****************************** ///
}
