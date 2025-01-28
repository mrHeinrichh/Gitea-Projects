// 聊天发送管理器
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:flutter/material.dart';

import 'package:jxim_client/api/chat.dart' as chat_api;
import 'package:jxim_client/im/model/audio_recording_model/volume_model.dart';

import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/task/document/document_mgr.dart';
import 'package:jxim_client/managers/task/image/image_mgr.dart';
import 'package:jxim_client/managers/task/video/video_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/read_user.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:synchronized/synchronized.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MySendMessageMgr extends EventDispatcher {
  final resPorcessLock = Lock();

  void updateLasMessage(Message message) {
    if (message.typ == messageTypeAddReactEmoji ||
        message.typ == messageTypeRemoveReactEmoji) {
      return;
    }
    Message? lastMessage =
        objectMgr.chatMgr.lastChatMessageMap[message.chat_id];
    if (lastMessage == null ||
        (message.chat_idx >= lastMessage.chat_idx &&
            message.send_time >= lastMessage.send_time)) {
      objectMgr.chatMgr.lastChatMessageMap[message.chat_id] = message;
      objectMgr.chatMgr
          .event(this, ChatMgr.eventChatLastMessageChanged, data: message);
      objectMgr.chatMgr.event(this, ChatMgr.eventChatListLoaded);
    }
  }

  Future<ResponseData?> checkReSend(Chat chat, int sendTime, Message msg,
      int firstSendTime, int reCheckWaitTime) async {
    try {
      var res = await chat_api.history(chat.chat_id, chat.msg_idx, forward: 0);
      if (res.success()) {
        Message? findMessage;
        int lastIdx = 0;
        for (final m in res.data) {
          Message message = Message()..init(m);
          if (message.send_time == sendTime &&
              message.send_id == objectMgr.userMgr.mainUser.uid) {
            findMessage = message;
          }
          if (message.chat_idx > lastIdx) {
            lastIdx = message.chat_idx;
          }
        }

        if (findMessage != null) {
          objectMgr.messageManager.LoadMsg([chat]);
          objectMgr.chatMgr.processRemoteMessage([findMessage]);
          objectMgr.chatMgr.saveMessage(findMessage);
          if (chat.msg_idx < lastIdx) {
            objectMgr.chatMgr.updateChatMsgIdx(chat.chat_id, lastIdx);
          }
          Map data = {
            'id': findMessage.message_id,
            'chat_idx': findMessage.chat_idx,
          };
          ResponseData rep = ResponseData(code: 0, message: "", data: data);
          onMessageSent(msg, shouldRemoveCache: /*shouldRemoveCache*/ null);
          return rep;
        }
      }
      return null;
    } catch (e) {
      int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowTime - firstSendTime > 10 * 60) {
        msg.sendState = MESSAGE_SEND_FAIL;
        updateLasMessage(msg);
        throw e;
      } else {
        await Future.delayed(Duration(seconds: reCheckWaitTime));
        if (reCheckWaitTime > 5) {
          reCheckWaitTime = 5;
        }
        return checkReSend(
            chat, sendTime, msg, firstSendTime, reCheckWaitTime + 1);
      }
    }
  }

  //发送
  Future<ResponseData> send(
    int chatID,
    int type,
    String content, {
    bool noUnread = false,
    dynamic data = null,
    String atUser = '',
    bool isReSend = false,
    int sendTime = 0,
  }) async {
    final chat = objectMgr.chatMgr.getChatById(chatID);
    Message message = Message();
    message.chat_id = chatID;
    message.typ = type;
    message.content = content;
    message.create_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    message.send_id = objectMgr.userMgr.mainUser.uid;
    message.chat_idx = chat?.msg_idx ?? 0;
    message.sendState = MESSAGE_SEND_ING;
    if (atUser.isNotEmpty) {
      message.atUser = jsonDecode(atUser).map<MentionModel>((e) {
        return MentionModel.fromJson(e);
      }).toList();
    }
    if (isReSend) {
      message.send_time = sendTime;
    } else {
      message.send_time = DateTime.now().millisecondsSinceEpoch;
    }
    return await realSend(
      message,
      noUnread: noUnread,
      data: data,
      atUser: atUser,
      isReSend: isReSend,
      sendTime: sendTime,
    );
  }

  Future<ResponseData> realSend(
    Message message, {
    bool noUnread = false,
    dynamic data = null,
    String atUser = '',
    bool isReSend = false,
    int sendTime = 0,
  }) async {
    int chatID = message.chat_id;
    int type = message.typ;
    Chat? _chat = await objectMgr.chatMgr.getChatById(chatID);
    int _userId = 0;
    if (_chat != null) {
      if (_chat.isSingle) {
        _userId = _chat.friend_id;
      }
      if (message.chat_idx == 0) {
        message.chat_idx = _chat.msg_idx;
      }
      if (_chat.msg_idx == _chat.hide_chat_msg_idx) {
        message.isHideShow = true;
      }
    }

    bool _isFail = await _doMsgContent(message, type, data: data);

    // 清楚发送以后的文件缓存, 暂时不需要
    final List<String> shouldRemoveCache = [];
    if (!_isFail && message.typ == messageTypeImage) {
      shouldRemoveCache.addAll(await checkImageCache(message));
    }

    if (!_isFail && message.typ == messageTypeVideo) {
      shouldRemoveCache.addAll(await checkVideoCache(message));
    }

    if (!_isFail && message.typ == messageTypeVoice) {
      shouldRemoveCache.addAll(await checkVoiceCache(message));
    }

    if (!_isFail && message.typ == messageTypeNewAlbum) {
      shouldRemoveCache.addAll(await checkAlbumCache(message));
    }

    if (_isFail || message.isSendFail) {
      mypdebug(
          "do message content failed====================================> chat_mgr");
      message.sendState = MESSAGE_SEND_FAIL;
      return ResponseData(
        code: 101,
        message: "failed",
        data: {
          'success': false,
        },
      );
    }

    int firstSendTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    //检查是否已经发送成功过了
    if (isReSend && _chat != null) {
      var rep = await checkReSend(_chat, sendTime, message, firstSendTime, 1);
      if (rep != null) {
        return rep;
      }
    }
    return sendMessageToServer(_userId, _chat!, atUser, message, noUnread,
        shouldRemoveCache, firstSendTime, 1);
  }

  Future<ResponseData> sendMessageToServer(
      int uid,
      Chat chat,
      String atUser,
      Message message,
      bool noUnread,
      List<String> shouldRemoveCache,
      int firstSendTime,
      int reSendWaitTime) async {
    var messageContent = message.content;
    var sendContent = messageContent;
    ResponseData? rep;
    try {
      rep = await chat_api.send(
        uid,
        objectMgr.userMgr.mainUser.uid,
        chat.chat_id,
        message.typ,
        sendContent,
        sendTime: message.send_time,
        no_unread: noUnread,
        atUser: atUser,
      );

      if (rep.success()) {
        message.sendState = MESSAGE_SEND_SUCCESS;
        message.message_id = rep.data['id'];
        message.chat_idx = rep.data['chat_idx'];
        objectMgr.chatMgr.processInputMessage([message]);
        await objectMgr.chatMgr.saveMessage(message);
        if (chat.msg_idx < message.chat_idx) {
          objectMgr.chatMgr.updateChatMsgIdx(chat.chat_id, message.chat_idx);
        }
        // socket可能后来，导致socket之后的一些逻辑需要用的send里面的值
        onMessageSent(message, shouldRemoveCache: shouldRemoveCache);
      } else {
        message.sendState = MESSAGE_SEND_FAIL;
      }
      updateLasMessage(message);
      return rep;
    } catch (e) {
      int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowTime - firstSendTime > 10 * 60) {
        message.sendState = MESSAGE_SEND_FAIL;
        updateLasMessage(message);
        throw e;
      } else {
        await Future.delayed(Duration(seconds: reSendWaitTime));
        var rep = await checkReSend(
            chat, message.send_time, message, firstSendTime, 1);
        if (rep != null) {
          return rep;
        }
        if (reSendWaitTime > 5) {
          reSendWaitTime = 5;
        }
        return sendMessageToServer(uid, chat, atUser, message, noUnread,
            shouldRemoveCache, firstSendTime, reSendWaitTime + 1);
      }
    }
  }

  //处理消息内容
  Future<bool> _doMsgContent(Message message, int type,
      {dynamic data = null}) async {
    bool _isFail = false;
    message.sendState = MESSAGE_SEND_ING;
    if (data != null) {
      if (type == messageTypeImage) {
        message.asset = data;
        _isFail = await _doImageSend(message);
      } else if (type == messageTypeFace || type == messageTypeGif) {
        var imageObj = jsonDecode(message.content);
        imageObj["url"] = data;
        message.content = jsonEncode(imageObj);
        _event(message);
      } else if (type == messageTypeVideo) {
        message.asset = data;
        _isFail = await doVideoSend(message);
      } else if (type == messageTypeVoice) {
        _isFail = await doVoiceSend(message, data);
      } else if (type == messageTypeFile) {
        _isFail = await doFileSend(message, data);
      } else if (type == messageTypeNewAlbum) {
        _isFail = await doAlbumSend(
          data,
          message,
        );
      } else if (type == messageTypeLocation) {
        message.asset = data;
        _isFail = await _doLocationSend(
          message,
        );
      }
    } else {
      //保存并触发更新
      if (message.typ != messageTypeAddReactEmoji &&
          message.typ != messageTypeRemoveReactEmoji) {
        _event(message);
        pdebug(
            "--------:message chat id:${message.chat_id} chat idx:${message.chat_idx}");
      }
    }

    return _isFail;
  }

  ///新相册 数据组装
  Future<bool> doAlbumSend(
    List<dynamic> assets,
    Message message, {
    bool needEvent = true,
  }) async {
    final NewMessageMedia mediaContent =
        message.decodeContent(cl: NewMessageMedia.creator);
    final List<AlbumDetailBean> cacheBeans = mediaContent.albumList ?? [];
    final bool showOriginal = mediaContent.showOriginal;
    final List<AlbumDetailBean> initialBeans = <AlbumDetailBean>[];

    List tempAssets = List.empty(growable: true);

    /// 预加载 处理相册初始化数据
    for (int i = 0; i < assets.length; i++) {
      final File? oriFile;
      //  图片预览入口来的数据
      if (assets[i] is AssetPreviewDetail) {
        final AssetPreviewDetail a = assets[i];
        oriFile = a.editedFile ?? (await a.entity.originFile);

        final bean = cacheBeans.isNotEmpty && cacheBeans.length > i
            ? cacheBeans[i]
            : AlbumDetailBean(
                url: '',
                aswidth: a.entity.orientatedWidth,
                asheight: a.entity.orientatedHeight,
                index_id: '$i',
              );

        bean.asid = a.entity.id;
        bean.astypeint = a.entity.typeInt;
        bean.aswidth = a.entity.orientatedWidth;
        bean.asheight = a.entity.orientatedHeight;

        bean.asset = a.editedFile ?? a.entity;
        bean.fileName = getFileName(oriFile?.path ?? '');

        bool hasCompressed = true;
        // 如果文件已经压缩过了, 不需要重复压缩
        if (!bean.filePath.contains('${bean.fileName}_compressed') ||
            !File(bean.filePath).existsSync()) {
          bean.filePath = oriFile?.path ?? '';
          hasCompressed = false;
        }

        bean.size = oriFile?.lengthSync() ?? 0;

        if (a.entity.type == AssetType.video) {
          bean.seconds = max(a.entity.duration, bean.seconds);
          bean.mimeType = 'video/mp4';
        } else {
          if (!hasCompressed &&
              (bean.aswidth! > 1600 || bean.asheight! > 1600)) {
            // 获取压缩以后的上传尺寸
            Size fileSize = await getImageCompressedSize(
              bean.aswidth!,
              bean.asheight!,
            );

            final compressedFile = await getThumbImageWithPath(
              oriFile!,
              fileSize.width.toInt(),
              fileSize.height.toInt(),
              savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
              sub: 'cover',
            );

            bean.aswidth = fileSize.width.toInt();
            bean.asheight = fileSize.height.toInt();
            bean.asset = compressedFile;
            bean.filePath = compressedFile.path;
            bean.fileName = getFileName(compressedFile.path);
          }

          bean.mimeType = 'image';
        }

        bean.sendTime = message.send_time;

        tempAssets.add(bean.asset);
        initialBeans.add(bean);
      } else if (assets[i] is AssetEntity) {
        // 图片选择器 | 相册入口来的数据
        oriFile = await assets[i].originFile;
        final bean = cacheBeans.isNotEmpty && cacheBeans.length > i
            ? cacheBeans[i]
            : AlbumDetailBean(
                url: '',
                aswidth: assets[i].orientatedWidth,
                asheight: assets[i].orientatedHeight,
                index_id: '$i',
              );

        bean.asid = assets[i].id;
        bean.astypeint = assets[i].typeInt;
        bean.aswidth = assets[i].orientatedWidth;
        bean.asheight = assets[i].orientatedHeight;

        bean.asset = assets[i];

        bean.fileName = getFileName(oriFile?.path ?? '');
        bool hasCompressed = true;
        // 如果文件已经压缩过了, 不需要重复压缩
        if (!bean.filePath.contains('${bean.fileName}_compressed') ||
            !File(bean.filePath).existsSync()) {
          bean.filePath = oriFile?.path ?? '';
          hasCompressed = false;
        }

        bean.size = oriFile?.lengthSync() ?? 0;

        bean.sendTime = message.send_time;

        if (assets[i].type == AssetType.video) {
          bean.seconds = max(assets[i].duration, bean.seconds);
          bean.mimeType = 'video/mp4';
        } else {
          if (!hasCompressed &&
              (bean.aswidth! > 1600 || bean.asheight! > 1600)) {
            // 获取压缩以后的上传尺寸
            Size fileSize = await getImageCompressedSize(
              bean.aswidth!,
              bean.asheight!,
            );

            final compressedFile = await getThumbImageWithPath(
              oriFile!,
              fileSize.width.toInt(),
              fileSize.height.toInt(),
              savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
              sub: 'cover',
            );

            bean.aswidth = fileSize.width.toInt();
            bean.asheight = fileSize.height.toInt();
            bean.asset = compressedFile;
            bean.filePath = compressedFile.path;
            bean.fileName = getFileName(compressedFile.path);
          }

          bean.mimeType = 'image';
        }

        tempAssets.add(bean.asset);
        initialBeans.add(bean);
      } else {
        /// assets is File
        /// 重发消息数据
        mediaContent.albumList![i].sendTime = message.send_time;
        initialBeans.add(mediaContent.albumList![i]);
        oriFile = assets[i];
        tempAssets.add(assets[i]);
      }

      message.albumFileSize["$i"] = oriFile?.lengthSync() ?? 0;
      message.albumUpdateStatus["$i"] = 0;
      message.albumUpdateProgress["$i"] = 0;
    }

    mediaContent.albumList = initialBeans;
    message.content = jsonEncode(mediaContent);
    message.asset = tempAssets;

    // 发送假消息
    _event(message);

    bool isFail = false;
    //资源处理需要串行
    await resPorcessLock.synchronized(() async {
      try {
        var albumObj = jsonDecode(message.content);

        // 添加缩略图
        for (int i = 0; i < initialBeans.length; i++) {
          final bean = initialBeans[i];

          if (bean.mimeType == 'video/mp4') {
            if (bean.coverPath.isEmpty || !File(bean.coverPath).existsSync()) {
              File coverF = await generateThumbnailWithPath(
                bean.filePath,
                savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
                sub: 'cover',
              );
              bean.coverPath = coverF.path;
            }
          }
        }

        mediaContent.albumList = initialBeans;
        message.content = jsonEncode(mediaContent);
        await objectMgr.chatMgr.saveMessage(message);

        ///内容转化，填充相关信息
        List<Map<String, dynamic>> albumList = List.empty(growable: true);

        for (int i = 0; i < tempAssets.length; i++) {
          if (message.sendState == MESSAGE_SEND_FAIL) {
            isFail = true;
            break;
          }

          AssetPreviewDetail? asset;
          AssetEntity? entity;

          AlbumDetailBean bean = initialBeans[i];
          if (tempAssets[i] is AssetPreviewDetail) {
            asset = tempAssets[i];
            entity = asset!.entity;
          } else if (tempAssets[i] is AssetEntity) {
            entity = tempAssets[i];
          }

          File? assetOriginFile =
              asset?.editedFile ?? (await entity?.originFile) ?? tempAssets[i];
          if (assetOriginFile == null && assetOriginFile!.existsSync()) {
            Toast.showToast(localized(toastVideoNotExit));
            isFail = true;
          }

          Map<String, dynamic> albumDetail = {
            ...initialBeans[i].toJson(),
            'showOriginal': showOriginal,
          };

          if (entity?.type == AssetType.image ||
              (bean.mimeType?.contains('image') ?? false)) {
            // 相册图片发送调用
            isFail = await doAlbumImageSend(
              message,
              assetOriginFile,
              mediaContent,
              initialBeans,
              i,
              albumDetail,
              asset: asset,
            );
          } else {
            // 相册视频发送调用
            isFail = await doAlbumVideoSend(
              message,
              assetOriginFile,
              mediaContent,
              initialBeans,
              i,
              entity,
              albumDetail,
            );
          }

          if (!isFail) {
            message.albumUpdateProgress.remove(i.toString());
            // message.albumUpdateStatus.remove(i.toString());
            message.event(message, Message.eventAlbumAssetProcessComplete,
                data: <String, dynamic>{
                  'index': i,
                  'success': true,
                  'url': albumDetail['url'],
                });
          } else {
            break;
          }

          albumList.add(albumDetail);
        }

        albumList.forEach((e) {
          if (e['url'] == null) {
            isFail = true;
          }
        });

        if (isFail || assets.length != albumList.length) {
          message.sendState = MESSAGE_SEND_FAIL;
          isFail = true;
        } else {
          albumObj["albumList"] = albumList;
          message.content = jsonEncode(albumObj);
        }
      } catch (e) {
        isFail = true;
      }
    });
    return isFail;
  }

  Future<bool> doAlbumImageSend(
    Message message,
    File file,
    NewMessageMedia msgMedia,
    List<AlbumDetailBean> albumList,
    int index,
    Map<String, dynamic> albumObj, {
    AssetPreviewDetail? asset,
  }) async {
    try {
      // 获取压缩以后的上传尺寸
      Size fileSize = await getImageCompressedSize(
        albumObj['aswidth'],
        albumObj['asheight'],
      );

      albumObj['aswidth'] = fileSize.width.toInt();
      albumObj['asheight'] = fileSize.height.toInt();

      albumObj['mimeType'] = 'image';
      if (asset != null) {
        albumObj['caption'] = asset.caption;
      }

      CancelToken cancelToken = CancelToken();

      bool _isFail = false;
      final String? imageUrl = await imageMgr.upload(
        albumObj['filePath'],
        albumObj['aswidth'],
        albumObj['asheight'],
        showOriginal: albumObj['showOriginal'] ?? false,
        cancelToken: cancelToken,
        onCompressedComplete: (String path) async {
          albumObj['filePath'] = path;

          albumList[index].filePath = albumObj['filePath'];
          msgMedia.albumList = albumList;
          message.content = jsonEncode(msgMedia);
          await objectMgr.chatMgr.saveMessage(message);

          // 更新相册Cell
          message.event(message, Message.eventAlbumBeanUpdate, data: {
            'index': index,
            'bean': albumList[index],
          });
        },
        onSendProgress: (bytes, total) {
          // 无网络或者取消发送
          if (message.sendState == MESSAGE_SEND_FAIL) {
            _isFail = true;
          }

          message.albumUpdateStatus["$index"] = 3;
          message.albumUpdateProgress["$index"] =
              double.parse((min(bytes, total) / total).toStringAsFixed(2));
          message.event(message, Message.eventAlbumUploadProgress,
              data: {'index': index});
        },
      );

      if (notBlank(imageUrl) && message.sendState != MESSAGE_SEND_FAIL) {
        message.albumUpdateStatus["$index"] = 5;
        albumObj['url'] = imageUrl;
        albumObj['size'] = file.lengthSync();
        _isFail = false;
      } else {
        message.albumUpdateStatus["$index"] = 0;
        _isFail = true;
      }

      return _isFail;
    } catch (e) {
      message.albumUpdateStatus["$index"] = 0;
      return true;
    }
  }

  Future<bool> doAlbumVideoSend(
    Message message,
    File file,
    NewMessageMedia msgMedia,
    List<AlbumDetailBean> albumList,
    int index,
    AssetEntity? entity,
    Map<String, dynamic> albumObj, {
    AssetPreviewDetail? asset,
  }) async {
    bool _isFail = false;
    try {
      albumObj['aswidth'] = entity?.orientatedWidth ?? albumList[index].aswidth;
      albumObj['asheight'] =
          entity?.orientatedHeight ?? albumList[index].asheight;

      albumObj['mimeType'] = 'video/mp4';

      if (asset != null) {
        albumObj['caption'] = asset.caption;
      }

      bool showOriginal = albumObj['showOriginal'] ?? false;
      CancelToken cancelToken = CancelToken();

      final String? coverThumbnail = await imageMgr.upload(
        albumObj['coverPath'],
        0,
        0,
        showOriginal: true,
      );

      final (String path, String sourcePath, String fileHash) =
          await videoMgr.upload(
        albumObj['filePath'],
        accurateWidth: albumObj['aswidth'],
        accurateHeight: albumObj['asheight'],
        showOriginal: showOriginal,
        cancelToken: cancelToken,
        onCompressProgress: (double progress) {
          if (message.sendState == MESSAGE_SEND_FAIL) {
            _isFail = true;
            cancelToken.cancel('Network Interruption.');
          }

          message.albumUpdateStatus["$index"] = 1;
          message.albumUpdateProgress["$index"] = progress / 100;
          message.event(message, Message.eventAlbumUploadProgress,
              data: {'index': index});
        },
        onCompressCallback: (String path) {
          message.albumUpdateStatus["$index"] = 2;
          message.albumFileSize[index.toString()] = File(path).lengthSync();
          message.albumUpdateProgress["$index"] = 0.0;
          albumObj['filePath'] = path;
          msgMedia.albumList = albumList;
          message.content = jsonEncode(msgMedia);
          objectMgr.chatMgr.saveMessage(message);
          message.event(message, Message.eventAlbumUploadProgress,
              data: {'index': index});
        },
        onStatusChange: (int status) {
          if (message.sendState == MESSAGE_SEND_FAIL) {
            _isFail = true;
            cancelToken.cancel('User cancel');
          }

          message.albumUpdateStatus["$index"] = status;
          message.event(message, Message.eventAlbumUploadProgress,
              data: {'index': index});
        },
        onSendProgress: (int bytes, int total) {
          if (message.sendState == MESSAGE_SEND_FAIL) {
            _isFail = true;
            cancelToken.cancel('Network Interruption.');
          }

          if (total > 0) {
            message.albumUpdateStatus["$index"] = 3;
            message.albumUpdateProgress["$index"] =
                double.parse((min(bytes, total) / total).toStringAsFixed(2));
            message.event(message, Message.eventAlbumUploadProgress,
                data: {'index': index});
          }
        },
      );

      message.event(message, Message.eventAlbumUploadProgress,
          data: {'index': index});

      if (notBlank(path) &&
          notBlank(coverThumbnail) &&
          message.sendState != MESSAGE_SEND_FAIL) {
        message.albumUpdateStatus["$index"] = 5;
        albumObj['url'] = path;
        albumObj['source'] = sourcePath;
        albumObj['fileHash'] = fileHash;
        albumObj['cover'] = coverThumbnail;
        albumObj['size'] = File(albumObj['filePath']).lengthSync();
        _isFail = false;
      } else {
        message.albumUpdateStatus["$index"] = 0;
        _isFail = true;
      }

      return _isFail;
    } catch (e, s) {
      debugInfo.printErrorStack(e, s);
      message.uploadStatus = 0;
      return true;
    }
  }

  Future<bool> _doImageSend(Message message) async {
    bool _isFail = false;
    File? f;
    var imageObj = jsonDecode(message.content);

    imageObj['sendTime'] = message.send_time;

    if (message.asset is AssetEntity) {
      AssetEntity entity = message.asset as AssetEntity;
      f = await entity.originFile;
      imageObj['filePath'] = f!.path;
      imageObj['asid'] = entity.id;
      imageObj['astypeint'] = entity.typeInt;
      imageObj['aswidth'] = entity.orientatedWidth;
      imageObj['asheight'] = entity.orientatedHeight;
      imageObj['width'] = entity.orientatedWidth;
      imageObj['height'] = entity.orientatedHeight;
    } else if (message.asset is File) {
      f = message.asset as File;
      imageObj['filePath'] = f.path;
    } else if (message.asset is String) {
      f = File(message.asset);
      message.asset = f;
      imageObj['filePath'] = f.path;
    }

    Size fileSize = await getImageCompressedSize(
      imageObj['width'],
      imageObj['height'],
    );
    imageObj['width'] = fileSize.width.toInt();
    imageObj['height'] = fileSize.height.toInt();

    message.content = jsonEncode(imageObj);
    _event(message);

    //资源处理需要串行
    await resPorcessLock.synchronized(() async {
      imageObj['fileName'] = f!.path.split('/').last;
      message.event(message, Message.eventAssetUpdate);

      try {
        if (!f.existsSync()) {
          Toast.showToast(localized(toastPhotoNotExist));
          _isFail = true;
        } else {
          CancelToken cancelToken = CancelToken();

          final String? imageUrl = await imageMgr.upload(
            f.path,
            imageObj['width'],
            imageObj['height'],
            showOriginal: imageObj['showOriginal'] ?? false,
            cancelToken: cancelToken,
            onCompressedComplete: (String path) async {
              imageObj['size'] = File(path).lengthSync();
              imageObj['filePath'] = path;
              message.content = jsonEncode(imageObj);
              await objectMgr.chatMgr.saveMessage(message);
              message.event(message, Message.eventAssetUpdate);
            },
            onSendProgress: (int bytes, int total) {
              if (message.sendState == MESSAGE_SEND_FAIL) {
                _isFail = true;
                cancelToken.cancel('Network Interruption.');
              }

              if (total > 0) {
                message.totalSize = total;
                message.uploadProgress = double.parse(
                    (min(bytes, total) / total).toStringAsFixed(2));
              }
            },
          );

          if (notBlank(imageUrl) && message.sendState != MESSAGE_SEND_FAIL) {
            imageObj['url'] = imageUrl;
            imageObj['size'] = f.lengthSync();
            message.content = jsonEncode(imageObj);
            _isFail = false;
          } else {
            _isFail = true;
          }
        }
      } catch (e) {
        _isFail = true;
      }
    });

    return _isFail;
  }

  Future<bool> doVideoSend(Message message) async {
    bool _isFail = false;
    File? f;
    File? coverF;
    final Map<String, dynamic> videoObj = jsonDecode(message.content);

    videoObj['sendTime'] = message.send_time;

    if (message.asset is AssetEntity) {
      AssetEntity entity = message.asset;
      f = await entity.originFile;
      videoObj['filePath'] = f!.path;
      videoObj['asid'] = entity.id;
      videoObj['astypeint'] = entity.typeInt;
      videoObj['aswidth'] = entity.orientatedWidth;
      videoObj['asheight'] = entity.orientatedHeight;
    } else if (message.asset is File) {
      f = message.asset as File;
      videoObj['filePath'] = f.path;
    }
    videoObj['fileName'] = f!.path.split('/').last;

    message.content = jsonEncode(videoObj);
    message.uploadStatus = 1;
    _event(message);

    //资源处理需要串行
    await resPorcessLock.synchronized(() async {
      try {
        if (!f!.existsSync()) {
          Toast.showToast(localized(toastVideoNotExit));
          _isFail = true;
        } else {
          // 初始化 cover
          if (videoObj['coverPath'] != null &&
              File(videoObj['coverPath']).existsSync()) {
            coverF = File(videoObj['coverPath']);
          }

          if (coverF == null && message.asset is AssetEntity) {
            AssetEntity asset = message.asset as AssetEntity;
            File? assetFile = await asset.originFile;
            if (assetFile != null) {
              coverF = await generateThumbnailWithPath(
                assetFile.path,
                savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
                sub: 'cover',
              );
            }
          }

          if (coverF == null || !coverF!.existsSync()) {
            coverF = await generateThumbnailWithPath(
              message.asset.path,
              savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
              sub: 'cover',
            );
          }

          videoObj['coverPath'] = coverF!.path;
          message.content = jsonEncode(videoObj);
          await objectMgr.chatMgr.saveMessage(message);

          bool showOriginal = videoObj['showOriginal'] ?? false;
          CancelToken cancelToken = CancelToken();

          final String? coverThumbnail = await imageMgr.upload(
            videoObj['coverPath'],
            0,
            0,
            showOriginal: true,
          );

          final (String path, String sourcePath, String fileHash) =
              await videoMgr.upload(
            f.path,
            accurateWidth: videoObj['width'],
            accurateHeight: videoObj['height'],
            showOriginal: showOriginal,
            cancelToken: cancelToken,
            onCompressProgress: (double progress) {
              if (message.sendState == MESSAGE_SEND_FAIL) {
                _isFail = true;
                cancelToken.cancel('User cancel');
              }

              message.uploadStatus = 1;
              message.uploadProgress = progress / 100;
            },
            onCompressCallback: (String path) {
              message.uploadStatus = 2;
              message.totalSize = File(path).lengthSync();
              message.uploadProgress = 0.0;
              videoObj['filePath'] = path;
              message.content = jsonEncode(videoObj);
              objectMgr.chatMgr.saveMessage(message);
            },
            onStatusChange: (int status) {
              if (message.sendState == MESSAGE_SEND_FAIL) {
                _isFail = true;
                cancelToken.cancel('User cancel');
              }

              message.uploadStatus = status;
            },
            onSendProgress: (int bytes, int total) {
              if (message.sendState == MESSAGE_SEND_FAIL) {
                _isFail = true;
                cancelToken.cancel('User cancel');
              }

              if (total > 0) {
                message.uploadStatus = 3;
                message.totalSize = total;
                message.uploadProgress = double.parse(
                    (min(bytes, total) / total).toStringAsFixed(2));
              }
            },
          );

          if (notBlank(path) &&
              notBlank(coverThumbnail) &&
              message.sendState != MESSAGE_SEND_FAIL) {
            message.uploadStatus = 5;
            videoObj['url'] = path;
            videoObj['cover'] = coverThumbnail;
            videoObj['fileHash'] = fileHash;
            videoObj['source'] = sourcePath;
            videoObj['size'] = f.lengthSync();
            message.content = jsonEncode(videoObj);
            _isFail = false;
          } else {
            message.uploadStatus = 0;
            _isFail = true;
          }
        }
      } catch (e, s) {
        debugInfo.printErrorStack(e, s);
        message.uploadStatus = 0;
        _isFail = true;
      }
    });

    return _isFail;
  }

  Future<bool> doFileSend(Message message, dynamic data) async {
    var fileObj = jsonDecode(message.content);

    fileObj['sendTime'] = message.send_time;

    message.asset = data;
    bool _isFail = false;

    fileObj['size'] = data.lengthSync();
    fileObj['filePath'] = data.path;
    message.content = jsonEncode(fileObj);
    _event(message);

    //资源处理需要串行
    await resPorcessLock.synchronized(() async {
      try {
        CancelToken cancelToken = CancelToken();
        final String? fileUrl = await documentMgr.upload(
          data.path,
          onSendProgress: (int bytes, int total) {
            if (message.sendState == MESSAGE_SEND_FAIL) {
              _isFail = true;
              cancelToken.cancel('Network Interruption.');
            }

            if (total > 0) {
              message.totalSize = total;
              message.uploadProgress =
                  double.parse((min(bytes, total) / total).toStringAsFixed(2));
            }
          },
          cancelToken: cancelToken,
        );

        if (notBlank(fileUrl)) {
          fileObj['url'] = fileUrl;
          fileObj['size'] = data.lengthSync();
          message.content = jsonEncode(fileObj);
          _isFail = false;
        } else {
          _isFail = true;
        }
      } catch (e) {
        _isFail = true;
      }
    });

    return _isFail;
  }

  Future<bool> doVoiceSend(Message message, dynamic data) async {
    final imageObj = jsonDecode(message.content);

    imageObj['sendTime'] = message.send_time;

    bool _isFail = false;
    message.asset = data;

    //语音
    imageObj['vmpath'] = data.path;
    imageObj['decibels'] = data.decibels;
    message.content = jsonEncode(imageObj);
    _event(message);

    try {
      var vFile = File(data.path);
      if (vFile.existsSync()) {
        CancelToken cancelToken = CancelToken();
        final String? audioUrl = await documentMgr.upload(
          data.path,
          cancelToken: cancelToken,
          onSendProgress: (int bytes, int total) {
            if (message.sendState == MESSAGE_SEND_FAIL) {
              _isFail = true;
              cancelToken.cancel('Network Interruption.');
            }

            if (total > 0) {
              message.totalSize = total;
              message.uploadProgress =
                  double.parse((min(bytes, total) / total).toStringAsFixed(2));
            }
          },
        );

        if (notBlank(audioUrl)) {
          imageObj['url'] = audioUrl;
        } else {
          _isFail = true;

          //失败 把文件保存到本地
          String fname = data.path.substring(data.path.lastIndexOf("/"));
          String _path = downloadMgr.appDocumentRootPath + fname;
          var vFileSave = File(_path);
          if (!vFileSave.existsSync()) {
            vFileSave.createSync(recursive: true);
            var vBytes = vFile.readAsBytesSync();
            await vFileSave.writeAsBytes(vBytes);
          }
          imageObj['vmpath'] = data.path;
          imageObj['vmpath1'] = _path;
        }

        message.content = jsonEncode(imageObj);
      } else {
        Toast.showToast(localized(chatFileCorrupt));
        _isFail = true;
      }
    } catch (e) {
      _isFail = true;
    }

    return _isFail;
  }

  Future<bool> _doLocationSend(
    Message message,
  ) async {
    bool _isFail = false;
    File? f;
    var locationObj = jsonDecode(message.content);
    locationObj['sendTime'] = message.send_time;

    if (message.asset is File) {
      f = message.asset as File;
      locationObj['filePath'] = f.path;
    } else {
      return true;
    }

    message.content = jsonEncode(locationObj);
    _event(message);

    locationObj['fileName'] = f.path.split('/').last;
    locationObj['size'] = f.lengthSync();
    message.event(message, Message.eventAssetUpdate);

    //资源处理需要串行
    await resPorcessLock.synchronized(() async {
      try {
        if (!f!.existsSync()) {
          Toast.showToast(localized(toastPhotoNotExist));
          _isFail = true;
        } else {
          CancelToken cancelToken = CancelToken();
          final String? imageUrl = await imageMgr.upload(
            f.path,
            0,
            0,
            showOriginal: true,
            cancelToken: cancelToken,
            onSendProgress: (int bytes, int total) {
              if (message.sendState == MESSAGE_SEND_FAIL) {
                _isFail = true;
                cancelToken.cancel('Network Interruption.');
              }

              if (total > 0) {
                message.totalSize = total;
                message.uploadProgress = double.parse(
                    (min(bytes, total) / total).toStringAsFixed(2));
              }
            },
          );

          if (notBlank(imageUrl)) {
            locationObj['url'] = imageUrl;
            locationObj['uuid'] = f.hashCode;
            locationObj['sendTime'] = message.send_time;
            message.content = jsonEncode(locationObj);
            _isFail = false;
          } else {
            _isFail = true;
          }
        }
      } catch (e) {
        _isFail = true;
      }
    });
    return _isFail;
  }

  //触发
  void _event(Message obj) {
    objectMgr.chatMgr.saveMessage(obj);
    objectMgr.chatMgr
        .event(objectMgr.chatMgr, ChatMgr.eventMessageSend, data: obj);
    updateLasMessage(obj);
  }

  //重新发送
  void onResend(Message message) async {
    Message obj = Message()..init(message.toJson());
    int sendTime = obj.send_time;
    obj.sendState = MESSAGE_SEND_ING;
    //Future.delayed(const Duration(milliseconds: 300), () async {
    dynamic data;
    if (obj.typ == messageTypeImage || obj.typ == messageTypeVideo) {
      data = _createAssetEntity(obj.content);

      final Map<String, dynamic> videoObj = jsonDecode(obj.content);
      if (data == null) {
        data = File(videoObj['filePath']);
      }

      if (videoObj.containsKey('album_id') && videoObj['album_id'] != null) {
        videoObj['album_id'] = null;
        obj.content = jsonEncode(videoObj);
      }
    } else if (obj.typ == messageTypeNewAlbum) {
      final Map<String, dynamic> albumObj = jsonDecode(obj.content);

      List<AssetEntity> assetList = [];
      if (albumObj.isNotEmpty &&
          albumObj.containsKey('albumList') &&
          albumObj['albumList'] is List) {
        albumObj['albumList'].forEach((album) {
          assetList.add(_createAssetEntity(jsonEncode(album)));
        });
      }

      data = assetList;
    } else if (obj.typ == messageTypeVoice) {
      final imageObj = jsonDecode(obj.content);
      if (imageObj['vmpath'] != null)
        data = VolumeModel(
            path: imageObj['vmpath'],
            second: imageObj['second'],
            decibels:
                imageObj['decibels'].map<double>((e) => e as double).toList());
    } else if (obj.typ == messageTypeFile) {
      final fileObj = jsonDecode(obj.content);
      if (fileObj['filePath'] != null) data = File(fileObj['filePath']);
    } else if (obj.typ == messageTypeLocation) {
      final locationObj = jsonDecode(obj.content);
      if (locationObj['filePath'] != null) data = File(locationObj['filePath']);
    }

    /// 添加 相册重试

    /// 删除之前的假消息
    onMessageSent(obj);

    await send(
      obj.chat_id,
      obj.typ,
      obj.content,
      data: data,
      isReSend: true,
      sendTime: sendTime,
    );
    //});
  }

  dynamic _createAssetEntity(String ss) {
    var imageObj = jsonDecode(ss);
    if (imageObj['asid'] != null &&
        imageObj['astypeint'] != null &&
        imageObj['aswidth'] != null &&
        imageObj['asheight'] != null)
      return AssetEntity(
          id: imageObj['asid'],
          typeInt: imageObj['astypeint'],
          width: imageObj['aswidth'],
          height: imageObj['asheight']);
    else if (imageObj['fpath'] != null) return File(imageObj['fpath']);
    return null;
  }

  //删除假数据 会话id、信息id
  Future<void> onMessageSent(
    Message obj, {
    List<String>? shouldRemoveCache,
  }) async {
    Chat? chat = objectMgr.chatMgr.getChatById(obj.chat_id);
    if (chat != null &&
        obj.typ != messageCancelCall &&
        obj.typ != messageRejectCall) {
      objectMgr.chatMgr
          .updateChatAfterSetRead(obj.chat_id, obj.chat_idx, isMe: true);
    }
  }

  Future<List<String>> checkImageCache(Message message) async {
    Map<String, dynamic> msgImage = jsonDecode(message.content);
    // final tempDir = await getApplicationCacheDirectory();
    List<String> list = [];
    // if (msgImage['filePath'] != null &&
    //     msgImage['filePath'].contains(tempDir.path)) {
    //   list.add(msgImage['filePath']);
    // }
    //
    // list.add(tempDir.path + '/${msgImage['fileName']}');

    // 暂时注释移除文件路径, 满足发送者再次开启APP的时候不出现重载的现象
    msgImage.remove('asid');
    msgImage.remove('astypeint');
    msgImage.remove('aswidth');
    msgImage.remove('asheight');
    message.content = jsonEncode(msgImage);

    return list;
  }

  Future<List<String>> checkVideoCache(Message message) async {
    Map<String, dynamic> msgVideo = jsonDecode(message.content);
    // final tempDir = await getApplicationCacheDirectory();
    List<String> list = [];

    // 暂时注释移除文件路径, 满足发送者再次开启APP的时候不出现重载的现象
    // msgVideo.remove('copiedFilePath');
    msgVideo.remove('asid');
    msgVideo.remove('astypeint');
    msgVideo.remove('aswidth');
    msgVideo.remove('asheight');

    message.content = jsonEncode(msgVideo);

    return list;
  }

  Future<List<String>> checkAlbumCache(Message message) async {
    final NewMessageMedia msgMedia = message.decodeContent(
      cl: NewMessageMedia.creator,
    );

    // final tempDir = await getApplicationCacheDirectory();

    List<String> list = [];
    if (notBlank(msgMedia.albumList)) {
      for (var item in msgMedia.albumList!) {
        // if (item.filePath.isNotEmpty && item.filePath.contains(tempDir.path)) {
        //   list.add(item.filePath);
        // }
        //
        // if (item.coverPath.isNotEmpty &&
        //     item.coverPath.contains(tempDir.path)) {
        //   list.add(item.coverPath);
        // }
        //
        // if (item.fileName.isNotEmpty) {
        //   list.add(tempDir.path + '/${item.fileName}');
        // }

        item.asid = null;
        item.astypeint = null;
      }
    }

    message.content = jsonEncode(msgMedia);
    message.event(message, Message.eventAssetUpdate);

    return list;
  }

  Future<List<String>> checkVoiceCache(Message message) async {
    final msgVoice = jsonDecode(message.content);
    // final tempDir = await getApplicationCacheDirectory();
    // String voiceDirPath = tempDir.path + '/voice';

    List<String> list = [];
    // if (msgVoice['vmpath1'] != null && msgVoice['vmpath1'].length > 0) {
    //   list.add(msgVoice['vmpath1']);
    // }

    msgVoice.remove('vmpath');
    message.content = jsonEncode(msgVoice);

    return list;
  }

  void remove(Message obj) {
    onMessageSent(obj);
  }

  Future<void> logout() async {}
}

