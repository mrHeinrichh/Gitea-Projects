import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/im/media_detail/photo_detail.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/task/video/video_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:media_kit/media_kit.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../../im/chat_info/group/group_chat_info_controller.dart';
import '../../im/chat_info/tool_option_model.dart';
import '../../im/custom_content/chat_content_controller.dart';
import '../../main.dart';
import '../../managers/object_mgr.dart';
import '../../object/chat/message.dart';
import '../../object/message/larger_photo_data.dart';
import '../../utils/format_time.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/net/download_mgr.dart';
import '../../utils/theme/text_styles.dart';
import '../../utils/toast.dart';
import '../../utils/utility.dart';
import 'delete_message_context.dart';
import 'desktop_forward_container.dart';
import 'desktop_general_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class NewDesktopLargePhoto extends StatefulWidget {
  const NewDesktopLargePhoto({
    super.key,
    required this.assetList,
    required this.index,
    this.contentController,
    this.groupChatInfoController,
    this.reverse = false,
  });

  /// [asset] 可以有的状态, asset : AssetEntity | String | AlbumDetailBean,
  /// [cover] 可以有的状态, url : String
  /// [message] 对应的消息
  final List<Map<String, dynamic>> assetList;

  final int index;
  final ChatContentController? contentController;
  final GroupChatInfoController? groupChatInfoController;
  final bool reverse;

  @override
  State<NewDesktopLargePhoto> createState() => _NewDesktopLargePhotoState();
}

class _NewDesktopLargePhotoState extends State<NewDesktopLargePhoto> {
  late final Player player = Player();
  late final VideoController videoController = VideoController(player);
  final LargerPhotoData photoData = LargerPhotoData();

  Message get currentMessage => widget.assetList[currentIndex]['message'];

  dynamic get currentAsset => widget.assetList[currentIndex]['asset'];

  CustomInputController get inputController =>
      Get.find<CustomInputController>(tag: currentMessage.chat_id.toString());
  TransformationController transformController = TransformationController();

  int currentIndex = 0;
  double scaleSize = 100.0;
  String url = '';

  @override
  void initState() {
    super.initState();
    currentIndex = widget.index;
    photoData.currentPage = widget.index;
    getUrlString();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void keyStrokeChecking(RawKeyEvent event) async {
    if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (isVideoMessage(currentMessage, currentAsset)) return;
      final result = await cacheMediaMgr.downloadMedia(url);
      try {
        if (result != null && result.isNotEmpty) {
          final isSuccess = await Pasteboard.writeFiles([result]);
          if (isSuccess) {
            Toast.showToast(localized(toastCopySuccess));
          } else {
            Toast.showToast(localized(toastCopyFailed));
          }
        }
      } catch (e) {
        Toast.showToast(localized(toastCopyFailed));
      }
      return;
    }
    if (event is RawKeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      onIndexChange();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      onIndexChange(false);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Get.back();
    }
  }

  void onIndexChange([bool isLeft = true]) {
    if (isLeft) {
      if (currentIndex < widget.assetList.length - 1) {
        currentIndex += 1;
      }
    } else {
      if (currentIndex > 0) {
        currentIndex -= 1;
      }
    }
    getUrlString();
    if (mounted) setState(() {});
  }

  void getUrlString() {
    url = currentAsset is AlbumDetailBean
        ? currentAsset.url
        : currentAsset is File
            ? currentAsset.path
            : currentAsset;
  }

  String getCaption() {
    final message = currentMessage;

    switch (message.typ) {
      case messageTypeImage:
        return _getCaptionFromMessage<MessageImage>(message);
      case messageTypeVideo:
      case messageTypeReel:
        return _getCaptionFromMessage<MessageVideo>(message);
      case messageTypeNewAlbum:
        return _getCaptionFromMessage<NewMessageMedia>(message);
      default:
        return '';
    }
  }

