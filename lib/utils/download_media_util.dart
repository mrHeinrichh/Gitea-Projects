import 'dart:io';

import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

final downloadMediaUtil = DownloadMediaUtil();

class DownloadMediaUtil {
  DownloadMediaUtil._internal();

  factory DownloadMediaUtil() => _instance;

  static final DownloadMediaUtil _instance = DownloadMediaUtil._internal();

  /// [asset] 可以有的状态, asset : AssetEntity | String | AlbumDetailBean,
  /// [file] 可以有的状态, file : File
  /// [cover] 可以有的状态, url : String
  /// [message] 对应的消息
  List<Map<String, dynamic>> processAssetList(List<Message> messageList) {
    List<Map<String, dynamic>> assetList = [];
    objectMgr.chatMgr.sortMessage(messageList);
    for (Message message in messageList) {
      if (message.deleted == 1 || !message.isMediaType || !message.isSendOk || message.isEncrypted) {
        continue;
      }

      if (message.typ == messageTypeImage) {
        Map<String, dynamic> assetMap = {};
        if (message.asset != null) {
          assetMap['asset'] = message.asset;
          assetMap['message'] = message;
        } else {
          MessageImage messageImage =
              message.decodeContent(cl: message.getMessageModel(message.typ));
          assetMap['asset'] = messageImage.url;
          assetMap['message'] = message;
        }
        assetList.add(assetMap);
      } else if (message.typ == messageTypeVideo ||
          message.typ == messageTypeReel) {
        Map<String, dynamic> assetMap = {};
        if (message.asset != null) {
          assetMap['asset'] = message.asset;
          assetMap['message'] = message;
          assetMap['hasVideo'] = true;
        } else {
          MessageVideo messageVideo =
              message.decodeContent(cl: message.getMessageModel(message.typ));
          assetMap['asset'] = messageVideo.url;
          assetMap['cover'] = messageVideo.cover;
          assetMap['message'] = message;
          assetMap['hasVideo'] = true;
        }

        assetList.add(assetMap);
      } else if (message.typ == messageTypeNewAlbum) { //到了这里只支援相册 其余场景例如file一概不支援
        if (notBlank(message.asset)) {
          List<dynamic> reversedAsset = message.asset.reversed.toList();
          for (int i = 0; i < reversedAsset.length; i++) {
            Map<String, dynamic> assetMap = {};
            dynamic asset = reversedAsset[i];
            NewMessageMedia msgMedia = message.decodeContent(
              cl: NewMessageMedia.creator,
            );

            if (notBlank(msgMedia.albumList) &&
                msgMedia.albumList!.length > i) {
              AlbumDetailBean bean = msgMedia.albumList![i];
              bean.asset = asset;
              assetMap['asset'] = bean;
              assetMap['message'] = message;

              if (asset is AssetEntity && asset.type == AssetType.video) {
                assetMap['hasVideo'] = true;
              }

              if (asset is AssetPreviewDetail &&
                  asset.entity.type == AssetType.video) {
                assetMap['hasVideo'] = true;
              }
            } else {
              AlbumDetailBean bean = AlbumDetailBean(
                url: '',
              );
              bean.asset = asset;
              bean.asheight = asset.height;
              bean.aswidth = asset.width;

              if (asset.mimeType != null) {
                bean.mimeType = asset.mimeType;
              } else {
                AssetType type = asset.type;
                if (type == AssetType.image) {
                  bean.mimeType = "image/png";
                } else if (type == AssetType.video) {
                  bean.mimeType = "video/mp4";
                }
              }
              bean.currentMessage = message;

              assetMap['asset'] = bean;
              assetMap['message'] = message;
            }

            if (assetMap.isNotEmpty) {
              assetList.add(assetMap);
            }
          }
        } else {
          NewMessageMedia messageMedia =
              message.decodeContent(cl: NewMessageMedia.creator);
          List<AlbumDetailBean> list = messageMedia.albumList ?? [];
          list = list.reversed.toList();
          for (AlbumDetailBean bean in list) {
            Map<String, dynamic> assetMap = {};
            bean.currentMessage = message;
            assetMap['asset'] = bean;
            assetMap['message'] = message;
            if (bean.mimeType != null && bean.mimeType == "video/mp4") {
              assetMap['hasVideo'] = true;
            }

            assetList.add(assetMap);
          }
        }
      }
    }

    return assetList;
  }

  Future<void> saveMedia(String path, {bool isReturnPathOfIOS = false}) async {
    final result = await ImageGallerySaver.saveFile(
      path,
      isReturnPathOfIOS: isReturnPathOfIOS,
    );

    if (result != null && result["isSuccess"]) {
      imBottomToast(
        Get.context!,
        title: localized(toastSaveSuccess),
        icon: ImBottomNotifType.saving,
        duration: 1,
      );
    } else {
      Toast.showToast(localized(toastSaveUnsuccessful));
    }
  }

  Future<bool> saveM3U8ToAlbum(String path) async {
    final mp4RelativeFolderIdx = path.lastIndexOf('/');
    final mp4RelativeFolder = path.substring(0, mp4RelativeFolderIdx);
    String? vidPath = downloadMgr.checkLocalFile(
      "$mp4RelativeFolder${Platform.pathSeparator}index.mp4",
    );
    if (vidPath != null && vidPath.isNotEmpty) {
      await saveMedia(vidPath);
      return true;
    }

    _logVideoSaveFailure(path);
    return false;
  }

  _logVideoSaveFailure(String path) async {
    String urlToSave1 = path;
    String urlToSave2 = "外部保存";
    String errorMsg =
        await objectMgr.tencentVideoMgr.checkFailedSave(urlToSave1, urlToSave2);
    objectMgr.tencentVideoMgr.addLog(urlToSave1, urlToSave2, errorMsg);
  }

  Future<bool> saveImageToAlum(
    String path, {
    bool shouldShowOriginal = false,
  }) async {
    String? localPath = downloadMgr.checkLocalFile(
      path,
      mini: shouldShowOriginal ? Config().maxOriImageMin : null,
    );
    if (!notBlank(localPath)) {
      localPath = downloadMgr.checkLocalFile(path, mini: Config().messageMin);
    }

    if (notBlank(localPath)) {
      await saveMedia(localPath!, isReturnPathOfIOS: true);
      return true;
    }

    return false;
  }

  Future<List<String>> getLocalM3U8VideoFiles(
    String m3u8Path, {
    bool isOld = false,
  }) async {
    final tsDirLastIdx = m3u8Path.lastIndexOf('/');
    final tsDir = m3u8Path.substring(0, tsDirLastIdx);
    Map<double, Map<String, dynamic>> tsMap = cacheMediaMgr.extractTsUrls(
      tsDir,
      m3u8Path,
    );

    List<String> tsFiles = [];
    if (isOld) {
      for (var e in tsMap.values) {
        if (e.containsKey('url')) {
          String? cacheUrl = downloadMgr.checkLocalFile(e['url']);
          if (cacheUrl != null) {
            tsFiles.add(e['url']);
          }
        }
      }
    } else {
      tsMap.forEach((key, value) {
        if (notBlank(value['url'])) {
          String? cacheUrl = downloadMgr.checkLocalFile(value['url']);
          if (cacheUrl != null) {
            tsFiles.add(cacheUrl);
          }
        }
      });
    }

    if (tsFiles.isNotEmpty &&
        notBlank(m3u8Path) &&
        tsFiles.length == tsMap.length) {
      return tsFiles;
    }

    return [];
  }
}
