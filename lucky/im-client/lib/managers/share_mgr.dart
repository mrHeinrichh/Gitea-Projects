import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/task/video/video_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_share.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/message/share_image.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/regular.dart';

class ShareMgr implements MgrInterface {
  final MethodChannel _channel = const MethodChannel('jxim/share.extent');

  ShareMgr() {
    _channel.setMethodCallHandler(handleNativeCallback);
  }

  Future<void> handleNativeCallback(MethodCall call) async {
    if (call.method == 'share_data_ready') {
      objectMgr.chatMgr.handleShareData();
    }
  }

  Future<ShareImage?> get getShareFilePath async {
    Map? _map = await _channel.invokeMethod('getShareFilePath');
    if (_map != null) {
      Map<String, dynamic> _muMap = {};
      for (var key in _map.keys) {
        _muMap[key.toString()] = _map[key];
      }
      return ShareImage.fromJson((_muMap));
    }
    return null;
  }

  Future<List<RecentFile>> get recentFilePaths async {
    List<RecentFile> files = [];
    final fileData = await _channel.invokeMethod('RecentFilePaths');
    if (fileData != null) {
      for (final data in fileData) {
        files.add(RecentFile(
            data["path"],
            data["name"],
            int.parse(data["dateAdded"]),
            data["type"],
            int.parse(data["size"])));
      }
    }
    return files;
  }

  Future<bool> get clearShare async {
    bool status = await _channel.invokeMethod('clearShare');
    return status;
  }

  Future<bool> get iosSwitchFullScreen async {
    bool status = await _channel.invokeMethod('switchFullScreen');
    return status;
  }

  Future<bool> get iosSwitchPortraitScreen async {
    bool status = await _channel.invokeMethod('switchPortraitScreen');
    return status;
  }

  Future<bool> get iosSwitchAllScreen async {
    bool status = await _channel.invokeMethod('switchAllScreen');
    return status;
  }

  Future<void> syncChatList(List<Chat> chats) async {
    if (Platform.isIOS) {
      List<ChatShare> chatListForShare = [];
      for (Chat chat in chats) {
        if (chat.isValid && !chat.isDeleteAccount) {
          ChatShare? chatShare;
          if (chat.isSingle) {
            User? user = objectMgr.userMgr.getUserById(chat.friend_id);
            if (user != null) {
              var nickName = objectMgr.userMgr.getUserTitle(user);
              chatShare = ChatShare(
                  chat.friend_id,
                  chat.id,
                  nickName,
                  shortNameFromNickName(nickName),
                  chatTypeSingle,
                  user.profilePicture);
            }
          } else if (chat.isGroup) {
            var displayName = "";
            var group = objectMgr.myGroupMgr.getGroupById(chat.id);
            if (group != null) {
              displayName = group.name;
            }
            if (displayName == "") {
              displayName = chat.name;
            }
            chatShare = ChatShare(chat.id, chat.id, displayName,
                shortNameFromNickName(displayName), chatTypeGroup, chat.icon);
          } else if (chat.isSaveMsg) {
            chatShare = ChatShare(chat.id, chat.id, chat.name,
                shortNameFromNickName(chat.name), chatTypeSaved, chat.icon);
          }
          if (chatShare != null) {
            if (chat.isSaveMsg) {
              chatListForShare.insert(0, chatShare);
            } else {
              chatListForShare.add(chatShare);
            }
          }
        }
      }

      _channel.invokeMethod(
          'syncChatList', {'chatList': jsonEncode(chatListForShare)});
    }
  }

  shareDataToChat(ShareImage shareData, {bool openChatRoom = true}) {
    Chat? chat = objectMgr.chatMgr.getChatById(shareData.chatId);
    if (chat != null && chat.isValid) {
      if ((chat.isSingle || chat.isSaveMsg) && openChatRoom) {
        if (!Get.isRegistered<SingleChatController>(tag: chat.id.toString())) {
          Routes.toChat(chat: chat);
        }
      } else if (chat.isGroup && openChatRoom) {
        if (!Get.isRegistered<GroupChatController>(tag: chat.id.toString())) {
          Routes.toChat(chat: chat);
        }
      }

      sendShare(chat, shareData.dataList, shareData.caption);
    } else {
      ImBottomToast(
        Routes.navigatorKey.currentContext!,
        title: localized(chatInfoPleaseTryAgainLater),
        icon: ImBottomNotifType.warning,
        duration: 3,
      );
    }
  }

