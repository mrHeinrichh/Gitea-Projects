import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/pages/chat_pin_container.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/convert_text.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_forward_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_read_text_icon.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_reply_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_translate_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/custom_content/painter/voice_painter.dart';
import 'package:jxim_client/im/custom_content/record_audio_control_item.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/audio_services/desktop_audio_player.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/event_model.dart';
import 'package:jxim_client/object/translate_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/swipeable_page_route.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:lottie/lottie.dart';

class GroupRecordSenderItem extends StatefulWidget {
  const GroupRecordSenderItem({
    super.key,
    required this.controller,
    required this.chat,
    required this.message,
    required this.messageVoice,
    required this.index,
    this.isPrevious = true,
  });

  final ChatContentController controller;
  final Chat chat;
  final Message message;
  final MessageVoice messageVoice;
  final int index;
  final bool isPrevious;

  @override
  GroupRecordSenderItemState createState() => GroupRecordSenderItemState();
}

class GroupRecordSenderItemState
    extends MessageWidgetMixin<GroupRecordSenderItem> {
  late ChatContentController controller;

  final GlobalKey targetWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;
  final double _kPlayerButtonSize = objectMgr.loginMgr.isDesktop ? 44 : 44;
  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  final VolumePlayerService playerService = VolumePlayerService.sharedInstance;
  late DesktopAudioPlayer desktopAudioPlayer;
  String? voiceFilePath;
  int sendID = 0;
  bool isSmallSecretary = false;
  final convertVoiceText = "".obs;
  bool isConverting = false;
  int totalTime = 0;

  final downloadProgress = 0.0.obs;
  final percentage = 0.0.obs;

  final isDownloaded = false.obs;

  final isDownloading = false.obs;

  final isPlayIcon = false.obs; //仅仅跟播放按钮UI挂钩
  bool get isPlaying =>
      isDesktop ? desktopAudioPlayer.isPlaying : playerService.isPlaying;

  bool get isPlayedBefore =>
      objectMgr.localStorageMgr.read('${widget.message.message_id}') != null;

  bool get isPaused => desktopAudioPlayer.isPaused;

  FancyGestureController? _fancyGestureController;

  bool get showPinned =>
      widget.controller.chatController.pinMessageList
          .firstWhereOrNull((pinnedMsg) => pinnedMsg.id == widget.message.id) !=
      null;

  final uiIsOperated = false.obs;

  CancelToken cancelToken = CancelToken();

  // 是否私聊
  bool get isSingleOrSystem {
    return widget.controller.chatController.chat.isSingle ||
        widget.controller.chatController.chat.isSystem;
  }

  void setStateOnlyOnPlayingVoiceMessage() {
    ///Optimize FPS
    if (mounted) {
      if (widget.message.id == playerService.currentMessage?.id) {
        setState(() {
          isPlayIcon.value = isDesktop
              ? desktopAudioPlayer.isPlaying
              : playerService.isPlaying;
        });
      } else {
        isPlayIcon.value = false;
      }
    }
  }

  _onPlayer() async {
    if (isDownloading.value) {
      cancelToken.cancel();
      isDownloading.value = false;
      downloadProgress.value = 0.0;
      cancelToken = CancelToken();
      return;
    }
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    objectMgr.chatMgr.event(objectMgr.chatMgr, ChatMgr.messageStopAllReading);
    playerService.playbackKey = playbackKey;
    isPlayIcon.value = !isPlayIcon.value;
    if (currentPlayingFileName != playbackKey) {
      if (isPlaying) {
        playerService.stopPlayer();
        await playerService
            .seekTo(playerService.getPlaybackDuration(playbackKey).toInt());
      }
      playerService.nextPlayerAudioTag.clear();
      playerService.setPlaybackDuration(currentPlayingFileName, 0.0);

      isDownloading.value = voiceFilePath == null;
      voiceFilePath ??= await cacheMediaMgr.downloadMediaWithCache(
        widget.messageVoice.url,
        cancelToken: cancelToken,
        onReceiveProgress: (double percentage) {
          downloadProgress.value = percentage;
        },
      );

      isDownloading.value = false;
      isDownloaded.value = voiceFilePath != null;

      if (voiceFilePath == null) {
        // Toast.showToast(localized(voiceFileDownloadFailed));
        return;
      }

      final f = File(voiceFilePath!);
      if (f.existsSync()) {
        playerService.currentPlayingFileName = playbackKey;
        playerService.currentMessage = widget.message;
        playerService.currentPlayingFile = voiceFilePath!;

        if (playerService
                .getPlaybackDuration('${widget.message.message_id}_null') >
            0.0) {
          playerService.setPlaybackDuration(
            playbackKey,
            playerService
                .getPlaybackDuration('${widget.message.message_id}_null'),
          );
          playerService
              .removePlaybackDuration('${widget.message.message_id}_null');
        }
      } else {
        Toast.showToast("语音文件不存在");
        return;
      }

      List<Message> allMessageList = RxList<Message>.from(
          controller.chatController.nextMessageList.reversed)
        ..addAll(controller.chatController.previousMessageList);

      for (int i = 0; i <= allMessageList.indexOf(widget.message); i++) {
        if (!objectMgr.userMgr.isMe(
              allMessageList[i].send_id,
            ) &&
            allMessageList[i].typ == messageTypeVoice) {
          playerService.nextPlayerAudioTag.add(
            allMessageList[i],
          );
        }
      }

      // if(isPlayedBefore) playerService.sendFunctionOnceAtStatusChange = false;

      if (isDesktop) {
        await desktopAudioPlayer.openPlayer(
          durationChanged: () {
            setStateOnlyOnPlayingVoiceMessage();
          },
          onPlayerCompleted: () {
            setStateOnlyOnPlayingVoiceMessage();
          },
          onPlayerStateChanged: (state) {
            setStateOnlyOnPlayingVoiceMessage();
          },
          filePath: voiceFilePath!,
        );
      } else {
        await playerService.openPlayer(
          onFinish: () {
            playerService.removePlaybackDuration(playbackKey);
            setStateOnlyOnPlayingVoiceMessage();
          },
          onProgress: (_) {
            setStateOnlyOnPlayingVoiceMessage();
            isAudioPinPlaying.value = true;
          },
          onPlayerStateChanged: () {
            setStateOnlyOnPlayingVoiceMessage();
          },
        );
      }
    } else {
      if (isDesktop) {
        if (!desktopAudioPlayer.isPlaying && voiceFilePath != null) {
          await desktopAudioPlayer.resumePlayer();
        } else {
          await desktopAudioPlayer.pausePlayer();
          isAudioPinPlaying.value = false;
        }
      } else {
        if (!playerService.isPlaying &&
            playerService.getPlaybackDuration(playbackKey) <
                widget.messageVoice.second * 1000) {
          await playerService.resumePlayer();
          await playerService
              .seekTo(playerService.getPlaybackDuration(playbackKey).toInt());
        } else {
          dragPosition.value = -1.0;
          await playerService.pausePlayer();
          isAudioPinPlaying.value = false;
        }
        setStateOnlyOnPlayingVoiceMessage();
      }
    }
    if (widget.messageVoice.isOperated != null &&
        widget.message.isContentViewed == false) {
      ChatHelp.sendFileOperate(
        chatID: widget.chat.id,
        messageId: widget.message.message_id,
        chatIdx: widget.message.chat_idx,
        userId: widget.message.send_id,
        receivers: [widget.message.send_id, objectMgr.userMgr.mainUser.uid],
      );
    }

    uiIsOperated.value = true; //立即更新UI
  }

  void getVoicePath() async {
    voiceFilePath = downloadMgrV2.getLocalPath(widget.messageVoice.url);

    isDownloading.value = voiceFilePath == null;
    voiceFilePath ??= await cacheMediaMgr.downloadMediaWithCache(
      widget.messageVoice.url,
      cancelToken: cancelToken,
      onReceiveProgress: (double percentage) {
        downloadProgress.value = percentage;
      },
    );

    isDownloading.value = false;
    isDownloaded.value = voiceFilePath != null;

    setStateOnlyOnPlayingVoiceMessage();
  }

  @override
  void initState() {
    totalTime = widget.messageVoice.second ~/ 1000;
    super.initState();

    if (Get.isRegistered<FancyGestureController>()) {
      _fancyGestureController = Get.find<FancyGestureController>();
    }

    controller =
        Get.find<ChatContentController>(tag: widget.chat.id.toString());

    checkExpiredMessage(widget.message);

    getVoicePath();
    if (playerService.isPlaying) {
      playerService.playerDurationStream.listen((event) {
        setStateOnlyOnPlayingVoiceMessage();
      });
    }

    if (isDesktop) {
      desktopAudioPlayer = DesktopAudioPlayer.create(
        messageId: widget.message.message_id,
        chat: widget.chat,
      );
      desktopAudioPlayer.on(VolumePlayerService.keyVolumePlayerProgress,
          _onDesktopPlayerProgressChange);
    }

    uiIsOperated.value = (widget.messageVoice.isOperated == null) ||
        widget.message.isContentViewed;

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventFileOperate, _onFileOperate);

    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    widget.message.on(Message.eventConvertText, convertText);
    widget.message.on(Message.eventDownloadProgress, updateDownloadProgress);
    playerService.on(
      VolumePlayerService.playerStateChange,
      _onPlayerStateChange,
    );
    playerService.on(
      VolumePlayerService.keyVolumePlayerStatus,
      _onPlayerStatusChange,
    );
    playerService.on(
      VolumePlayerService.keyVolumePlayerProgress,
      _onPlayerProgressChange,
    );
    playerService.on(
      VolumePlayerService.keyDownloadStart_FromVolumePlayService,
      _onDownloadStart_from_VolumePlayService,
    );
    playerService.on(
      VolumePlayerService.keyDownloadProgress_FromVolumePlayService,
      _onDownloadProgress_from_VolumePlayService,
    );
    playerService.on(
        VolumePlayerService.keyDownloadResult_FromVolumePlayService,
        _onDownloadResult_from_VolumePlayService);

    initMessage(controller.chatController, widget.index, widget.message);
    widget.message.on("eventUpdateTranscribe", _updateMessageTranscribe);
    convertVoiceText.value = widget.messageVoice.transcribe;

    emojiUserList.value = widget.message.emojis;

    if (mounted) {
      if (controller.chatController.nextMessageList.isNotEmpty &&
          playerService.currentMessage?.chat_id == widget.message.chat_id) {
        for (Message e in controller.chatController.nextMessageList.reversed) {
          if (e.typ == messageTypeVoice &&
              widget.message.message_id == e.message_id &&
              message.chat_id == e.chat_id &&
              !playerService.nextPlayerAudioTag.contains(e) &&
              !objectMgr.userMgr.isMe(widget.message.send_id)) {
            playerService.nextPlayerAudioTag.insert(0, e);
          }
        }
      }
    }

    getRealSendID();
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.chat.isSaveMsg) {
      sendID = widget.messageVoice.forward_user_id;
      if (widget.messageVoice.forward_user_name == 'Secretary') {
        isSmallSecretary = true;
      }
    }
    if (widget.chat.typ == chatTypeSmallSecretary) {
      isSmallSecretary = true;
    }
  }

  _onReactEmojiUpdate(Object sender, Object type, Object? data) async {
    if (data is Message) {
      if (widget.message.chat_id == data.chat_id &&
          data.id == widget.message.id) {
        emojiUserList.value = data.emojis;
        emojiUserList.refresh();
      }
    }
  }

  _onFileOperate(Object sender, Object type, Object? data) async {
    if (data is Message) {
      if (widget.message.chat_id == data.chat_id &&
          data.id == widget.message.id) {
        uiIsOperated.value = true;
      }
    }
  }

  void _onAutoDeleteMsgTriggered(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (widget.message.message_id == data.message_id) {
        controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
        objectMgr.localStorageMgr.remove('${widget.message.message_id}');
      }
    }
  }

  onChatMessageDelete(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
      return;
    }
    if (data['message'] != null) {
      for (var item in data['message']) {
        if (item is Message) {
          if (item.id == widget.message.id) {
            isDeleted.value = true;
            checkDateMessage(message);
            if (playerService.currentMessage?.id == widget.message.id) {
              isShowAudioPin.value = false;
            }
            objectMgr.localStorageMgr.remove('${widget.message.message_id}');
            break;
          }
        } else {
          if (item == widget.message.message_id) {
            isDeleted.value = true;
            checkDateMessage(message);
            if (playerService.currentMessage?.id == widget.message.id) {
              isShowAudioPin.value = false;
            }
            objectMgr.localStorageMgr.remove('${widget.message.message_id}');
            break;
          }
        }
      }
    }
  }

  void _onPlayerStateChange(sender, type, data) {
    // setStateOnlyOnPlayingVoiceMessage();
    if (mounted) setState(() {});
    percentage.value = 0.0;
  }

  void _onPlayerStatusChange(sender, type, data) {
    if (mounted) {
      isPlayIcon.value = data == VolumePlayerServiceType.play; //捕捉顶部栏的播放停止状态
      if (data == VolumePlayerServiceType.stop &&
          widget.message.id == playerService.currentMessage?.id) {
        percentage.value = 0.0;
      }
    }
  }

  void _onPlayerProgressChange(sender, type, data) {
    setStateOnlyOnPlayingVoiceMessage();
    percentage.value = 0.0;
    if (widget.message.id == playerService.currentMessage?.id) {
      var progress = data;
      percentage.value = (progress.position.inMilliseconds /
              progress.duration.inMilliseconds) +
          0.01;
    }
  }

  void _onDesktopPlayerProgressChange(sender, type, data) {
    setStateOnlyOnPlayingVoiceMessage();
    percentage.value = 0.0;
    if (widget.message.id == playerService.currentMessage?.id) {
      percentage.value = data + 0.01;
    }
  }

  void _onDownloadStart_from_VolumePlayService(sender, type, data) {
    final d = data as VolumePlayerServiceNextAudioDownloadStarted;
    if (d.url == widget.messageVoice.url) {
      isDownloading.value = true;
    }
  }

  void _onDownloadProgress_from_VolumePlayService(sender, type, data) {
    final d = data as VolumePlayerServiceNextAudioDownloadProgress;
    if (d.url == widget.messageVoice.url) {
      isDownloading.value = true; //可能再次进来下载中状态要还原
      downloadProgress.value = d.downloadProgress;
    }
  }

  void _onDownloadResult_from_VolumePlayService(sender, type, data) {
    final d = data as VolumePlayerServiceNextAudioDownloadResult;
    if (d.url == widget.messageVoice.url) {
      isDownloading.value = false; //得到失败或成功的结果了 所以肯定不在下载中了
      isDownloaded.value = d.isDownloaded;
    }
  }

  _updateMessageTranscribe(_, __, data) {
    if (data is Message) {
      if (data.message_id == widget.message.message_id) {
        MessageVoice messageVoice =
            data.decodeContent(cl: MessageVoice.creator);
        if (messageVoice.transcribe != '') {
          convertVoiceText.value = messageVoice.transcribe;
        } else {
          convertVoiceText.value = '';
          convertVoiceText.value = '';
          translationText.value = '';
          translationLocale.value = '';
          showOriginalContent.value = true;
          showTranslationContent.value = false;
        }
      }
    }
  }

  Future<void> convertText(_, __, data) async {
    if (data != null && data is EventTranscribeModel) {
      if (data.messageId == message.id) {
        isConverting = data.isConverting ?? false;

        if (data.text == "" && isConverting != true) {
          imBottomToast(
            Get.context!,
            title: localized(unableToRecogniseContent),
            icon: ImBottomNotifType.warning,
          );
        }

        setStateOnlyOnPlayingVoiceMessage();
      }
    }
  }

  void updateDownloadProgress(sender, type, data) {
    if (data != null && data is EventDownloadProgress) {
      if (data.id == widget.message.id) {
        downloadProgress.value = data.progress ?? 0.0;

        setStateOnlyOnPlayingVoiceMessage();
      }
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    widget.message.off(Message.eventConvertText, convertText);
    widget.message.off(Message.eventDownloadProgress, updateDownloadProgress);
    objectMgr.chatMgr.off(ChatMgr.eventFileOperate, _onFileOperate);

    playerService.off(
      VolumePlayerService.playerStateChange,
      _onPlayerStateChange,
    );
    playerService.off(
      VolumePlayerService.keyVolumePlayerStatus,
      _onPlayerStatusChange,
    );
    playerService.off(
      VolumePlayerService.keyVolumePlayerProgress,
      _onPlayerProgressChange,
    );
    playerService.off(
        VolumePlayerService.keyDownloadStart_FromVolumePlayService,
        _onDownloadStart_from_VolumePlayService);
    playerService.off(
        VolumePlayerService.keyDownloadProgress_FromVolumePlayService,
        _onDownloadProgress_from_VolumePlayService);
    playerService.off(
        VolumePlayerService.keyDownloadResult_FromVolumePlayService,
        _onDownloadResult_from_VolumePlayService);
    widget.message.off("eventUpdateTranscribe", _updateMessageTranscribe);
    if (isDesktop) {
      desktopAudioPlayer.off(VolumePlayerService.keyVolumePlayerProgress,
          _onDesktopPlayerProgressChange);
    }
    super.dispose();
  }

  bool get isPinnedOpen => controller.chatController.isPinnedOpened;

  String get currentPlayingFileName => playerService.currentPlayingFileName;

  String get playbackKey => '${widget.message.message_id}_$voiceFilePath';

  double get currentPlayingPosition => isDesktop
      ? desktopAudioPlayer.duration
      : playerService.getPlaybackDuration(playbackKey);

  ValueNotifier<double> dragPosition = ValueNotifier<double>(-1.0);

  bool isDragging = false;

  bool get showAvatar =>
      !controller.chat!.isSystem &&
      !controller.chat!.isSecretary &&
      !controller.chat!.isSingle &&
      (isLastMessage || controller.chatController.isPinnedOpened);

  GroupTextMessageReadType _readType = GroupTextMessageReadType.none;

  double get maxWidth => isDesktop
      ? (ObjectMgr.screenMQ!.size.width - 320) * 0.6
      : ObjectMgr.screenMQ!.size.width - 96.w;

  double get extraWidth => setWidth(showPinned, widget.message.edit_time > 0);

  bool isOnlyVoice = false;

  @override
  Widget build(BuildContext context) {
    isOnlyVoice = isNoText(
      widget.messageVoice.transcribe,
      widget.messageVoice.reply,
      translationText.value,
    );
    NewLineBean bean = calculateTextMaxWidth(
      message: widget.message,
      messageText: widget.messageVoice.transcribe,
      maxWidth: maxWidth - 24.w,
      extraWidth: extraWidth,
      reply: widget.messageVoice.reply,
      showTranslationContent: showTranslationContent.value,
      translationText: translationText.value,
      showOriginalContent: showOriginalContent.value,
      messageEmojiOnly: false,
      isPlayingSound: isPlayingSound.value,
      isWaitingRead: isWaitingRead.value,
      showPinned: showPinned,
      emojiUserList: emojiUserList,
      minWidth: minVoiceWidth,
      isReceiver: true,
    );
    _readType = bean.type;
    Widget child = messageBody(context,
        calculatedWidth: bean.actualWidth, minW: bean.minWidth);

    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                GestureDetector(
                  key: targetWidgetKey,
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    tapPosition = details.globalPosition;
                    isPressed.value = true;
                  },
                  onTapUp: (details) {
                    if (controller.isCTRLPressed()) {
                      desktopGeneralDialog(
                        context,
                        color: Colors.transparent,
                        widgetChild: DesktopMessagePopMenu(
                          offset: details.globalPosition,
                          emojiSelector: EmojiSelector(
                            chat: widget.chat,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.chat,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                            widget.message,
                            widget.chat,
                            extr: false,
                          ),
                        ),
                      );
                    }
                    controller.chatController.onCancelFocus();
                    isPressed.value = false;
                    setState(() {});
                  },
                  onTapCancel: () {
                    isPressed.value = false;
                  },
                  onLongPress: () {
                    if (!objectMgr.loginMgr.isDesktop) {
                      enableFloatingWindow(
                        context,
                        widget.chat.id,
                        widget.message,
                        child,
                        targetWidgetKey,
                        tapPosition,
                        ChatPopMenuSheet(
                          message: widget.message,
                          chat: widget.chat,
                          sendID: widget.message.send_id,
                        ),
                        bubbleType: BubbleType.receiverBubble,
                        menuHeight: ChatPopMenuUtil.getMenuHeight(
                          widget.message,
                          widget.chat,
                        ),
                        topWidget: EmojiSelector(
                          chat: widget.chat,
                          message: widget.message,
                          emojiMapList: emojiUserList,
                        ),
                      );
                      isPressed.value = false;
                    }
                  },
                  onSecondaryTapDown: (details) {
                    if (objectMgr.loginMgr.isDesktop) {
                      desktopGeneralDialog(
                        context,
                        color: Colors.transparent,
                        widgetChild: DesktopMessagePopMenu(
                          offset: details.globalPosition,
                          emojiSelector: EmojiSelector(
                            chat: widget.chat,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.chat,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                            widget.message,
                            widget.chat,
                            extr: false,
                          ),
                        ),
                      );
                    }
                    isPressed.value = false;
                  },
                  child: child,
                ),
                Positioned(
                  top: 0.0,
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: MoreChooseView(
                    chatController: controller.chatController,
                    message: widget.message,
                    chat: widget.chat,
                  ),
                ),
              ],
            ),
    );
  }

  Widget messageBody(BuildContext context,
      {required double calculatedWidth, required double minW}) {
    return Obx(() {
      /// 消息主体
      int constructedDuration = widget.messageVoice.second ~/ 1000;

      Widget playbackButton = Stack(
        children: <Widget>[
          Container(
            width: _kPlayerButtonSize.toDouble(),
            height: _kPlayerButtonSize.toDouble(),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: const CircleBorder(),
              color: themeColor,
            ),
            margin: const EdgeInsets.all(4.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: TweenSequence<double>(
                  <TweenSequenceItem<double>>[
                    TweenSequenceItem<double>(
                      tween: Tween<double>(begin: 1.0, end: 0.1)
                          .chain(CurveTween(curve: Curves.ease)),
                      weight: 50.0,
                    ),
                    TweenSequenceItem<double>(
                      tween: Tween<double>(begin: 0.1, end: 1.0)
                          .chain(CurveTween(curve: Curves.ease)),
                      weight: 50.0,
                    ),
                  ],
                ).animate(anim),
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: isDownloading.value
                  ? SvgPicture.asset(
                      'assets/svgs/close_icon.svg',
                      width: 20,
                      height: 20,
                      fit: BoxFit.fill,
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    )
                  : isDownloaded.value
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          switchInCurve: Curves.bounceIn,
                          switchOutCurve: Curves.bounceOut,
                          transitionBuilder: (child, anim) =>
                              RotationTransition(
                            turns: child.key == const ValueKey('play')
                                ? Tween<double>(begin: 1, end: 0.5)
                                    .animate(anim)
                                : Tween<double>(begin: 0.5, end: 1)
                                    .animate(anim),
                            child: ScaleTransition(scale: anim, child: child),
                          ),
                          child: playbackKey == currentPlayingFileName &&
                                  isPlayIcon.value
                              ? const Icon(
                                  Icons.pause,
                                  color: colorWhite,
                                  size: 28,
                                  key: ValueKey('pause'),
                                )
                              : const RotatedBox(
                                  quarterTurns: 4,
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: colorWhite,
                                    size: 28,
                                    key: ValueKey('play'),
                                  ),
                                ),
                        )
                      : SvgPicture.asset(
                          'assets/svgs/download_file_icon.svg',
                          width: 20,
                          height: 20,
                          fit: BoxFit.fill,
                          colorFilter: const ColorFilter.mode(
                            colorWhite,
                            BlendMode.srcIn,
                          ),
                        ),
            ),
          ),
          if (isDownloading.value)
            Positioned(
              top: 6,
              left: 6,
              right: 6,
              bottom: 6,
              child: downloadProgress.value == 0
                  ? CircularLoadingBarRotate(
                      key: ValueKey(widget.index),
                      value: 0,
                    )
                  : CircularLoadingBar(
                      value: downloadProgress.value,
                    ),
            ),
        ],
      );

      Widget decibelPaint = RepaintBoundary(
        child: ValueListenableBuilder(
          valueListenable: dragPosition,
          builder: (_, double value, __) {
            return CustomPaint(
              size: Size(
                4.0 *
                    (widget.messageVoice.decibels.length > 30
                        ? 30
                        : widget.messageVoice.decibels.length),
                72,
              ),
              willChange: true,
              painter: VoicePainter(
                decibels: widget.messageVoice.decibels.cast<double>(),
                lineColor:
                    !uiIsOperated.value ? themeColor : colorTextPlaceholder,
                playColor: themeColor,
                playedProgress:
                    (value != -1 && !playerService.isPlaying) || isDragging
                        ? value
                        : percentage.value,
              ),
            );
          },
        ),
      );

      Widget body = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: controller.chatController.popupEnabled ? null : _onPlayer,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 4),

              /// 昵称
              if ((widget.messageVoice.reply.isEmpty ||
                      (widget.message.hasReply &&
                          ReplyModel.fromJson(
                                json.decode(widget.message.replyModel!),
                              ).userId !=
                              sendID)) &&
                  (isFirstMessage || isPinnedOpen))
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Offstage(
                    offstage: widget.chat.isSingle ||
                        widget.chat.typ == chatTypeSystem,
                    child: NicknameText(
                      uid: sendID,
                      // color: themeColor,
                      isRandomColor: true,
                      fontWeight: MFontWeight.bold5.value,
                      fontSize: bubbleNicknameSize,
                      groupId: widget.chat.isGroup ? widget.chat.id : null,
                    ),
                  ),
                ),

              if (widget.messageVoice.forward_user_id != 0)
                MessageForwardComponent(
                  forwardUserId: widget.messageVoice.forward_user_id,
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                  isSender: true,
                  padding: const EdgeInsets.only(left: 4),
                ),

              if (widget.messageVoice.reply.isNotEmpty)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPressReply(
                    controller.chatController,
                    widget.message,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: MessageReplyComponent(
                      replyModel: ReplyModel.fromJson(
                        json.decode(widget.messageVoice.reply),
                      ),
                      message: widget.message,
                      chat: widget.chat,
                      maxWidth: jxDimension.groupTextSenderMaxWidth(),
                      controller: controller,
                    ),
                  ),
                ),

              Row(
                children: <Widget>[
                  Stack(
                    children: [
                      if (playbackKey == currentPlayingFileName &&
                          isPlayIcon.value)
                        ClipOval(
                          child: Stack(
                            children: <Widget>[
                              Lottie.asset(
                                'assets/lottie/c-bubble-wave-blue.json',
                                width: 52,
                                height: 52,
                              ),
                              if (isPressed.value)
                                const Positioned.fill(
                                  child: ColoredBox(
                                    color: colorTextPlaceholder,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (uiIsOperated.value == false)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeColor,
                            ),
                          ),
                        ),
                      playbackButton,
                    ],
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: controller.chatController.popupEnabled
                          ? null
                          : _onPlayer,
                      onTapDown: (_) {
                        if (Platform.isIOS &&
                            playbackKey == currentPlayingFileName) {
                          _fancyGestureController?.event.event(
                            this,
                            FancyGestureEvent.ON_EDGE_SWIPE_UPDATE,
                            data: FancyGestureEventType.disable,
                          );
                        }
                      },
                      onTapUp: (_) {
                        if (Platform.isIOS &&
                            playbackKey == currentPlayingFileName) {
                          _fancyGestureController?.event.event(
                            this,
                            FancyGestureEvent.ON_EDGE_SWIPE_UPDATE,
                            data: FancyGestureEventType.enable,
                          );
                        }
                      },
                      onTapCancel: () {
                        if (Platform.isIOS) {
                          _fancyGestureController?.event.event(
                              this, FancyGestureEvent.ON_EDGE_SWIPE_UPDATE,
                              data: FancyGestureEventType.enable);
                        }
                      },
                      onHorizontalDragUpdate: controller
                                  .chatController.popupEnabled ||
                              currentPlayingFileName != playbackKey
                          ? null
                          : (DragUpdateDetails details) {
                              if (percentage.value >= 0.95) {
                                isDragging = false;
                                dragPosition.value = -1.0;
                                return;
                              }

                              dragPosition.value = details.localPosition.dx /
                                  (4.0 * widget.messageVoice.decibels.length);
                              if (mounted &&
                                  widget.message ==
                                      playerService.currentMessage) {
                                setState(() {
                                  isDragging = true;
                                });
                              }
                            },
                      onHorizontalDragEnd:
                          controller.chatController.popupEnabled ||
                                  currentPlayingFileName != playbackKey
                              ? null
                              : (DragEndDetails details) async {
                                  double dragMillisecond = dragPosition.value *
                                      widget.messageVoice.second;

                                  if (dragMillisecond.isNegative) {
                                    dragMillisecond = 0.0;
                                  }
                                  if (mounted &&
                                      widget.message ==
                                          playerService.currentMessage) {
                                    setState(() {
                                      playerService.setPlaybackDuration(
                                        playbackKey,
                                        dragMillisecond,
                                      );
                                    });
                                  }

                                  if (isDesktop) {
                                    await desktopAudioPlayer
                                        .seekTo(dragMillisecond.toInt());
                                  } else if ('${widget.message.message_id}_$voiceFilePath' ==
                                      playerService.currentPlayingFileName) {
                                    await playerService
                                        .seekTo(dragMillisecond.toInt());
                                    percentage.value = dragPosition.value;
                                  }

                                  if (mounted &&
                                      widget.message ==
                                          playerService.currentMessage) {
                                    setState(() {
                                      isDragging = false;
                                      dragPosition.value = -1.0;
                                    });
                                  }

                                  if (Platform.isIOS &&
                                      playbackKey == currentPlayingFileName) {
                                    _fancyGestureController?.event.event(
                                      this,
                                      FancyGestureEvent.ON_EDGE_SWIPE_UPDATE,
                                      data: FancyGestureEventType.enable,
                                    );
                                  }
                                },
                      onHorizontalDragCancel: () {
                        if (Platform.isIOS) {
                          _fancyGestureController?.event.event(
                              this, FancyGestureEvent.ON_EDGE_SWIPE_UPDATE,
                              data: FancyGestureEventType.enable);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Obx(
                            () => ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    controller.chatController.chooseMore.value
                                        ? 190.w
                                        : 230.w,
                                maxHeight: 28,
                              ),
                              child: decibelPaint,
                            ),
                          ),
                          Container(
                            width: 32,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$constructedDuration″',
                              style: jxTextStyle.textStyleBold15(
                                  color: !uiIsOperated.value
                                      ? themeColor
                                      : colorTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              Obx(() {
                if (isOnlyVoice &&
                    convertVoiceText.value.isNotEmpty &&
                    showOriginalContent.value) {
                  NewLineBean bean = calculateTextMaxWidth(
                    message: widget.message,
                    messageText: convertVoiceText.value,
                    maxWidth: maxWidth - 24.w,
                    extraWidth: extraWidth,
                    reply: widget.messageVoice.reply,
                    showTranslationContent: showTranslationContent.value,
                    translationText: translationText.value,
                    showOriginalContent: showOriginalContent.value,
                    messageEmojiOnly: false,
                    isPlayingSound: isPlayingSound.value,
                    isWaitingRead: isWaitingRead.value,
                    showPinned: showPinned,
                    emojiUserList: emojiUserList,
                    isReceiver: true,
                  );
                  calculatedWidth = bean.actualWidth;
                  _readType = bean.type;
                }
                return Visibility(
                  visible:
                      notBlank(convertVoiceText.value) || isConverting == true,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: calculatedWidth,
                    ),
                    padding:
                        const EdgeInsets.only(bottom: 6, right: 4, left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showOriginalContent.value)
                          ConvertTextItem(
                            convertText: convertVoiceText.value,
                            isConverting: isConverting,
                            minWidth:
                                isConverting ? minVoiceWidth : calculatedWidth,
                            isSender: false,
                            type: _readType,
                            extraWidth: extraWidth,
                          ),
                        if (showTranslationContent.value &&
                            isConverting == false)
                          MessageTranslateComponent(
                            chat: baseController.chat,
                            message: message,
                            translatedText: translationText.value,
                            locale: translationLocale.value,
                            controller: widget.controller,
                            showDivider: showOriginalContent.value &&
                                showTranslationContent.value,
                            constraints: BoxConstraints(
                              minWidth: calculatedWidth,
                            ),
                          ),
                        SizedBox(
                          height:
                              _readType == GroupTextMessageReadType.beakLineType
                                  ? lineSpacing
                                  : 0,
                        )
                      ],
                    ),
                  ),
                );
              }),
              if (!(notBlank(convertVoiceText.value) || isConverting == true))
                SizedBox(height: emojiUserList.isNotEmpty ? 0 : 10),
            ],
          ),
        ),
      );

      BubblePosition position = isFirstMessage && isLastMessage
          ? BubblePosition.isFirstAndLastMessage
          : isLastMessage
              ? BubblePosition.isLastMessage
              : isFirstMessage
                  ? BubblePosition.isFirstMessage
                  : BubblePosition.isMiddleMessage;

      if (controller.chatController.isPinnedOpened) {
        position = BubblePosition.isLastMessage;
      }

      body = Container(
        padding: EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
        child: ChatBubbleBody(
          // verticalPadding: 12,
          horizontalPadding: 8,
          position: position,
          isPressed: isPressed.value,
          constraints: BoxConstraints(maxWidth: maxWidth),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: ObjectMgr.screenMQ!.size.width,
                ),
                child: body,
              ),

              /// react emoji 表情栏
              Obx(() {
                List<Map<String, int>> emojiCountList = [];
                for (var emoji in emojiUserList) {
                  final emojiCountMap = {
                    emoji.emoji: emoji.uidList.length,
                  };
                  emojiCountList.add(emojiCountMap);
                }
                return Visibility(
                  visible: emojiUserList.isNotEmpty,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            controller.onViewReactList(context, emojiUserList),
                        child: EmojiListItem(
                          emojiModelList: emojiUserList,
                          message: widget.message,
                          controller: controller,
                          eMargin: EmojiMargin.sender,
                        ),
                      ),
                      SizedBox(height: 5.h)
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );

      return Container(
        margin: EdgeInsets.only(
          // right: jxDimension.chatRoomSideMarginMaxGap,
          left: controller.chatController.chooseMore.value
              ? 40
              : (widget.chat.typ == chatTypeSingle
                  ? jxDimension.chatRoomSideMarginSingle
                  : jxDimension.chatRoomSideMargin),
          bottom: isPinnedOpen ? 4 : 0,
        ),
        child: AbsorbPointer(
          absorbing: controller.chatController.popupEnabled,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              /// 头像
              Opacity(
                opacity: showAvatar ? 1 : 0,
                child: buildAvatar(),
              ),

              Stack(
                children: <Widget>[
                  body,
                  Positioned(
                    right: 12,
                    bottom: 8,
                    child: ChatReadNumView(
                      message: widget.message,
                      chat: widget.chat,
                      showPinned: controller.chatController.pinMessageList
                              .firstWhereOrNull(
                            (pinnedMsg) => pinnedMsg.id == widget.message.id,
                          ) !=
                          null,
                      sender: true,
                    ),
                  ),
                  if (isPlayingSound.value || isWaitingRead.value)
                    MessageReadTextIcon(
                      isWaitingRead: isWaitingRead.value,
                      isMe: false,
                      right: 0,
                      isPause: isPauseRead.value,
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildAvatar() {
    if (controller.chat!.isSaveMsg) {
      return Container(
        width: jxDimension.chatRoomAvatarSize(),
        height: jxDimension.chatRoomAvatarSize(),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [
              Color(0xFFFFD08E),
              Color(0xFFFFECD2),
            ],
          ),
        ),
        child: const SavedMessageIcon(),
      );
    }

    if (controller.chat!.isSecretary) {
      return Image.asset(
        'assets/images/message_new/secretary.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isSystem) {
      return Image.asset(
        'assets/images/message_new/sys_notification.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isGroup) {
      return CustomAvatar.normal(
        sendID,
        size: jxDimension.chatRoomAvatarSize(),
        headMin: Config().headMin,
        onTap: sendID == 0
            ? null
            : () {
                Get.toNamed(
                  RouteName.chatInfo,
                  arguments: {
                    "uid": sendID,
                  },
                  id: objectMgr.loginMgr.isDesktop ? 1 : null,
                );
              },
        onLongPress: sendID == 0
            ? null
            : () async {
                User? user = await objectMgr.userMgr.loadUserById2(sendID);
                if (user != null) {
                  HapticFeedback.mediumImpact();
                  controller.inputController.onAppendMentionUser(user);
                }
              },
      );
    }

    return SizedBox(
      width: controller.chatController.chat.isSingle ||
              controller.chatController.chat.isSystem
          ? 0
          : jxDimension.chatRoomAvatarSize(),
    );
  }

  double get minVoiceWidth {
    return _kPlayerButtonSize.toDouble() +
        6 +
        4.0 * widget.messageVoice.decibels.length;
  }

  bool isNoText(String transcribe, String reply, String translationText) {
    if (transcribe.isEmpty && reply.isEmpty && translationText.isEmpty) {
      return true;
    }
    return false;
  }
}
