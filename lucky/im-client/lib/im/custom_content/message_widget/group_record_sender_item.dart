import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_source_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/custom_content/painter/voice_painter.dart';
import 'package:jxim_client/im/custom_content/record_audio_control_item.dart';
import 'package:jxim_client/im/services/audio_services/desktop_audio_player.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/im/model/emoji_model.dart';

import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/reply_model.dart';
import 'package:jxim_client/object/event_model.dart';
import 'package:jxim_client/object/translate_model.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/convert_text.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_reply_item.dart';

class GroupRecordSenderItem extends StatefulWidget {
  const GroupRecordSenderItem({
    Key? key,
    required this.chat,
    required this.message,
    required this.messageVoice,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);
  final Chat chat;
  final Message message;
  final MessageVoice messageVoice;
  final int index;
  final isPrevious;

  @override
  _GroupRecordSenderItemState createState() => _GroupRecordSenderItemState();
}

class _GroupRecordSenderItemState extends State<GroupRecordSenderItem>
    with MessageWidgetMixin {
  late ChatContentController controller;

  final GlobalKey targetWidgetKey = GlobalKey();
  final GlobalKey avatarWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;
  final double _kPlayerButtonSize = 44;
  final bool isDesktop = objectMgr.loginMgr.isDesktop;

  final VolumePlayerService playerService = VolumePlayerService.sharedInstance;
  late DesktopAudioPlayer desktopAudioPlayer;
  String? voiceFilePath;
  int sendID = 0;
  bool isSmallSecretary = false;
  String convertVoiceText = "";
  bool? isConverting;

  final downloadProgress = 0.0.obs;

  final isDownloaded = false.obs;

  bool get isDownloading => downloadProgress > 0 && downloadProgress < 1.0;

  bool get isPlaying =>
      isDesktop ? desktopAudioPlayer.isPlaying : playerService.isPlaying;

  bool get isPaused => desktopAudioPlayer.isPaused;

  _onPlayer() async {
    playerService.playbackKey = playbackKey;
    if (currentPlayingFileName != playbackKey) {
      if (voiceFilePath == null || voiceFilePath!.isEmpty) {
        voiceFilePath = await cacheMediaMgr.downloadMedia(
              widget.messageVoice.url,
              onReceiveProgress: (int received, int total) {
                downloadProgress.value = received / total;
              },
            ) ??
            '';
      }

      if (voiceFilePath == null || voiceFilePath!.isEmpty) {
        mypdebug(localized(voiceFileDownloadFailed), toast: true);
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
                  .getPlaybackDuration('${widget.message.message_id}_null'));
          playerService
              .removePlaybackDuration('${widget.message.message_id}_null');
        }
      } else {
        Toast.showToast("语音文件不存在");
        return;
      }

      if (isDesktop) {
        await desktopAudioPlayer.openPlayer(
          durationChanged: () {
            if (mounted) setState(() {});
          },
          onPlayerCompleted: (event) {
            if (mounted) setState(() {});
          },
          onPlayerStateChanged: (state) {
            if (mounted) setState(() {});
          },
          filePath: voiceFilePath!,
        );
      } else {
        await playerService.openPlayer(
          onFinish: () {
            playerService.removePlaybackDuration(playbackKey);
            if (mounted) setState(() {});
          },
          onProgress: (_) {
            if (mounted) setState(() {});
            isAudioPinPlaying.value = true;
          },
          onPlayerStateChanged: () {
            if (mounted) setState(() {});
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
        if (mounted) setState(() {});
      }
    }
  }

  void getVoicePath() async {
    String? cacheUrl = widget.messageVoice.localUrl;
    if (cacheUrl != null && cacheUrl.isNotEmpty) {
      voiceFilePath = cacheUrl;
      final f = File(voiceFilePath!);
      if (!f.existsSync()) {
        voiceFilePath = null;
      }
    }

    if (voiceFilePath == null || voiceFilePath!.isEmpty) {
      voiceFilePath = await cacheMediaMgr.downloadMedia(
            widget.messageVoice.url,
            onReceiveProgress: (int received, int total) {
              downloadProgress.value = received / total;
            },
          ) ??
          '';
    }

    if (voiceFilePath != null) {
      isDownloaded.value = true;
    } else {
      isDownloaded.value = false;
    }

    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.id.toString());

    checkExpiredMessage(widget.message);

    getVoicePath();
    if (playerService.isPlaying) {
      playerService.playerDurationStream.listen((event) {
        if (mounted) {
          setState(() {});
        }
      });
    }

    if (isDesktop) {
      desktopAudioPlayer = DesktopAudioPlayer.create(
        messageId: widget.message.message_id,
        chat: widget.chat,
      );
    }

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);
    widget.message.on(Message.eventConvertText, convertText);
    widget.message.on(Message.eventDownloadProgress, updateDownloadProgress);
    playerService.on(
        VolumePlayerService.playerStateChange, _onPlayerStateChange);
    playerService.on(
        VolumePlayerService.keyVolumePlayerStatus, _onPlayerStatusChange);