  String _getCaptionFromMessage<T>(dynamic message) {
    final cl = T is MessageImage
        ? MessageImage.creator()
        : T is MessageVideo
            ? MessageVideo.creator()
            : NewMessageMedia.creator();
    final bean = message.decodeContent(cl: cl);
    return bean.caption;
  }

  void onTapSecondMenu(ToolOptionModel option, Message message) {
    switch (option.optionType) {
      case 'deleteForEveryone':
        Get.back();
        inputController.onDeleteMessage(
          inputController.chatController.context,
          [message],
          isAll: true,
        );
        break;
      case 'deleteForMe':
        Get.back();
        inputController.onDeleteMessage(
          inputController.chatController.context,
          [message],
          isAll: false,
        );
        break;
      default:
        break;
    }
  }

  _onDownLoad() async {
    Toast.showToast(localized(downloadingFile));

    dynamic curData = currentAsset;

    if (curData is AlbumDetailBean) {
      curData = curData.url;
    }

    if (curData is String) {
      await _downloadString(curData);
    } else if (curData is AssetEntity) {
      await _downloadAsset(curData);
    } else if (curData is File) {
      await _downloadRegularFile(curData);
    }
  }

  _downloadString(String downloadUrl) async {
    var filePath =
        await cacheMediaMgr.downloadMedia(downloadUrl, timeoutSeconds: 500);

    if (filePath == null) {
      Toast.showToast(localized(toastSaveUnsuccessful));
      return;
    }

    if (downloadUrl.contains('.m3u8')) {
      convertM3u8Format(filePath, downloadUrl);
    } else {
      final File sourceFile = File(filePath);
      List<int> bytes = await sourceFile.readAsBytes();
      await _saveFile(bytes, filePath, 'Image');
    }
  }

  _downloadAsset(AssetEntity asset) async {
    File? file = await asset.file;

    List<int> bytes = await file!.readAsBytes();

    await _saveFile(
        bytes, file.path, asset.type == AssetType.image ? 'Image' : 'Video');

    Toast.showToast(localized(toastSaveSuccess));
  }

  _downloadRegularFile(File file) async {
    List<int> bytes = await file.readAsBytes();

    await _saveFile(bytes, file.path, "Media");
  }

  _saveFile(List<int> bytes, String filePath, String fileTypeName) async {
    String fileName =
        "HeyTalk $fileTypeName ${formatTimestamp(DateTime.now().millisecondsSinceEpoch)}${path.extension(url)}";

    final destinationFile =
        File(desktopDownloadMgr.desktopDownloadsDirectory.path + '/$fileName');

    try {
      await destinationFile.writeAsBytes(bytes);

      desktopDownloadMgr.openDownloadDir('$fileName', context);

      Toast.showToast(
        localized(fileDownloaded),
        duration: const Duration(milliseconds: 2500),
      );
    } catch (e) {
      pdebug(e);
      throw (e);
    }
  }

  String formatTimestamp(int timestamp) {
    // Convert timestamp to DateTime
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    // Format the DateTime to the desired string format
    String formattedDate =
        "${dateTime.year}-${_pad(dateTime.month)}-${_pad(dateTime.day)} at ${_pad(dateTime.hour)}.${_pad(dateTime.minute)}.${_pad(dateTime.second)}";

    return formattedDate;
  }

  String _pad(int value) {
    // Pad single-digit values with a leading zero
    return value.toString().padLeft(2, '0');
  }

