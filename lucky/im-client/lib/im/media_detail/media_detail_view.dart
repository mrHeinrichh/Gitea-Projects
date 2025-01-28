import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cbb_video_player/cbb_video_event_dispatcher.dart';
import 'package:cbb_video_player/cbb_video_player_controller.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as IM;
import 'package:image_editor/flutter_image_editor.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/tool_option_model.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/forward/forward_container.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/media_detail/photo_detail.dart';
import 'package:jxim_client/im/media_detail/video_detail.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/services/media/models/asset_preview_detail.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/task/video/video_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/ToolOptionModelConstants.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/message/larger_photo_data.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/floating_window/assist/floating_slide_type.dart';
import 'package:jxim_client/views/floating_window/floating.dart';
import 'package:jxim_client/views/floating_window/manager/floating_manager.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:jxim_client/views/component/custom_alert_dialog.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';

class MediaDetailView extends StatefulWidget {
  /// [asset] 可以有的状态, asset : AssetEntity | String | AlbumDetailBean,
  /// [cover] 可以有的状态, url : String
  /// [message] 对应的消息
  final List<Map<String, dynamic>> assetList;

  final int index;

  final ChatContentController? contentController;
  final GroupChatInfoController? groupChatInfoController;
  final bool reverse;

  const MediaDetailView({
    super.key,
    required this.assetList,
    required this.index,
    this.contentController,
    this.groupChatInfoController,
    this.reverse = false,
  });

  @override
  State<MediaDetailView> createState() => MediaDetailViewState();
}