/// 消息发送
abstract mixin class ChatSend {
  /// 发送消息
  Future<ResponseData> send(
    int chatID,
    int type,
    String content, {
    bool noUnread = false,
    dynamic data = null,
    String atUser = '',
  }) async {
    return objectMgr.chatMgr.mySendMgr.send(
      chatID,
      type,
      content,
      noUnread: noUnread,
      data: data,
      atUser: atUser,
    );
  }

  /// 发送消息 (文本)
  Future<ResponseData> sendText(
    int chatID,
    String content,
    bool isLink, {
    String atUser = '',
    String? reply,
  }) async {
    Map<String, dynamic> dict = {};
    dict['text'] = content;
    var _typ = isLink ? messageTypeLink : messageTypeText;
    if (reply != null) {
      dict['reply'] = reply;
      _typ = messageTypeReply;
    }
    return await send(
      chatID,
      _typ,
      jsonEncode(dict),
      atUser: atUser,
    );
  }

  /// 发送消息 (转发)
  Future<ResponseData> sendForward(
    int chatID,
    Message message,
    int typ, {
    String? text,
  }) async {
    try {
      Map<String, dynamic> _map = jsonDecode(message.content);
      Map<String, dynamic> _newMap = {};
      if (typ == messageTypeText) {
        _newMap['text'] = text!;
      } else {
        _newMap = _map;
      }
      if (_map['forward_user_id'] != null && _map['forward_user_id'] != 0) {
        _newMap['forward_user_id'] = _map['forward_user_id'];
        _newMap['forward_user_name'] = _map['forward_user_name'];

        return await send(
          chatID,
          typ,
          jsonEncode(_newMap),
        );
      } else {
        final User? user =
            await objectMgr.userMgr.loadUserById(message.send_id);

        final Chat? chat = await objectMgr.chatMgr.getChatById(message.chat_id);

        if (chat != null) {
          if (chat.typ == chatTypeSmallSecretary &&
              message.send_id == message.secretary_id) {
            _newMap['forward_user_id'] = isSecretary;
            _newMap['forward_user_name'] = 'Secretary';
          } else if (chat.typ == chatTypeSystem &&
              message.send_id == message.secretary_id) {
            _newMap['forward_user_id'] = isSystem;
            _newMap['forward_user_name'] = 'System';
          } else {
            if (user != null) {
              _newMap['forward_user_id'] = user.uid;
              _newMap['forward_user_name'] = user.nickname;
            }
          }
        } else {
          if (user != null) {
            _newMap['forward_user_id'] = user.uid;
            _newMap['forward_user_name'] = user.nickname;
          }
        }

        return await send(
          chatID,
          typ,
          jsonEncode(_newMap),
        );
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<ResponseData> sendNewAlbum<T>({
    required int chatID,
    required List<T> assets,
    String? caption,
    String? reply,
    bool isOriginalImageSend = false,
  }) async {
    return await send(
      chatID,
      messageTypeNewAlbum,
      jsonEncode({
        'chat_id': chatID,
        'caption': caption,
        'reply': reply,
        'showOriginal': isOriginalImageSend,
      }),
      data: assets,
    );
  }

  /// 发送消息 (图片)
  Future<ResponseData> sendImage({
    required int chatID,
    required int width,
    required int height,
    String? caption,
    String? reply,
    dynamic data = null,
    String atUser = '',
    bool isOriginalImageSend = false,
  }) async {
    return await send(
      chatID,
      messageTypeImage,
      jsonEncode({
        'caption': caption,
        'reply': reply,
        'width': width,
        'height': height,
        'showOriginal': isOriginalImageSend,
      }),
      data: data,
      atUser: atUser,
    );
  }

  /// 发送消息 (视频)
  Future<ResponseData> sendVideo(
    int chatID,
    String name,
    int size,
    int width,
    int height,
    int second, {
    dynamic data = null,
    String? caption = null,
    String? reply = null,
    String atUser = '',
    bool isOriginalImageSend = false,
  }) async {
    return await send(
      chatID,
      messageTypeVideo,
      jsonEncode({
        'url': name,
        'size': size,
        'width': width,
        'height': height,
        'second': second,
        'caption': caption,
        'reply': reply,
        'showOriginal': isOriginalImageSend,
      }),
      data: data,
      atUser: atUser,
    );
  }

  /// 发送贴纸
  Future<ResponseData> sendStickers({
    required int chatID,
    required String name,
    String? reply,
    dynamic data = null,
  }) async {
    return await send(
      chatID,
      messageTypeFace,
      jsonEncode({
        'url': name,
        'reply': reply,
      }),
      data: data,
    );
  }

  /// 发送gif
  Future<ResponseData> sendGif({
    required int chatID,
    required String name,
    String? reply,
    dynamic data = null,
  }) async {
    return await send(
      chatID,
      messageTypeGif,
      jsonEncode({
        'url': name,
        'reply': reply,
      }),
      data: data,
    );
  }

  /// 发送react 表情
  Future<ResponseData> sendReactEmoji({
    required int chatID,
    required int messageId,
    required int chatIdx,
    required int recipientId,
    required int userId,
    required String emoji,
  }) async {
    return await send(
      chatID,
      messageTypeAddReactEmoji,
      jsonEncode({
        'chat_id': chatID,
        'message_id': messageId,
        'chat_idx': chatIdx,
        'recipient_id': recipientId,
        'user_id': userId,
        'emoji': emoji,
      }),
    );
  }

  /// 取消 react 表情
  Future<ResponseData> sendRemoveReactEmoji({
    required int chatID,
    required int messageId,
    required int chatIdx,
    required int recipientId,
    required int userId,
    required String emoji,
  }) async {
    return await send(
      chatID,
      messageTypeRemoveReactEmoji,
      jsonEncode({
        'chat_id': chatID,
        'message_id': messageId,
        'chat_idx': chatIdx,
        'recipient_id': recipientId,
        'user_id': userId,
        'emoji': emoji,
      }),
    );
  }

  /// 发送消息 (文件)
  Future<ResponseData> sendFile({
    required int chatID,
    required int length,
    required String file_name,
    required String suffix,
    String? caption,
    String? reply,
    File? data = null,
  }) async {
    return await send(
      chatID,
      messageTypeFile,
      jsonEncode({
        'length': length,
        'file_name': file_name,
        'suffix': suffix,
        'caption': caption,
        'reply': reply,
      }),
      data: data,
    );
  }

  /// 发送消息 (语音)
  Future<ResponseData> sendVoice(
    int chatID,
    String name,
    int size,
    int flag,
    int second,
    String? reply, {
    VolumeModel? data = null,
  }) async {
    return await send(
      chatID,
      messageTypeVoice,
      jsonEncode({
        'url': name,
        'size': size,
        'flag': flag,
        'second': second,
        'decibels': data?.decibels.reversed.toList(),
        'reply': reply,
      }),
      data: data,
    );
  }

  /// 发送消息 (推荐好友)
  Future<ResponseData> sendRecommendFriend(
    int chatID,
    int user_id,
    String nickName,
    int head,
    String countryCode,
    String contact,
  ) async {
    return await send(
      chatID,
      messageTypeRecommendFriend,
      jsonEncode(
        {
          'user_id': user_id,
          'nick_name': nickName,
          'head': head,
          'country_code': countryCode,
          'contact': contact,
        },
      ),
    );
  }

  Future<ResponseData> sendLocation(
    File data,
    int chatID,
    String name,
    String address,
    String longitude,
    String latitude,
    int type, // 0 当前位置 1 实时位置
    {
    int? startTime,
    int? duration,
  }) async {
    final params = <dynamic, dynamic>{
      'name': name,
      'address': address,
      'longitude': longitude,
      'latitude': latitude,
      'type': type,
    };
    if (type == 1) {
      params['startTime'] = startTime;
      params['duration'] = duration;
    }
    return await send(
      chatID,
      messageTypeLocation,
      jsonEncode(params),
      data: data,
    );
  }

  /// 发送自定义消息 (json字符串)
  Future<ResponseData> sendCustom(int chatID, String info,
      {bool noUnread = false}) async {
    return await send(chatID, messageTypeCustom, info, noUnread: noUnread);
  }

  /// 发送自定义消息 (json字符串)
  Future<ResponseData> sendGroupCall(int chatID, String info,
      {bool noUnread = false}) async {
    return await send(chatID, messageDiscussCall, info, noUnread: noUnread);
  }

  /// 发送自定义消息 (json字符串)
  Future<ResponseData> sendCloseGroupCall(int chatID, String info,
      {bool noUnread = false}) async {
    return await send(chatID, messageCloseDiscussCall, info,
        noUnread: noUnread);
  }

  /// 消息已读列表
  getMessageReadInfos({
    required int messageId,
    String? lastId,
    required int pageCount,
    required Function(List<ReadUser> users, String?) onSuccess,
  }) async {
    var rep = await chat_api.getMessageReadInfos(messageId, lastId, pageCount);
    if (rep.success) {
      List<ReadUser> _list = (rep.data["datas"] as List)
          .map((e) => ReadUser()..applyJson(e))
          .toList();
      lastId = rep.data["last_id"];
      onSuccess(_list, lastId);
    }
    return rep;
  }

  /// 查询转发消息
  getForwardInfoList({
    required int messageId,
    required int page,
    required int pageSize,
    required Function(List<Message> data) onSuccess,
  }) async {
    var rep = await chat_api.getForwardInfoList(messageId, page, pageSize);
    if (rep.success()) {
      List<Message> _list = rep.data.map((e) => Message()..init(e)).toList();
      onSuccess(_list);
    } else {
      Toast.showToast(rep.message, code: rep.code);
    }
  }

  /// 消息未读列表
  Future<HttpResponseBean> getMessageUnreadInfos({
    required int messageId,
    String? lastId,
    required int pageCount,
    required Function(List<ReadUser> user, String?) onSuccess,
  }) async {
    var rep =
        await chat_api.getMessageUnreadInfos(messageId, lastId, pageCount);
    if (rep.success) {
      List<ReadUser> _list = (rep.data["datas"] as List)
          .map((e) => ReadUser()..applyJson(e))
          .toList();
      lastId = rep.data["last_id"];
      onSuccess(_list, lastId);
    }
    return rep;
  }

  ///未读消息人数
  Future<HttpResponseBean> getMessageUnreadNum(int messageId) async {
    var rep = await chat_api.getMessageUnreadNum(messageId);
    return rep;
  }

  ///编辑撤回消息
  List<Message> withdrawList = [];

  updateWithdrawList(Message message) {
    withdrawList.add(message);
  }

  Message? getWithDrawMessage(int messageId) {
    for (var item in withdrawList) {
      if (messageId == item.id) {
        return item;
      }
    }
    return null;
  }
}
