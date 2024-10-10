import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' hide ImBottomToast, ImBottomNotifType;
import 'package:image_editor/flutter_image_editor.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_slider.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/media_detail/photo_detail.dart';
import 'package:jxim_client/im/media_detail/video_detail.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/enums/tool_extension.dart';
import 'package:jxim_client/object/message/larger_photo_data.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/object/tencent_video_config.dart';
import 'package:jxim_client/reel/reel_page/video_volume_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transparent_page_route.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/message_utils.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/photo_view_util.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

enum Mode {
  preview,
  edit,
}

class MediaDetailView extends StatefulWidget {
  final List<Map<String, dynamic>> assetList;

  final int index;

  final ChatContentController? contentController;
  final GroupChatInfoController? groupChatInfoController;
  final TencentVideoStream? pipStartStream;
  final bool reverse;
  final bool isFromChatRoom;

  const MediaDetailView({
    super.key,
    required this.assetList,
    required this.index,
    this.contentController,
    this.groupChatInfoController,
    this.pipStartStream,
    this.reverse = false,
    this.isFromChatRoom = false,
  });

  @override
  State<MediaDetailView> createState() => MediaDetailViewState();
}

class MediaDetailViewState extends State<MediaDetailView>
    with WidgetsBindingObserver {
  static final ToolOptionModel _forwardOption =
      MessagePopupOption.forward.toolOption;
  late final PhotoViewPageController photoPageController;
  final LargerPhotoData photoData = LargerPhotoData();
  ScrollPhysics scrollPhysics = const BouncingScrollPhysics();

  RxBool showToolBox = true.obs;

  final reelFloatingKey = "reel_view";
  final isReelVideo = false.obs;
  final isFullMode = true.obs;
  final isLandscape = false.obs;

  final List<ToolOptionModel> _imageBottomOptionList = [
    _forwardOption,
    MessagePopupOption.edit.toolOption,
    MessagePopupOption.delete.toolOption,
  ];

  final List<ToolOptionModel> _vidBottomOptionList = [
    _forwardOption,
    MessagePopupOption.backward10sec.toolOption,
    MessagePopupOption.play.toolOption,
    MessagePopupOption.forward10sec.toolOption,
    MessagePopupOption.delete.toolOption,
  ];

  final List<ToolOptionModel> _imageAppOptionList = [
    MessagePopupOption.saveToGallery.toolOption,
  ];

  final List<ToolOptionModel> _vidAppOptionList = [
    MessagePopupOption.mute.toolOption,
    MessagePopupOption.saveToGallery.toolOption,
    MessagePopupOption.minimize.toolOption,
  ];

  final optionList = [].obs;
  final appbarOptionList = [].obs;
  final subOptionList = [].obs;
  final RxList<Map<String, dynamic>> computedAssets =
      RxList<Map<String, dynamic>>();
  bool noMoreNext = false;
  final size = 0.obs;

  final TextEditingController captionController = TextEditingController();
  final FocusNode captionFocus = FocusNode();
  final currMode = Mode.preview.obs;
  final bottomBarHeight = 48.0;
  Rx<File> editedFile = File('').obs;
  final coverFilePath = Rx<dynamic>(null);
  bool hasLimitedVolume = false;
  bool _preloadedVideos = false;

  TencentVideoStreamMgr? videoStreamMgr;
  StreamSubscription? videoStreamSubscription;

  int get videoCacheRange => 1;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    videoStreamMgr = objectMgr.tencentVideoMgr.getStream();
    videoStreamMgr!.currentIndex.value = widget.index;
    if (widget.pipStartStream != null) {
      videoStreamMgr?.addPipStream(widget.pipStartStream!);
    }
    videoStreamSubscription =
        videoStreamMgr?.onStreamBroadcast.listen(_onVideoUpdates);
    computedAssets.assignAll(widget.assetList);
    photoPageController = PhotoViewPageController(
      initialPage: widget.index,
      shouldIgnorePointerWhenScrolling: true,
    );
    photoData.currentPage = widget.index;

    if (_isVideoAsset(widget.index)) {
      hasLimitedVolume = true;
      VideoVolumeManager.instance.limitVideoVolume();
      widget.contentController?.chatController.playerService.onClose();
      optionList.assignAll(_vidBottomOptionList);
      appbarOptionList.assignAll(_vidAppOptionList);
    } else {
      optionList.assignAll(_imageBottomOptionList);
      appbarOptionList.assignAll(_imageAppOptionList);
    }

    _preloadVideos(widget.index);

    if (computedAssets.length == 1) {
      scrollPhysics = const ClampingScrollPhysics();
    }

    if (widget.contentController != null &&
        !widget.contentController!.chatController.canForward.value) {
      _forwardOption.isShow = false;
    }

    if (widget.groupChatInfoController != null &&
        widget.groupChatInfoController?.forwardEnable != null &&
        widget.groupChatInfoController?.forwardEnable.value != true) {
      _forwardOption.isShow = false;
    }

    isReelVideo.value = isReel(widget.index);

    isLandscape.value = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.aspectRatio >
        1;

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    isLandscape.value = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.aspectRatio >
        1;
  }

  @override
  void dispose() {
    captionController.dispose();
    captionFocus.dispose();

    WidgetsBinding.instance.removeObserver(this);

    videoStreamSubscription?.cancel();
    if (videoStreamMgr != null) {
      objectMgr.tencentVideoMgr.disposeStream(videoStreamMgr!);
    }
    WakelockPlus.disable();

    super.dispose();
  }

  _onVideoUpdates(TencentVideoStream item) {
    if (item.pageIndex != photoData.currentPage) return;
  }

  void onPageChange(int index) {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _populateData(index);
    });

    _onVideoPageChange(index);
    videoStreamMgr!.currentIndex.value = index;
    photoData.currentPage = index;

    if (mounted) {
      isReelVideo.value = isReel(index);
      resetStatus();
    }

    if (mounted) setState(() {});
  }

  _populateData(int index) async {
    if (noMoreNext) return;
    if (widget.contentController == null) return;
    bool toCheck = false;
    int indexRange = videoCacheRange;
    for (int i = index + 1; i <= index + indexRange; i++) {
      if (computedAssets.length <= i) {
        toCheck = true;
        break;
      }
    }

    if (!toCheck) return;

    Chat chat = widget.contentController!.chat!;
    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND chat_idx < ? AND (typ = ? OR typ = ? OR typ = ? OR typ = ?) AND deleted != 1 AND expire_time == 0',
      [
        chat.id,
        chat.hide_chat_msg_idx,
        computedAssets.isEmpty
            ? chat.msg_idx + 1
            : computedAssets.last['message'].chat_idx,
        messageTypeImage,
        messageTypeVideo,
        messageTypeReel,
        messageTypeNewAlbum,
      ],
      'DESC',
      30,
    );

    if (tempList.isEmpty) {
      noMoreNext = true;
    }

    List<Message> mList =
        tempList.map<Message>((e) => Message()..init(e)).toList();

    computedAssets.addAll(processAssetList(mList));
    pdebug("#### 加载更多完了 ####");
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> processAssetList(List<Message> messageList) {
    List<Map<String, dynamic>> assetList = [];
    for (Message message in messageList) {
      if (message.deleted == 1 || !message.isMediaType || !message.isEncrypted) {
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
        } else {
          MessageVideo messageVideo =
              message.decodeContent(cl: message.getMessageModel(message.typ));
          assetMap['asset'] = messageVideo.url;
          assetMap['cover'] = messageVideo.cover;
          assetMap['message'] = message;
        }

        assetList.add(assetMap);
      } else if (message.typ == messageTypeMarkdown) {
        MessageMarkdown messageMarkdown =
            message.decodeContent(cl: MessageMarkdown);
        if (messageMarkdown.image.isNotEmpty) {
          Map<String, dynamic> assetMap = {};
          assetMap['message'] = message;
          if (messageMarkdown.video.isNotEmpty) {
            assetMap['cover'] = messageMarkdown.image;
            assetMap['asset'] = messageMarkdown.video;
          } else {
            assetMap['asset'] = messageMarkdown.image;
          }
          assetList.add(assetMap);
        }
      } else if (message.typ == messageTypeNewAlbum) {
        //到了这里只支援相册 其余场景例如file一概不支援
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

            assetList.add(assetMap);
          }
        }
      }
    }

    return assetList;
  }

  _onMinimize() async {
    TencentVideoController? controller = _getVideo(photoData.currentPage);
    TencentVideoStream? stream =
        videoStreamMgr?.getVideoStream(photoData.currentPage);

    if (controller == null) return;
    if (stream == null) return;

    videoStreamMgr?.removeFloatingStream(stream);
    controller.config.isPip = true;
    controller.config.onPIPMaximize = (TencentVideoStream s) {
      Navigator.of(navigatorKey.currentContext!).push(
        TransparentRoute(
          builder: (BuildContext context) => MediaDetailView(
            assetList: computedAssets,
            index: photoData.currentPage,
            contentController: widget.contentController,
            pipStartStream: s,
            reverse: widget.reverse,
            isFromChatRoom: widget.isFromChatRoom,
          ),
          settings: const RouteSettings(name: RouteName.mediaDetailView),
        ),
      );
    };
    Get.back();
    objectMgr.tencentVideoMgr.startPipController(stream, photoData.currentPage);
  }

  bool isReel(int index) {
    Message message = computedAssets[index]['message'];
    if (message.typ == messageTypeReel) {
      return true;
    } else if (message.typ == messageTypeVideo) {
      MessageVideo messageVideo =
          message.decodeContent(cl: MessageVideo.creator);
      Uri uri = Uri.parse(messageVideo.url);
      if (uri.hasQuery) {
        return true;
      }
    }
    return false;
  }

  _onTapVideo() {
    showToolBox.toggle();
    if (!showToolBox.value && subOptionList.isNotEmpty) {
      subOptionList.clear();
    }
  }

  void onTap(String optionType, int index) {
    final Message currentMsg = computedAssets[photoData.currentPage]['message'];

    TencentVideoController? controller = _getVideo(index);

    int? chatId;
    int? chatIdx;

    switch (optionType) {
      case "showInChat":
        Get.back();

        if (Get.isRegistered<ChatInfoController>() ||
            Get.isRegistered<GroupChatInfoController>()) {
          Get.back();
        }

        if (widget.contentController != null) {
          if (widget.contentController!.chatController.isPinnedOpened) {
            Get.back();
          }

          chatId = currentMsg.chat_id;
          chatIdx = currentMsg.chat_idx;

          if (Get.isRegistered<SingleChatController>(tag: chatId.toString()) ||
              Get.isRegistered<GroupChatController>(tag: chatId.toString())) {
            widget.contentController!.chatController.showMessageOnScreen(
              chatIdx,
              currentMsg.id,
              currentMsg.create_time,
            );
          } else {
            Chat? chat = objectMgr.chatMgr.getChatById(chatId);
            if (chat != null) {
              Routes.toChat(
                chat: chat,
                selectedMsgIds: [currentMsg],
              );
            }
          }
        } else {
          Chat? chat = objectMgr.chatMgr.getChatById(currentMsg.chat_id);
          if (chat != null) {
            Routes.toChat(
              chat: chat,
              selectedMsgIds: [currentMsg],
            );
          }
        }
        break;
      case "edit":
        resetStatus();
        _onPhotoEdit();
        break;
      case "forward":
        resetStatus();
        _onForwardMedia();
        break;
      case "saveToGallery":
        resetStatus();
        _onDownLoad();
        break;
      case "delete":
        resetStatus();
        _onDelete();
        break;
      case "play":
      case "pause":
        resetStatus();
        controller?.togglePlayState();
        break;
      case "forward10sec":
        resetStatus();
        controller?.onForwardVideo();
        break;
      case "backward10sec":
        resetStatus();
        controller?.onRewindVideo();
        break;
      case "mute":
        resetStatus();
        controller?.toggleMute();
        break;
      case "minimize":
        resetStatus();
        _onMinimize();
        break;
      case "more":
        if (subOptionList.isNotEmpty) {
          subOptionList.clear();
        } else {
          var options = appbarOptionList
              .where((item) => item != appbarOptionList[0])
              .toList();
          subOptionList.addAll(options);
        }
        break;
      default:
        break;
    }
  }

  void _onPhotoEdit() async {
    try {
      final asset = computedAssets[photoData.currentPage]['asset'];
      final message = computedAssets[photoData.currentPage]['message'];
      String? filePath;

      if (asset is AssetEntity) {
        coverFilePath.value = asset;
        File? assetFile = await asset.originFile;
        if (assetFile == null) return;
        filePath = assetFile.path;
      } else {
        String? fileName;
        if (asset is AlbumDetailBean) {
          if (!(asset.mimeType?.contains('image') ?? true)) {
            Toast.showToast(localized(toastFileFailed));
            return;
          }
          fileName = asset.url;
        } else if (asset is File) {
          coverFilePath.value = asset;
          handleEdit(message, asset.path);
          return;
        } else {
          fileName = asset;
        }

        if (fileName == null || fileName.isEmpty) {
          Toast.showToast(localized(toastFileFailed));
          return;
        }

        filePath = downloadMgr.checkLocalFile(fileName);

        filePath ??= await cacheMediaMgr.downloadMedia(fileName);
        coverFilePath.value = File(filePath ?? '');
      }

      if (filePath == null) {
        Toast.showToast(localized(toastFileFailed));
        return;
      }

      handleEdit(message, filePath);
    } catch (e) {
      debugPrint('[onPhotoEdit]: edit photo in error $e');
    }
  }

  Future<void> handleEdit(
    Message message,
    String? filePath,
  ) async {
    assert(filePath != null, 'filePath can not be null');
    final newFile = await copyImageFile(File(filePath!));

    var done = await FlutterPhotoEditor().editImage(
      newFile.path,
      languageCode: objectMgr.langMgr.currLocale.languageCode,
    );
    if (done) {
      currMode.value = Mode.edit;
      editedFile.value = newFile;

      ImageGallerySaver.saveFile(newFile.path);
    } else {
      currMode.value = Mode.preview;
    }
  }

  void reEditPhoto() async {
    try {
      coverFilePath.value = editedFile.value;
      final newFile = await copyImageFile(editedFile.value);
      var done = await FlutterPhotoEditor().editImage(
        newFile.path,
        languageCode: objectMgr.langMgr.currLocale.languageCode,
      );
      if (done) {
        editedFile.value = newFile;
      } else {
        currMode.value = Mode.preview;
      }
    } catch (e) {
      debugPrint('[onPhotoEdit]: edit photo in error $e');
    }
  }

  Future<void> sendReEditedImageWithCaption() async {
    final message = computedAssets[photoData.currentPage]['message'];
    final Map<String, dynamic>? uiImage =
        await getImageFromAsset(editedFile.value);
    final chat = objectMgr.chatMgr.getChatById(message.chat_id);
    assert(chat != null, 'Chat can not be null');

    ChatHelp.sendImageFile(
      editedFile.value,
      chat!,
      width: uiImage?['width'].toInt(),
      height: uiImage?['height'].toInt(),
      caption: captionController.text,
    );
    Get.back();
    playSendMessageSound();
  }

  void playSendMessageSound() {
    if (Get.isRegistered<CustomInputController>()) {
      final controller = Get.find<CustomInputController>();
      controller.playSendMessageSound();
    }
  }

  void onForwardMessage(
    BuildContext context,
    Chat currChat,
    EditorImageResult result,
  ) {
    showModalBottomSheet(
      context: Get.context!,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ForwardContainer(
          chat: currChat,
          isForward: true,
        );
      },
    ).then((dynamic chat) {
      processOnSendEditedImage(chat, currChat, result);
    });
  }

  void processOnSendEditedImage(
    List<Chat>? chat,
    Chat currChat,
    EditorImageResult result,
  ) async {
    if (chat == null) return;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: [
            IgnorePointer(
              child: Material(
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                    right: 12.0,
                    top: 16.0,
                    bottom: 16.0,
                  ),
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                      Image.file(
                        result.newFile,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        localized(confirmSend),
                        style: jxTextStyle
                            .textStyle16(color: colorTextPrimary)
                            .copyWith(decoration: TextDecoration.none),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => onSendEditedImage(chat, currChat, result),
              child: Material(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  color: Colors.white,
                  child: Text(
                    localized(buttonYes),
                    style: jxTextStyle
                        .textStyle16(color: themeColor)
                        .copyWith(decoration: TextDecoration.none),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localized(buttonNo),
              style: jxTextStyle
                  .textStyle16(color: themeColor)
                  .copyWith(decoration: TextDecoration.none),
            ),
          ),
        );
      },
    );
  }

  String setUsername(List<Chat> chats) {
    String text = "";
    if (chats.isNotEmpty) {
      if (chats.length == 1) {
        text = chats.first.name;
      } else if (chats.length == 2) {
        text =
            "${setFilterUsername(chats.first.name)} ${localized(shareAnd)} ${setFilterUsername(chats[1].name)}";
      } else if (chats.length > 2) {
        text =
            "${setFilterUsername(chats.first.name)}, ${setFilterUsername(chats[1].name)} ${localized(
          andOthersWithParam,
          params: [
            '${chats.length - 2}',
          ],
        )}";
      }
    }
    return text;
  }

  String setFilterUsername(String text) {
    String username = text;
    if (text.length > 7) {
      username = "${text.substring(0, 7)}...";
    }
    return username;
  }

  void onSendEditedImage(
    List<Chat> chats,
    Chat currChat,
    EditorImageResult result,
  ) async {
    for (var chat in chats) {
      ChatHelp.sendImageFile(
        result.newFile,
        chat,
        width: result.imgWidth,
        height: result.imgHeight,
      );
    }
    Get.back();
    Get.back();

    imBottomToast(
      navigatorKey.currentContext!,
      title: localized(
        messageForwardedSuccessfullyToParam,
        params: [setUsername(chats)],
      ),
      icon: ImBottomNotifType.success,
      withAction: chats.length == 1,
      actionFunction: () {
        if (chats.length == 1) {
          Routes.toChat(chat: chats.first);
        }
      },
    );
  }

  void _onForwardMedia() {
    final Message msg = Message()
      ..init(computedAssets[photoData.currentPage]['message'].toJson());

    if (computedAssets[photoData.currentPage]['asset'] is AlbumDetailBean) {
      final AlbumDetailBean bean =
          computedAssets[photoData.currentPage]['asset'] as AlbumDetailBean;
      if (bean.cover.isNotEmpty ||
          (bean.asset is AssetEntity && bean.asset?.type == AssetType.video) ||
          (bean.asset is AssetPreviewDetail &&
              bean.asset.entity != null &&
              bean.asset.entity.type == AssetType.video)) {
        if (bean.url.isEmpty) return;
        msg.typ = messageTypeVideo;
        MessageVideo messageVideo = MessageVideo();
        if (msg.asset != null || bean.asset != null) {
          msg.asset = bean.asset;
        }
        messageVideo.url = bean.url;
        messageVideo.cover = bean.cover;
        messageVideo.size = bean.size;
        messageVideo.second = bean.seconds;
        messageVideo.height = bean.asheight ?? 0;
        messageVideo.width = bean.aswidth ?? 0;
        messageVideo.forward_user_id = objectMgr.userMgr.mainUser.uid;
        messageVideo.forward_user_name = objectMgr.userMgr.mainUser.nickname;
        msg.content = jsonEncode(messageVideo);

        msg.decodeContent(
          cl: msg.getMessageModel(msg.typ),
          v: jsonEncode(messageVideo),
        );
      } else {
        msg.typ = messageTypeImage;
        if (msg.asset != null || bean.asset != null) {
          msg.asset = bean.asset;
        }
        MessageImage messageImage = MessageImage();
        messageImage.url = bean.url;
        messageImage.height = bean.asheight ?? 0;
        messageImage.width = bean.aswidth ?? 0;
        messageImage.forward_user_id = objectMgr.userMgr.mainUser.uid;
        messageImage.forward_user_name = objectMgr.userMgr.mainUser.nickname;
        msg.content = jsonEncode(messageImage);
        msg.decodeContent(
          cl: msg.getMessageModel(msg.typ),
          v: jsonEncode(messageImage),
        );
      }
    }

    _onForwardAction(msg);
  }

  _onForwardAction(Message msg) {
    bool fromChatInfo = false;
    if (Get.isRegistered<ChatInfoController>() ||
        Get.isRegistered<GroupChatInfoController>()) {
      fromChatInfo = true;
    }

    if (widget.contentController == null) {
      if (fromChatInfo) {
        if (Get.isRegistered<ChatInfoController>()) {
          ChatInfoController controller = Get.find<ChatInfoController>();
          controller.selectedMessageList.add(msg);
          controller.onForwardMessage(context);
        } else if (Get.isRegistered<GroupChatInfoController>()) {
          GroupChatInfoController controller =
              Get.find<GroupChatInfoController>();
          controller.selectedMessageList.add(msg);
          controller.onForwardMessage(context);
        } else {
          Toast.showToast(localized(toastFileFailed));
          return;
        }
      }
      return;
    }

    widget.contentController!.chatController.chooseMessage[msg.message_id] =
        msg;

    widget.contentController!.inputController.onForwardMessage(
      fromChatInfo: fromChatInfo,
      fromMediaDetail: true,
    );
  }

  bool _isSaving = false;

  _onDownLoad() async {
    if (_isSaving) return;
    _isSaving = true;

    TencentVideoController? controller = _getVideo(photoData.currentPage);
    if (controller != null) {
      String vidPath = controller.downloadVideo();
      if (vidPath.isNotEmpty) await saveMedia(vidPath);
      _isSaving = false;
      return;
    }

    dynamic curData = computedAssets[photoData.currentPage]['asset'];
    Message message = computedAssets[photoData.currentPage]['message'];

    if (curData is AssetEntity) {
      File? file = await curData.file;
      await saveMedia(file!.path);
      _isSaving = false;
      return;
    }

    if (curData is File) {
      await saveMedia(curData.path);
      _isSaving = false;
      return;
    }

    if (curData is AlbumDetailBean) {
      if (computedAssets[photoData.currentPage]['filePath'] != null &&
          File(computedAssets[photoData.currentPage]['filePath'])
              .existsSync()) {
        await saveMedia(
          computedAssets[photoData.currentPage]['filePath'],
          isReturnPathOfIOS: true,
        );
        _isSaving = false;
        return;
      }

      curData = curData.url;
      final success = await saveImageToAlum(curData);
      if (success) {
        _isSaving = false;
        return;
      }
    }

    if (curData is String) {
      if (message.typ == messageTypeImage ||
          (message.typ == messageTypeNewAlbum) ||
          message.typ == messageTypeMarkdown) {
        if (computedAssets[photoData.currentPage]['filePath'] != null &&
            File(computedAssets[photoData.currentPage]['filePath'])
                .existsSync()) {
          await saveMedia(
            computedAssets[photoData.currentPage]['filePath'],
            isReturnPathOfIOS: true,
          );
          _isSaving = false;
          return;
        }

        final success = await saveImageToAlum(curData);
        if (success) {
          _isSaving = false;
          return;
        }
      }
    }

    Toast.showToast(localized(toastHavenDownload));
    _isSaving = false;
  }

  Future<bool> saveImageToAlum(String path) async {
    String? localPath = downloadMgr.checkLocalFile(
      path,
      mini: photoData.shouldShowOriginal ? Config().maxOriImageMin : null,
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

  Future<bool> saveMp4ToAlbum(String path) async {
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

  saveMedia(String path, {bool isReturnPathOfIOS = false}) async {
    final result = await ImageGallerySaver.saveFile(
      path,
      isReturnPathOfIOS: isReturnPathOfIOS,
    );

    if (result != null && result["isSuccess"]) {
      imBottomToast(
        Get.context!,
        title: localized(toastSaveSuccess),
        icon: ImBottomNotifType.saving,
        duration: 3,
      );
    } else {
      _onSaveFailToast(context);
    }
  }

  void _onSaveFailToast(BuildContext context) {
    BotToast.removeAll(BotToast.textKey);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title: localized(toastTryLater),
          subTitle: localized(toastSaveUnsuccessfulWaitVideoDownload),
          confirmButtonColor: colorRed,
          cancelButtonColor: themeColor,
          confirmButtonText: localized(buttonConfirm),
          cancelButtonText: localized(buttonConfirm),
          cancelCallback: Navigator.of(context).pop,
          confirmCallback: () {},
        );
      },
    );
  }

  _onDelete() async {
    Message message = computedAssets[photoData.currentPage]['message'];
    List<SelectionOptionModel> deleteOptionList = [
      SelectionOptionModel(
        title: localized(deleteForMe),
        stringValue: DeletePopupOption.deleteForMe.optionType,
        isSelected: false,
        titleTextStyle: jxTextStyle.textStyle20(color: colorRed),
      ),
    ];

    bool isOwner = false;
    bool isAdmin = false;
    bool isMine = objectMgr.userMgr.isMe(message.send_id);
    bool isSavedMessage = false;

    bool within24Hours =
        DateTime.now().millisecondsSinceEpoch - (message.create_time * 1000) <
            const Duration(days: 1).inMilliseconds;

    bool canDeleteForAll = true;

    if (widget.groupChatInfoController != null) {
      isOwner = widget.groupChatInfoController!.isOwner.value;
      isAdmin = widget.groupChatInfoController!.isAdmin.value;
    }
    if (widget.contentController != null) {
      if (widget.contentController!.chatController.chat.isGroup) {
        final chatController =
            widget.contentController!.chatController as GroupChatController;
        isOwner = chatController.isOwner;
        isAdmin = chatController.isAdmin;
      }

      isSavedMessage = widget.contentController!.chatController.chat.isSaveMsg;
    }

    if (isOwner) {
      if (isMine && !within24Hours) {
        canDeleteForAll = false;
      }
    } else if (isAdmin) {
      if (isMine && !within24Hours) {
        canDeleteForAll = false;
      } else {
        final chatController =
            widget.contentController!.chatController as GroupChatController;
        if (chatController.group.value != null &&
            chatController.group.value!.owner == message.send_id) {
          canDeleteForAll = false;
        }
      }
    } else if (isSavedMessage) {
      canDeleteForAll = false;
    } else {
      if (!isMine) {
        canDeleteForAll = false;
      } else {
        if (isMine && !within24Hours) {
          canDeleteForAll = false;
        }
      }
    }

    if (canDeleteForAll) {
      deleteOptionList.insert(
        0,
        SelectionOptionModel(
          title: localized(deleteForEveryone),
          stringValue: DeletePopupOption.deleteForEveryone.optionType,
          isSelected: false,
          titleTextStyle: jxTextStyle.textStyle20(color: colorRed),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectionBottomSheet(
          context: context,
          selectionOptionModelList: deleteOptionList,
          cancelButtonTextStyle: jxTextStyle.textStyle20(color: themeColor),
          callback: (int index) async {
            resetStatus();
            switch (deleteOptionList[index].stringValue) {
              case 'deleteForEveryone':
                onDeletePrompt(isAll: true);
                break;
              case 'deleteForMe':
                onDeletePrompt(isAll: false);
                break;
              default:
                break;
            }
          },
        );
      },
    );
  }

  onDeletePrompt({bool isAll = false}) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: localized(popupDelete),
          content: Text(
            isAll
                ? localized(chatInfoThisMessageWillBeDeletedForAllReceipts)
                : localized(
                    chatInfoThisMessageWillBeDeletedFromYourMessageHistory,
                  ),
            style: jxTextStyle.textDialogContent(),
            textAlign: TextAlign.center,
          ),
          confirmText: localized(buttonDelete),
          cancelText: localized(buttonCancel),
          confirmCallback: () => confirmDelete(isAll),
        );
      },
    );
  }

  Future<void> confirmDelete(bool isAll) async {
    int deletedIndex = photoData.currentPage;

    TencentVideoController? controller = _getVideo(deletedIndex);

    if (controller != null) {
      videoStreamMgr?.removeController(deletedIndex);
    }

    bool fromChatInfo = false;
    if (Get.isRegistered<ChatInfoController>() ||
        Get.isRegistered<GroupChatInfoController>()) {
      fromChatInfo = true;
    }

    final int actualPage = widget.reverse
        ? computedAssets.length - photoData.currentPage
        : photoData.currentPage;
    final asset = computedAssets[photoData.currentPage]['asset'];
    final message = computedAssets[photoData.currentPage]['message'];

    int? assetLength;
    int dest = 0;
    if (asset is AlbumDetailBean) {
      final NewMessageMedia mediaContent =
          message.decodeContent(cl: NewMessageMedia.creator);
      assetLength = mediaContent.albumList!.length - 1;
      int assetIndex = int.parse(asset.index_id!);
      if (assetLength != assetIndex) {
        dest = actualPage + assetIndex - assetLength;
      } else {
        dest = actualPage;
      }
    } else {
      dest = actualPage;
    }

    if (widget.reverse) {
      dest = computedAssets.length - dest;
    }

    Message delMessage = computedAssets[deletedIndex]["message"];
    if (computedAssets.length == 1 ||
        (assetLength != null && assetLength + 1 == computedAssets.length)) {
      if (!widget.isFromChatRoom) {
        Get.back();
      }
    } else {
      try {
        if (widget.reverse) {
          int k1 = computedAssets.length;
          int k2 = dest - (assetLength ?? 0);
          int k3 = dest + 1 > k1 ? k1 : dest + 1;
          k2 = k2 < 0 ? 0 : k2;
          computedAssets.removeRange(k2, k3);

          if (computedAssets.isEmpty) {
            Get.back();
            return;
          }

          if (dest - (assetLength ?? 0) == 0) {
            photoPageController.jumpToPage(dest + 1);
            photoPageController.jumpToPage(0);
            photoData.currentPage = 0;
          }
        } else {
          if (dest != 0) {
            photoPageController.jumpToPage(dest - 1);
            photoData.currentPage = dest - 1;
          } else {
            photoPageController.jumpToPage(0);
            photoData.currentPage = 0;
          }
          computedAssets.removeRange(dest, dest + (assetLength ?? 0) + 1);
        }
      } catch (e) {
        rethrow;
      }
    }

    if (widget.contentController == null) {
      if (fromChatInfo) {
        if (Get.isRegistered<ChatInfoController>()) {
          final controller = Get.find<ChatInfoController>();
          controller.deleteMessages(
            [delMessage],
            chatId: delMessage.chat_id,
            isAll: isAll,
          );
        } else if (Get.isRegistered<GroupChatInfoController>()) {
          final controller = Get.find<GroupChatInfoController>();
          controller.deleteMessages(
            [delMessage],
            chatId: delMessage.chat_id,
            isAll: isAll,
          );
        } else {
          Toast.showToast(localized(toastFileFailed));
          return;
        }
      }
    } else {
      await widget.contentController!.inputController.deleteMessages(
        [delMessage],
        widget.contentController!.chatController.chat.id,
        isAll: isAll,
        isFromChatRoom: widget.isFromChatRoom,
      );
    }
    resetStatus();
    if (mounted) setState(() {});
  }

  void resetStatus() {
    if (subOptionList.isNotEmpty) subOptionList.clear();

    if (_isVideoAsset(photoData.currentPage)) {
      optionList.assignAll(_vidBottomOptionList);
      appbarOptionList.assignAll(_vidAppOptionList);
    } else {
      optionList.assignAll(_imageBottomOptionList);
      appbarOptionList.assignAll(_imageAppOptionList);
    }
    widget.contentController?.chatController.isPinnedOpened = false;
  }

  bool keyboardEnabled(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 200;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        body: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Obx(
              () {
                if (coverFilePath.value is AssetEntity) {
                  return PhotoView(
                    image: AssetEntityImageProvider(
                      coverFilePath.value,
                    ),
                    fit: BoxFit.contain,
                    constraints: const BoxConstraints.expand(),
                  );
                } else if (coverFilePath.value is File) {
                  return PhotoView.file(
                    coverFilePath.value,
                    fit: BoxFit.contain,
                    constraints: const BoxConstraints.expand(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Obx(
              () => currMode.value == Mode.preview
                  ? buildPreview()
                  : buildEditPreview(),
            ),
            Obx(
              () => AnimatedPositioned(
                top: showToolBox.value
                    ? 0.0
                    : -kToolbarHeight - MediaQuery.of(context).viewPadding.top,
                left: 0.0,
                right: 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                child: currMode.value == Mode.preview
                    ? buildAppBar(context)
                    : buildEditAppBar(context),
              ),
            ),
            Obx(() {
              return AnimatedPositioned(
                right: 12.0,
                top: kToolbarHeight + MediaQuery.of(context).viewPadding.top,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  width: subOptionList.isNotEmpty ? 152 : 0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorMediaBarBg,
                  ),
                  child: Column(
                    children: [
                      ...List.generate(subOptionList.length, (index) {
                        ToolOptionModel model = subOptionList[index];
                        return OpacityEffect(
                          child: GestureDetector(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: index == subOptionList.length - 1
                                      ? BorderSide.none
                                      : const BorderSide(
                                          color: colorBorder,
                                          width: 1.0,
                                        ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      localized(model.title),
                                      style: jxTextStyle.textStyle16(
                                        color: colorWhite.withOpacity(0.95),
                                      ),
                                    ),
                                  ),
                                  SvgPicture.asset(
                                    model.imageUrl ?? "",
                                    width: 20,
                                    height: 20,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              onTap(model.optionType, index);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
            Obx(() {
              return AnimatedPositioned(
                bottom: showToolBox.value
                    ? 0
                    : -48 - 48 - MediaQuery.of(context).viewPadding.bottom,
                left: 0.0,
                right: 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                child: currMode.value == Mode.preview
                    ? buildBottomBar(context, photoData.currentPage)
                    : buildEditBottomBar(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildPreview() {
    return PhotoViewSlidePage(
      slideAxis: SlideDirection.vertical,
      slideType: SlideArea.onlyImage,
      slidePageBackgroundHandler: (Offset offset, Size pageSize) {
        return Colors.black;
      },
      child: PhotoViewGesturePageView.builder(
        reverse: widget.reverse,
        scrollDirection: Axis.horizontal,
        controller: photoPageController,
        itemCount: computedAssets.length,
        onPageChanged: onPageChange,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              _onTapVideo();
              captionFocus.unfocus();
            },
            child: buildMedia(context, index),
          );
        },
      ),
    );
  }

  Widget buildEditPreview() {
    return Obx(
      () => RepaintBoundary(
        child: PhotoView.file(
          editedFile.value,
          fit: BoxFit.contain,
          mode: PhotoViewMode.gesture,
          constraints: const BoxConstraints.expand(),
          initGestureConfigHandler: initGestureConfigHandler,
          loadStateChanged: onEditedPhotoViewLoadStateChanged,
        ),
      ),
    );
  }

  Widget onEditedPhotoViewLoadStateChanged(PhotoViewState state) {
    if (state.extendedImageLoadState == PhotoViewLoadState.completed) {
      Future.delayed(const Duration(milliseconds: 300), () {
        coverFilePath.value = '';
      });
    }
    return photoLoadStateChanged(
      state,
      loadingItemBuilder: () => const SizedBox.shrink(),
    );
  }

  Widget buildAppBar(BuildContext context) {
    int index = photoData.currentPage;
    if (index > computedAssets.length - 1) {
      return const SizedBox();
    }
    Message message = computedAssets[index]['message'];
    var options =
        appbarOptionList.where((item) => item.isShow == true).toList();
    List<Widget> optionTab = [];

    if (options.isNotEmpty) {
      if (options.length <= 2) {
        optionTab = _loadAllOptions(options, index);
      } else {
        var first = options.sublist(0, 1);
        var moreOption = MessagePopupOption.more.toolOption;
        var others = List<ToolOptionModel>.from(options.sublist(1));
        moreOption.subOptions = others;
        first.add(moreOption);
        optionTab = _loadAllOptions(first, index);
      }
    }

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(
          top: 0,
          bottom: 8.0,
        ),
        color: Colors.black.withOpacity(0.6),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: Opacity(
                opacity: _isVideoAsset(photoData.currentPage) ? 1 : 0,
                alwaysIncludeSemantics: true,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Obx(
                      () => SizedBox(
                        height: isLandscape.value
                            ? 4
                            : MediaQuery.of(context).viewPadding.top +
                                (Platform.isIOS ? 0 : 3),
                      ),
                    ),
                    message.send_id == 0
                        ? Text(
                            Config().appName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MFontSize.size20.value,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: MFontWeight.bold5.value,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : NicknameText(
                            uid: message.send_id,
                            color: Colors.white,
                            fontSize: MFontSize.size20.value,
                            fontWeight: MFontWeight.bold5.value,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            isTappable: false,
                            groupId: widget.contentController!.chat!.isGroup
                                ? widget.contentController!.chat!.id
                                : null,
                          ),
                    Text(
                      FormatTime.getTime(message.create_time),
                      style: jxTextStyle.textStyle14(
                        color: colorWhite.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(
                      height: (Platform.isIOS ? 6 : 3),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0.0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: Navigator.of(context).pop,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 40,
                    top: MediaQuery.of(context).viewPadding.top,
                  ),
                  child: OpacityEffect(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svgs/Back.svg',
                          width: 17.5,
                          height: 17.5,
                          color: Colors.white,
                        ),
                        Container(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            localized(buttonBack),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: MFontWeight.bold4.value,
                              fontFamily: appFontfamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).viewPadding.top,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: optionTab,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEditAppBar(BuildContext context) {
    double appBarHeight =
        kToolbarHeight + MediaQuery.of(context).viewPadding.top;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).viewPadding.top,
      ),
      height: appBarHeight,
      color: colorMediaBarBg,
      child: NavigationToolbar(
        leading: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Get.back();
          },
          child: OpacityEffect(
            child: SizedBox(
              width: 90,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      localized(buttonBack),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.25,
                        fontFamily: appFontfamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        centerMiddle: true,
      ),
    );
  }

  List<Widget> _loadAllOptions(dynamic options, int index) {
    List<Widget> optionTab = [];
    options.forEach((item) {
      TencentVideoController? controller = _getVideo(photoData.currentPage);

      Widget w;

      if (controller != null &&
          item.optionType == MessagePopupOption.mute.optionType) {
        w = Obx(
          () => SvgPicture.asset(
            controller.muted.value ? item.checkImageUrl : item.unCheckImageUrl,
            width: 24,
            height: 24,
            color: Colors.white,
          ),
        );
      } else {
        w = SvgPicture.asset(
          item.imageUrl ?? item.checkImageUrl,
          width: 24,
          height: 24,
          color: Colors.white,
        );
      }

      bool scaleTouchArea = item.optionType == "saveToGallery";
      Widget tab = GestureDetector(
        onTap: () => onTap(item.optionType, index),
        behavior: HitTestBehavior.translucent,
        child: OpacityEffect(
          child: Padding(
            padding: EdgeInsets.only(
              right: 16,
              top: scaleTouchArea ? 5 : 0,
              left: scaleTouchArea ? 5 : 0,
              bottom: scaleTouchArea ? 5 : 0,
            ).w,
            child: w,
          ),
        ),
      );
      optionTab.add(tab);
    });

    return optionTab;
  }

  Widget buildBottomBar(BuildContext context, int index) {
    if (photoData.currentPage > computedAssets.length - 1) {
      return const SizedBox();
    }
    List<Widget> optionTab = [];
    dynamic bean = computedAssets[photoData.currentPage]['asset'];
    Message message = computedAssets[photoData.currentPage]['message'];
    bool isVideo = _isVideoAsset(photoData.currentPage);
    TencentVideoController? controller = _getVideo(photoData.currentPage);

    if (optionList.isNotEmpty) {
      for (var item in optionList) {
        if (item.isShow) {
          if (item.optionType == MessagePopupOption.edit.optionType) {
            if (message.typ == messageTypeVideo ||
                message.typ == messageTypeReel) continue;
            if (bean is AlbumDetailBean &&
                (bean.cover.isNotEmpty ||
                    (bean.mimeType?.contains('video') ?? false))) continue;

            if (message.typ == messageTypeMarkdown ||
                (widget.contentController?.chat?.typ ?? 0) > chatTypeSaved) {
              Widget tab = const SizedBox();
              optionTab.add(tab);
              continue;
            } else {
              Widget tab = GestureDetector(
                onTap: () => onTap(item.optionType, index),
                behavior: HitTestBehavior.translucent,
                child: OpacityEffect(
                  child: SvgPicture.asset(
                    item.imageUrl!,
                    width: 24,
                    height: 24,
                  ),
                ),
              );
              optionTab.add(tab);
              continue;
            }
          }

          Widget w;

          if (controller != null &&
              item.optionType == MessagePopupOption.play.optionType) {
            w = Obx(
              () => SvgPicture.asset(
                controller.isSeeking.value
                    ? ((controller.previousState == TencentVideoState.PLAYING ||
                            controller.previousState ==
                                TencentVideoState.LOADING)
                        ? item.checkImageUrl
                        : item.unCheckImageUrl)
                    : (controller.playerState.value ==
                                TencentVideoState.PLAYING ||
                            controller.playerState.value ==
                                TencentVideoState.LOADING)
                        ? item.checkImageUrl
                        : item.unCheckImageUrl,
                width: 24,
                height: 24,
                color: Colors.white,
              ),
            );
          } else {
            w = SvgPicture.asset(
              item.imageUrl ?? item.checkImageUrl,
              width: 24,
              height: 24,
              color: Colors.white,
            );
          }

          if (item.optionType == MessagePopupOption.forward.optionType &&
              ((widget.contentController?.chat?.typ ?? 0) > chatTypeSaved ||
                  message.typ == messageTypeMarkdown)) {
            Widget tab = const Padding(
              padding: EdgeInsets.only(left: 16.0, right: 16.0),
              child: SizedBox(
                height: 24,
                width: 24,
              ),
            );
            optionTab.add(tab);
            continue;
          }

          Widget tab = GestureDetector(
            onTap: () => onTap(item.optionType, index),
            behavior: HitTestBehavior.translucent,
            child: OpacityEffect(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: w,
              ),
            ),
          );
          optionTab.add(tab);
        }
      }
    }

    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        height:
            (isVideo ? 83.0 : 44.0) + MediaQuery.of(context).viewPadding.bottom,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (controller != null)
              TencentVideoSlider(
                controller: controller,
              ),
            Stack(
              alignment: AlignmentDirectional.center,
              children: [
                !isVideo
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          optionTab[0],
                          ...[
                            Row(
                              children: [
                                optionTab[1],
                                optionTab[2],
                              ],
                            ),
                          ],
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: optionTab,
                      ),
                if (!isVideo) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      optionTab[0],
                      ...[
                        Row(children: [optionTab[1], optionTab[2]]),
                      ],
                    ],
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 170,
                          child: message.send_id == 0
                              ? Text(
                                  Config().appName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: MFontSize.size17.value,
                                    overflow: TextOverflow.ellipsis,
                                    height: ImLineHeight.getLineHeight(
                                      fontSize: 17,
                                      lineHeight: 23.8,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              : NicknameText(
                                  uid: message.send_id,
                                  color: Colors.white,
                                  fontSize: MFontSize.size17.value,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLine: 1,
                                  fontLineHeight: ImLineHeight.getLineHeight(
                                    fontSize: 17,
                                    lineHeight: 23.8,
                                  ),
                                  isTappable: false,
                                  groupId:
                                      widget.contentController!.chat!.isGroup
                                          ? widget.contentController!.chat!.id
                                          : null,
                                ),
                        ),
                        Text(
                          FormatTime.getTime(message.create_time),
                          style: jxTextStyle.textStyle13(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEditBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        top: showToolBox.value ? 6.0 : 0.0,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? max(
                MediaQuery.of(context).viewInsets.bottom,
                MediaQuery.of(context).viewPadding.bottom,
              )
            : MediaQuery.of(context).viewPadding.bottom,
      ),
      color: colorMediaBarBg,
      child: Column(
        children: <Widget>[
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: TextField(
                contextMenuBuilder: textMenuBar,
                autocorrect: false,
                enableSuggestions: false,
                textAlignVertical: TextAlignVertical.center,
                textAlign:
                    captionController.text.isNotEmpty || captionFocus.hasFocus
                        ? TextAlign.left
                        : TextAlign.center,
                maxLines: 4,
                minLines: 1,
                focusNode: captionFocus,
                controller: captionController,
                keyboardType: TextInputType.multiline,
                scrollPhysics: const ClampingScrollPhysics(),
                maxLength: 4096,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4096),
                ],
                cursorColor: Colors.white,
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 16.0,
                  color: colorWhite,
                  height: 1.25,
                  textBaseline: TextBaseline.alphabetic,
                ),
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: localized(writeACaption),
                  hintStyle: TextStyle(
                    fontSize: 16.0,
                    color: keyboardEnabled(context)
                        ? colorWhite
                        : colorWhite.withOpacity(0.6),
                    height: 1.25,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                  isDense: true,
                  fillColor: colorWhite.withOpacity(0.2),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  isCollapsed: true,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                ),
                onTapOutside: (event) {
                  captionFocus.unfocus();
                },
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: bottomBarHeight,
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16,
              top: 4.0,
              bottom: 4.0,
            ),
            margin: const EdgeInsets.only(bottom: 6.0),
            alignment: Alignment.center,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => reEditPhoto(),
                  child: OpacityEffect(
                    child: Image.asset(
                      'assets/images/pen_edit2.png',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                OpacityEffect(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: sendReEditedImageWithCaption,
                    child: Row(
                      children: [
                        ClipOval(
                          child: Container(
                            color: themeColor,
                            width: 28,
                            height: 28,
                            padding: const EdgeInsets.all(6.0),
                            child: SvgPicture.asset(
                              'assets/svgs/send_arrow.svg',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMedia(BuildContext context, int index) {
    if (_isVideoAsset(index) &&
        !shouldBuildMedia(photoData.currentPage, index)) {
      return const SizedBox();
    }

    return _buildMediaWidget(index);
  }

  bool shouldBuildMedia(int currentIndexOfPage, int indexToBuild) {
    int range = videoCacheRange;

    return (currentIndexOfPage - range) <= indexToBuild &&
        indexToBuild <= (currentIndexOfPage + range);
  }

  Widget _buildMediaWidget(int index) {
    Message message = computedAssets[index]['message'];
    Map<String, dynamic> asset = computedAssets[index];

    if (message.typ == messageTypeImage) {
      MessageImage messageImage =
          message.decodeContent(cl: MessageImage.creator);
      return PhotoDetail(
        key: ValueKey("${message.message_id}-$index"),
        item: message.asset ?? messageImage,
        message: message,
        photoData: photoData,
        height: messageImage.height.toDouble(),
        width: messageImage.width.toDouble(),
      );
    }

    if (message.typ == messageTypeVideo || message.typ == messageTypeReel) {
      MessageVideo messageVideo =
          message.decodeContent(cl: MessageVideo.creator);

      dynamic asset;
      if (message.asset != null &&
          (message.asset is AssetEntity || message.asset is File)) {
        asset = message.asset;
      } else if (File(messageVideo.filePath).existsSync()) {
        asset = File(messageVideo.filePath);
      } else {
        asset = messageVideo.url;
      }

      VideoDetail detail = VideoDetail(
        key: ValueKey("${message.message_id}-$index"),
        url: asset,
        coverSrc: messageVideo.cover,
        streamMgr: videoStreamMgr!,
        index: index,
        message: computedAssets[index]['message'],
        width: messageVideo.width,
        height: messageVideo.height,
        currentPage: photoData.currentPage,
      );

      return detail;
    }

    if (asset['asset'] is AlbumDetailBean) {
      AlbumDetailBean bean = asset['asset'];

      bool isVideo = bean.asset != null &&
          ((bean.asset is AssetEntity && bean.asset!.type == AssetType.video) ||
              (bean.asset is AssetPreviewDetail &&
                  bean.asset!.entity.type == AssetType.video));

      if (bean.cover.isNotEmpty ||
          (bean.mimeType?.contains('video') ?? false) ||
          isVideo) {
        return buildAlbumDetailItemVideo(message, bean, index);
      } else {
        return buildAlbumDetailItemImage(message, bean, index);
      }
    }

    if (message.typ == messageTypeMarkdown) {
      MessageMarkdown messageMarkdown =
          message.decodeContent(cl: MessageMarkdown.creator);
      if (messageMarkdown.video.isNotEmpty) {
        return VideoDetail(
          key: ValueKey("${message.message_id}-$index"),
          url: messageMarkdown.video,
          coverSrc: messageMarkdown.image,
          streamMgr: videoStreamMgr!,
          index: index,
          message: computedAssets[index]['message'],
          width: messageMarkdown.width,
          height: messageMarkdown.height,
          currentPage: photoData.currentPage,
        );
      } else {
        return PhotoDetail(
          key: ValueKey("${message.message_id}-$index"),
          item: messageMarkdown,
          message: message,
          photoData: photoData,
          width: messageMarkdown.width.toDouble(),
          height: messageMarkdown.height.toDouble(),
        );
      }
    }

    return const SizedBox();
  }

  Widget buildAlbumDetailItemImage(
    Message message,
    AlbumDetailBean media,
    int index,
  ) {
    if (media.url.isNotEmpty) {
      return PhotoDetail(
        key: ValueKey(media.url),
        photoData: photoData,
        item: media,
        message: message,
        height: media.asheight!.toDouble(),
        width: media.aswidth!.toDouble(),
      );
    } else {
      dynamic entity = media.asset;
      if (entity != null) {
        return PhotoDetail(
          key: ValueKey(media.asset.toString()),
          photoData: photoData,
          item: entity,
          message: message,
          height: entity.height.toDouble(),
          width: entity.width.toDouble(),
        );
      } else {
        return const SizedBox();
      }
    }
  }

  Widget buildAlbumDetailItemVideo(
    Message message,
    AlbumDetailBean media,
    int index,
  ) {
    dynamic asset;

    if (message.asset != null &&
        (message.asset is AssetEntity || message.asset is File)) {
      asset = message.asset;
    } else if (File(media.filePath).existsSync()) {
      asset = File(media.filePath);
    } else {
      asset = media.url;
    }

    VideoDetail detail = VideoDetail(
      key: ValueKey("${message.message_id}-$index"),
      url: asset,
      coverSrc: media.cover,
      streamMgr: videoStreamMgr!,
      index: index,
      message: computedAssets[index]['message'],
      width: media.aswidth ?? 0,
      height: media.asheight ?? 0,
      currentPage: photoData.currentPage,
    );

    return detail;
  }

  void _preloadVideos(int index) async {
    for (int i = index - videoCacheRange; i <= index + videoCacheRange; i++) {
      final (
        String url,
        String cover,
        String? gausPath,
        int width,
        int height
      ) = await _getPreloadParams(i);
      if (url.isNotEmpty) {
        if (objectMgr.tencentVideoMgr.currentStreamMgr?.getVideoStream(i) ==
            null) {
          TencentVideoConfig config = TencentVideoConfig(
            url: url,
            thumbnail: cover,
            thumbnailGausPath: gausPath,
            width: width,
            height: height,
            autoplay: i == photoData.currentPage,
            type: ConfigType.saveMp4,
          );

          objectMgr.tencentVideoMgr.currentStreamMgr
              ?.addController(config, index: i);
        }
      }
    }
    if (!_preloadedVideos && mounted) {
      _preloadedVideos = true;
      setState(() {});
    }
  }

  void _onVideoPageChange(int index) {
    videoStreamMgr!.removeControllersOutOfRange(index, videoCacheRange);
    _preloadVideos(index);

    TencentVideoController? controller = _getVideo(index);

    videoStreamMgr!.pausePlayingControllers(index);
    if (controller != null) {
      if (!hasLimitedVolume) {
        hasLimitedVolume = true;
        VideoVolumeManager.instance.limitVideoVolume();
        widget.contentController?.chatController.playerService.onClose();
      }
      controller.play();
    }
  }

  bool _isVideoAsset(int index) {
    if (index > computedAssets.length - 1) {
      return false;
    }
    Message message = computedAssets[index]['message'];
    dynamic asset = computedAssets[index]['asset'];
    return checkForVideo(message, asset);
  }

  TencentVideoController? _getVideo(int index) {
    return videoStreamMgr?.getVideo(index);
  }

  Future<(String, String, String?, int, int)> _getPreloadParams(
      int index) async {
    if (!(index >= 0 && index < computedAssets.length)) {
      return ("", "", null, 0, 0);
    }
    Message message = computedAssets[index]['message'];
    dynamic asset = computedAssets[index]['asset'];
    return await getVideoParams(message, asset);
  }
}
