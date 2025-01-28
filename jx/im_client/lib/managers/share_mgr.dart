import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im_common;
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/managers/interface/base_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_share.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/message/share_image.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ShareMgr extends BaseMgr {
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
    Map? map = await _channel.invokeMethod('getShareFilePath');
    if (map != null) {
      Map<String, dynamic> muMap = {};
      for (var key in map.keys) {
        muMap[key.toString()] = map[key];
      }
      return ShareImage.fromJson((muMap));
    }
    return null;
  }

  Future<List<ShareImage>> get getShareFilePathList async {
    List<ShareImage> imgs = [];
    List? list = await _channel.invokeMethod('getShareFilePath');
    if (list != null) {
      for (var map in list) {
        if (map != null) {
          Map<String, dynamic> muMap = {};
          for (var key in map.keys) {
            muMap[key.toString()] = map[key];
          }

          var item = ShareImage.fromJson((muMap));
          imgs.add(item);
        }
      }
    }
    return imgs;
  }

  Future<List<RecentFile>> get recentFilePaths async {
    List<RecentFile> files = [];
    final fileData = await _channel.invokeMethod('RecentFilePaths');
    if (fileData != null) {
      for (final data in fileData) {
        files.add(
          RecentFile(
            data["path"],
            data["name"],
            int.parse(data["dateAdded"]),
            data["type"],
            int.parse(data["size"]),
          ),
        );
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
                user.profilePicture,
              );
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
            chatShare = ChatShare(
              chat.id,
              chat.id,
              displayName,
              shortNameFromNickName(displayName),
              chatTypeGroup,
              chat.icon,
            );
          } else if (chat.isSaveMsg) {
            chatShare = ChatShare(
              chat.id,
              chat.id,
              chat.name,
              shortNameFromNickName(chat.name),
              chatTypeSaved,
              chat.icon,
            );
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
        'syncChatList',
        {'chatList': jsonEncode(chatListForShare)},
      );
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
    }
  }

  void sendShare(Chat chat, List<ShareItem> dataList, String caption) async {
    for (ShareItem shareItem in dataList) {
      if (notBlank(shareItem.imagePath)) {
        String imagePath = generateValidPath(shareItem.imagePath);
        File imageFile = File(imagePath);
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
            data: imagePath,
          );
        }
      } else if (notBlank(shareItem.videoPath)) {
        final title = path.basename(shareItem.videoPath);
        String videoPath = generateValidPath(shareItem.videoPath);
        File videoFile = File(videoPath);

        final File? coverPath = await generateThumbnailWithPath(
          videoPath,
          savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          sub: 'cover',
        );

        if (coverPath == null) {
          return;
        }

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
            'coverPath': coverPath.path,
          }),
          data: videoFile,
        );
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
                data: shareItem.filePath,
              );
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
              data: docFile,
            );
            break;
        }
      } else if (notBlank(shareItem.webLink)) {
        pdebug("WebLink======> ${shareItem.webLink}");
        FileType fileType = getFileType(shareItem.webLink);
        switch (fileType) {
          case FileType.image:
            DownloadResult result = await downloadMgrV2.download(
              shareItem.webLink,
              downloadType: DownloadType.largeFile,
            );
            String? localPath = result.localPath;
            // String? localPath = await downloadMgr.downloadFile(
            //   shareItem.webLink,
            // );

            if (notBlank(localPath)) {
              objectMgr.chatMgr.mySendMgr.send(
                chat.id,
                messageTypeImage,
                jsonEncode({'showOriginal': true, 'caption': caption}),
                data: File(localPath!),
              );
            }
            break;
          case FileType.video:
            String filename = path.basename(shareItem.webLink);
            DownloadResult result = await downloadMgrV2.download(
              shareItem.webLink,
              downloadType: DownloadType.largeFile,
            );
            String? localPath = result.localPath;
            // String? localPath = await downloadMgr.downloadFile(
            //   shareItem.webLink,
            // );
            if (notBlank(localPath)) {
              objectMgr.chatMgr.mySendMgr.send(
                chat.id,
                messageTypeVideo,
                jsonEncode({
                  'url': filename,
                  'showOriginal': false,
                  'caption': caption,
                }),
                data: File(localPath!),
              );
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
                'caption': caption,
              }),
              data: docFile,
            );
            break;
          default:
            objectMgr.chatMgr.sendText(
              chat.id,
              shareItem.webLink,
            );
            break;
        }
      } else if (notBlank(shareItem.text)) {
        /// 文本过长，需要当作文件来发送
        if (shareItem.text.length < 4096) {
          objectMgr.chatMgr.sendText(chat.id, shareItem.text);
        } else {
          Toast.showToast(localized(errorMaxCharInput));
          String str = shareItem.text.substring(0, 4096);
          objectMgr.chatMgr.sendText(chat.id, str);
        }
        if (caption != '') {
          objectMgr.chatMgr.sendText(chat.id, caption);
        }
      }else if(notBlank(shareItem.miniAppLink)){
        objectMgr.chatMgr.sendHousekeepingSysShareLink(chat.id, shareItem);
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

  Future<bool> shareMessage(
    BuildContext context,
    Message message, {
    bool isFromChatRoom = false,
  }) async {
    RxBool isSuccess = false.obs;
    int animationSuccessTotalTime = 834;
    if (message.typ == messageTypeVideo && !isFromChatRoom) {
      showModalBottomSheet(
        context: context,
        barrierColor: colorOverlay40,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 130,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Obx(
                    () => !isSuccess.value
                        ? Lottie.asset(
                            "assets/lottie/animate_loading.json",
                            height: 50,
                            width: 50,
                          )
                        : LottieBuilder.asset(
                            "assets/lottie/animate_success.json",
                            height: 50,
                            width: 50,
                            repeat: false,
                            animate: true,
                            onLoaded: (composition) {
                              animationSuccessTotalTime =
                                  composition.duration.inMilliseconds;
                              pdebug("$animationSuccessTotalTime");
                            },
                          ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    isSuccess.value = false;
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      localized(cancel),
                      style: jxTextStyle.textStyle16(
                        color: themeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
              ],
            ),
          );
        },
      );
    }
    final (List<File?> cacheFileList, String? albumError) =
        await getShareFile(message, isFromChatRoom: isFromChatRoom);
    if (message.typ == messageTypeVideo && !isFromChatRoom) {
      isSuccess.value = true;
      if (!isSuccess.value) {
        return false;
      }
      //对勾动画时长
      await Future.delayed(Duration(milliseconds: animationSuccessTotalTime));
      Get.back();
      if (!isSuccess.value) {
        return false;
      }
    }
    List<XFile> fileList = [];
    for (File? cacheFile in cacheFileList) {
      if (cacheFile != null && cacheFile.existsSync()) {
        fileList.add(XFile(cacheFile.path));
      }
    }
    if (fileList.isEmpty) {
      Toast.showToast(albumError ?? localized(toastShareFail));
      return false;
    }

    final shareResult = await Share.shareXFiles(fileList);
    if (Platform.isAndroid) {
      final ShareImage? shareImage = await getShareFilePath;
      if (shareImage != null) {
        shareDataToChat(shareImage);
      }
    } else {
      final List<ShareImage> list = await getShareFilePathList;
      for (var data in list) {
        if (data.dataList.isNotEmpty) {
          shareDataToChat(data);
        }
      }
    }
    clearShare;
    return shareResult.status == ShareResultStatus.success;
  }

  File? getLocalImage(String path, {bool shouldShowOriginal = false}) {
    String? localPath = downloadMgrV2.getLocalPath(
      path,
      mini: shouldShowOriginal ? Config().maxOriImageMin : null,
    );
    if (!notBlank(localPath)) {
      localPath = downloadMgrV2.getLocalPath(path, mini: Config().messageMin);
    }

    if (notBlank(localPath)) {
      File f = File(localPath!);
      return f;
    }

    return null;
  }

  File? getLocalVideo(String path) {
    final mp4RelativeFolderIdx = path.lastIndexOf('/');
    final mp4RelativeFolder = path.substring(0, mp4RelativeFolderIdx);
    String? vidPath = downloadMgrV2.getLocalPath(
      "$mp4RelativeFolder${Platform.pathSeparator}index.mp4",
    );

    if (vidPath != null && vidPath.isNotEmpty) {
      File f = File(vidPath);
      return f;
    }
    return null;
  }

  Future<(List<File?>, String? albumFailure)> getShareFile(
    Message message, {
    bool isFromChatRoom = false,
  }) async {
    List<File?> localFileList = [];
    String? albumFailure;
    try {
      if (isFromChatRoom) im_common.showLoading();
      // Toast.showToast(localized(processingShareData),
      //     duration: const Duration(milliseconds: 5 * 60 * 1000));
      if (message.typ == messageTypeImage) {
        if (message.asset != null) {
          if (message.asset is AssetEntity) {
            File? file = await message.asset.file;
            localFileList = [file];
          }

          if (message.asset is File) {
            localFileList = [message.asset];
          }
        } else {
          MessageImage messageImage =
              message.decodeContent(cl: MessageImage.creator);
          File? image = getLocalImage(messageImage.url);
          if (image != null) {
            localFileList = [image];
          } else {
            //兜底下载逻辑
            DownloadResult result =
                await downloadMgrV2.download(messageImage.url);
            String? path = result.localPath;
            // String? path = await downloadMgr.downloadFile(messageImage.url);
            if (path != null) {
              image = File(path);
              if (path != null && image.existsSync()) {
                localFileList = [image];
              }
            }
          }
        }
      } else if (message.typ == messageTypeVideo ||
          message.typ == messageTypeReel) {
        if (message.asset != null) {
          if (message.asset is AssetEntity) {
            File? file = await message.asset.file;
            localFileList = [file];
          }

          if (message.asset is File) {
            localFileList = [message.asset];
          }
        } else {
          MessageVideo messageVideo =
              message.decodeContent(cl: MessageVideo.creator);

          var file = File(messageVideo.filePath);
          if (File(messageVideo.filePath).existsSync()) {
            localFileList = [file];
          } else {
            final urlPath = messageVideo.url;
            File? f = getLocalVideo(urlPath);
            if (f != null) {
              localFileList = [f];
            } else {
              //兜底下载逻辑 m3u8 + mp4 生成
              DownloadResult result = await downloadMgrV2.download(urlPath);
              String? m3u8Path = result.localPath;
              // String? m3u8Path = await downloadMgr.downloadFile(path);
              if (m3u8Path != null) {
                var videoFile = File(m3u8Path);
                if (m3u8Path != null && videoFile.existsSync()) {
                  if (videoFile.path.contains('.m3u8')) {
                    f = await convertM3u8Format(m3u8Path, urlPath);
                    if (f != null) {
                      localFileList = [f];
                    }
                  } else {
                    final File sourceFile = File(videoFile.path);
                    localFileList = [sourceFile];
                  }
                }
              }
              //mp4 回退
              // else {
              //   String? sourceMp4Path = await _checkForSourceMp4(
              //     urlPath,
              //     sourceExtension:
              //         path.extension(messageVideo.filePath).toLowerCase(),
              //   );
              //   if (sourceMp4Path != null) {
              //     result = await downloadMgrV2.download(sourceMp4Path);
              //     var mp4Path = result.localPath;
              //     if (mp4Path != null) {
              //       File file = File(mp4Path);
              //       if (file.existsSync()) {
              //         localFileList = [file];
              //       }
              //     }
              //   }
              // }
            }
          }
        }
      } else if (message.typ == messageTypeFile) {
        MessageFile messageFile =
            message.decodeContent(cl: MessageFile.creator);

        DownloadResult result = await downloadMgrV2.download(messageFile.url,
            downloadType: DownloadType.largeFile,
            timeout: const Duration(seconds: 3000));
        String? cachePath = result.localPath;
        // String? cachePath = await downloadMgr.downloadFile(
        //   messageFile.url,
        //   timeout: const Duration(seconds: 3000),
        // );

        if (notBlank(cachePath)) {
          File localFile = File(cachePath!);
          //rename file name
          String newFilePath =
              "${localFile.parent.path}/${messageFile.file_name}";
          localFile = await localFile.rename(newFilePath);
          localFileList = [localFile];
        }
      } else if (message.typ == messageTypeNewAlbum) {
        NewMessageMedia bean =
            message.decodeContent(cl: NewMessageMedia.creator);
        List<AlbumDetailBean> list = bean.albumList ?? [];
        int vidCount = 0;
        int vidSaved = 0;
        for (AlbumDetailBean bean in list) {
          bool isVideo = bean.cover.isNotEmpty ||
              (bean.mimeType?.contains('video') ?? false);
          if (isVideo) {
            vidCount++;
            File file = File(bean.filePath);
            if (file.existsSync()) {
              vidSaved++;
              localFileList.add(file);
            } else {
              final urlPath = bean.url;
              File? f = getLocalVideo(urlPath);
              if (f != null) {
                vidSaved++;
                localFileList.add(f);
              } else {
                //兜底下载逻辑
                DownloadResult result = await downloadMgrV2.download(urlPath);
                String? m3u8Path = result.localPath;
                // String? m3u8Path = await downloadMgr.downloadFile(path);
                if (m3u8Path != null) {
                  var videoFile = File(m3u8Path);
                  if (m3u8Path != null && videoFile.existsSync()) {
                    if (videoFile.path.contains('.m3u8')) {
                      f = await convertM3u8Format(m3u8Path, urlPath);
                      if (f != null) {
                        vidSaved++;
                        localFileList.add(f);
                      }
                    } else {
                      final File sourceFile = File(videoFile.path);
                      vidSaved++;
                      localFileList.add(sourceFile);
                    }
                  }
                }
                // else {
                //   String? sourceMp4Path = await _checkForSourceMp4(
                //     urlPath,
                //     sourceExtension:
                //         path.extension(bean.filePath).toLowerCase(),
                //   );
                //   if (sourceMp4Path != null) {
                //     result = await downloadMgrV2.download(urlPath);
                //     var mp4Path = result.localPath;
                //     if (mp4Path != null) {
                //       File file = File(mp4Path);
                //       if (file.existsSync()) {
                //         vidSaved++;
                //         localFileList.add(file);
                //       }
                //     }
                //   }
                // }
              }
            }
          } else {
            File? image = getLocalImage(bean.url);
            if (image != null) {
              localFileList.add(image);
            } else {
              //兜底下载逻辑
              DownloadResult result = await downloadMgrV2.download(bean.url);
              String? path = result.localPath;

              // String? path = await downloadMgr.downloadFile(bean.url);
              if (path != null) {
                image = File(path);
                if (path != null && image.existsSync()) {
                  localFileList = [image];
                }
              }
            }
          }
        }
        if (vidCount != vidSaved) {
          albumFailure =
              "${vidCount - vidSaved} ${localized(video)} ${localized(toastSaveUnsuccessful)}";
        }
      }
    } catch (e) {
      pdebug("Share Download Failed: $e");
    }

    // Toast.hide();
    if (isFromChatRoom) im_common.dismissLoading();
    return (localFileList, albumFailure);
  }

  // Future<String?> _checkForSourceMp4(String videoPath,
  //     {String sourceExtension = ".mp4"}) async {
  //   final mp4RelativeFolderIdx =
  //       videoPath.lastIndexOf(Platform.pathSeparator); //去除 index.m3u8
  //   final mp4RelativeFolder = videoPath.substring(0, mp4RelativeFolderIdx);
  //   final hlsHashFolderIndex =
  //       mp4RelativeFolder.lastIndexOf(Platform.pathSeparator); //去除 hls folder
  //   final hlsHashFolder = mp4RelativeFolder.substring(0, hlsHashFolderIndex);
  //   final urlHashFolderIdx =
  //       hlsHashFolder.lastIndexOf(Platform.pathSeparator); //找寻hash点位
  //   final urlHash = hlsHashFolder.substring(urlHashFolderIdx + 1); //取hash
  //   String type = videoPath.contains("Reels") ? "Reels" : "Video";
  //   bool isEncrypt = videoPath.contains("secret");
  //   bool hasM3u8 = await videoMgr.checkM3u8HasFinishedProcessing(
  //     urlHash,
  //     type: type,
  //     isEncrypt: isEncrypt,
  //     // sourceExtension: sourceExtension,
  //   );
  //   return hasM3u8;
  // }

  Future<File?> convertM3u8Format(String str, String downloadUrl) async {
    File file = File(str);
    File? finalFile;
    try {
      if (file.existsSync()) {
        final fileContent = file.readAsStringSync();
        List<String> tsUrls = await extractTsUrls(downloadUrl, fileContent);
        final data = await videoMgr.combineToMp4(
          tsUrls,
          dir: str.substring(0, str.lastIndexOf('/')),
        );

        finalFile = File(data);
      } else {
        pdebug('File does not exist: ${file.path}');
      }
    } catch (e) {
      pdebug(e);
    } finally {}

    return finalFile;
  }

  Future<List<String>> extractTsUrls(String pathURL, String m3u8Content) async {
    List<String> urls = [];

    final lines = m3u8Content.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.endsWith('.ts')) {
        final tsDirLastIdx = pathURL.lastIndexOf('/');
        final tsDir = pathURL.substring(0, tsDirLastIdx);

        final downloadUrl = '$tsDir/$line';

        DownloadResult result = await downloadMgrV2.download(downloadUrl,
            timeout: const Duration(seconds: 500));
        var str = result.localPath;

        // var str = await downloadMgr.downloadFile(downloadUrl,
        //     timeout: const Duration(seconds: 500));

        if (str != null) {
          urls.add(str);
        }
      }
    }

    return urls;
  }

  @override
  Future<void> cleanup() async {
    _channel.invokeMethod('clearChatList');
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> recover() async {}

  @override
  Future<void> registerOnce() async {}
}

class RecentFile {
  final String? path;
  final String? displayName;
  final int? dateAdded;
  final String? type;
  final int? size;

  RecentFile(this.path, this.displayName, this.dateAdded, this.type, this.size);
}
