import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_content/painter/voice_painter.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class VoiceView extends StatefulWidget {
  final Chat? chat;
  final bool isGroup;

  const VoiceView({
    super.key,
    required this.isGroup,
    this.chat,
  });

  @override
  State<VoiceView> createState() => _VoiceViewState();
}

class _VoiceViewState extends State<VoiceView>
    with AutomaticKeepAliveClientMixin {
  /// 加载状态
  final isLoading = false.obs;
  bool chatIsDeleted = false;

  final messageList = <Message>[].obs;

  bool singleAndNotFriend = false;

  ChatInfoController? get chatInfoController =>
      Get.isRegistered<ChatInfoController>()
          ? Get.find<ChatInfoController>()
          : null;

  GroupChatInfoController? get groupInfoController =>
      Get.isRegistered<GroupChatInfoController>()
          ? Get.find<GroupChatInfoController>()
          : null;

  @override
  void initState() {
    super.initState();

    if (widget.chat != null) {
      if (widget.chat!.isSingle) {
        chatInfoController!.onMoreSelectCallback = onJumpToOriginalMessage;
        if (chatInfoController!.user.value!.relationship !=
            Relationship.friend) {
          singleAndNotFriend = true;
        }
      } else {
        groupInfoController!.onMoreSelectCallback = onJumpToOriginalMessage;
        if (widget.chat!.flag_my >= ChatStatus.MyChatFlagKicked.value) {
          chatIsDeleted = true;
        } else {
          chatIsDeleted = false;
        }
      }
      loadVoiceList();
    } else {
      singleAndNotFriend = true;
    }

    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onVoiceMessageUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onMessageAutoDelete);

    if (!chatIsDeleted) {
      objectMgr.chatMgr.on(ChatMgr.eventMessageComing, _onMessageComing);
    }
  }

  _onVoiceMessageUpdate(sender, type, data) {
    if (data['id'] != widget.chat?.id || data['message'] == null) {
      return;
    }
    List<dynamic> delAsset = [];
    for (var item in data['message']) {
      int id = 0;
      int message_id = 0;
      if (item is Message) {
        id = item.id;
      } else {
        message_id = item;
      }
      for (final asset in messageList) {
        Message? msg = asset;
        if (id == 0) {
          if (msg.message_id == message_id) {
            delAsset.add(asset);
          }
        } else {
          if (msg.id == id) {
            delAsset.add(asset);
          }
        }
      }
    }

    if (delAsset.isNotEmpty) {
      for (final item in delAsset) {
        messageList.remove(item);
      }
    }
  }

  _onMessageAutoDelete(sender, type, data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeVoice) return;
      messageList.removeWhere((element) => element.message_id == data.message_id);
      return;
    }
  }

  _onMessageComing(Object sender, Object type, Object? data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeVoice) return;
      messageList.insert(0, data);
      return;
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, _onVoiceMessageUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventAutoDeleteMsg, _onMessageAutoDelete);
    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _onMessageComing);
    super.dispose();
  }

  loadVoiceList() async {
    if (messageList.isEmpty) isLoading.value = true;

    List<Map<String, dynamic>> tempList =
        await objectMgr.localDB.loadMessagesByWhereClause(
      'chat_id = ? AND chat_idx > ? AND (typ = ?)',
      [
        widget.chat!.id,
        messageList.isEmpty
            ? widget.chat!.hide_chat_msg_idx
            : messageList.last.chat_idx - 1,
        messageTypeVoice,
      ],
      'DESC',
      null,
    );
    List<Message> mList = tempList.map((e) => Message()..init(e)).toList();

    mList = mList
        .where((element) => !element.isDeleted && !element.isExpired)
        .toList();

    if (mList.isNotEmpty) {
      messageList.addAll(mList);
    }

    isLoading.value = false;
  }

  onItemLongPress(Message message) async {
    if (widget.isGroup) {
      groupInfoController!.onMoreSelect.value = true;
      groupInfoController!.selectedMessageList.add(message);
    } else {
      chatInfoController!.onMoreSelect.value = true;
      chatInfoController!.selectedMessageList.add(message);
    }
  }

  onItemTap(Message message) {
    if (widget.isGroup) {
      if (groupInfoController!.selectedMessageList.contains(message)) {
        groupInfoController!.selectedMessageList.remove(message);
        if (groupInfoController!.selectedMessageList.isEmpty) {
          groupInfoController!.onMoreSelect.value = false;
        }
      } else {
        groupInfoController!.selectedMessageList.add(message);
      }
    } else {
      if (chatInfoController!.selectedMessageList.contains(message)) {
        chatInfoController!.selectedMessageList.remove(message);
        if (chatInfoController!.selectedMessageList.isEmpty) {
          chatInfoController!.onMoreSelect.value = false;
        }
      } else {
        chatInfoController!.selectedMessageList.add(message);
      }
    }
  }

  onJumpToOriginalMessage(Message message) {
    Get.back();
    if (widget.isGroup) {
      if (Get.isRegistered<GroupChatController>(
          tag: widget.chat!.id.toString())) {
        final groupController =
            Get.find<GroupChatController>(tag: widget.chat!.id.toString());
        groupController.clearSearching();
        groupController.locateToSpecificPosition([message.chat_idx]);
      } else {
        Routes.toChat(chat: widget.chat!, selectedMsgIds: [message]);
      }
    } else {
      if (Get.isRegistered<SingleChatController>(
          tag: widget.chat!.id.toString())) {
        final singleChatController =
            Get.find<SingleChatController>(tag: widget.chat!.id.toString());
        singleChatController.clearSearching();
        singleChatController.locateToSpecificPosition([message.chat_idx]);
      } else {
        Routes.toChat(chat: widget.chat!, selectedMsgIds: [message]);
      }
    }
  }

  bool voiceIsSelected(int index) {
    return widget.isGroup
        ? groupInfoController!.selectedMessageList.contains(messageList[index])
        : chatInfoController!.selectedMessageList.contains(messageList[index]);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      if (!widget.isGroup) {
        if (chatInfoController!.user.value!.relationship !=
            Relationship.friend) {
          singleAndNotFriend = true;
        } else {
          singleAndNotFriend = false;
        }
      }

      if (isLoading.value) {
        return BallCircleLoading(
          radius: 20,
          ballStyle: BallStyle(
            size: 4,
            color: accentColor,
            ballType: BallType.solid,
            borderWidth: 1,
            borderColor: accentColor,
          ),
        );
      }

      if (singleAndNotFriend && messageList.isEmpty) {
        return Center(
          child: Text(localized(noItemFoundAddThisUserFirst)),
        );
      } else if (messageList.isEmpty) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding:
                  EdgeInsets.only(top: objectMgr.loginMgr.isDesktop ? 30.0 : 0),
              child: SvgPicture.asset(
                'assets/svgs/empty_state.svg',
                width: 60,
                height: 60,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localized(noHistoryYet),
              style: jxTextStyle.textStyleBold16(),
            ),
            Text(
              localized(yourHistoryIsEmpty),
              style:
                  jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
            ),
          ],
        );
      } else {
        return CustomScrollView(
          slivers: <Widget>[
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  MessageVoice audio = messageList[index]
                      .decodeContent(cl: MessageVoice.creator);
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (widget.isGroup) {
                        if (groupInfoController!.onAudioPlaying.value) return;
                        if (groupInfoController!.onMoreSelect.value) {
                          onItemTap(messageList[index]);
                        }
                      } else {
                        if (chatInfoController!.onAudioPlaying.value) return;
                        if (chatInfoController!.onMoreSelect.value) {
                          onItemTap(messageList[index]);
                        }
                      }
                    },
                    onLongPress: () {
                      if (widget.isGroup) {
                        if (groupInfoController!.onAudioPlaying.value) return;
                        if (!groupInfoController!.onMoreSelect.value) {
                          onItemLongPress(messageList[index]);
                        }
                      } else {
                        if (chatInfoController!.onAudioPlaying.value) return;
                        if (!chatInfoController!.onMoreSelect.value) {
                          onItemLongPress(messageList[index]);
                        }
                      }
                    },
                    child: Obx(
                      () => Stack(
                        children: [
                          AudioItem(
                            message: messageList[index],
                            messageVoice: audio,
                            isSelected: voiceIsSelected(index),
                          ),
                          if (voiceIsSelected(index))
                            Positioned(
                              left: 0.0,
                              right: 0.0,
                              bottom: 0.0,
                              top: 0.0,
                              child: ColoredBox(
                                color: systemColor.withOpacity(0.1),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: messageList.length,
              ),
            ),
          ],
        );
      }
    });
  }
}

