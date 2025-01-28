// 聊天发送管理器
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/stream_information.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/api/chat.dart' as chat_api;
import 'package:jxim_client/im/model/audio_recording_model/volume_model.dart';
import 'package:jxim_client/im/model/mention_model.dart';
import 'package:jxim_client/im/services/emojis/util.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/read_user.dart';
import 'package:jxim_client/object/chat/translation_model.dart';
import 'package:jxim_client/object/message/share_image.dart';
import 'package:jxim_client/object/sticker.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/net/link_analyzer/parser.dart';
import 'package:jxim_client/utils/net/lock_with_cancel.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MySendMessageMgr {
  final _resProcessLock = LockWithCancel();
  final _msgProcessLock = Lock();
  final _msgSendTimeLock = Lock();
  int lastSendTime = 0;

  void updateLasMessage(Message message) {
    if (message.isInvisibleMsg) {
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

  Future<ResponseData?> _checkReSend(
    Chat chat,
    Message msg,
    int reCheckWaitTime,
  ) async {
    try {
      var res = await chat_api.history(chat.chat_id, chat.msg_idx, forward: 0);
      if (res.success()) {
        Message? findMessage;
        int lastIdx = 0;
        for (final m in res.data) {
          Message message = Message()..init(m);
          if (message.cmid == msg.cmid &&
              message.send_id == objectMgr.userMgr.mainUser.uid) {
            findMessage = message;
          }
          if (message.chat_idx > lastIdx) {
            lastIdx = message.chat_idx;
          }
        }

        if (findMessage != null) {
          objectMgr.messageManager.loadMsg([chat]);
          objectMgr.chatMgr.processRemoteMessage([findMessage]);
          objectMgr.chatMgr.saveMessage(findMessage);
          if (chat.msg_idx < lastIdx) {
            chat.msg_idx = lastIdx;
            objectMgr.chatMgr.updateChatMsgIdx(chat.chat_id, lastIdx);
          }
          Map data = {
            'id': findMessage.message_id,
            'chat_idx': findMessage.chat_idx,
          };
          ResponseData rep = ResponseData(code: 0, message: "", data: data);
          _onMessageSent(msg);
          return rep;
        }
      }
      return null;
    } catch (e) {
      if (e is CodeException) {
        switch (e.getPrefix()) {
          case 20210:
            return null;
          default:
            break;
        }
      }
      int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowTime - (msg.send_time ~/ 1000) > 10 * 60) {
        msg.sendState = MESSAGE_SEND_FAIL;
        updateLasMessage(msg);
        rethrow;
      } else {
        await Future.delayed(Duration(seconds: reCheckWaitTime));
        if (reCheckWaitTime > 5) {
          reCheckWaitTime = 5;
        }
        return _checkReSend(
          chat,
          msg,
          reCheckWaitTime + 1,
        );
      }
    }
  }

  //发送
  Future<ResponseData> send(
    int chatID,
    int type,
    String content, {
    bool noUnread = false,
    dynamic data,
    String atUser = '',
    bool isReSend = false,
    int sendTime = 0,
    String cmid = '',
    List<int>? receivers,
    int chat_idx = 0,
  }) async {
    final chat = objectMgr.chatMgr.getChatById(chatID);
    Message message = Message();
    message.chat_id = chatID;
    message.typ = type;
    message.content = content;
    message.send_id = objectMgr.userMgr.mainUser.uid;
    message.sendState = MESSAGE_SEND_ING;
    if (atUser.isNotEmpty) {
      message.atUser = jsonDecode(atUser).map<MentionModel>((e) {
        return MentionModel.fromJson(e);
      }).toList();
    }
    message.create_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (isReSend) {
      message.send_time = sendTime;
      message.cmid = cmid;
      message.chat_idx = chat_idx;
      if (objectMgr.chatMgr.chatMessageMap[chatID] != null) {
        Message? findMessage =
            objectMgr.chatMgr.chatMessageMap[chatID]![message.getID()];
        if (findMessage != null) {
          findMessage.chat_idx = message.chat_idx;
          findMessage.create_time = message.create_time;
        }
      }
    } else {
      await _msgSendTimeLock.synchronized(() async {
        message.send_time = DateTime.now().millisecondsSinceEpoch;
        if (message.send_time <= lastSendTime) {
          message.send_time = lastSendTime + 1;
        }
        lastSendTime = message.send_time;
      });
      message.cmid = const Uuid().v4().replaceAll('-', '');
      message.chat_idx = (chat?.msg_idx ?? 0) + 1;
    }
    return await _realSend(
      message,
      noUnread: noUnread,
      data: data,
      atUser: atUser,
      isReSend: isReSend,
      receivers: receivers,
    );
  }

  Future<ResponseData> _realSend(
    Message message, {
    bool noUnread = false,
    dynamic data,
    String atUser = '',
    bool isReSend = false,
    List<int>? receivers,
  }) async {
    int chatID = message.chat_id;
    int type = message.typ;
    Chat? chat = objectMgr.chatMgr.getChatById(chatID);
    int userId = 0;
    if (chat != null) {
      if (chat.isSingle) {
        userId = chat.friend_id;
      }
      if (message.chat_idx == 0) {
        message.chat_idx = chat.msg_idx;
      }
      if (chat.msg_idx == chat.hide_chat_msg_idx) {
        message.isHideShow = true;
      }
    }

    bool isFail = await _doMsgContent(message, type, data: data, chat: chat);

    if (isFail || message.isSendFail) {
      pdebug(
        "do message content failed====================================> chat_mgr",
      );
      if (message.sendState != MESSAGE_SEND_FAIL) {
        message.sendState = MESSAGE_SEND_FAIL;
      }

      if (message.failMessageErrorCode > 0) {
        Future.delayed(const Duration(milliseconds: 100), () {
          objectMgr.chatMgr.generateFailSystemMessage(message);
        });
      }

      return ResponseData(
        code: 101,
        message: "failed",
        data: {
          'success': false,
        },
      );
    }

    return await _msgProcessLock.synchronized(() async {
      try {
        //检查是否已经发送成功过了
        if (isReSend && chat != null) {
          var rep = await _checkReSend(chat, message, 1);
          if (rep != null) {
            return rep;
          }
        }
        return _sendMessageToServer(
          userId,
          chat!,
          atUser,
          message,
          noUnread,
          1,
          isReSend: isReSend,
          receivers: receivers,
        );
      } catch (e) {
        if (message.sendState != MESSAGE_SEND_FAIL) {
          message.sendState = MESSAGE_SEND_FAIL;
        }
        return ResponseData(
          code: 101,
          message: "failed",
          data: {
            'success': false,
          },
        );
      }
    });
  }

  Future<ResponseData> _sendMessageToServer(
    int uid,
    Chat chat,
    String atUser,
    Message message,
    bool noUnread,
    int reSendWaitTime, {
    bool isReSend = false,
    List<int>? receivers,
  }) async {
    var messageContent = message.content;
    var sendContent = messageContent;
    ResponseData? rep;
    try {
      if (chat.isEncrypted &&
          chat.isActiveChatKeyValid &&
          chat.activeKeyRound < chat.round) {
        int currentActiveRound = chat.round;
        String updatedActiveKey =
            objectMgr.encryptionMgr.getCalculatedKey(chat, currentActiveRound);
        if (notBlank(updatedActiveKey)) {
          chat.updateActiveChatKey(updatedActiveKey, currentActiveRound);
          objectMgr.chatMgr.updateEncryptionKeys([chat]);
        }
      }
      rep = await chat_api.send(
        uid,
        objectMgr.userMgr.mainUser.uid,
        chat.chat_id,
        message.typ,
        sendContent,
        message.cmid,
        isReSend,
        message.chat_idx,
        sendTime: message.send_time,
        no_unread: noUnread,
        atUser: atUser,
        refType: (chat.flag & ChatEncryptionFlag.encrypted.value),
        chatKey: chat.activeChatKey,
        keyRound: chat.activeKeyRound,
        isGroup: chat.isGroup,
        friendId: chat.friend_id,
        receivers: receivers,
      );

      if (rep.success()) {
        message.sendState = MESSAGE_SEND_SUCCESS;
        message.message_id = rep.data['id'];
        objectMgr.chatMgr.updateSendMessageIdx(
            chat.chat_id, message.chat_idx, rep.data['chat_idx']);
        message.chat_idx = rep.data['chat_idx'];
        if (chat.msg_idx < message.chat_idx) {
          chat.msg_idx = message.chat_idx;
          objectMgr.chatMgr.updateChatMsgIdx(chat.chat_id, message.chat_idx);
        }
        if (chat.autoDeleteInterval > 0) {
          message.expire_time = chat.autoDeleteInterval + message.create_time;
        }
        if (!message.isInvisibleMsg) {
          objectMgr.chatMgr.saveMessage(message);
        }
        // socket可能后来，导致socket之后的一些逻辑需要用的send里面的值
        _onMessageSent(message);
      } else {
        message.sendState = MESSAGE_SEND_FAIL;
        var contentMap = jsonDecode(sendContent);
        contentMap['error_code'] = rep.code;
        message.content = jsonEncode(contentMap);
        await objectMgr.chatMgr.saveMessage(message);
        objectMgr.chatMgr.generateFailSystemMessage(message);
      }
      updateLasMessage(message);
      return rep;
    } catch (e) {
      if (e is CodeException) {
        switch (e.getPrefix()) {
          case 10005:
            message.sendState = MESSAGE_SEND_FAIL;
            return ResponseData(
              code: 101,
              message: "failed",
              data: {
                'success': false,
              },
            );
          default:
            break;
        }
      }
      int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowTime - (message.send_time ~/ 1000) > 10 * 60) {
        message.sendState = MESSAGE_SEND_FAIL;
        updateLasMessage(message);
        rethrow;
      } else {
        await Future.delayed(Duration(seconds: reSendWaitTime));
        var rep = await _checkReSend(
          chat,
          message,
          1,
        );
        if (rep != null) {
          return rep;
        }
        if (reSendWaitTime > 5) {
          reSendWaitTime = 5;
        }
        return _sendMessageToServer(
          uid,
          chat,
          atUser,
          message,
          noUnread,
          reSendWaitTime + 1,
          isReSend: true,
          receivers: receivers,
        );
      }
    }
  }

  //处理消息内容
  Future<bool> _doMsgContent(
    Message message,
    int type, {
    dynamic data,
    Chat? chat,
  }) async {
    bool isFail = false;
    message.sendState = MESSAGE_SEND_ING;
    if (data != null) {
      if (type == messageTypeImage) {
        message.asset = data;
        isFail = await _doImageSend(message, chat: chat);
      } else if (type == messageTypeFace || type == messageTypeGif) {
        var imageObj = jsonDecode(message.content);
        imageObj["url"] = data;
        message.content = jsonEncode(imageObj);
        _event(message);
      } else if (type == messageTypeVideo) {
        message.asset = data;
        isFail = await _doVideoSend(message, chat: chat);
      } else if (type == messageTypeVoice) {
        isFail = await _doVoiceSend(message, data, chat: chat);
      } else if (type == messageTypeFile) {
        isFail = await _doFileSend(message, data, chat: chat);
      } else if (type == messageTypeNewAlbum) {
        isFail = await _doAlbumSend(data, message, chat: chat);
      } else if (type == messageTypeLocation) {
        message.asset = data;
        isFail = await _doLocationSend(message, chat: chat);
      } else if (type == messageTypeLink) {
        isFail = await _doLinkSend(message, data, chat: chat);
      }
    } else {
      //保存并触发更新
      _event(message);
      await _msgProcessLock.synchronized(
        () async {
          await _doMediaGausProcess(message);
        },
        timeout: const Duration(minutes: 10),
      );
    }

    if (chat != null) {
      objectMgr.chatMgr.chatInput(
        chat.isGroup ? 0 : chat.friend_id,
        ChatInputState.noTyping,
        message.chat_id,
      );
    }

    return isFail;
  }

  ///新相册 数据组装
  Future<bool> _doAlbumSend(
    List<dynamic> assets,
    Message message, {
    Chat? chat,
  }) async {
    final NewMessageMedia mediaContent =
        message.decodeContent(cl: NewMessageMedia.creator);
    final List<AlbumDetailBean> cacheBeans = mediaContent.albumList ?? [];
    final List<AlbumDetailBean> initialBeans = <AlbumDetailBean>[];

    List tempAssets = List.empty(growable: true);

    /// 预加载 处理相册初始化数据
    for (int i = 0; i < assets.length; i++) {
      File? oriFile;
      //  图片预览入口来的数据
      if (assets[i] is AssetPreviewDetail) {
        final AssetPreviewDetail a = assets[i];

        if (a.entity.type == AssetType.image &&
            a.imageResolution == MediaResolution.image_standard &&
            a.isCompressed) {
          final bean = cacheBeans.isNotEmpty && cacheBeans.length > i
              ? cacheBeans[i]
              : AlbumDetailBean(
                  url: '',
                  aswidth: a.entity.orientatedWidth,
                  asheight: a.entity.orientatedHeight,
                  index_id: '$i',
                );

          bean.resolution = a.entity.type == AssetType.image
              ? a.imageResolution.minSize
              : a.videoResolution.minSize;

          // 获取压缩以后的上传尺寸
          Size fileSize = getResolutionSize(
            bean.aswidth!,
            bean.asheight!,
            bean.resolution,
          );

          bean.asid = a.entity.id;
          bean.astypeint = a.entity.typeInt;
          bean.aswidth = fileSize.width.toInt();
          bean.asheight = fileSize.height.toInt();

          bean.asset = a.editedFile ?? a.entity;
          bean.filePath = a.editedFile?.path ?? '';
          bean.fileName = getFileName(a.editedFile?.path ?? '');
          bean.size = a.editedFile?.lengthSync() ?? 0;

          bean.mimeType = 'image';

          tempAssets.add(bean.asset);
          initialBeans.add(bean);
          continue;
        }

        // oriFile = a.editedFile ?? (await a.entity.file);

        final bean = cacheBeans.isNotEmpty && cacheBeans.length > i
            ? cacheBeans[i]
            : AlbumDetailBean(
                url: '',
                aswidth: a.entity.orientatedWidth,
                asheight: a.entity.orientatedHeight,
                index_id: '$i',
              );

        bean.resolution = a.entity.type == AssetType.image
            ? a.imageResolution.minSize
            : a.videoResolution.minSize;

        if (bean.url.isNotEmpty) continue;

        bean.asid = a.entity.id;
        bean.astypeint = a.entity.typeInt;

        if (bean.asheight == 0 || bean.aswidth == 0) {
          MediaInformationSession infoSession =
              await FFprobeKit.getMediaInformation(oriFile!.path);
          MediaInformation? mediaInformation =
              infoSession.getMediaInformation();

          final List<StreamInformation> streams =
              mediaInformation?.getStreams() ?? [];
          if (streams.isEmpty) {
            Toast.showToast(localized(toastVideoNotExit));
            return true;
          }

          final videoStream =
              streams.firstWhere((stream) => stream.getType() == 'video');

          bean.aswidth = videoStream.getWidth();
          bean.asheight = videoStream.getHeight();
        }

        // 获取压缩以后的上传尺寸
        Size fileSize = getResolutionSize(
          bean.aswidth!,
          bean.asheight!,
          bean.resolution,
        );

        bean.aswidth = fileSize.width.toInt();
        bean.asheight = fileSize.height.toInt();

        bean.asset = a.editedFile ?? a.entity;
        // bean.filePath = oriFile?.path ?? '';
        // bean.fileName = getFileName(oriFile?.path ?? '');
        // bean.size = oriFile?.lengthSync() ?? 0;

        if (a.entity.type == AssetType.video) {
          oriFile = a.editedFile ?? (await a.entity.file);

          bean.filePath = oriFile?.path ?? '';
          bean.fileName = getFileName(oriFile?.path ?? '');
          bean.size = oriFile?.lengthSync() ?? 0;

          bean.seconds = max(a.entity.duration, bean.seconds);
          bean.mimeType = 'video/mp4';

          // 初始化 cover
          String? videoCover;
          if (bean.coverPath.isNotEmpty && File(bean.coverPath).existsSync()) {
            videoCover = bean.coverPath;
          }

          videoCover ??= await videoMgr.genVideoCover(
            oriFile!.path,
            fileSize.width.toInt(),
            fileSize.height.toInt(),
            entity: a.entity,
          );

          bean.coverPath = videoCover ?? '';
        } else {
          // final String? compressedPath = await imageMgr.compressImage(
          //   oriFile!.path,
          //   fileSize.width.toInt(),
          //   fileSize.height.toInt(),
          // );
          //
          // if (compressedPath != null) {
          //   bean.asset = File(compressedPath);
          //   bean.filePath = compressedPath;
          //   bean.size = File(compressedPath).lengthSync();
          // }

          bean.mimeType = 'image';
        }

        bean.sendTime = message.send_time;

        tempAssets.add(bean.asset);
        initialBeans.add(bean);
      } else if (assets[i] is AssetEntity) {
        // 图片选择器 | 相册入口来的数据
        // oriFile = await assets[i].file;

        final bean = cacheBeans.isNotEmpty && cacheBeans.length > i
            ? cacheBeans[i]
            : AlbumDetailBean(
                url: '',
                aswidth: assets[i].orientatedWidth,
                asheight: assets[i].orientatedHeight,
                index_id: '$i',
              );

        if (bean.url.isNotEmpty) continue;

        bean.asid = assets[i].id;
        bean.astypeint = assets[i].typeInt;

        if (bean.asheight == 0 || bean.aswidth == 0) {
          MediaInformationSession infoSession =
              await FFprobeKit.getMediaInformation(oriFile!.path);
          MediaInformation? mediaInformation =
              infoSession.getMediaInformation();

          final List<StreamInformation> streams =
              mediaInformation?.getStreams() ?? [];
          if (streams.isEmpty) {
            Toast.showToast(localized(toastVideoNotExit));
            return true;
          }

          final videoStream =
              streams.firstWhere((stream) => stream.getType() == 'video');

          bean.aswidth = videoStream.getWidth();
          bean.asheight = videoStream.getHeight();
        }

        // 获取压缩以后的上传尺寸
        Size fileSize = getResolutionSize(
          bean.aswidth!,
          bean.asheight!,
          bean.resolution,
        );

        bean.aswidth = fileSize.width.toInt();
        bean.asheight = fileSize.height.toInt();

        bean.asset = assets[i];

        // bean.filePath = oriFile?.path ?? '';
        // bean.fileName = getFileName(oriFile?.path ?? '');
        // bean.size = oriFile?.lengthSync() ?? 0;
        bean.sendTime = message.send_time;

        if (assets[i].type == AssetType.video) {
          oriFile = await assets[i].file;

          bean.filePath = oriFile?.path ?? '';
          bean.fileName = getFileName(oriFile?.path ?? '');
          bean.size = oriFile?.lengthSync() ?? 0;

          bean.seconds = max(assets[i].duration, bean.seconds);
          bean.mimeType = 'video/mp4';

          // 初始化 cover
          String? videoCover;
          if (bean.coverPath.isNotEmpty && File(bean.coverPath).existsSync()) {
            videoCover = bean.coverPath;
          }

          videoCover ??= await videoMgr.genVideoCover(
            oriFile!.path,
            fileSize.width.toInt(),
            fileSize.height.toInt(),
            entity: assets[i],
          );

          bean.coverPath = videoCover ?? '';
        } else {
          // final String? compressedPath = await imageMgr.compressImage(
          //   oriFile!.path,
          //   fileSize.width.toInt(),
          //   fileSize.height.toInt(),
          // );
          //
          // if (compressedPath != null) {
          //   bean.asset = File(compressedPath);
          //   bean.filePath = compressedPath;
          //   bean.size = File(compressedPath).lengthSync();
          // }

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

      message.albumUpdateStatus["$i"] = 0;
      message.albumUpdateProgress["$i"] = 0;
    }

    mediaContent.albumList = initialBeans;

    bool isFail = false;

    if (chat?.isSingle ?? false) {
      final userIdx = objectMgr.userMgr.allUsers.indexWhere(
        (element) => element.uid == chat!.friend_id,
      );
      if (userIdx == -1 ||
          objectMgr.userMgr.allUsers[userIdx].relationship ==
              Relationship.stranger) {
        mediaContent.errorCode = ErrorCodeConstant.STATUS_NOT_IN_CHAT;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blocked) {
        mediaContent.errorCode = ErrorCodeConstant.STATUS_USER_ME_IN_BLACKLIST;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blockByTarget) {
        mediaContent.errorCode = ErrorCodeConstant.STATUS_USER_HE_IN_BLACKLIST;
        isFail = true;
      }
    }

    message.content = jsonEncode(mediaContent);
    message.asset = tempAssets;

    // 发送假消息
    _event(message);

    // 图片压缩
    for (int i = 0; i < assets.length; i++) {
      File? oriFile;
      if ((mediaContent.albumList?.length ?? 0) < i) continue;

      final bean = mediaContent.albumList![i];
      if (assets[i] is AssetPreviewDetail) {
        final AssetPreviewDetail a = assets[i];
        if ((a.entity.type == AssetType.image &&
                a.imageResolution == MediaResolution.image_standard &&
                a.isCompressed) ||
            a.entity.type != AssetType.image) continue;
        oriFile = a.editedFile ?? (await a.entity.file);
      } else if (assets[i] is AssetEntity) {
        final AssetEntity a = assets[i];
        if (a.type != AssetType.image) continue;
        oriFile = await a.file;
      } else {
        /// assets is File
        oriFile = assets[i];
      }

      if (oriFile == null) continue;

      if (bean.asheight == 0 || bean.aswidth == 0) {
        MediaInformationSession infoSession =
            await FFprobeKit.getMediaInformation(oriFile.path);
        MediaInformation? mediaInformation = infoSession.getMediaInformation();

        final List<StreamInformation> streams =
            mediaInformation?.getStreams() ?? [];
        if (streams.isEmpty) {
          Toast.showToast(localized(toastVideoNotExit));
          return true;
        }

        final videoStream =
            streams.firstWhere((stream) => stream.getType() == 'video');

        bean.aswidth = videoStream.getWidth();
        bean.asheight = videoStream.getHeight();
      }

      // 获取压缩以后的上传尺寸
      Size fileSize = getResolutionSize(
        bean.aswidth!,
        bean.asheight!,
        bean.resolution,
      );

      bean.aswidth = fileSize.width.toInt();
      bean.asheight = fileSize.height.toInt();

      final String? compressedPath = await imageMgr.compressImage(
        oriFile.path,
        fileSize.width.toInt(),
        fileSize.height.toInt(),
      );

      if (compressedPath != null) {
        bean.asset = File(compressedPath);
        bean.filePath = compressedPath;
        bean.size = File(compressedPath).lengthSync();
      }
    }

    message.content = jsonEncode(mediaContent);
    objectMgr.chatMgr.saveMessage(message);

    if (isFail) return isFail;

    //资源处理需要串行
    await _resProcessLock.synchronized(() async {
      try {
        final Chat? chat = objectMgr.chatMgr.getChatById(message.chat_id);
        if (chat != null) {
          objectMgr.chatMgr.chatInput(
            chat.isGroup ? 0 : chat.friend_id,
            ChatInputState.sendAlbum,
            message.chat_id,
          );
        }

        var albumObj = jsonDecode(message.content);

        ///内容转化，填充相关信息
        List<Map<String, dynamic>> albumList = List.empty(growable: true);

        for (int i = 0; i < tempAssets.length; i++) {
          if (message.sendState == MESSAGE_SEND_FAIL) {
            isFail = true;
            break;
          }

          AssetPreviewDetail? asset;

          AlbumDetailBean bean = initialBeans[i];
          if (tempAssets[i] is AssetPreviewDetail) {
            asset = tempAssets[i];
          }

          Map<String, dynamic> albumDetail = {
            ...initialBeans[i].toJson(),
          };

          if (albumDetail['url'].isNotEmpty) {
            message.albumUpdateStatus["$i"] = 4;
            message.event(
              message,
              Message.eventAlbumAssetProcessComplete,
              data: <String, dynamic>{
                'index': i,
                'success': true,
                'gausPath': albumDetail['gausPath'],
                'url': albumDetail['url'],
                'cover': albumDetail['cover'],
              },
            );
            albumList.add(albumDetail);
            continue;
          }

          if (bean.mimeType?.contains('image') ?? false) {
            // 相册图片发送调用
            isFail = await _doAlbumImageSend(
              message,
              i,
              albumDetail,
              asset: asset,
            );
          } else {
            // 相册视频发送调用
            isFail = await _doAlbumVideoSend(
              message,
              mediaContent,
              i,
              albumDetail,
            );
          }

          if (!isFail) {
            message.event(
              message,
              Message.eventAlbumAssetProcessComplete,
              data: <String, dynamic>{
                'index': i,
                'success': true,
                'gausPath': albumDetail['gausPath'],
                'url': albumDetail['url'],
                'cover': albumDetail['cover'],
              },
            );
          } else {
            break;
          }

          albumList.add(albumDetail);
        }

        for (var e in albumList) {
          if (e['url'] == null) {
            isFail = true;
          }
        }

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

  Future<bool> _doAlbumImageSend(
    Message message,
    int index,
    Map<String, dynamic> albumObj, {
    AssetPreviewDetail? asset,
  }) async {
    try {
      albumObj['mimeType'] = 'image';
      if (asset != null) {
        albumObj['caption'] = asset.caption;
      }

      CancelToken cancelToken = CancelToken();

      cancelToken.whenCancel.then((value) {
        _resProcessLock.cancel();
        return true;
      });

      void stateListener(_, __, ___) {
        if (message.isSendFail) {
          cancelToken.cancel('User cancel');
          message.off(Message.eventSendState, stateListener);
        }
      }

      message.on(Message.eventSendState, stateListener);

      bool isFail = false;

      message.albumUpdateStatus["$index"] = 1;
      message.event(
        message,
        Message.eventAlbumUploadProgress,
        data: {'index': index},
      );

      final String? imageUrl = await imageMgr.upload(
        albumObj['filePath'],
        albumObj['aswidth'],
        albumObj['asheight'],
        cancelToken: cancelToken,
        format: GaussianGenFormat.blurHash,
        onGaussianComplete: (String gausPath) {
          albumObj['gausPath'] = gausPath;
        },
        onSendProgress: (bytes, total) {
          // 无网络或者取消发送
          if (message.sendState == MESSAGE_SEND_FAIL) {
            isFail = true;
          }

          message.albumUpdateStatus["$index"] = 3;
          message.albumUpdateProgress["$index"] =
              double.parse((min(bytes, total) / total).toStringAsFixed(2))
                  .clamp(0.0, 0.95);
          message.event(
            message,
            Message.eventAlbumUploadProgress,
            data: {'index': index},
          );
        },
      );

      if (notBlank(imageUrl) && message.sendState != MESSAGE_SEND_FAIL) {
        message.albumUpdateProgress["$index"] = 1.0;
        message.albumUpdateStatus["$index"] = 4;
        albumObj['url'] = imageUrl;
        isFail = false;
      } else {
        message.albumUpdateStatus["$index"] = 0;
        isFail = true;
      }

      return isFail;
    } catch (e) {
      message.albumUpdateStatus["$index"] = 0;
      return true;
    }
  }

  Future<bool> _doAlbumVideoSend(
    Message message,
    NewMessageMedia msgMedia,
    int index,
    Map<String, dynamic> albumObj, {
    AssetPreviewDetail? asset,
  }) async {
    bool isFail = false;
    try {
      albumObj['mimeType'] = 'video/mp4';

      if (asset != null) {
        albumObj['caption'] = asset.caption;
      }

      bool showOriginal = false;
      CancelToken cancelToken = CancelToken();

      cancelToken.whenCancel.then((value) {
        _resProcessLock.cancel();
        return true;
      });

      void stateListener(_, __, ___) {
        if (message.isSendFail) {
          cancelToken.cancel('User cancel');
          message.off(Message.eventSendState, stateListener);
        }
      }

      message.on(Message.eventSendState, stateListener);

      message.albumUpdateStatus["$index"] = 1;
      message.event(
        message,
        Message.eventAlbumUploadProgress,
        data: {'index': index},
      );

      final String? coverThumbnail = await imageMgr.upload(
        albumObj['coverPath'],
        albumObj['aswidth'],
        albumObj['asheight'],
        cancelToken: cancelToken,
        format: GaussianGenFormat.blurHash,
        onGaussianComplete: (String gausPath) {
          albumObj['gausPath'] = gausPath;
        },
      );

      final (String path, String sourcePath) = await videoMgr.upload(
        albumObj['filePath'],
        accurateWidth: albumObj['aswidth'],
        accurateHeight: albumObj['asheight'],
        showOriginal: showOriginal,
        cancelToken: cancelToken,
        onCompressProgress: (double progress) {
          if (message.sendState == MESSAGE_SEND_FAIL) {
            isFail = true;
            cancelToken.cancel('Network Interruption.');
          }

          if ((message.albumUpdateStatus["$index"] ?? 0) <= 2) {
            message.albumUpdateStatus["$index"] = 2;
          }

          message.event(
            message,
            Message.eventAlbumUploadProgress,
            data: {'index': index},
          );
        },
        onCompressCallback: (String path) {
          if ((message.albumUpdateStatus["$index"] ?? 0) <= 2) {
            message.albumUpdateStatus["$index"] = 2;
          }

          msgMedia.albumList![index].size = File(path).lengthSync();
          msgMedia.albumList![index].filePath = path;
          albumObj['filePath'] = path;
          message.content = jsonEncode(msgMedia);
          objectMgr.chatMgr.saveMessage(message);
          message.event(
            message,
            Message.eventAlbumUploadProgress,
            data: {'index': index},
          );
        },
        onStatusChange: (int status) {
          if (message.sendState == MESSAGE_SEND_FAIL) {
            isFail = true;
            cancelToken.cancel('User cancel');
          }

          if ((message.albumUpdateStatus["$index"] ?? 0) <= 2) {
            message.albumUpdateStatus["$index"] = status;
          }

          message.event(
            message,
            Message.eventAlbumUploadProgress,
            data: {'index': index},
          );
        },
        onSendProgress: (int bytes, int total) {
          if (message.sendState == MESSAGE_SEND_FAIL) {
            isFail = true;
            cancelToken.cancel('Network Interruption.');
          }

          if (total > 0) {
            message.albumUpdateStatus["$index"] = 3;
            message.albumUpdateProgress["$index"] = max(
              message.uploadProgress,
              double.parse((min(bytes, total) / total).toStringAsFixed(2))
                  .clamp(0.0, 0.95),
            );
            message.event(
              message,
              Message.eventAlbumUploadProgress,
              data: {'index': index},
            );
          }
        },
      );

      message.event(
        message,
        Message.eventAlbumUploadProgress,
        data: {'index': index},
      );

      if (notBlank(path) &&
          notBlank(coverThumbnail) &&
          message.sendState != MESSAGE_SEND_FAIL) {
        message.albumUpdateProgress["$index"] = 1.0;
        message.albumUpdateStatus["$index"] = 4;
        await Future.delayed(const Duration(seconds: 1));
        albumObj['url'] = path;
        albumObj['source'] = sourcePath;
        albumObj['cover'] = coverThumbnail;
        albumObj['size'] = File(albumObj['filePath']).lengthSync();
        isFail = false;
      } else {
        message.albumUpdateStatus["$index"] = 0;
        isFail = true;
      }

      return isFail;
    } catch (e, s) {
      pdebug(e, stackTrace: s);
      message.uploadStatus = 0;
      return true;
    }
  }

  Future<bool> _doImageSend(Message message, {Chat? chat}) async {
    bool isFail = false;
    File? f;
    var imageObj = jsonDecode(message.content);

    imageObj['sendTime'] = message.send_time;

    if (message.asset is AssetEntity) {
      AssetEntity entity = message.asset as AssetEntity;
      f = await entity.file;
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

    if (f == null || !f.existsSync()) {
      isFail = true;
      return isFail;
    }

    if (imageObj['width'] == 0 || imageObj['asheight'] == 0) {
      MediaInformationSession infoSession =
          await FFprobeKit.getMediaInformation(f.path);
      MediaInformation? mediaInformation = infoSession.getMediaInformation();

      final List<StreamInformation> streams =
          mediaInformation?.getStreams() ?? [];
      if (streams.isEmpty) {
        Toast.showToast(localized(toastVideoNotExit));
        isFail = true;
      }
      final imageStream = streams.firstWhere(
        (stream) =>
            double.parse(stream.getAllProperties()?['duration'] ?? 0.0) < 1,
      );

      imageObj['aswidth'] = imageStream.getWidth();
      imageObj['asheight'] = imageStream.getHeight();
      imageObj['width'] = imageStream.getWidth();
      imageObj['height'] = imageStream.getHeight();
    }

    Size fileSize = getResolutionSize(
      imageObj['width'],
      imageObj['height'],
      imageObj['resolution'] ?? MediaResolution.image_standard.minSize,
    );
    imageObj['width'] = fileSize.width.toInt();
    imageObj['height'] = fileSize.height.toInt();

    final String? compressedPath = await imageMgr.compressImage(
      f.path,
      imageObj['width'],
      imageObj['height'],
    );

    if (compressedPath == null) {
      isFail = true;
      return isFail;
    }

    imageObj['size'] = File(compressedPath).lengthSync();
    imageObj['filePath'] = compressedPath;
    imageObj['fileName'] = getFileNameWithExtension(compressedPath);

    if (chat?.isSingle ?? false) {
      final userIdx = objectMgr.userMgr.allUsers.indexWhere(
        (element) => element.uid == chat!.friend_id,
      );
      if (userIdx == -1 ||
          objectMgr.userMgr.allUsers[userIdx].relationship ==
              Relationship.stranger) {
        imageObj['error_code'] = ErrorCodeConstant.STATUS_NOT_IN_CHAT;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blocked) {
        imageObj['error_code'] = ErrorCodeConstant.STATUS_USER_ME_IN_BLACKLIST;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blockByTarget) {
        imageObj['error_code'] = ErrorCodeConstant.STATUS_USER_HE_IN_BLACKLIST;
        isFail = true;
      }
    }

    message.content = jsonEncode(imageObj);
    _event(message);

    if (isFail) return isFail;

    //资源处理需要串行
    await _resProcessLock.synchronized(() async {
      try {
        final Chat? chat = objectMgr.chatMgr.getChatById(message.chat_id);
        if (chat != null) {
          objectMgr.chatMgr.chatInput(
            chat.isGroup ? 0 : chat.friend_id,
            ChatInputState.sendImage,
            message.chat_id,
          );
        }

        CancelToken cancelToken = CancelToken();

        cancelToken.whenCancel.then((value) {
          _resProcessLock.cancel();
          isFail = true;
          return isFail;
        });

        void stateListener(_, __, ___) {
          if (message.isSendFail) {
            cancelToken.cancel('User cancel');
            message.off(Message.eventSendState, stateListener);
          }
        }

        message.on(Message.eventSendState, stateListener);

        final String? imageUrl = await imageMgr.upload(
          compressedPath,
          imageObj['width'],
          imageObj['height'],
          cancelToken: cancelToken,
          onGaussianComplete: (String gausPath) {
            imageObj['gausPath'] = gausPath;
          },
          onSendProgress: (int bytes, int total) {
            if (message.sendState == MESSAGE_SEND_FAIL) {
              isFail = true;
              cancelToken.cancel('Network Interruption.');
            }

            if (total > 0) {
              message.totalSize = total;
              message.uploadProgress = max(
                message.uploadProgress,
                double.parse((min(bytes, total) / total).toStringAsFixed(2))
                    .clamp(0.0, 0.95),
              );
            }
          },
        );

        if (notBlank(imageUrl) && message.sendState != MESSAGE_SEND_FAIL) {
          message.uploadProgress = 1.0;
          imageObj['url'] = imageUrl;
          message.content = jsonEncode(imageObj);
          isFail = false;
        } else {
          isFail = true;
        }
      } catch (e) {
        isFail = true;
      }
    });

    return isFail;
  }

  Future<bool> _doVideoSend(Message message, {Chat? chat}) async {
    bool isFail = false;
    File? f;
    final Map<String, dynamic> videoObj = jsonDecode(message.content);

    videoObj['sendTime'] = message.send_time;

    if (message.asset is AssetEntity) {
      AssetEntity entity = message.asset;

      f = await entity.originFile;

      videoObj['aswidth'] = entity.orientatedWidth;
      videoObj['asheight'] = entity.orientatedHeight;

      if (videoObj['asheight'] == 0 || videoObj['aswidth'] == 0) {
        MediaInformationSession infoSession =
            await FFprobeKit.getMediaInformation(f!.path);
        MediaInformation? mediaInformation = infoSession.getMediaInformation();

        final List<StreamInformation> streams =
            mediaInformation?.getStreams() ?? [];
        if (streams.isEmpty) {
          Toast.showToast(localized(toastVideoNotExit));
          isFail = true;
        }

        final videoStream =
            streams.firstWhere((stream) => stream.getType() == 'video');

        videoObj['aswidth'] = videoStream.getWidth();
        videoObj['asheight'] = videoStream.getHeight();
      }

      videoObj['filePath'] = f!.path;
      videoObj['asid'] = entity.id;
      videoObj['astypeint'] = entity.typeInt;
      videoObj['width'] = videoObj['aswidth'];
      videoObj['height'] = videoObj['asheight'];
    } else if (message.asset is File) {
      f = message.asset as File;
      videoObj['filePath'] = f.path;
    }
    videoObj['fileName'] = getFileNameWithExtension(f!.path);

    Size videoSize = getResolutionSize(
      videoObj['width'],
      videoObj['height'],
      videoObj['resolution'] ?? MediaResolution.video_standard.minSize,
    );

    videoObj['width'] = videoSize.width.toInt();
    videoObj['height'] = videoSize.height.toInt();

    if (f == null || !f.existsSync()) {
      isFail = true;
    }

    // 初始化 cover
    String? videoCover;
    if (videoObj['coverPath'] != null &&
        File(videoObj['coverPath']).existsSync()) {
      videoCover = videoObj['coverPath'];
    }

    if (Platform.isMacOS) {
      videoCover ??= await videoMgr.genMacOSVideoCover(
        f.path,
        videoObj['width'],
        videoObj['height'],
        entity: message.asset,
      );
    } else {
      videoCover ??= await videoMgr.genVideoCover(
        f.path,
        videoObj['width'],
        videoObj['height'],
        entity: message.asset,
      );
    }

    videoObj['coverPath'] = videoCover;

    if (chat?.isSingle ?? false) {
      final userIdx = objectMgr.userMgr.allUsers.indexWhere(
        (element) => element.uid == chat!.friend_id,
      );
      if (userIdx == -1 ||
          objectMgr.userMgr.allUsers[userIdx].relationship ==
              Relationship.stranger) {
        videoObj['error_code'] = ErrorCodeConstant.STATUS_NOT_IN_CHAT;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blocked) {
        videoObj['error_code'] = ErrorCodeConstant.STATUS_USER_ME_IN_BLACKLIST;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blockByTarget) {
        videoObj['error_code'] = ErrorCodeConstant.STATUS_USER_HE_IN_BLACKLIST;
        isFail = true;
      }
    }

    message.content = jsonEncode(videoObj);
    message.uploadStatus = 1;
    _event(message);

    if (isFail) return isFail;

    //资源处理需要串行
    await _resProcessLock.synchronized(() async {
      try {
        final Chat? chat = objectMgr.chatMgr.getChatById(message.chat_id);
        if (chat != null) {
          objectMgr.chatMgr.chatInput(
            chat.isGroup ? 0 : chat.friend_id,
            ChatInputState.sendVideo,
            message.chat_id,
          );
        }

        bool showOriginal = false;
        CancelToken cancelToken = CancelToken();

        cancelToken.whenCancel.then((value) {
          _resProcessLock.cancel();
          isFail = true;
          return isFail;
        });

        void stateListener(_, __, ___) {
          if (message.isSendFail) {
            cancelToken.cancel('User cancel');
            message.off(Message.eventSendState, stateListener);
          }
        }

        message.on(Message.eventSendState, stateListener);

        final String? coverThumbnail = await imageMgr.upload(
          videoObj['coverPath'],
          videoObj['width'],
          videoObj['height'],
          onGaussianComplete: (String gausPath) {
            videoObj['gausPath'] = gausPath;
          },
          cancelToken: cancelToken,
        );

        final (String path, String sourcePath) = await videoMgr.upload(
          f!.path,
          accurateWidth: videoObj['width'],
          accurateHeight: videoObj['height'],
          showOriginal: showOriginal,
          cancelToken: cancelToken,
          onCompressProgress: (double progress) {
            if (message.sendState == MESSAGE_SEND_FAIL) {
              isFail = true;
              cancelToken.cancel('User cancel');
            }

            if (message.uploadStatus <= 2) {
              message.uploadStatus = 2;
            }
          },
          onCompressCallback: (String path) {
            if (message.uploadStatus <= 2) {
              message.uploadStatus = 2;
              objectMgr.chatMgr.saveMessage(message);
            }
            message.totalSize = File(path).lengthSync();
            videoObj['filePath'] = path;
            videoObj['size'] = message.totalSize;
            message.content = jsonEncode(videoObj);
            objectMgr.chatMgr.saveMessage(message);
          },
          onStatusChange: (int status) {
            if (message.sendState == MESSAGE_SEND_FAIL) {
              isFail = true;
              cancelToken.cancel('User cancel');
            }

            if (message.uploadStatus <= 2) {
              message.uploadStatus = status;
            }
          },
          onSendProgress: (int bytes, int total) {
            if (message.sendState != MESSAGE_SEND_ING) {
              isFail = true;
              cancelToken.cancel('User cancel');
            }

            if (total > 0) {
              if (message.uploadStatus <= 3) {
                message.uploadStatus = 3;
                message.totalSize = total;
                message.uploadProgress = max(
                  message.uploadProgress,
                  double.parse((min(bytes, total) / total).toStringAsFixed(2))
                      .clamp(0.0, 0.95),
                );
              }
            }
          },
        );

        if (notBlank(path) &&
            notBlank(coverThumbnail) &&
            message.sendState != MESSAGE_SEND_FAIL) {
          message.uploadProgress = 1.0;
          message.uploadStatus = 4;
          await Future.delayed(const Duration(seconds: 1));
          videoObj['url'] = path;
          videoObj['cover'] = coverThumbnail;
          videoObj['source'] = sourcePath;
          message.content = jsonEncode(videoObj);
          isFail = false;
        } else {
          message.uploadStatus = 0;
          isFail = true;
        }
      } catch (e, s) {
        pdebug(e, stackTrace: s);
        message.uploadStatus = 0;
        isFail = true;
      }
    });

    return isFail;
  }

  Future<bool> _doFileSend(Message message, dynamic data, {Chat? chat}) async {
    var fileObj = jsonDecode(message.content);

    fileObj['sendTime'] = message.send_time;

    message.asset = data;
    bool isFail = false;

    fileObj['size'] = data.lengthSync();
    fileObj['filePath'] = data.path;

    if (chat?.isSingle ?? false) {
      final userIdx = objectMgr.userMgr.allUsers.indexWhere(
        (element) => element.uid == chat!.friend_id,
      );
      if (userIdx == -1 ||
          objectMgr.userMgr.allUsers[userIdx].relationship ==
              Relationship.stranger) {
        fileObj['error_code'] = ErrorCodeConstant.STATUS_NOT_IN_CHAT;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blocked) {
        fileObj['error_code'] = ErrorCodeConstant.STATUS_USER_ME_IN_BLACKLIST;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blockByTarget) {
        fileObj['error_code'] = ErrorCodeConstant.STATUS_USER_HE_IN_BLACKLIST;
        isFail = true;
      }
    }
    message.content = jsonEncode(fileObj);
    _event(message);

    if (isFail) return isFail;

    //资源处理需要串行
    await _resProcessLock.synchronized(() async {
      try {
        final Chat? chat = objectMgr.chatMgr.getChatById(message.chat_id);
        if (chat != null) {
          objectMgr.chatMgr.chatInput(
            chat.isGroup ? 0 : chat.friend_id,
            ChatInputState.sendDocument,
            message.chat_id,
          );
        }

        CancelToken cancelToken = CancelToken();
        bool shouldUploadCover = false;
        String coverPath = '';

        cancelToken.whenCancel.then((value) {
          _resProcessLock.cancel();
          return true;
        });

        void stateListener(_, __, ___) {
          if (message.isSendFail) {
            cancelToken.cancel('User cancel');
            message.off(Message.eventSendState, stateListener);
          }
        }

        message.on(Message.eventSendState, stateListener);

        final String? fileUrl = await documentMgr.upload(
          data.path,
          onSendProgress: (int bytes, int total) {
            if (message.sendState == MESSAGE_SEND_FAIL) {
              isFail = true;
              cancelToken.cancel('Network Interruption.');
            }

            if (total > 0) {
              message.totalSize = total;
              message.uploadProgress = max(
                message.uploadProgress,
                0.95 *
                    double.parse((min(bytes, total) / total).toStringAsFixed(2))
                        .clamp(0.0, 1.0),
              );
            }
          },
          onFileCoverGenerated:
              (String cover, bool isEncrypt, FileType type) async {
            if (cover.isNotEmpty) {
              shouldUploadCover = true;
              coverPath = cover;
            }

            if (type == FileType.video && fileObj['asset_id'] != null) {
              AssetEntity? entity =
                  await AssetEntity.fromId(fileObj['asset_id']);
              if (entity != null) {
                File? assetFile = await entity.originFile;
                if (assetFile != null) {
                  File coverF = File(
                    await downloadMgr.getTmpCachePath(
                      '${DateTime.now().millisecondsSinceEpoch}.jpeg',
                    ),
                  );
                  coverF.createSync(recursive: true);
                  coverF.writeAsBytesSync(
                    (await entity.thumbnailDataWithSize(
                      ThumbnailSize(entity.width, entity.height),
                      format: ThumbnailFormat.jpeg,
                      quality: 80,
                    ))!,
                  );

                  coverPath = coverF.path;
                  shouldUploadCover = true;
                }
              }
            }

            fileObj['isEncrypt'] = isEncrypt ? 1 : 0;
          },
          cancelToken: cancelToken,
        );

        if (shouldUploadCover) {
          if (fileObj['width'] == null || fileObj['height'] == null) {
            MediaInformationSession infoSession =
                await FFprobeKit.getMediaInformation(coverPath);
            MediaInformation? mediaInformation =
                infoSession.getMediaInformation();

            final List<StreamInformation> streams =
                mediaInformation?.getStreams() ?? [];
            if (streams.isNotEmpty) {
              final videoStream =
                  streams.firstWhere((stream) => stream.getType() == 'video');

              fileObj['width'] = videoStream.getWidth();
              fileObj['height'] = videoStream.getHeight();
            }
          }

          if (fileObj['width'] != null && fileObj['height'] != null) {
            String? compressedFile = await imageMgr.compressImage(
              coverPath,
              fileObj['width'] ?? 0,
              fileObj['height'] ?? 0,
            );

            if (compressedFile != null) {
              String? uploadedCover = await imageMgr.upload(
                compressedFile,
                fileObj['width'] ?? 0,
                fileObj['height'] ?? 0,
                cancelToken: cancelToken,
                onGaussianComplete: (String gausPath) {
                  fileObj['gausPath'] = gausPath;
                },
                onSendProgress: (int bytes, int total) {
                  if (message.sendState == MESSAGE_SEND_FAIL) {
                    isFail = true;
                    cancelToken.cancel('Network Interruption.');
                  }

                  if (total > 0) {
                    message.uploadProgress = max(
                      message.uploadProgress,
                      0.95 +
                          (0.05 *
                              double.parse((min(bytes, total) / total)
                                      .toStringAsFixed(2))
                                  .clamp(0.0, 1.0)),
                    );
                  }
                },
              );

              fileObj['cover'] = uploadedCover;
            }
          }
        }

        if (notBlank(fileUrl)) {
          fileObj['url'] = fileUrl;
          message.content = jsonEncode(fileObj);
          message.event(message, Message.eventSendState, data: message.content);
          isFail = false;
        } else {
          isFail = true;
        }
      } catch (e) {
        isFail = true;
      }
    });

    return isFail;
  }

  Future<bool> _doVoiceSend(Message message, dynamic data, {Chat? chat}) async {
    final imageObj = jsonDecode(message.content);

    imageObj['sendTime'] = message.send_time;

    bool isFail = false;
    message.asset = data;

    //语音
    imageObj['vmpath'] = data.path;
    imageObj['decibels'] = data.decibels;

    if (chat?.isSingle ?? false) {
      final userIdx = objectMgr.userMgr.allUsers.indexWhere(
        (element) => element.uid == chat!.friend_id,
      );
      if (userIdx == -1 ||
          objectMgr.userMgr.allUsers[userIdx].relationship ==
              Relationship.stranger) {
        imageObj['error_code'] = ErrorCodeConstant.STATUS_NOT_IN_CHAT;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blocked) {
        imageObj['error_code'] = ErrorCodeConstant.STATUS_USER_ME_IN_BLACKLIST;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blockByTarget) {
        imageObj['error_code'] = ErrorCodeConstant.STATUS_USER_HE_IN_BLACKLIST;
        isFail = true;
      }
    }

    message.content = jsonEncode(imageObj);
    _event(message);

    if (isFail) return isFail;

    try {
      final Chat? chat = objectMgr.chatMgr.getChatById(message.chat_id);
      if (chat != null) {
        objectMgr.chatMgr.chatInput(
          chat.isGroup ? 0 : chat.friend_id,
          ChatInputState.sendVoice,
          message.chat_id,
        );
      }

      var vFile = File(data.path);
      if (vFile.existsSync()) {
        CancelToken cancelToken = CancelToken();

        void stateListener(_, __, ___) {
          if (message.isSendFail) {
            cancelToken.cancel('User cancel');
            message.off(Message.eventSendState, stateListener);
          }
        }

        message.on(Message.eventSendState, stateListener);

        final String? audioUrl = await documentMgr.upload(
          data.path,
          cancelToken: cancelToken,
          onSendProgress: (int bytes, int total) {
            if (message.sendState == MESSAGE_SEND_FAIL) {
              isFail = true;
              cancelToken.cancel('Network Interruption.');
            }

            if (total > 0) {
              message.totalSize = total;
              message.uploadProgress = max(
                message.uploadProgress,
                double.parse((min(bytes, total) / total).toStringAsFixed(2))
                    .clamp(0.0, 1.0),
              );
            }
          },
        );

        if (notBlank(audioUrl)) {
          imageObj['url'] = audioUrl;
        } else {
          isFail = true;

          //失败 把文件保存到本地
          String fname = data.path.substring(data.path.lastIndexOf("/"));
          String path = downloadMgr.appDocumentRootPath + fname;
          var vFileSave = File(path);
          if (!vFileSave.existsSync()) {
            vFileSave.createSync(recursive: true);
            var vBytes = vFile.readAsBytesSync();
            await vFileSave.writeAsBytes(vBytes);
          }
          imageObj['vmpath'] = data.path;
          imageObj['vmpath1'] = path;
        }

        message.content = jsonEncode(imageObj);
      } else {
        Toast.showToast(localized(chatFileCorrupt));
        isFail = true;
      }
    } catch (e) {
      isFail = true;
    }

    return isFail;
  }

  Future<bool> _doLocationSend(Message message, {Chat? chat}) async {
    bool isFail = false;
    File? f;
    var locationObj = jsonDecode(message.content);
    locationObj['sendTime'] = message.send_time;

    if (message.asset is File) {
      f = message.asset as File;
      locationObj['filePath'] = f.path;
    } else {
      return true;
    }

    locationObj['fileName'] = getFileNameWithExtension(f.path);
    locationObj['size'] = f.lengthSync();

    if (chat?.isSingle ?? false) {
      final userIdx = objectMgr.userMgr.allUsers.indexWhere(
        (element) => element.uid == chat!.friend_id,
      );
      if (userIdx == -1 ||
          objectMgr.userMgr.allUsers[userIdx].relationship ==
              Relationship.stranger) {
        locationObj['error_code'] = ErrorCodeConstant.STATUS_NOT_IN_CHAT;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blocked) {
        locationObj['error_code'] =
            ErrorCodeConstant.STATUS_USER_ME_IN_BLACKLIST;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blockByTarget) {
        locationObj['error_code'] =
            ErrorCodeConstant.STATUS_USER_HE_IN_BLACKLIST;
        isFail = true;
      }
    }

    message.content = jsonEncode(locationObj);
    _event(message);

    if (isFail) return isFail;

    //资源处理需要串行
    await _resProcessLock.synchronized(() async {
      try {
        if (!f!.existsSync()) {
          Toast.showToast(localized(toastPhotoNotExist));
          isFail = true;
        } else {
          CancelToken cancelToken = CancelToken();

          cancelToken.whenCancel.then((value) {
            _resProcessLock.cancel();
            return true;
          });

          final String? imageUrl = await imageMgr.upload(
            f.path,
            0,
            0,
            cancelToken: cancelToken,
            onGaussianComplete: (String gausPath) {
              locationObj['gausPath'] = gausPath;
            },
            onSendProgress: (int bytes, int total) {
              if (message.sendState == MESSAGE_SEND_FAIL) {
                isFail = true;
                cancelToken.cancel('Network Interruption.');
              }

              if (total > 0) {
                message.totalSize = total;
                message.uploadProgress = double.parse(
                  (min(bytes, total) / total).toStringAsFixed(2),
                );
              }
            },
          );

          if (notBlank(imageUrl)) {
            locationObj['url'] = imageUrl;
            locationObj['uuid'] = f.hashCode;
            locationObj['sendTime'] = message.send_time;
            message.content = jsonEncode(locationObj);
            isFail = false;
          } else {
            isFail = true;
          }
        }
      } catch (e) {
        isFail = true;
      }
    });
    return isFail;
  }

  Future<bool> _doLinkSend(Message message, dynamic data, {Chat? chat}) async {
    final content = jsonDecode(message.content);
    bool isFail = false;

    if (chat?.isSingle ?? false) {
      final userIdx = objectMgr.userMgr.allUsers.indexWhere(
        (element) => element.uid == chat!.friend_id,
      );
      if (userIdx == -1 ||
          objectMgr.userMgr.allUsers[userIdx].relationship ==
              Relationship.stranger) {
        content['error_code'] = ErrorCodeConstant.STATUS_NOT_IN_CHAT;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blocked) {
        content['error_code'] = ErrorCodeConstant.STATUS_USER_ME_IN_BLACKLIST;
        isFail = true;
      } else if (objectMgr.userMgr.allUsers[userIdx].relationship ==
          Relationship.blockByTarget) {
        content['error_code'] = ErrorCodeConstant.STATUS_USER_HE_IN_BLACKLIST;
        isFail = true;
      }
    }

    _event(message);
    if (isFail) return isFail;
    if (data is! File) return false;

    final metadata = Metadata.fromJson(content['link_metadata']);

    if (metadata.imageWidth == null && metadata.imageHeight == null) {
      metadata.image = null;
      content['link_metadata'] = metadata.toJson();
      message.content = jsonEncode(content);
      return false;
    }

    Size fileSize = getResolutionSize(
      int.parse(metadata.imageWidth ?? '384'),
      int.parse(metadata.imageHeight ?? '384'),
      MediaResolution.image_standard.minSize,
    );

    CancelToken cancelToken = CancelToken();

    try {
      final String? imageUrl = await imageMgr.upload(
        data.path,
        fileSize.width.toInt(),
        fileSize.height.toInt(),
        cancelToken: cancelToken,
        onGaussianComplete: (String gausPath) {
          content['link_image_src_gaussian'] = gausPath;
        },
        onSendProgress: (int bytes, int total) {
          if (message.sendState == MESSAGE_SEND_FAIL) {
            isFail = true;
            cancelToken.cancel('Network Interruption.');
          }
        },
      );
      if (notBlank(imageUrl) && message.sendState != MESSAGE_SEND_FAIL) {
        content['link_image_src'] = imageUrl;
        message.content = jsonEncode(content);
        return false;
      }

      return true;
    } catch (e) {
      return true;
    }
  }

  Future<bool> _doMediaGausProcess(Message message) async {
    if (message.isMediaType) {
      final List<Map<String, dynamic>> assetList = <Map<String, dynamic>>[];
      // 生成缩略图
      switch (message.typ) {
        case messageTypeImage:
          final MessageImage msgImg = message.decodeContent(
            cl: MessageImage.creator,
          );
          if (msgImg.url.isEmpty || msgImg.gausPath.isNotEmpty) break;
          assetList.add({
            'url': msgImg.url,
            'width': msgImg.width,
            'height': msgImg.height,
          });
          break;
        case messageTypeVideo:
        case messageTypeReel:
          final MessageVideo msgVideo = message.decodeContent(
            cl: MessageVideo.creator,
          );
          if (msgVideo.cover.isEmpty || msgVideo.gausPath.isNotEmpty) break;
          assetList.add({
            'url': msgVideo.cover,
            'width': msgVideo.width,
            'height': msgVideo.height,
          });
          break;
        case messageTypeNewAlbum:
          final NewMessageMedia msgMedia = message.decodeContent(
            cl: NewMessageMedia.creator,
          );

          for (final album in msgMedia.albumList!) {
            final url = album.isVideo ? album.cover : album.url;
            if (url.isEmpty || album.gausPath.isNotEmpty) continue;

            assetList.add({
              'url': url,
              'width': album.aswidth,
              'height': album.asheight,
            });
          }
          break;
        default:
          break;
      }

      for (final assetInfo in assetList) {
        // 检查url的文件是否存在
        String? localPath = downloadMgrV2.getLocalPath(assetInfo['url']);
        // 不存在就下载
        DownloadResult result = await downloadMgrV2.download(
          assetInfo['url'],
          mini: Config().messageMin,
        );
        localPath = result.localPath;
        // localPath ??= await downloadMgr.downloadFile(
        //   assetInfo['url'],
        //   mini: Config().messageMin,
        // );

        if (localPath == null || !File(localPath).existsSync()) {
          return true;
        }

        final String? gausImagePath = await imageMgr.genBlurHashFFi(localPath);
        final Map<String, dynamic> content = jsonDecode(message.content);
        content['gausPath'] = gausImagePath;

        message.content = jsonEncode(content);
      }
    }

    return true;
  }

  //触发
  void _event(Message obj) {
    objectMgr.chatMgr.saveMessage(obj);
    if (obj.isInvisibleMsg) {
      return;
    }
    objectMgr.chatMgr
        .event(objectMgr.chatMgr, ChatMgr.eventMessageSend, data: obj);
    updateLasMessage(obj);
  }

  //重新发送
  void onResend(Message message, {bool isAuto = false}) async {
    /// 这个是删除假消息的
    await objectMgr.chatMgr.localDelMessage(message);

    Message obj = Message()..init(message.toJson());
    int sendTime = DateTime.now().millisecondsSinceEpoch;
    if (isAuto) {
      sendTime = obj.send_time;
    }
    // 重新发送的消息，发送时间需要用重新发送那一刻的
    List<int>? receivers;
    obj.sendState = MESSAGE_SEND_ING;
    //Future.delayed(const Duration(milliseconds: 300), () async {
    dynamic data;
    if (obj.typ == messageTypeImage || obj.typ == messageTypeVideo) {
      data = _createAssetEntity(obj.content);

      final Map<String, dynamic> videoObj = jsonDecode(obj.content);
      data ??= File(videoObj['filePath']);

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
      if (imageObj['vmpath'] != null) {
        data = VolumeModel(
          path: imageObj['vmpath'],
          second: imageObj['second'],
          decibels:
              imageObj['decibels'].map<double>((e) => e as double).toList(),
        );
      }
    } else if (obj.typ == messageTypeFile) {
      final fileObj = jsonDecode(obj.content);
      if (fileObj['filePath'] != null) data = File(fileObj['filePath']);
    } else if (obj.typ == messageTypeLocation) {
      final locationObj = jsonDecode(obj.content);
      if (locationObj['filePath'] != null) data = File(locationObj['filePath']);
    } else if (obj.typ == messageTypeCommandFileOperate) {
      final cmdOpt = jsonDecode(obj.content);
      if (cmdOpt['uid'] != null) {
        receivers = [cmdOpt['uid'], objectMgr.userMgr.mainUser.uid];
      }
    }

    /// 添加 相册重试

    /// 删除之前的假消息
    _onMessageSent(obj);

    await send(obj.chat_id, obj.typ, obj.content,
        data: data,
        isReSend: true,
        sendTime: sendTime,
        cmid: obj.cmid,
        receivers: receivers,
        chat_idx: obj.chat_idx);
    //});
  }

  dynamic _createAssetEntity(String ss) {
    var imageObj = jsonDecode(ss);
    if (imageObj['asid'] != null &&
        imageObj['astypeint'] != null &&
        imageObj['aswidth'] != null &&
        imageObj['asheight'] != null) {
      return AssetEntity(
        id: imageObj['asid'],
        typeInt: imageObj['astypeint'],
        width: imageObj['aswidth'],
        height: imageObj['asheight'],
      );
    } else if (imageObj['fpath'] != null) {
      return File(imageObj['fpath']);
    }
    return null;
  }

  //删除假数据 会话id、信息id
  Future<void> _onMessageSent(Message obj) async {
    Chat? chat = objectMgr.chatMgr.getChatById(obj.chat_id);
    if (chat != null &&
        obj.typ != messageCancelCall &&
        obj.typ != messageRejectCall) {
    }
  }

  void remove(Message obj) {
    _onMessageSent(obj);
  }

  // void cleanUp() {
  //   _resProcessLock = Lock();
  //   _msgProcessLock = Lock();
  //   _msgSendTimeLock = Lock();
  //   lastSendTime = 0;
  // }
}

/// 消息发送
abstract mixin class ChatSend {
  /// 发送消息
  Future<ResponseData> send(
    int chatID,
    int type,
    String content, {
    bool noUnread = false,
    dynamic data,
    String atUser = '',
    List<int>? receivers,
  }) async {
    return objectMgr.chatMgr.mySendMgr.send(
      chatID,
      type,
      content,
      noUnread: noUnread,
      data: data,
      atUser: atUser,
      receivers: receivers,
    );
  }

  /// 发送消息 (文本)
  Future<ResponseData> sendText(
    int chatID,
    String content, {
    String atUser = '',
    String? reply,
    String? translation,
  }) async {
    final dict = <String, dynamic>{};
    dict['text'] = content;
    var typ = messageTypeText;
    if (reply != null) {
      dict['reply'] = reply;
      typ = messageTypeReply;
    }

    if (translation != null) {
      dict['translation'] = translation;
    }
    return await send(
      chatID,
      typ,
      jsonEncode(dict),
      atUser: atUser,
    );
  }

  /// 发送消息 (链接)
  Future<ResponseData> sendLinkText(
    int chatID,
    String content, {
    Metadata? linkPreviewData,
    String atUser = '',
    String? reply,
    String? translation,
  }) async {
    final dict = <String, dynamic>{};
    dict['text'] = content;
    if (reply != null) {
      dict['reply'] = reply;
    }
    if (translation != null) {
      dict['translation'] = translation;
    }

    File? imageFile;
    if (linkPreviewData != null &&
        notBlank(linkPreviewData.image) &&
        linkPreviewData.image!.startsWith('http')) {
      final savePath = downloadMgrV2.getLocalPath(linkPreviewData.image!) ?? '';
      imageFile = File(savePath);
      bool fileExist = imageFile.existsSync();
      if (fileExist &&
          (linkPreviewData.imageHeight == null ||
              linkPreviewData.imageWidth == null)) {
        try {
          final imageSize = await getImageFromAsset(imageFile);
          if (notBlank(imageSize)) {
            linkPreviewData.imageHeight = imageSize['height'].toString();
            linkPreviewData.imageWidth = imageSize['width'].toString();
          }
        } catch (e) {
          fileExist = false;
        }
      }

      if (!fileExist) {
        linkPreviewData.image = null;
        linkPreviewData.imageWidth = null;
        linkPreviewData.imageHeight = null;
        linkPreviewData.video = null;
        linkPreviewData.videoWidth = null;
        linkPreviewData.videoHeight = null;
      }
    }

    if (linkPreviewData != null) {
      dict['link_metadata'] = linkPreviewData.toJson();
    }

    return await send(
      chatID,
      messageTypeLink,
      jsonEncode(dict),
      atUser: atUser,
      data: imageFile,
    );
  }

  /// 管家系统链接分享
  Future<ResponseData> sendHousekeepingSysShareLink(
      int chatID,
      ShareItem item) async {
    Map<String, dynamic> dict = {};
    dict['text'] = item.miniAppLink;
    dict["mini_app_avatar"] = item.miniAppAvatar;
    dict["mini_app_picture"] = item.miniAppPicture;
    dict["mini_app_picture_gaussian"] = item.miniAppPictureGaussian;
    dict["mini_app_name"] = item.miniAppName;
    dict["mini_app_title"] = item.miniAppTitle;
    var typ = messageTypeShareChat;
    return await send(
      chatID,
      typ,
      jsonEncode(dict),
      atUser: "",
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
      Map<String, dynamic> map = jsonDecode(message.content);
      Map<String, dynamic> newMap = {};

      final Chat? toChat = objectMgr.chatMgr.getChatById(chatID);

      if (typ == messageTypeText) {
        newMap['text'] = text!;
      } else {
        newMap = map;
      }

      bool needTranslate = false;
      if (map['translation'] != null && map['translation'] != '') {
        newMap['translation'] = map['translation'];
        TranslationModel? translationModel = message.getTranslationModel();
        if (translationModel != null &&
            toChat != null &&
            toChat.isAutoTranslateOutgoing) {
          if (translationModel.currentLocale != toChat.currentLocaleOutgoing) {
            needTranslate = true;
          }
        }
      } else {
        if (toChat != null && toChat.isAutoTranslateOutgoing) {
          needTranslate = true;
        }
      }

      if (needTranslate && toChat != null) {
        String original = message.messageContent;
        if (!EmojiParser.hasOnlyEmojis(original)) {
          String locale = toChat.currentLocaleOutgoing == 'auto'
              ? getAutoLocale(chat: toChat, isMe: true)
              : toChat.currentLocaleOutgoing;
          final res = await objectMgr.chatMgr
              .getMessageTranslation(original, locale: locale);
          if (res['translation'] != '') {
            TranslationModel translationModel = TranslationModel();
            translationModel.translation = {locale: res['translation']};
            translationModel.showTranslation = true;
            translationModel.currentLocale = locale;
            translationModel.visualType = toChat.visualTypeOutgoing;
            newMap['translation'] = jsonEncode(translationModel);
          }
        }
      }

      if (map['forward_user_id'] != null && map['forward_user_id'] != 0) {
        newMap['forward_user_id'] = map['forward_user_id'];
        newMap['forward_user_name'] = map['forward_user_name'];

        return await send(
          chatID,
          typ,
          jsonEncode(newMap),
        );
      } else {
        final User? user =
            await objectMgr.userMgr.loadUserById(message.send_id);
        final Chat? chat = objectMgr.chatMgr.getChatById(message.chat_id);
        if (chat != null) {
          if (chat.typ == chatTypeSmallSecretary) {
            newMap['forward_user_id'] = isSecretary;
            newMap['forward_user_name'] = 'Secretary';
          } else if (chat.typ == chatTypeSystem) {
            newMap['forward_user_id'] = isSystem;
            newMap['forward_user_name'] = 'System';
          } else {
            if (user != null) {
              newMap['forward_user_id'] = user.uid;
              newMap['forward_user_name'] = user.nickname;
            }
          }
        } else {
          if (user != null) {
            if (user.uid != 0) {
              newMap['forward_user_id'] = user.uid;
              newMap['forward_user_name'] = user.nickname;
            }
          }
        }

        return await send(
          chatID,
          typ,
          jsonEncode(newMap),
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
    String? translation,
    String atUser = '',
  }) async {
    return await send(
      chatID,
      messageTypeNewAlbum,
      jsonEncode({
        'chat_id': chatID,
        'caption': caption,
        'reply': reply,
        'translation': translation,
      }),
      data: assets,
      atUser: atUser,
    );
  }

  /// 发送消息 (图片)
  void sendImage({
    required int chatID,
    required int width,
    required int height,
    String? caption,
    MediaResolution resolution = MediaResolution.image_standard,
    String? reply,
    dynamic data,
    String atUser = '',
    String translation = '',
  }) async {
    send(
      chatID,
      messageTypeImage,
      jsonEncode({
        'caption': caption,
        'resolution': resolution.minSize,
        'reply': reply,
        'width': width,
        'height': height,
        'translation': translation,
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
    MediaResolution resolution = MediaResolution.video_standard,
    dynamic data,
    String? caption,
    String? reply,
    String atUser = '',
    String translation = '',
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
        'resolution': resolution.minSize,
        'reply': reply,
        'translation': translation,
      }),
      data: data,
      atUser: atUser,
    );
  }

  /// 发送贴纸
  Future<ResponseData> sendStickers({
    required int chatID,
    required Sticker sticker,
    String? reply,
    dynamic data,
  }) async {
    return await send(
      chatID,
      messageTypeFace,
      jsonEncode({
        'url': sticker.url,
        'reply': reply,
        'sticker': {
          'id': sticker.id,
          'collection_id': sticker.collectionId,
          'creator_id': sticker.creatorId,
        },
      }),
      data: data,
    );
  }

  /// 发送gif
  Future<ResponseData> sendGif({
    required int chatID,
    required String name,
    required int width,
    required int height,
    String? reply,
    dynamic data,
  }) async {
    return await send(
      chatID,
      messageTypeGif,
      jsonEncode({
        'url': name,
        'width': width,
        'height': height,
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

  Future<ResponseData> sendFileOperate({
    required int chatID,
    required int messageId,
    required int chatIdx,
    required int userId,
    List<int>? receivers,
  }) async {
    return await send(
      chatID,
      messageTypeCommandFileOperate,
      jsonEncode({
        'chat_id': chatID,
        'message_id': messageId,
        'chat_idx': chatIdx,
        'uid': userId,
      }),
      receivers: receivers,
    );
  }

  /// 发送消息 (文件)
  Future<ResponseData> sendFile({
    required int chatID,
    required int length,
    required String fileName,
    required String suffix,
    String? caption,
    String? reply,
    dynamic data,
    int? width,
    int? height,
    String translation = '',
    String? assetId,
  }) async {
    return await send(
      chatID,
      messageTypeFile,
      jsonEncode({
        'size': length,
        'width': width,
        'height': height,
        'file_name': fileName,
        'suffix': suffix,
        'caption': caption,
        'reply': reply,
        'translation': translation,
        'asset_id': assetId,
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
    String? reply,
    String? translation, {
    VolumeModel? data,
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
        'translation': translation,
        'isOperated': false,
      }),
      data: data,
    );
  }

  /// 发送消息 (推荐好友)
  Future<ResponseData> sendRecommendFriend(
    int chatID,
    int userId,
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
          'user_id': userId,
          'nick_name': nickName,
          'head': head,
          'country_code': countryCode,
          'contact': contact,
        },
      ),
    );
  }

  /// 发送消息 (好友链接)
  Future<ResponseData> sendFriendLink(
    int chatID,
    int userId,
    String nickName,
    String userProfile,
    String shortLink,
  ) async {
    return await send(
      chatID,
      messageTypeFriendLink,
      jsonEncode(
        {
          'user_id': userId,
          'nick_name': nickName,
          'user_profile': userProfile,
          'short_link': shortLink,
        },
      ),
    );
  }

  /// 发送消息 (群组链接)
  Future<ResponseData> sendGroupLink(
    int chatID,
    int userId,
    String nickName,
    int groupId,
    String groupName,
    String groupProfile,
    String shortLink,
  ) async {
    return await send(
      chatID,
      messageTypeGroupLink,
      jsonEncode(
        {
          'user_id': userId,
          'nick_name': nickName,
          'group_id': groupId,
          'group_name': groupName,
          'group_profile': groupProfile,
          'short_link': shortLink,
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
  Future<ResponseData> sendCustom(
    int chatID,
    String info, {
    bool noUnread = false,
  }) async {
    return await send(chatID, messageTypeCustom, info, noUnread: noUnread);
  }

  /// 发送自定义消息 (json字符串)
  Future<ResponseData> sendGroupCall(
    int chatID,
    String info, {
    bool noUnread = false,
  }) async {
    return await send(chatID, messageDiscussCall, info, noUnread: noUnread);
  }

  /// 发送自定义消息 (json字符串)
  Future<ResponseData> sendCloseGroupCall(
    int chatID,
    String info, {
    bool noUnread = false,
  }) async {
    return await send(
      chatID,
      messageCloseDiscussCall,
      info,
      noUnread: noUnread,
    );
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
      List<ReadUser> list = (rep.data["datas"] as List)
          .map(
            (e) => ReadUser()..applyJson(e),
          )
          .toList();
      lastId = rep.data["last_id"];
      onSuccess(list, lastId);
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
      List<Message> list = rep.data
          .map(
            (e) => Message()..init(e),
          )
          .toList();
      onSuccess(list);
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
      List<ReadUser> list = (rep.data["datas"] as List)
          .map(
            (e) => ReadUser()..applyJson(e),
          )
          .toList();
      lastId = rep.data["last_id"];
      onSuccess(list, lastId);
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