class MediaDetailViewState extends State<MediaDetailView>
    with WidgetsBindingObserver {
  static ToolOptionModel _forwardOption = MessagePopupOption.forward.toolOption;
  late final PageController photoPageController;
  final LargerPhotoData photoData = LargerPhotoData();
  ScrollPhysics scrollPhysics = const BouncingScrollPhysics();

  // 展示工具栏
  RxBool showToolBox = true.obs;

  ValueNotifier<bool> isDragging = ValueNotifier<bool>(false);

  final reelFloatingKey = "reel_view";
  final isReelVideo = false.obs;
  final isFullMode = true.obs;
  final isLandscape = false.obs;

  Floating? _videoFloating;

  List<ToolOptionModel> _imageBottomOptionList = [
    _forwardOption,
    MessagePopupOption.edit.toolOption,
    MessagePopupOption.delete.toolOption
  ];

  List<ToolOptionModel> _vidBottomOptionList = [
    _forwardOption,
    MessagePopupOption.backward10sec.toolOption,
    MessagePopupOption.play.toolOption,
    MessagePopupOption.forward10sec.toolOption,
    MessagePopupOption.delete.toolOption
  ];

  List<ToolOptionModel> _imageAppOptionList = [
    // MessagePopupOption.edit.toolOption,
    MessagePopupOption.saveToGallery.toolOption
  ];

  List<ToolOptionModel> _vidAppOptionList = [
    // MessagePopupOption.mute.toolOption,
    // MessagePopupOption.minimize.toolOption,
    // MessagePopupOption.speed.toolOption,
    MessagePopupOption.saveToGallery.toolOption
  ];

  final optionList = [].obs;
  final appbarOptionList = [].obs;
  final subOptionList = [].obs;
  final RxList<Map<String, dynamic>> computedAssets =
      RxList<Map<String, dynamic>>();
  bool noMoreNext = false;
  final showingPhotoOriginal = false.obs;
  final shouldShowPhotoOriginal = false.obs;
  Function()? onOriginalShow;
  final size = 0.obs;
  final Map<int, VideoDetail> localMP4Details = {};

  @override
  void initState() {
    super.initState();
    computedAssets.assignAll(widget.assetList);
    CBBVideoEvents.instance.isDebug = Config().isDebug;
    photoPageController = PageController(initialPage: widget.index);
    photoData.currentPage = widget.index;

    if (CBBVideoEvents.instance.getController(widget.index,
            isVideo: computedAssets[widget.index]['hasVideo'] ?? false) !=
        null) {
      optionList.assignAll(_vidBottomOptionList);
      appbarOptionList.assignAll(_vidAppOptionList);
    } else {
      optionList.assignAll(_imageBottomOptionList);
      appbarOptionList.assignAll(_imageAppOptionList);
    }

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

    photoData.on(LargerPhotoData.eventScaleChange, onScaleChange);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    isLandscape.value = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.aspectRatio >
        1;

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    // This will be triggered by changes in orientation.
    super.didChangeMetrics();
    // WidgetsBinding.instance.window.physicalSize.aspectRatio > 1 ? Orientation.landscape : Orientation.portrait;
    isLandscape.value = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.aspectRatio >
        1;

    if (isLandscape.value &&
        objectMgr.callMgr.currentState.value == CallState.Idle) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.bottom]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    }
  }

  @override
  void dispose() {
    photoData.off(LargerPhotoData.eventScaleChange, onScaleChange);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    WidgetsBinding.instance.removeObserver(this);

    CBBVideoEvents.instance.removeAllControllers();
    super.dispose();
  }

  void onScaleChange(_, __, ___) {
    if (photoData.scale <= 1.0) {
      isDragging.value = false;
    } else {
      isDragging.value = true;
    }
  }

  void onPageChange(int index) {
    _populateData(index);
    _onVideoPageChange(index);
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
    int indexRange = CBBVideoEvents.instance.cacheRange;
    for (int i = index + 1; i <= index + indexRange; i++) {
      if (computedAssets.value.length <= i) {
        toCheck = true;
        break;
      }
    }

    if (!toCheck) return;
    //已经超出范围，需要重新下载更多。

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
      if (message.deleted == 1 || !message.isMediaType) {
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

        assetMap['hasVideo'] = true;
        assetList.add(assetMap);
      } else {
        if (notBlank(message.asset)) {
          List<AssetEntity> reversedAsset = message.asset.reversed.toList();
          for (int i = 0; i < reversedAsset.length; i++) {
            Map<String, dynamic> assetMap = {};
            AssetEntity asset = reversedAsset[i];
            NewMessageMedia msgMedia = message.decodeContent(
              cl: NewMessageMedia.creator,
            );

            if (notBlank(msgMedia.albumList) &&
                msgMedia.albumList!.length > i) {
              AlbumDetailBean bean = msgMedia.albumList![i];
              bean.asset = asset;
              assetMap['asset'] = bean;
              assetMap['message'] = message;

              if (asset.type == AssetType.video) {
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
                  assetMap['hasVideo'] = true;
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

  void _closeFloating() {
    floatingManager.closeFloating(reelFloatingKey);
    isFullMode.value = true;
    _videoFloating = null;
  }

  //新版本用messageType来判断，旧版本用视频链接后面的参数判断，发几个版本后删除旧版本的支持
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

  _onShowMediaView(BuildContext context) {
    Get.back();

    _videoFloating = floatingManager.createFloating(
      reelFloatingKey,
      Floating(
        Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: JXColors.black,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4C000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 12,
                    offset: Offset(0, 8),
                    spreadRadius: 6,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: buildMedia(context, photoData.currentPage),
              ),
            )),
        slideType: FloatingSlideType.onRightAndTop,
        isShowLog: false,
        isSnapToEdge: false,
        isPosCache: true,
        moveOpacity: 1.0,
        height: 200,
        width: 120,
        top: MediaQuery.of(context).viewPadding.top,
      ),
    );
    isFullMode.value = false;
    _videoFloating?.open(context);
  }

  bool _onTapVideo() {
    showToolBox.value = !showToolBox.value;
    return showToolBox.value;
  }

  void onTap(String optionType, int index) {
    final Message currentMsg = computedAssets[photoData.currentPage]['message'];
    CBBVideoPlayerController? controller = CBBVideoEvents.instance
        .getController(index,
            isVideo: computedAssets[index]['hasVideo'] ?? false);

    int? chatId;
    int? chatIdx;

    if (EasyDebounce.hasTag(CBBVideoPlayerController.stateChangeDebounceTag)) {
      EasyDebounce.cancel(CBBVideoPlayerController.stateChangeDebounceTag);
    }

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
                chatIdx, currentMsg.id, currentMsg.create_time);
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

        /// 获取到指定的option
        resetStatus();
        _onPhotoEdit();
        break;
      case "forward":

        /// 获取到指定的option
        resetStatus();
        _onForwardMedia();
        break;
      case "saveToGallery":
        resetStatus();
        _onDownLoad();
        break;
      case "delete":

        /// 获取到指定的option
        resetStatus();
        _onDelete();
        break;
      case "play":
      case "pause":
        resetStatus();
        if (controller != null) {
          controller.togglePlayState();
        }
        break;
      case "forward10sec":
        resetStatus();
        if (controller != null) {
          controller.onForwardVideo();
        }
        break;
      case "backward10sec":
        resetStatus();
        if (controller != null) {
          controller.onRewindVideo();
        }
        break;
      case "mute":
        resetStatus();
        if (controller != null) {
          controller.isMuted.value = !controller.isMuted.value;
        }
        break;
      case "minimize":
        resetStatus();
        break;
      case "more":
        // var options =
        // appbarOptionList.values.firstWhere((item) => item.subOptions != null && item.subOptions).toList();
        // subOptionList.value.addAll(callback.)
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
          getImageSizeThenSendMessage(message, asset.path);
          return;
        } else {
          fileName = asset;
        }

        if (fileName == null || fileName.isEmpty) {
          Toast.showToast(localized(toastFileFailed));
          return;
        }

        filePath = cacheMediaMgr.checkLocalFile(fileName);

        if (filePath == null) {
          filePath = await cacheMediaMgr.downloadMedia(fileName);
        }
      }

      if (filePath == null) {
        Toast.showToast(localized(toastFileFailed));
        return;
      }

      getImageSizeThenSendMessage(message, filePath);
    } catch (e) {
      debugPrint('[onPhotoEdit]: edit photo in error $e');
    }
  }

  Future<void> getImageSizeThenSendMessage(
    Message message,
    String? filePath,
  ) async {
    final newFile = await copyImageFile(File(filePath!));
    var done = await FlutterPhotoEditor().editImage(newFile.path);
    final Map<String, dynamic>? uiImage = await getImageFromAsset(newFile);

    if (done) {
      Chat? chat = await objectMgr.chatMgr.getChatById(message.chat_id);
      if (chat != null) {
        final result = await Get.toNamed(
          RouteName.mediaPreSendView,
          arguments: {
            'filePath': newFile.path,
            'message': message,
          },
        );
        debugPrint('=====result=======${result}');
        ChatHelp.sendImageFile(
          File(result['filePath']),
          chat,
          width: uiImage?['width'].toInt(),
          height: uiImage?['height'].toInt(),
          caption: result['caption'],
        );
        Get.back();
        playSendMessageSound();
      }
      // when edit completely, save to galley
      ImageGallerySaver.saveFile(newFile.path);
    }
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
      List<Chat>? chat, Chat currChat, EditorImageResult result) async {
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
                            .textStyle16(color: JXColors.primaryTextBlack)
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
                        .textStyle16(color: accentColor)
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
                  .textStyle16(color: accentColor)
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
            "${setFilterUsername(chats.first.name)}, ${setFilterUsername(chats[1].name)} ${localized(andOthersWithParam, params: [
              '${chats.length - 2}'
            ])}";
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
      List<Chat> chats, Chat currChat, EditorImageResult result) async {
    chats.forEach((chat) {
      ChatHelp.sendImageFile(
        result.newFile,
        chat,
        width: result.imgWidth,
        height: result.imgHeight,
      );
    });
    Get.back();
    Get.back();

    ImBottomToast(
      Routes.navigatorKey.currentContext!,
      title: localized(messageForwardedSuccessfullyToParam,
          params: [setUsername(chats)]),
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
            cl: msg.getMessageModel(msg.typ), v: jsonEncode(messageVideo));
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
            cl: msg.getMessageModel(msg.typ), v: jsonEncode(messageImage));
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
        final controller;
        if (Get.isRegistered<ChatInfoController>()) {
          controller = Get.find<ChatInfoController>();
        } else if (Get.isRegistered<GroupChatInfoController>()) {
          controller = Get.find<GroupChatInfoController>();
        } else {
          Toast.showToast(localized(toastFileFailed));
          return;
        }

        controller!.selectedMessageList.add(msg);
        controller!.onForwardMessage(context);
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

  _onDownLoad() async {
    if (await Permission.storage.request().isGranted) {
      ImBottomToast(
        context,
        title: localized(mediaDownloading),
        icon: ImBottomNotifType.none,
        duration: 1,
      );
      dynamic curData = computedAssets[photoData.currentPage]['asset'];
      Message message = computedAssets[photoData.currentPage]['message'];

      if (curData is AssetEntity) {
        File? file = await curData.file;
        await saveMedia(file!.path);
        return;
      }

      if (curData is File) {
        await saveMedia(curData.path);
        return;
      }

      bool isVideo = false;

      if (curData is AlbumDetailBean) {
        isVideo = curData.cover.isNotEmpty ||
            (curData.mimeType?.contains('video') ?? false);
        if (isVideo) {
          String? path = await checkExistM3u8(curData.url);
          if (path != null) {
            await saveMedia(path);
            return;
          }

          if (notBlank(curData.source)) {
            curData = curData.source;
          } else {
            curData = curData.url;
          }
        } else {
          curData = curData.url;
        }
      }

      if (message.typ == messageTypeVideo) {
        isVideo = true;
        var messageVideo = message.decodeContent(cl: MessageVideo.creator);
        String? path = await checkExistM3u8(messageVideo.url);
        if (path != null) {
          await saveMedia(path);
          return;
        }

        curData = message.decodeContent(cl: MessageVideo.creator).source;
      }

      /// 可能到这个判断的 消息为 [MessageImage] 和 [MessageVideo]
      if (curData is String) {
        String? downloadedSrc;
        if (message.typ == messageTypeImage ||
            (message.typ == messageTypeNewAlbum && !isVideo)) {
          downloadedSrc = await cacheMediaMgr.downloadMedia(
            curData,
            mini: photoData.shouldShowOriginal ? Config().maxOriImageMin : null,
          );

          if (downloadedSrc == null) {
            downloadedSrc = await cacheMediaMgr.downloadMedia(
              curData,
              mini: Config().messageMin,
            );
          }
        } else {
          if (curData.contains('.m3u8')) {
            downloadedSrc = await _onDownloadOldVideo(curData);
          } else {
            downloadedSrc = await cacheMediaMgr.downloadMedia(
              curData,
              timeoutSeconds: 500,
            );
          }
        }

        if (downloadedSrc == null) {
          await Future.delayed(const Duration(seconds: 1));
          Toast.showToast(localized(toastSaveUnsuccessful));
          return;
        }

        await saveMedia(downloadedSrc, isReturnPathOfIOS: true);
        return;
      }

      await Future.delayed(const Duration(seconds: 1));
      Toast.showToast(localized(toastSaveUnsuccessful));
    }
  }

  Future<String?> checkExistM3u8(String m3u8Path) async {
    final String localM3u8File = await videoMgr.previewVideoM3u8(m3u8Path);
    final tsDirLastIdx = m3u8Path.lastIndexOf('/');
    final tsDir = m3u8Path.substring(0, tsDirLastIdx);
    Map<double, Map<String, dynamic>> tsMap = await cacheMediaMgr.extractTsUrls(
      tsDir,
      localM3u8File,
    );
    List<String> tsFiles = [];

    tsMap.forEach((key, value) {
      if (notBlank(value['url'])) {
        String? cacheUrl = cacheMediaMgr.checkLocalFile(value['url']);
        if (cacheUrl != null) {
          tsFiles.add(cacheUrl);
        }
      }
    });

    if (tsFiles.isNotEmpty &&
        notBlank(localM3u8File) &&
        tsFiles.length == tsMap.length) {
      return await videoMgr.combineToMp4(tsFiles,
          dir: localM3u8File.substring(0, localM3u8File.lastIndexOf('/')));
    } else {
      return null;
    }
  }

  Future<String?> _onDownloadOldVideo(String m3u8Path) async {
    final String localM3u8File = await videoMgr.previewVideoM3u8(m3u8Path);
    final tsDirLastIdx = m3u8Path.lastIndexOf('/');
    final tsDir = m3u8Path.substring(0, tsDirLastIdx);
    Map<double, Map<String, dynamic>> tsMap = await cacheMediaMgr.extractTsUrls(
      tsDir,
      localM3u8File,
    );

    List<String> tsFiles = [];
    tsMap.values.forEach((element) {
      if (element.containsKey('url')) tsFiles.add(element['url']);
    });

    List<String> localCachePaths =
        await videoMgr.multipleDownloadTsFiles(tsFiles);

    if (localCachePaths.isNotEmpty && notBlank(localM3u8File)) {
      return await videoMgr.combineToMp4(localCachePaths,
          dir: localM3u8File.substring(0, localM3u8File.lastIndexOf('/')));
    }

    return null;
  }

  Future<void> saveMedia(String path, {bool isReturnPathOfIOS = false}) async {
    final result = await ImageGallerySaver.saveFile(
      path,
      isReturnPathOfIOS: isReturnPathOfIOS,
    );
    await Future.delayed(const Duration(seconds: 1));
    result != null
        ? ImBottomToast(
            context,
            title: localized(toastSaveSuccess),
            icon: ImBottomNotifType.download,
            duration: 1,
          )
        : Toast.showToast(localized(toastSaveUnsuccessful));
  }

  _onDelete() async {
    Message message = computedAssets[photoData.currentPage]['message'];
    List<SelectionOptionModel> deleteOptionList = [
      SelectionOptionModel(
          title: localized(deleteForMe),
          stringValue: DeletePopupOption.deleteForMe.optionType,
          isSelected: false,
          color: errorColor),
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
            color: errorColor),
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
    /// close delete option popup

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: localized(popupDelete),
          content: Text(
            isAll
                ? localized(chatInfoThisMessageWillBeDeletedForAllReceipts)
                : localized(
                    chatInfoThisMessageWillBeDeletedFromYourMessageHistory),
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

    CBBVideoPlayerController? controller = CBBVideoEvents.instance
        .getController(deletedIndex,
            isVideo: computedAssets[deletedIndex]['hasVideo'] ?? false);

    if (controller != null) {
      //移除/释放当前视频controller
      CBBVideoEvents.instance.removeControllerOnIndex(deletedIndex);
      if (localMP4Details[deletedIndex] != null) {
        localMP4Details.remove(deletedIndex);
      }
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

    /// 清理对应的变量
    Message delMessage = computedAssets[deletedIndex]["message"];
    if (computedAssets.length == 1 ||
        (assetLength != null && assetLength + 1 == computedAssets.length)) {
      Get.back();
    } else {
      if (widget.reverse) {
        computedAssets.removeRange(dest - (assetLength ?? 0), dest + 1);

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
    }

    if (widget.contentController == null) {
      if (fromChatInfo) {
        final controller;
        if (Get.isRegistered<ChatInfoController>()) {
          controller = Get.find<ChatInfoController>();
        } else if (Get.isRegistered<GroupChatInfoController>()) {
          controller = Get.find<GroupChatInfoController>();
        } else {
          Toast.showToast(localized(toastFileFailed));
          return;
        }

        controller!.deleteMessages(
          [delMessage],
          chatId: delMessage.chat_id,
          isAll: isAll,
        );
      }
    } else {
      await widget.contentController!.inputController.deleteMessages(
        [delMessage],
        widget.contentController!.chatController.chat.id,
        isAll: isAll,
      );
    }
    resetStatus();
    if (mounted) setState(() {});
  }

  void resetStatus() {
    CBBVideoPlayerController? controller = CBBVideoEvents.instance
        .getController(photoData.currentPage,
            isVideo:
                computedAssets[photoData.currentPage]['hasVideo'] ?? false);
    if (controller != null) {
      optionList.assignAll(_vidBottomOptionList);
      appbarOptionList.assignAll(_vidAppOptionList);

      // processVideoInitialize();
    } else {
      optionList.assignAll(_imageBottomOptionList);
      appbarOptionList.assignAll(_imageAppOptionList);
    }
    widget.contentController?.chatController.isPinnedOpened = false;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            ValueListenableBuilder<bool>(
              valueListenable: isDragging,
              builder: (_, bool value, Widget? __) {
                return DismissiblePage(
                  disabled: value,
                  onDismissed: Navigator.of(context).pop,
                  hitTestBehavior: HitTestBehavior.deferToChild,
                  direction: DismissiblePageDismissDirection.vertical,
                  child: PhotoViewGallery.builder(
                    scrollPhysics: value
                        ? const NeverScrollableScrollPhysics()
                        : scrollPhysics,
                    pageController: photoPageController,
                    reverse: widget.reverse,
                    itemCount: computedAssets.length,
                    builder: (BuildContext context, int index) {
                      Size? childSize;
                      Message message = computedAssets[index]['message'];
                      Map<String, dynamic> asset = computedAssets[index];

                      bool disableGesture = false;
                      int width = 0;
                      int height = 0;

                      bool closeXAxis = false;

                      switch (message.typ) {
                        case messageTypeImage:
                          MessageImage msgImage =
                              message.decodeContent(cl: MessageImage.creator);
                          width = msgImage.width;
                          height = msgImage.height;

                          final screenWidth = MediaQuery.of(context).size.width;
                          final screenHeight =
                              MediaQuery.of(context).size.height;

                          final wRatio =
                              1 - (min(screenWidth, width) / screenWidth);
                          final hRatio =
                              1 - (min(screenHeight, height) / screenHeight);

                          if (wRatio < hRatio && wRatio < 1) {
                            width = screenWidth.toInt();
                            height = (height * (1 + wRatio)).toInt();
                            closeXAxis = true;
                          }

                          if (hRatio < wRatio && hRatio < 1) {
                            height = screenHeight.toInt();
                            width = (width * (1 + hRatio)).toInt();
                          }

                          break;
                        case messageTypeVideo:
                        case messageTypeReel:
                          disableGesture = true;
                          break;
                        default:
                          // 相册
                          AlbumDetailBean bean = asset['asset'];
                          width = bean.aswidth ?? 1;
                          height = bean.asheight ?? 1;

                          if (bean.cover.isNotEmpty ||
                              (bean.mimeType?.contains('video') ?? false)) {
                            disableGesture = true;
                          }
                          break;
                      }

                      if (!disableGesture) {
                        final ratio = width / height;
                        if (closeXAxis) {
                          childSize = Size(
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.width / ratio,
                          );
                        } else {
                          childSize = Size(
                            MediaQuery.of(context).size.height * ratio,
                            MediaQuery.of(context).size.height,
                          );
                        }
                      }

                      return PhotoViewGalleryPageOptions.customChild(
                        initialScale: PhotoViewComputedScale.contained,
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 4.1,
                        disableGestures: disableGesture,
                        gestureDetectorBehavior: HitTestBehavior.deferToChild,
                        onTapDown: (_, __, ___) {
                          showToolBox.value = !showToolBox.value;
                        },
                        child: buildMedia(context, index),
                        childSize: childSize,
                      );
                    },
                    onPageChanged: onPageChange,
                  ),
                );
              },
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
                child: buildAppBar(context),
              ),
            ),
            Obx(
              () => AnimatedPositioned(
                bottom: showToolBox.value
                    ? 0
                    : -48 - 48 - MediaQuery.of(context).viewPadding.bottom,
                left: 0.0,
                right: 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                child: buildBottomBar(context, photoData.currentPage),
              ),
            ),
            _buildOriginalPanel(),
          ],
        ),
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    int index = photoData.currentPage;
    Message message = computedAssets[photoData.currentPage]['message'];
    var options =
        appbarOptionList.where((item) => item.isShow == true).toList();
    CBBVideoPlayerController? controller = CBBVideoEvents.instance
        .getController(photoData.currentPage,
            isVideo:
                computedAssets[photoData.currentPage]['hasVideo'] ?? false);
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
        //MediaQuery.of(context).viewPadding.top
        color: Colors.black.withOpacity(0.6),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (controller != null)
                  CBBVideoEvents.instance.onCodeTap(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: Opacity(
                  opacity: controller != null ? 1 : 0,
                  alwaysIncludeSemantics: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Obx(
                        () => SizedBox(
                            height: isLandscape.value
                                ? 4
                                : MediaQuery.of(context).viewPadding.top + 6),
                      ),
                      NicknameText(
                        uid: message.send_id,
                        color: Colors.white,
                        fontSize: MFontSize.size20.value,
                        fontWeight: MFontWeight.bold5.value,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        isTappable: false,
                      ),
                      Text(
                        FormatTime.getTime(message.create_time),
                        style: jxTextStyle.textStyle14(
                          color: JXColors.secondaryTextWhite,
                        ),
                      )
                    ],
                  ),
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
                      top: (MediaQuery.of(context).viewPadding.top - 5) < 0
                          ? 0
                          : (MediaQuery.of(context).viewPadding.top + 7)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      OpacityEffect(
                        child: SvgPicture.asset(
                          'assets/svgs/Back.svg',
                          width: 17.5,
                          height: 17.5,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          localized(buttonBack),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: MFontWeight.bold4.value,
                            fontFamily: MFontFamilies.first,
                          ),
                        ),
                      ),
                    ],
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
                      top: (MediaQuery.of(context).viewPadding.top - 5) < 0
                          ? 0
                          : (MediaQuery.of(context).viewPadding.top + 7)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: optionTab,
                  ),
                ))
          ],
        ),
      ),
    );
  }

  List<Widget> _loadAllOptions(dynamic options, int index) {
    List<Widget> optionTab = [];
    options.forEach((item) {
      CBBVideoPlayerController? controller = CBBVideoEvents.instance
          .getController(index,
              isVideo: computedAssets[index]['hasVideo'] ?? false);
      Widget w;

      if (controller != null &&
          item.optionType == MessagePopupOption.mute.optionType) {
        w = Obx(
          () => SvgPicture.asset(
            controller.isMuted.value
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

      Widget tab = GestureDetector(
        onTap: () => onTap(item.optionType, index),
        behavior: HitTestBehavior.translucent,
        child: OpacityEffect(
          child: Padding(
            padding: const EdgeInsets.only(right: 16).w,
            child: w,
          ),
        ),
      );
      optionTab.add(tab);
    });

    return optionTab;
  }

  Widget buildBottomBar(BuildContext context, int index) {
    List<Widget> optionTab = [];
    dynamic bean = computedAssets[photoData.currentPage]['asset'];
    Message message = computedAssets[photoData.currentPage]['message'];
    CBBVideoPlayerController? controller = CBBVideoEvents.instance
        .getController(photoData.currentPage,
            isVideo:
                computedAssets[photoData.currentPage]['hasVideo'] ?? false);

    if (optionList.length > 0) {
      optionList.forEach((item) {
        if (item.isShow) {
          if (item.optionType == MessagePopupOption.edit.optionType) {
            if (message.typ == messageTypeVideo ||
                message.typ == messageTypeReel) return;
            if (bean is AlbumDetailBean &&
                (bean.cover.isNotEmpty ||
                    (bean.mimeType?.contains('video') ?? false))) return;

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
            return;
          }

          Widget w;

          if (controller != null &&
              item.optionType == MessagePopupOption.play.optionType) {
            w = Obx(
              () => SvgPicture.asset(
                controller.isPlaying.value
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
      });
    }

    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        height: (controller != null ? 84.0 : 44.0) +
            MediaQuery.of(context).viewPadding.bottom,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (controller != null) controller.getSlider(),
            // if (controller != null)
            //   SizedBox(height: MediaQuery.of(context).viewPadding.bottom / 2.0),
            Stack(
              alignment: AlignmentDirectional.center,
              children: [
                controller == null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          optionTab[0], // Share
                          ...[
                            Row(
                              children: [
                                optionTab[1], // Edit Photo
                                optionTab[2], // Delete
                              ],
                            )
                          ]
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: optionTab,
                      ),
                if (controller == null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      optionTab[0],
                      ...[
                        Row(children: [optionTab[1], optionTab[2]])
                      ]
                    ],
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        NicknameText(
                          uid: message.send_id,
                          color: JXColors.secondaryTextWhite,
                          fontSize: MFontSize.size17.value,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          fontLineHeight: IM.ImLineHeight.getLineHeight(
                              fontSize: 17, lineHeight: 23.8),
                          isTappable: false,
                        ),
                        Text(
                          FormatTime.getTime(message.create_time),
                          style: jxTextStyle.textStyle13(
                            color: JXColors.secondaryTextWhite,
                          ),
                        )
                      ],
                    ),
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMedia(BuildContext context, int index) {
    //如果为图片，自然走更新流程，不扰乱删除顺序
    if ((computedAssets[index]['hasVideo'] ?? false) &&
        !CBBVideoEvents.instance.shouldBuildMedia(photoData.currentPage, index))
      return const SizedBox();

    return _buildMediaWidget(index);
  }

  Widget _buildMediaWidget(int index) {
    if (localMP4Details[index] != null) {
      CBBVideoPlayerController controller =
          CBBVideoEvents.instance.getController(index)!;
      if (photoData.currentPage == index)
        CBBVideoEvents.instance.activeController = controller;
      return localMP4Details[index]!;
    }

    Message message = computedAssets[index]['message'];
    Map<String, dynamic> asset = computedAssets[index];

    if (message.typ == messageTypeImage) {
      MessageImage messageImage =
          message.decodeContent(cl: MessageImage.creator);
      return PhotoDetail(
        key: ValueKey("${message.message_id}-$index"),
        item: message.asset != null ? message.asset : messageImage,
        message: message,
        photoData: photoData,
        height: messageImage.height.toDouble(),
        width: messageImage.width.toDouble(),
        onUpdateShowPhotoOriginal: _onShowPhotoOriginal,
      );
    }

    if (message.typ == messageTypeVideo || message.typ == messageTypeReel) {
      MessageVideo messageVideo =
          message.decodeContent(cl: MessageVideo.creator);

      CBBVideoPlayerController controller =
          CBBVideoEvents.instance.getController(index)!;

      controller.coverString.value = cacheMediaMgr.checkLocalFile(
            messageVideo.cover,
            mini: Config().messageMin,
          ) ??
          '';
      controller.isFullMode = isFullMode;
      controller.closeFloating = _closeFloating;
      controller.showToolbox = showToolBox;
      controller.autoplay.value = true;
      controller.onTapVideo = _onTapVideo;

      dynamic asset;
      bool isLocalAsset = false;
      if (message.asset != null &&
          (message.asset is AssetEntity || message.asset is File)) {
        asset = message.asset;
        isLocalAsset = true;
      } else if (File(messageVideo.filePath).existsSync()) {
        asset = File(messageVideo.filePath);
        isLocalAsset = true;
      } else {
        asset = messageVideo.url;
      }

      if (photoData.currentPage == index)
        CBBVideoEvents.instance.activeController = controller;
      else if (isLocalAsset) {
        return const SizedBox();
      }

      VideoDetail detail = VideoDetail(
        key: ValueKey(asset),
        url: asset,
        remoteSrc: messageVideo.source,
        fileHash: messageVideo.fileHash,
        index: index,
        message: computedAssets[index]['message'],
        width: messageVideo.width,
        height: messageVideo.height,
        currentPage: photoData.currentPage,
      );

      if (isLocalAsset) localMP4Details[index] = detail;
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

    return const SizedBox();
  }

  Widget buildAlbumDetailItemImage(
      Message message, AlbumDetailBean media, int index) {
    if (media.url.isNotEmpty) {
      return PhotoDetail(
        key: ValueKey(media.url),
        photoData: photoData,
        item: media,
        message: message,
        height: media.asheight!.toDouble(),
        width: media.aswidth!.toDouble(),
        onUpdateShowPhotoOriginal: _onShowPhotoOriginal,
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
          onUpdateShowPhotoOriginal: _onShowPhotoOriginal,
        );
      } else {
        return const SizedBox();
      }
    }
  }

  Widget buildAlbumDetailItemVideo(
      Message message, AlbumDetailBean media, int index) {
    dynamic asset;

    bool isLocalAsset = false;
    if (message.asset != null &&
        (message.asset is AssetEntity || message.asset is File)) {
      asset = message.asset;
      isLocalAsset = true;
    } else if (File(media.filePath).existsSync()) {
      asset = File(media.filePath);
      isLocalAsset = true;
    } else {
      asset = media.url;
    }

    final CBBVideoPlayerController controller =
        CBBVideoEvents.instance.getController(index)!;
    controller.coverString.value = cacheMediaMgr.checkLocalFile(
          media.cover,
          mini: Config().messageMin,
        ) ??
        '';
    controller.isFullMode = isFullMode;
    controller.closeFloating = _closeFloating;
    controller.showToolbox = showToolBox;
    controller.autoplay.value = true;
    controller.onTapVideo = _onTapVideo;

    if (photoData.currentPage == index)
      CBBVideoEvents.instance.activeController = controller;
    else if (isLocalAsset) {
      return const SizedBox();
    }

    VideoDetail detail = VideoDetail(
      key: ValueKey(asset),
      url: asset,
      remoteSrc: media.source,
      fileHash: media.fileHash,
      index: index,
      message: computedAssets[index]['message'],
      width: media.aswidth ?? 0,
      height: media.asheight ?? 0,
      currentPage: photoData.currentPage,
    );

    if (isLocalAsset) {
      localMP4Details[index] = detail;
    }
    return detail;
  }

  void _onVideoPageChange(int index) {
    CBBVideoEvents.instance.removeControllersForIndex(index);
    CBBVideoPlayerController? controller = CBBVideoEvents.instance
        .getController(index,
            isVideo: computedAssets[index]['hasVideo'] ?? false);

    if (controller != null)
      CBBVideoEvents.instance.activeController = controller;
    else
      CBBVideoEvents.instance.activeController = null;
    CBBVideoEvents.instance.pausePlayingControllers(index);

    if (controller != null) controller.play();
  }

  Widget _buildOriginalPanel() {
    if (computedAssets[photoData.currentPage]['hasVideo'] ?? false)
      return const SizedBox();
    return Positioned(
      bottom: 48 + 48,
      right: 0,
      child: Obx(
        () => Offstage(
          offstage:
              !(shouldShowPhotoOriginal.value || showingPhotoOriginal.value),
          child: GestureDetector(
            onTap: onOriginalShow,
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.only(right: 16.0, bottom: 12.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: JXColors.primaryTextBlack.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/svgs/Download.svg',
                    width: 16.0,
                    height: 16.0,
                    color: JXColors.white,
                  ),
                  const SizedBox(width: 6.0),
                  if (showingPhotoOriginal.value)
                    Text(
                      '${localized(downloading)}...',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: JXColors.white,
                      ),
                    )
                  else
                    Text(
                      '${localized(original)} (${fileMB(size.value)})',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: JXColors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onShowPhotoOriginal(Function() onOriginalShow, int size,
      bool showOriginal, bool shouldShowOriginal) {
    showingPhotoOriginal.value = showOriginal;
    shouldShowPhotoOriginal.value = shouldShowOriginal;
    this.size.value = size;
    this.onOriginalShow = onOriginalShow;
  }
}