class AudioItem extends StatefulWidget {
  final Message message;
  final MessageVoice messageVoice;
  final bool isSelected;

  const AudioItem({
    super.key,
    required this.message,
    required this.messageVoice,
    this.isSelected = false,
  });

  @override
  State<AudioItem> createState() => _AudioItemState();
}

class _AudioItemState extends State<AudioItem> {
  final int _kPlayerButtonSize = 40;

  String? voiceFilePath;
  final VolumePlayerService playerService = VolumePlayerService.sharedInstance;

  ValueNotifier<double> dragPosition = ValueNotifier<double>(-1.0);
  bool isDragging = false;

  @override
  void initState() {
    super.initState();

    playerService.on(
        VolumePlayerService.playerStateChange, _onPlayerStateChange);

    if (playerService.isPlaying) {
      final tempPlaybackKey =
          '${widget.message.message_id}_${playerService.currentPlayingFile}';
      if (tempPlaybackKey == playerService.currentPlayingFileName) {
        voiceFilePath = playerService.currentPlayingFile;

        playerService.playerDurationStream.listen((event) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(AudioItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) setState(() {});
  }

  @override
  void dispose() {
    playerService.stopPlayer();
    playerService.off(
        VolumePlayerService.playerStateChange, _onPlayerStateChange);
    super.dispose();
  }

  void _onPlayerStateChange(Object sender, Object type, Object? data) {
    setState(() {});
  }

  String get currentPlayingFileName => playerService.currentPlayingFileName;

  String get playbackKey => '${widget.message.message_id}_${voiceFilePath}';

  double get currentPlayingPosition =>
      playerService.getPlaybackDuration(playbackKey);

  _onPlayer() async {
    if (currentPlayingFileName != playbackKey) {
      String? cacheUrl = widget.messageVoice.localUrl;
      if (cacheUrl != null && cacheUrl.isNotEmpty) {
        voiceFilePath = cacheUrl;
        final f = File(voiceFilePath!);
        if (!f.existsSync()) {
          voiceFilePath = null;
        }
      }

      if (voiceFilePath == null || voiceFilePath!.isEmpty) {
        voiceFilePath = await cacheMediaMgr
                .downloadMedia(widget.messageVoice.url) ??
            '';
      }
      if (voiceFilePath == null || voiceFilePath!.isEmpty) {
        Toast.showToast(localized(voiceFileDownloadFailed));
        return;
      }

      final f = File(voiceFilePath!);
      if (f.existsSync()) {
        playerService.currentPlayingFileName =
            '${widget.message.message_id}_${voiceFilePath!}';
        playerService.currentMessage = widget.message;
        playerService.currentPlayingFile = voiceFilePath!;
      } else {
        Toast.showToast("语音文件不存在");
        return;
      }

      await playerService.openPlayer(
        onFinish: () {
          playerService.removePlaybackDuration(playbackKey);
          if (mounted) {
            setState(() {});
          }
        },
        onProgress: (_) {
          if (mounted) {
            setState(() {});
          }
        },
        onPlayerStateChanged: () {
          if (mounted) {
            setState(() {});
          }
        },
      );
    } else {
      if (!playerService.isPlaying &&
          playerService.getPlaybackDuration(playbackKey) <
              widget.messageVoice.second * 1000) {
        await playerService.resumePlayer();
      } else {
        dragPosition.value = -1.0;
        await playerService.pausePlayer();
      }
      setState(() {});
    }
  }

  Widget playbackButton(IconData iconData, Color backgroundColor) {
    return Container(
      alignment: Alignment.center,
      width: _kPlayerButtonSize.toDouble(),
      height: _kPlayerButtonSize.toDouble(),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: const CircleBorder(),
      ),
      child: Icon(
        iconData,
        color: backgroundColor == Colors.white
            ? primaryTextColor.withOpacity(0.6)
            : Colors.white,
        size: objectMgr.loginMgr.isDesktop ? 24 : 24.w,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double percentage = currentPlayingPosition / widget.messageVoice.second;

    Widget decibelPaint = GestureDetector(
      onPanUpdate: (DragUpdateDetails details) {
        dragPosition.value = details.localPosition.dx /
            (4.0 * widget.messageVoice.decibels.length);
        setState(() {
          isDragging = true;
        });
      },
      onPanEnd: (DragEndDetails details) async {
        final dragMillisecond = dragPosition.value * widget.messageVoice.second;
        setState(() {
          playerService.setPlaybackDuration(playbackKey, dragMillisecond);
        });

        if (playerService.isPlaying) {
          await playerService.seekTo(dragMillisecond.toInt());
        }

        setState(() {
          isDragging = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: RepaintBoundary(
          child: ValueListenableBuilder(
              valueListenable: dragPosition,
              builder: (_, double value, __) {
                return CustomPaint(
                  size: Size(
                    4.0 * widget.messageVoice.decibels.length,
                    10,
                  ),
                  willChange: true,
                  painter: VoicePainter(
                    decibels: widget.messageVoice.decibels.cast<double>(),
                    playedProgress:
                        (value != -1 && !playerService.isPlaying) || isDragging
                            ? value
                            : percentage,
                  ),
                );
              }),
        ),
      ),
    );

    return GestureDetector(
      onTap: () => _onPlayer(),
      child: OverlayEffect(
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: playbackButton(
                  playbackKey == currentPlayingFileName &&
                          playerService.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow_rounded,
                  accentColor,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  decoration: BoxDecoration(
                    border: customBorder,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            objectMgr.userMgr.isMe(widget.message.send_id)
                                ? Text(
                                    localized(chatInfoYou),
                                    style: jxTextStyle.textStyleBold16(
                                      fontWeight: MFontWeight.bold6.value,
                                    ),
                                  )
                                : NicknameText(
                                    uid: widget.message.send_id,
                                    isTappable: false,
                                    fontSize: MFontSize.size16.value,
                                    fontWeight: MFontWeight.bold6.value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            SizedBox(
                                height: objectMgr.loginMgr.isDesktop ? 4 : 4.w),
                            Text(
                              '${constructTime(
                                widget.messageVoice.second ~/ 1000,
                                showHour: false,
                              )}',
                              style: jxTextStyle.textStyle12(
                                color: JXColors.secondaryTextBlack,
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOutCubic,
                              child: Visibility(
                                visible: currentPlayingFileName == playbackKey,
                                child: decibelPaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: objectMgr.loginMgr.isDesktop ? 16 : 16.w),
                      Text(
                        '${FormatTime.chartTime(
                          widget.message.create_time,
                          true,
                          todayShowTime: true,
                          dateStyle: DateStyle.MMDDYYYY,
                        )}',
                        style: jxTextStyle.textStyle14(
                          color: JXColors.secondaryTextBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