    initMessage(controller.chatController, widget.index, widget.message);

    emojiUserList.value = widget.message.emojis;
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

  void _onAutoDeleteMsgTriggered(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (widget.message.message_id == data.message_id) {
        controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
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
            break;
          }
        } else {
          if (item == widget.message.message_id) {
            isDeleted.value = true;
            checkDateMessage(message);
            break;
          }
        }
      }
    }
  }

  onChatMessageEdit(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
      return;
    }
    if (data['message'] != null) {
      Message item = data['message'];
      if (item.id == widget.message.id) {
        widget.message.content = item.content;
        widget.message.edit_time = item.edit_time;
        widget.message.sendState = item.sendState;
      }
    }
  }

  void _onPlayerStateChange(sender, type, data) {
    if (mounted) setState(() {});
  }

  void _onPlayerStatusChange(sender, type, data) {
    if (mounted) setState(() {});
  }

  Future<void> convertText(_, __, data) async {
    if (data != null && data is EventTranscribeModel) {
      if (data.messageId == message.id) {
        convertVoiceText = data.text ?? "";
        isConverting = data.isConverting;

        if (!notBlank(convertVoiceText) && isConverting != true) {
          ImBottomToast(
            Get.context!,
            title: localized(unableToRecogniseContent),
            icon: ImBottomNotifType.warning,
            isStickBottom: false,
          );
        }

        if (mounted) setState(() {});
      }
    }
  }

  void updateDownloadProgress(sender, type, data) {
    if (data != null && data is EventDownloadProgress) {
      if (data.id == widget.message.id) {
        downloadProgress.value = data.progress ?? 0.0;

        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    widget.message.off(Message.eventConvertText, convertText);
    widget.message.on(Message.eventDownloadProgress, updateDownloadProgress);

    playerService.off(
        VolumePlayerService.playerStateChange, _onPlayerStateChange);
    playerService.off(
        VolumePlayerService.keyVolumePlayerStatus, _onPlayerStatusChange);

    super.dispose();
  }

  bool get isPinnedOpen => controller.chatController.isPinnedOpened;

  String get currentPlayingFileName => playerService.currentPlayingFileName;

  String get playbackKey => '${widget.message.message_id}_${voiceFilePath}';

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

  @override
  Widget build(BuildContext context) {
    Widget child = messageBody();

    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Stack(
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
                      DesktopGeneralDialog(
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
                          menuHeight: ChatPopMenuSheet.getMenuHeight(
                              widget.message, widget.chat,
                              extr: false),
                        ),
                      );
                    }
                    controller.chatController.onCancelFocus();
                    isPressed.value = false;
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
                        menuHeight: ChatPopMenuSheet.getMenuHeight(
                            widget.message, widget.chat),
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
                      DesktopGeneralDialog(
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
                          menuHeight: ChatPopMenuSheet.getMenuHeight(
                              widget.message, widget.chat,
                              extr: false),
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

  Widget messageBody() {
    return Obx(() {
      /// 消息主体
      String constructedDuration = '';
      if ('${widget.message.message_id}_$voiceFilePath' ==
              currentPlayingFileName &&
          isPlaying) {
        constructedDuration = constructTime(
          currentPlayingPosition ~/ 1000,
          showHour: false,
        );
      } else {
        if (isDesktop && isPaused)
          constructedDuration = constructTime(
            currentPlayingPosition ~/ 1000,
            showHour: false,
          );
        else
          constructedDuration = constructTime(
            widget.messageVoice.second ~/ 1000,
            showHour: false,
          );
      }

      Widget playbackButton = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: controller.chatController.popupEnabled ? null : _onPlayer,
        child: Stack(
          children: <Widget>[
            Container(
              width: _kPlayerButtonSize.toDouble(),
              height: _kPlayerButtonSize.toDouble(),
              alignment: Alignment.center,
              decoration: const ShapeDecoration(
                shape: const CircleBorder(),
                color: JXColors.chatBubbleSenderRecordColor,
              ),
              child: isDownloading
                  ? SvgPicture.asset(
                      'assets/svgs/close_icon.svg',
                      width: 20,
                      height: 20,
                      fit: BoxFit.fill,
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    )
                  : isDownloaded.value
                      ? Icon(
                          playbackKey == currentPlayingFileName && isPlaying
                              ? Icons.pause
                              : Icons.play_arrow_rounded,
                          color: JXColors.chatBubbleSenderRecordIconColor,
                          size: 28,
                        )
                      : SvgPicture.asset(
                          'assets/svgs/download_file_icon.svg',
                          width: 20,
                          height: 20,
                          fit: BoxFit.fill,
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                        ),
            ),
            if (isDownloading)
              Positioned(
                top: 2,
                left: 2,
                right: 2,
                bottom: 2,
                child: CircularLoadingBar(
                  value: downloadProgress.value,
                ),
              ),
          ],
        ),
      );

      double percentage = currentPlayingPosition / widget.messageVoice.second;

      Widget decibelPaint = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: controller.chatController.popupEnabled
            ? null
            : (DragUpdateDetails details) {
                dragPosition.value = details.localPosition.dx /
                    (4.0 * widget.messageVoice.decibels.length);
                if (mounted) setState(() {
                  isDragging = true;
                });
              },
        onPanEnd: controller.chatController.popupEnabled
            ? null
            : (DragEndDetails details) async {
                final dragMillisecond =
                    dragPosition.value * widget.messageVoice.second;
                if (mounted) setState(() {
                  playerService.setPlaybackDuration(
                      playbackKey, dragMillisecond);
                });

                if (isDesktop)
                  await desktopAudioPlayer.seekTo(dragMillisecond.toInt());
                else if (isPlaying) {
                  await playerService.seekTo(dragMillisecond.toInt());
                }

                if (mounted) setState(() {
                  isDragging = false;
                  dragPosition.value = -1.0;
                });
              },
        child: Transform.scale(
          scaleY: 0.75,
          scaleX: 1,
          alignment: Alignment.bottomLeft,
          child: RepaintBoundary(
            child: ValueListenableBuilder(
                valueListenable: dragPosition,
                builder: (_, double value, __) {
                  return CustomPaint(
                    size: Size(
                      4.0 * widget.messageVoice.decibels.length,
                      30,
                    ),
                    willChange: true,
                    painter: VoicePainter(
                      decibels: widget.messageVoice.decibels.cast<double>(),
                      lineColor: JXColors.chatBubbleSenderRecordDrawBGColor,
                      playColor: JXColors.chatBubbleSenderRecordDrawColor,
                      playedProgress:
                          (value != -1 && !playerService.isPlaying) ||
                                  isDragging
                              ? value
                              : percentage,
                    ),
                  );
                }),
          ),
        ),
      );

      Widget body = IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// 昵称
            if ((widget.messageVoice.reply.isEmpty ||
                    (widget.message.hasReply &&
                        ReplyModel.fromJson(
                              json.decode(widget.message.replyModel!),
                            ).userId !=
                            sendID)) &&
                (isFirstMessage || isPinnedOpen))
              Offstage(
                offstage:
                    widget.chat.isSingle || widget.chat.typ == chatTypeSystem,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: NicknameText(
                    uid: sendID,
                    // color: accentColor,
                    isRandomColor: true,
                    fontWeight: MFontWeight.bold5.value,
                  ),
                ),
              ),

            if (widget.messageVoice.forward_user_id != 0)
              Padding(
                padding: const EdgeInsets.only(bottom: bubbleInnerPadding),
                child: ChatSourceView(
                  forward_user_id: widget.messageVoice.forward_user_id,
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                  isSender: true,
                ),
              ),

            if (widget.messageVoice.reply.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPressReply(
                  controller.chatController,
                  widget.message,
                ),
                child: GroupReplyItem(
                  replyModel: ReplyModel.fromJson(
                    json.decode(widget.messageVoice.reply),
                  ),
                  message: widget.message,
                  chat: widget.chat,
                  maxWidth: jxDimension.groupTextSenderMaxWidth(
                      isMoreChoose: controller.chatController.chooseMore.value),
                  controller: controller,
                ),
              ),

            Container(
              margin: emojiUserList.length > 0
                  ? null
                  : const EdgeInsets.only(bottom: 12),
              child: Row(
                children: <Widget>[
                  playbackButton,
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 173.w),
                            child: FittedBox(child: decibelPaint)),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          '$constructedDuration\u202F',
                          style: const TextStyle(
                            fontSize: 12,
                            color: JXColors.chatBubbleSenderRecordSubTitleColor,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.normal,
                            height: 16.8 / 12,
                            fontFeatures: [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ConvertTextItem(
              convertText: convertVoiceText,
              isConverting: isConverting,
              margin: const EdgeInsets.only(top: 4, bottom: 16),
              minWidth: _kPlayerButtonSize.toDouble() +
                  6 +
                  4.0 * widget.messageVoice.decibels.length,
              isSender: false,
            ),
          ],
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
          verticalPadding: 6,
          horizontalPadding: 12,
          position: position,
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
                emojiUserList.forEach((emoji) {
                  final emojiCountMap = {
                    MessageReactEmoji.emojiNameOldToNew(emoji.emoji):
                        emoji.uidList.length,
                  };
                  emojiCountList.add(emojiCountMap);
                });
                return Visibility(
                  visible: emojiUserList.length > 0,
                  child: GestureDetector(
                    onTap: () =>
                        controller.onViewReactList(context, emojiUserList),
                    child: EmojiListItem(
                      emojiModelList: emojiUserList,
                      message: widget.message,
                      controller: controller,
                      eMargin: EmojiMargin.sender,
                    ),
                  ),
                );
              })
            ],
          ),
        ),
      );

      return Container(
        margin: EdgeInsets.only(
          right: jxDimension.chatRoomSideMarginMaxGap,
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
                              .firstWhereOrNull((pinnedMsg) =>
                                  pinnedMsg.id == widget.message.id) !=
                          null,
                      sender: true,
                    ),
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
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
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
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        'assets/images/message_new/secretary.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isSystem) {
      return Image.asset(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        'assets/images/message_new/sys_notification.png',
        width: 36,
        height: 36,
      );
    }

    if (controller.chat!.isGroup) {
      return CustomAvatar(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        uid: sendID,
        size: jxDimension.chatRoomAvatarSize(),
        headMin: Config().headMin,
        onTap: sendID == 0
            ? null
            : () {
                Get.toNamed(RouteName.chatInfo,
                    arguments: {
                      "uid": sendID,
                    },
                    id: objectMgr.loginMgr.isDesktop ? 1 : null);
              },
        onLongPress: sendID == 0
            ? null
            : () async {
                User? user = await objectMgr.userMgr.loadUserById2(sendID);
                if (user != null) {
                  controller.inputController.addMentionUser(user);
                }
              },
      );
    }

    return SizedBox(
      key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
      width: controller.chatController.chat.isSingle ||
              controller.chatController.chat.isSystem
          ? 0
          : jxDimension.chatRoomAvatarSize(),
    );
  }
}