  Future<List<String>> extractTsUrls(String m3u8Content) async {
    List<String> urls = [];
    dynamic curData;
    var media = widget.assetList[photoData.currentPage];

    final lines = m3u8Content.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.endsWith('.ts')) {
        if (media['asset'] is AlbumDetailBean) {
          curData = media['asset'].url;
          final tsDirLastIdx = curData.lastIndexOf('/');
          final tsDir = curData.substring(0, tsDirLastIdx);

          final downloadUrl = '${tsDir}/$line';

          var _str = await cacheMediaMgr.downloadMedia(downloadUrl,
              timeoutSeconds: 500);
          urls.add(_str!);
        } else {
          Message message = media['message'];
          if (message.asset != null) {
            curData = message.asset;
          } else {
            if (message.typ == messageTypeImage) {
              MessageImage messageImage =
                  message.decodeContent(cl: MessageImage.creator);
              curData = messageImage.url;
            } else if (message.typ == messageTypeVideo ||
                message.typ == messageTypeReel) {
              MessageVideo messageVideo =
                  message.decodeContent(cl: MessageVideo.creator);
              curData = messageVideo.url;
            } else {
              throw "检查类型";
            }
          }

          final tsDirLastIdx = curData.lastIndexOf('/');
          final tsDir = curData.substring(0, tsDirLastIdx);

          final downloadUrl = '${tsDir}/$line';

          var _str = await cacheMediaMgr.downloadMedia(downloadUrl,
              timeoutSeconds: 500);
          urls.add(_str!);
        }
      }
    }

    return urls;
  }

  Future<void> convertM3u8Format(String _str, String downloadUrl) async {
    File file = File(_str);
    try {
      if (file.existsSync()) {
        final response = await http.get(Uri.parse(downloadUrl));

        if (response.statusCode == 200) {
          final fileContent = utf8.decode(response.bodyBytes);
          final int startTime = DateTime.now().millisecondsSinceEpoch;

          List<String> tsUrls = await extractTsUrls(fileContent);
          final data = await videoMgr.combineToMp4(tsUrls,
              dir: _str.substring(0, _str.lastIndexOf('/')));

          final dataFile = File(data);

          if (dataFile.existsSync()) {
            final String combinedHash =
                calculateMD5(dataFile.readAsBytesSync());
            pdebug("combinedHash download: $combinedHash");
          }
          List<int> bytes = await dataFile.readAsBytes();

          int endTime = DateTime.now().millisecondsSinceEpoch;
          pdebug('spend in ${endTime - startTime}');
          String fileName =
              "HeyTalk Video ${formatTimestamp(DateTime.now().millisecondsSinceEpoch)}${path.extension(data)}";

          final File destinationFile = File(
              desktopDownloadMgr.desktopDownloadsDirectory.path + '/$fileName');
          try {
            await destinationFile.writeAsBytes(bytes);
            desktopDownloadMgr.openDownloadDir(
                '${data.split('/').last}', context);
          } catch (e) {
            pdebug(e);
            throw (e);
          }
          pdebug('Segment URL: $tsUrls');
        } else {
          pdebug(
              'Failed to fetch M3U8 file. Status code: ${response.statusCode}');
        }
      } else {
        pdebug('File does not exist: ${file.path}');
      }
    } catch (e) {
      pdebug(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: keyStrokeChecking,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    CustomAvatar(
                      key: ValueKey(currentMessage.send_id),
                      uid: currentMessage.send_id,
                      size: 40,
                      onTap: () {},
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        NicknameText(
                          key: ValueKey(currentMessage.send_id),
                          uid: currentMessage.send_id,
                          color: Colors.white,
                          fontSize: 16,
                          isTappable: false,
                        ),
                        Text(
                          FormatTime.getTime(currentMessage.create_time),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        final Message msg = Message()
                          ..init(currentMessage.toJson());

                        if (currentAsset is AlbumDetailBean) {
                          final AlbumDetailBean bean =
                              currentAsset as AlbumDetailBean;
                          if (bean.cover.isNotEmpty ||
                              (bean.asset != null &&
                                  bean.asset!.type == AssetType.video)) {
                            if (bean.url.isEmpty) return;
                            currentMessage.typ = messageTypeVideo;
                            MessageVideo messageVideo = MessageVideo();
                            if (currentMessage.asset != null ||
                                bean.asset != null) {
                              currentMessage.asset = bean.asset;
                            }
                            messageVideo.url = bean.url;
                            messageVideo.cover = bean.cover;
                            messageVideo.size = bean.size;
                            messageVideo.second = bean.seconds;
                            messageVideo.height = bean.asheight ?? 0;
                            messageVideo.width = bean.aswidth ?? 0;
                            messageVideo.forward_user_id =
                                objectMgr.userMgr.mainUser.uid;
                            messageVideo.forward_user_name =
                                objectMgr.userMgr.mainUser.nickname;
                            msg.content = jsonEncode(messageVideo);

                            msg.decodeContent(
                                cl: msg.getMessageModel(msg.typ),
                                v: jsonEncode(messageVideo));
                          } else {
                            msg.typ = messageTypeImage;
                            if (msg.asset != null || bean.asset != null) {
                              msg.asset = bean.asset;
                            }
                            MessageImage messageImage = MessageImage();
                            messageImage.url = bean.url;
                            messageImage.height = bean.asheight ?? 0;
                            messageImage.width = bean.aswidth ?? 0;
                            messageImage.forward_user_id =
                                objectMgr.userMgr.mainUser.uid;
                            messageImage.forward_user_name =
                                objectMgr.userMgr.mainUser.nickname;
                            msg.content = jsonEncode(messageImage);
                            msg.decodeContent(
                                cl: msg.getMessageModel(msg.typ),
                                v: jsonEncode(messageImage));
                          }
                        }
                        widget.contentController!.chatController
                            .chooseMessage[msg.message_id] = msg;
                        DesktopGeneralDialog(
                          context,
                          widgetChild: DesktopForwardContainer(
                            chat: inputController.chat!,
                            fromMediaDetail: true,
                          ),
                        );
                      },
                      icon: SvgPicture.asset(
                        'assets/svgs/forward_icon.svg',
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        _onDownLoad();
                      },
                      icon: SvgPicture.asset(
                        'assets/svgs/download.svg',
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        DesktopGeneralDialog(
                          context,
                          widgetChild: DeleteMessageContext(
                            onTapSecondMenu: onTapSecondMenu,
                            message: currentMessage,
                          ),
                        );
                      },
                      icon: SvgPicture.asset(
                        'assets/svgs/delete_icon.svg',
                        color: Colors.red,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        player.pause();
                        Get.back();
                      },
                      icon: SvgPicture.asset(
                        'assets/svgs/close_icon.svg',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Get.back(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        scaleSize != 100.0
                            ? '${scaleSize.toStringAsFixed(0)} %'
                            : ' ',
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: MFontWeight.bold4.value,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Focus(
                      onKey: (node, event) {
                        return KeyEventResult.handled;
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DesktopGeneralButton(
                            child: Container(
                              width: 50,
                              child: Icon(
                                Icons.chevron_left,
                                size:
                                    currentIndex != widget.assetList.length - 1
                                        ? 50
                                        : 25,
                                color:
                                    currentIndex != widget.assetList.length - 1
                                        ? Colors.white
                                        : Colors.grey,
                              ),
                            ),
                            onPressed: () {
                              onIndexChange();
                            },
                          ),
                          GestureDetector(onTap: () {}, child: getContent()),
                          DesktopGeneralButton(
                            child: Container(
                              width: 50,
                              child: Icon(
                                Icons.chevron_right,
                                size: currentIndex != 0 ? 50 : 25,
                                color: currentIndex != 0
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                            onPressed: () {
                              onIndexChange(false);
                            },
                          ),
                        ],
                      ),
                    ),
                    Text(
                      getCaption(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        '${widget.assetList.length - currentIndex} of ${widget.assetList.length}',
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: MFontWeight.bold4.value,
                          fontSize: 12,
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget getContent() {
    scaleSize = 100;

    if (isVideoMessage(currentMessage, currentAsset)) {
      return buildVideoContent();
    } else {
      return buildImageContent();
    }
  }

  bool isVideoMessage(dynamic message, dynamic asset) {
    return message.typ == messageTypeVideo ||
        message.typ == messageTypeReel ||
        (asset is AlbumDetailBean && asset.cover.isNotEmpty);
  }

  Widget buildVideoContent() {
    String videoPath = currentAsset is File ? url : '$url';

    if (!videoPath.startsWith('http') && serversUriMgr.download2Uri != null) {
      videoPath = '${serversUriMgr.download2Uri!.origin}/$videoPath';
    }

    player.open(Media(videoPath));
    player.play();

    return SizedBox(
      width: ObjectMgr.screenMQ!.size.width *
          0.85 *
          ObjectMgr.screenMQ!.size.height /
          ObjectMgr.screenMQ!.size.height,
      height: ObjectMgr.screenMQ!.size.height * 0.75,
      child: Builder(
        builder: (context) {
          return MaterialDesktopVideoControlsTheme(
            normal: MaterialDesktopVideoControlsThemeData(
              toggleFullscreenOnDoublePress: false,
              keyboardShortcuts: {
                const SingleActivator(LogicalKeyboardKey.keyF): () {},
                const SingleActivator(LogicalKeyboardKey.space): () =>
                    player.playOrPause(),
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                  final rate =
                      player.state.position - const Duration(seconds: 1);
                  player.seek(rate);
                },
                const SingleActivator(LogicalKeyboardKey.arrowRight): () {
                  final rate =
                      player.state.position + const Duration(seconds: 1);
                  player.seek(rate);
                },
              },
              bottomButtonBar: const [
                MaterialDesktopPlayOrPauseButton(),
                MaterialDesktopVolumeButton(),
                MaterialDesktopPositionIndicator(),
                Spacer(),
              ],
            ),
            fullscreen: const MaterialDesktopVideoControlsThemeData(),
            child: Video(key: ValueKey(url), controller: videoController),
          );
        },
      ),
    );
  }

  Widget buildImageContent() {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 10,
      transformationController: transformController,
      onInteractionUpdate: (updateDetails) {
        // Handle interaction updates if needed
      },
      child: SizedBox(
        width: ObjectMgr.screenMQ!.size.width *
            0.80 *
            ObjectMgr.screenMQ!.size.height /
            ObjectMgr.screenMQ!.size.height,
        height: ObjectMgr.screenMQ!.size.height * 0.65,
        child: currentAsset is AlbumDetailBean
            ? buildAlbumDetailItemImage()
            : buildMessageItemImage(),
      ),
    );
  }

  Widget buildMessageItemImage() {
    MessageImage messageImage =
        currentMessage.decodeContent(cl: MessageImage.creator);
    return PhotoDetail(
      key: ValueKey(currentMessage.asset != null
          ? currentMessage.asset
          : messageImage.url),
      photoData: photoData,
      item: currentMessage.asset != null ? currentMessage.asset : messageImage,
      message: currentMessage,
      height: messageImage.height.toDouble(),
      width: messageImage.width.toDouble(),
    );
  }

  Widget buildAlbumDetailItemImage() {
    if (currentAsset.url.isNotEmpty) {
      return PhotoDetail(
        key: ValueKey(currentAsset.url.toString()),
        photoData: photoData,
        item: currentAsset,
        message: currentMessage,
        height: currentAsset.asheight!.toDouble(),
        width: currentAsset.aswidth!.toDouble(),
      );
    } else {
      AssetEntity? entity = currentAsset.asset;
      if (entity != null) {
        return PhotoDetail(
          key: ValueKey(currentAsset.url.toString()),
          photoData: photoData,
          item: entity,
          message: currentMessage,
          height: entity.height.toDouble(),
          width: entity.width.toDouble(),
        );
      } else {
        throw "代码检查,逻辑不通过";
      }
    }
  }
}