  void sendShare(Chat chat, List<ShareItem> dataList, String caption) async {
    for (ShareItem shareItem in dataList) {
      if (notBlank(shareItem.imagePath)) {
        String _imagePath = generateValidPath(shareItem.imagePath);
        File imageFile = File(_imagePath);
        if (imageFile.existsSync()) {
          objectMgr.chatMgr.mySendMgr.send(
              chat.id,
              messageTypeImage,
              jsonEncode({
                'caption': caption,
                'reply': null,
                'width': shareItem.width.toInt(),
                'height': shareItem.height.toInt(),
                'showOriginal': true,
              }),
              data: _imagePath);
        }
      } else if (notBlank(shareItem.videoPath)) {
        final title = path.basename(shareItem.videoPath);
        String videoPath = generateValidPath(shareItem.videoPath);
        File videoFile = File(videoPath);

        File coverPath = await generateThumbnailWithPath(
          videoPath,
          savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          sub: 'cover',
        );

         objectMgr.chatMgr.mySendMgr.send(
            chat.id,
            messageTypeVideo,
            jsonEncode({
              'url': title,
              'size': shareItem.videoSize,
              'width': shareItem.videoWidth.toInt().abs(),
              'height': shareItem.videoHeight.toInt().abs(),
              'second': shareItem.videoDuration.toInt(),
              'caption': caption,
              'reply': '',
              'showOriginal': false,
              'coverPath': coverPath.path
            }),
            data: videoFile);
      } else if (notBlank(shareItem.filePath)) {
        FileType fileType = getFileType(shareItem.filePath);
        switch (fileType) {
          case FileType.image:
            final imageFile = File(shareItem.filePath);
            if (imageFile.existsSync()) {
              final decodedImage =
                  await decodeImageFromList(imageFile.readAsBytesSync());
              objectMgr.chatMgr.mySendMgr.send(
                  chat.id,
                  messageTypeImage,
                  jsonEncode({
                    'caption': caption,
                    'reply': null,
                    'width': decodedImage.width.toInt(),
                    'height': decodedImage.height.toInt(),
                    'showOriginal': true,
                  }),
                  data: shareItem.filePath);
            }
            break;
          default:
            File docFile = File(shareItem.filePath);
            String filename = path.basename(docFile.path);
            objectMgr.chatMgr.mySendMgr.send(
                chat.id,
                messageTypeFile,
                jsonEncode({
                  'url': shareItem.filePath,
                  'length': shareItem.length,
                  'file_name': filename,
                  'suffix': shareItem.suffix,
                  'caption': caption,
                }),
                data: docFile);
            break;
        }
      } else if (notBlank(shareItem.webLink)) {
        pdebug("WebLink======> ${shareItem.webLink}");
        FileType fileType = getFileType(shareItem.webLink);
        switch (fileType) {
          case FileType.image:
            String filename = path.basename(shareItem.webLink);
            String? localPath = await cacheMediaMgr.downloadMedia(
              shareItem.webLink,
              savePath: filename,
            );

            if (notBlank(localPath)) {
              objectMgr.chatMgr.mySendMgr.send(chat.id, messageTypeImage,
                  jsonEncode({'showOriginal': true, 'caption': caption}),
                  data: File(localPath!));
            }
            break;
          case FileType.video:
            String filename = path.basename(shareItem.webLink);
            String? localPath = await cacheMediaMgr.downloadMedia(
              shareItem.webLink,
              savePath: filename,
            );
            if (notBlank(localPath)) {
              objectMgr.chatMgr.mySendMgr.send(
                  chat.id,
                  messageTypeVideo,
                  jsonEncode({
                    'url': filename,
                    'showOriginal': false,
                    'caption': caption
                  }),
                  data: File(localPath!));
            }
            break;
          case FileType.document:
            final filePath =
                shareItem.webLink.substring(7, shareItem.webLink.length);
            File docFile = File(filePath);
            String filename = path.basename(docFile.path);
            pdebug("docFile=====> ${docFile.existsSync()}");
            objectMgr.chatMgr.mySendMgr.send(
                chat.id,
                messageTypeFile,
                jsonEncode({
                  'url': filePath,
                  'length': shareItem.length,
                  'file_name': filename,
                  'suffix': shareItem.suffix,
                  'caption': caption
                }),
                data: docFile);
            break;
          default:
            Iterable<RegExpMatch> matches =
                Regular.extractLink(shareItem.webLink);
            objectMgr.chatMgr.sendText(
              chat.id,
              shareItem.webLink,
              matches.isNotEmpty,
            );
            break;
        }
      } else if (notBlank(shareItem.text)) {
        Iterable<RegExpMatch> matches = Regular.extractLink(shareItem.text);
        final bool textWithLink;
        if (matches.isNotEmpty) {
          textWithLink = true;
        } else {
          textWithLink = false;
        }
        objectMgr.chatMgr.sendText(chat.id, shareItem.text, textWithLink);
        if (caption != '') {
          Iterable<RegExpMatch> matches = Regular.extractLink(caption);
          final bool captionWithLink;
          if (matches.isNotEmpty) {
            captionWithLink = true;
          } else {
            captionWithLink = false;
          }
          objectMgr.chatMgr.sendText(chat.id, caption, captionWithLink);
        }
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  String generateValidPath(String path) {
    String validPath = path;
    if (Platform.isIOS) {
      /// ios的文件需要删除前面file://
      validPath = path.substring(7, path.length);
    }
    return validPath;
  }

  shareMessage(BuildContext context, Message message) async {
    final cacheFile = await getShareFile(message);
    if (cacheFile != null && cacheFile.existsSync()) {
      await Share.shareXFiles([XFile(cacheFile.path)]);
      final ShareImage? data = await getShareFilePath;
      if (data != null && data.dataList.isNotEmpty) {
        shareDataToChat(data);
        clearShare;
      }
    } else {
      Toast.showToast(localized(toastShareFail));
    }
  }

  Future<File?> getShareFile(Message message) async {
    File? localFile;
    try {
      Toast.showToast(localized(processingShareData),
          duration: const Duration(milliseconds: 5 * 60 * 1000));
      if (message.typ == messageTypeImage) {
        MessageImage messageImage =
            message.decodeContent(cl: MessageImage.creator);
        String? cachePath = await cacheMediaMgr.downloadMedia(messageImage.url);

        if (notBlank(cachePath)) {
          localFile = File(cachePath!);
        }
      } else if (message.typ == messageTypeVideo) {
        MessageVideo messageVideo =
            message.decodeContent(cl: MessageVideo.creator);
        String? cachePath = await cacheMediaMgr.downloadMedia(messageVideo.url,
            timeoutSeconds: 500);
        if (notBlank(cachePath)) {
          if (messageVideo.url.contains('.m3u8')) {
            final tsDirLastIdx = messageVideo.url.lastIndexOf('/');
            final tsDir = messageVideo.url.substring(0, tsDirLastIdx);
            Map<double, Map<String, dynamic>> tsMap =
                await cacheMediaMgr.extractTsUrls(
              tsDir,
              cachePath!,
            );
            List<String> tsFiles = [];
            tsMap.values.forEach((element) {
              if (element.containsKey('url')) tsFiles.add(element['url']);
            });

            List<String> localCachePaths =
                await videoMgr.multipleDownloadTsFiles(tsFiles);
            if (localCachePaths.isNotEmpty && notBlank(cachePath)) {
              cachePath = await videoMgr.combineToMp4(localCachePaths,
                  dir: cachePath.substring(0, cachePath.lastIndexOf('/')));
              localFile = File(cachePath);
            }
          }
        }
      } else if (message.typ == messageTypeFile) {
        MessageFile messageFile =
            message.decodeContent(cl: MessageFile.creator);
        String? cachePath = await cacheMediaMgr.downloadMedia(
          messageFile.url,
          savePath: downloadMgr.getSavePath(messageFile.file_name),
          timeoutSeconds: 3000,
        );

        if (notBlank(cachePath)) {
          localFile = File(cachePath!);
          //rename file name
          String newFilePath =
              "${localFile.parent.path}/${messageFile.file_name}";
          localFile = await localFile.rename(newFilePath);
        }
      }
    } catch (e) {
      mypdebug("Share Download Failed: $e");
    }

    Toast.hide();
    return localFile;
  }

  @override
  Future<void> register() async {}

  @override
  Future<void> init() async {}

  @override
  Future<void> logout() async {
    _channel.invokeMethod('clearChatList');
  }

  @override
  Future<void> reloadData() async {}
}

class RecentFile {
  final String? path;
  final String? displayName;
  final int? dateAdded;
  final String? type;
  final int? size;

  RecentFile(this.path, this.displayName, this.dateAdded, this.type, this.size);
}
