import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet_info.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/record_audio_control_item.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/im/services/audio_services/desktop_audio_player.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/im/services/chat_pop_animation_info.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/circular_loading_bar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';

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

class _VoiceViewState extends MessageWidgetMixin<VoiceView>
    with AutomaticKeepAliveClientMixin {
  /// 加载状态
  final isLoading = false.obs;
  bool chatIsDeleted = false;

  final messageList = <Message>[].obs;

  final List<TargetWidgetKeyModel> _keyList = [];

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
      if (widget.chat!.isSingle || widget.chat!.isSpecialChat) {
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
      int messageId = 0;
      if (item is Message) {
        id = item.id;
      } else {
        messageId = item;
      }
      for (final asset in messageList) {
        Message? msg = asset;
        if (id == 0) {
          if (msg.message_id == messageId) {
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
        int index = messageList.indexOf(item);
        _keyList.removeAt(index);
        messageList.remove(item);
      }
    }
  }

  _onMessageAutoDelete(sender, type, data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeVoice) return;
      messageList
          .removeWhere((element) => element.message_id == data.message_id);
      return;
    }
  }

  _onMessageComing(Object sender, Object type, Object? data) {
    if (data is Message && data.chat_id == widget.chat?.id) {
      if (data.typ != messageTypeVoice) return;
      if (data.isEncrypted) return;
      messageList.insert(0, data);
      for (Message msg in messageList) {
        if (data.id == msg.id && msg.message_id == 0) {
          messageList.remove(msg);
          break;
        }
      }
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
      'chat_id = ? AND chat_idx > ? AND (typ = ?) AND (ref_typ == 0)',
      [
        widget.chat!.id,
        messageList.isEmpty
            ? widget.chat!.hide_chat_msg_idx
            : messageList.last.chat_idx - 1,
        messageTypeVoice,
      ],
      'DESC',
      null,
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
    return WillPopScope(
      onWillPop: Platform.isAndroid
          ? () async {
              resetPopupWindow();
              return true;
            }
          : null,
      child: Obx(() {
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
              color: themeColor,
              ballType: BallType.solid,
              borderWidth: 1,
              borderColor: themeColor,
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
                padding: EdgeInsets.only(
                    top: objectMgr.loginMgr.isDesktop ? 30.0 : 0),
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
                style: jxTextStyle.textStyle14(color: colorTextSecondary),
              ),
            ],
          );
        } else {
          if (widget.isGroup) {
            groupInfoController?.setUpItemKey(messageList, _keyList);
          } else {
            chatInfoController?.setUpItemKey(messageList, _keyList);
          }
          return CustomScrollView(
            slivers: <Widget>[
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    MessageVoice audio = messageList[index]
                        .decodeContent(cl: MessageVoice.creator);

                    Widget child = AudioItem(
                      message: messageList[index],
                      messageVoice: audio,
                      isSelected: voiceIsSelected(index),
                      isGroup: widget.chat?.isGroup ?? false,
                      chat: widget.chat,
                    );
                    TargetWidgetKeyModel model = _keyList[index];

                    return GestureDetector(
                      key: model.targetWidgetKey,
                      behavior: HitTestBehavior.translucent,
                      onTapDown: (details) {
                        tapPosition = details.globalPosition;
                      },
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
                        vibrate();
                        if (objectMgr.loginMgr.isDesktop) {
                          if (widget.isGroup) {
                            if (groupInfoController!.onAudioPlaying.value) {
                              return;
                            }
                            if (!groupInfoController!.onMoreSelect.value) {
                              onItemLongPress(messageList[index]);
                            }
                          } else {
                            if (chatInfoController!.onAudioPlaying.value) {
                              return;
                            }
                            if (!chatInfoController!.onMoreSelect.value) {
                              onItemLongPress(messageList[index]);
                            }
                          }
                        } else {
                          if (widget.chat != null) {
                            final msg = messageList[index];
                            enableFloatingWindowInfo(
                              context,
                              widget.chat!.id,
                              msg,
                              child,
                              model.targetWidgetKey,
                              tapPosition,
                              ChatPopMenuSheetInfo(
                                message: msg,
                                chat: widget.chat!,
                                sendID: msg.send_id,
                                menuClick: (String title) {
                                  resetPopupWindow();
                                },
                              ),
                              chatPopAnimationType: ChatPopAnimationType.right,
                              menuHeight: ChatPopMenuSheetInfo.getMenuHeight(
                                msg,
                                widget.chat!,
                              ),
                            );
                          }
                        }
                      },
                      child: Obx(
                        () => Stack(
                          children: [
                            child,
                            if (voiceIsSelected(index))
                              const Positioned(
                                left: 0.0,
                                right: 0.0,
                                bottom: 0.0,
                                top: 0.0,
                                child: ColoredBox(
                                  color: colorBorder,
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
      }),
    );
  }
}

class AudioItem extends StatefulWidget {
  final Message message;
  final MessageVoice messageVoice;
  final bool isSelected;
  final bool isGroup;
  final Chat? chat;

  /// for searchView only
  final bool? isSearch;
  final String? searchText;

  const AudioItem({
    super.key,
    required this.message,
    required this.messageVoice,
    required this.isGroup,
    this.isSelected = false,
    this.chat,
    this.isSearch = false,
    this.searchText,
  });

  @override
  State<AudioItem> createState() => _AudioItemState();
}

class _AudioItemState extends State<AudioItem> {
  final int _kPlayerButtonSize = 40;

  String? voiceFilePath;
  final VolumePlayerService playerService = VolumePlayerService.sharedInstance;
  DesktopAudioPlayer? desktopAudioPlayer;

  ValueNotifier<double> dragPosition = ValueNotifier<double>(-1.0);
  bool isDragging = false;

  final downloadProgress = 0.0.obs;

  final isDownloaded = false.obs;

  final isDownloading = false.obs;
  final isPlayIcon = false.obs; //仅仅跟播放按钮UI挂钩
  bool get isDesktop => objectMgr.loginMgr.isDesktop;

  bool get isPlaying =>
      isDesktop ? desktopAudioPlayer!.isPlaying : playerService.isPlaying;

  Map<String, String> get chatNameMap {
    if (widget.isSearch == true) {
      return getChatNameMap(widget.message);
    } else {
      return {};
    }
  }

  String get transcribeContent {
    if (widget.isSearch == true && notBlank(widget.searchText)) {
      return widget.messageVoice.transcribe;
    } else {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();

    playerService.on(
        VolumePlayerService.playerStateChange, _onPlayerStateChange);
    playerService.on(
      VolumePlayerService.keyVolumePlayerStatus,
      _onPlayerStatusChange,
    );
    playerService.on(VolumePlayerService.playerStateChange_for_voice_view,
        _onPlayerStateChangeForVoiceView);

    final messageContent = jsonDecode(widget.message.content);
    final localFilePath = notBlank(messageContent['vmpath'])
        ? messageContent['vmpath']
        : messageContent['url'];
    if (File(localFilePath).existsSync()) {
      voiceFilePath = localFilePath;
      isDownloaded.value = true;
    } else {
      final voiceFilePathTmp =
          downloadMgrV2.getLocalPath(widget.messageVoice.url);
      isDownloaded.value = voiceFilePathTmp != null;
      final percentage =
          cacheMediaMgr.getDownloadPercentage(widget.messageVoice.url);
      isDownloading.value = percentage != null;
    }

    if (playerService.isPlaying) {
      final tempPlaybackKey =
          '${widget.message.message_id}_${playerService.currentPlayingFile}';
      if (tempPlaybackKey == playerService.currentPlayingFileName) {
        voiceFilePath = playerService.currentPlayingFile;
        isPlayIcon.value = true;
        playerService.playerDurationStream.listen((event) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }

    if (isDesktop && widget.chat != null) {
      desktopAudioPlayer = DesktopAudioPlayer.create(
        messageId: widget.message.message_id,
        chat: widget.chat!,
      );
    }
  }

  @override
  void didUpdateWidget(AudioItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) setState(() {});
  }

  @override
  void dispose() {
    // playerService.pausePlayer();
    playerService.off(
        VolumePlayerService.playerStateChange, _onPlayerStateChange);
    playerService.off(
      VolumePlayerService.keyVolumePlayerStatus,
      _onPlayerStatusChange,
    );
    playerService.off(VolumePlayerService.playerStateChange_for_voice_view,
        _onPlayerStateChangeForVoiceView);
    super.dispose();
  }

  void _onPlayerStateChange(Object sender, Object type, Object? data) {
    setState(() {});
  }

  void _onPlayerStatusChange(sender, type, data) {
    if (mounted) {
      isPlayIcon.value = data == VolumePlayerServiceType.play; //捕捉顶部栏的播放停止状态
    }
  }

  void _onPlayerStateChangeForVoiceView(
      Object sender, Object type, Object? data) {
    voiceFilePath ??= downloadMgrV2.getLocalPath(widget.messageVoice.url);
    setStateOnlyOnPlayingVoiceMessage();
  }

  void setStateOnlyOnPlayingVoiceMessage() {
    ///Optimize FPS
    if (mounted) {
      if (widget.message.id == playerService.currentMessage?.id) {
        setState(() {
          isPlayIcon.value = isPlaying;
        });
      } else {
        isPlayIcon.value = false;
      }
    }
  }

  String get currentPlayingFileName => playerService.currentPlayingFileName;

  String get playbackKey => '${widget.message.message_id}_$voiceFilePath';

  double get currentPlayingPosition =>
      playerService.getPlaybackDuration(playbackKey);

  _onPlayer() async {
    if (!CoolDownManager.handler(
        key: "voice_onclick${widget.messageVoice.localUrl}", duration: 500)) {
      showWarningToast(localized(toastBusy));
      return;
    }
    if (currentPlayingFileName != playbackKey) {
      if (playerService.isPlaying) {
        await playerService.seekTo(0);
        playerService.stopPlayer();
      }
      playerService.setPlaybackDuration(currentPlayingFileName, 0.0);

      voiceFilePath ??= downloadMgrV2.getLocalPath(widget.messageVoice.url);
      isDownloading.value = voiceFilePath == null;
      if (voiceFilePath == null) {
        /// 在群信息页的语音列表下载语音消息 也要通知到聊天页去同步更新UI
        final data = VolumePlayerServiceNextAudioDownloadStarted(
            widget.messageVoice.url);
        playerService.event(playerService,
            VolumePlayerService.keyDownloadStart_FromVolumePlayService,
            data: data);
      }

      DownloadResult result = await downloadMgrV2.download(
        widget.messageVoice.url,
        onReceiveProgress: (int received, int total) {
          downloadProgress.value = received / total;
          final data = VolumePlayerServiceNextAudioDownloadProgress(
              widget.messageVoice.url, received / total);
          playerService.event(playerService,
              VolumePlayerService.keyDownloadProgress_FromVolumePlayService,
              data: data);
        },
      );
      voiceFilePath = result.localPath;

      // voiceFilePath ??= await downloadMgr.downloadFile(
      //   widget.messageVoice.url,
      //   onReceiveProgress: (int received, int total) {
      //     downloadProgress.value = received / total;
      //     final data = VolumePlayerServiceNextAudioDownloadProgress(
      //         widget.messageVoice.url, received / total);
      //     playerService.event(playerService,
      //         VolumePlayerService.keyDownloadProgress_FromVolumePlayService,
      //         data: data);
      //   },
      // );
      isDownloading.value = false;
      isDownloaded.value = voiceFilePath != null;
      final data = VolumePlayerServiceNextAudioDownloadResult(
          widget.messageVoice.url, voiceFilePath != null);
      playerService.event(playerService,
          VolumePlayerService.keyDownloadResult_FromVolumePlayService,
          data: data);
      if (voiceFilePath == null) {
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

      isPlayIcon.value = !isPlayIcon.value;
      if (isDesktop) {
        await desktopAudioPlayer?.openPlayer(
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
        return;
      }

      Message nextMsg = widget.message;
      MessageVoice nextMsgVoice = widget.messageVoice;

      if (nextMsgVoice.isOperated == false &&
          nextMsg.send_id != objectMgr.userMgr.mainUser.uid) {
        ChatHelp.sendFileOperate(
          chatID: nextMsg.chat_id,
          messageId: nextMsg.message_id,
          chatIdx: nextMsg.chat_idx,
          userId: nextMsg.send_id,
          receivers: [nextMsg.send_id, objectMgr.userMgr.mainUser.uid],
        );
      }

      await playerService.openPlayer(
        isFromChatInfoPage: true,
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
    } else {
      if (!isDesktop) {
        if (!playerService.isPlaying &&
            playerService.getPlaybackDuration(playbackKey) <
                widget.messageVoice.second * 1000) {
          await playerService.resumePlayer();
        } else {
          dragPosition.value = -1.0;
          await playerService.pausePlayer();
        }
      }

      if (isDesktop && desktopAudioPlayer != null) {
        if (!desktopAudioPlayer!.isPlaying && voiceFilePath != null) {
          await desktopAudioPlayer!.resumePlayer();
        } else {
          await desktopAudioPlayer!.pausePlayer();
          dragPosition.value = -1.0;
        }
      }
      setState(() {});
    }
  }

  Widget playbackButton(IconData iconData, Color backgroundColor) {
    return Obx(() => Stack(
          children: [
            Container(
              alignment: Alignment.center,
              width: _kPlayerButtonSize.toDouble(),
              height: _kPlayerButtonSize.toDouble(),
              decoration: ShapeDecoration(
                color: backgroundColor,
                shape: const CircleBorder(),
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
                          transitionBuilder: (child, anim) =>
                              RotationTransition(
                            turns: child.key == const ValueKey('pause')
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
                              : const Icon(
                                  Icons.play_arrow_rounded,
                                  color: colorWhite,
                                  size: 28,
                                  key: ValueKey('play'),
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
            if (isDownloading.value)
              Positioned(
                top: 2,
                left: 2,
                right: 2,
                bottom: 2,
                child: CircularLoadingBarRotate(
                  value: downloadProgress.value,
                ),
              ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
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
                  themeColor,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  decoration: BoxDecoration(
                    border: customBorder,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      widget.isSearch ?? false
                          ? Row(
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.40),
                                  child: Text(
                                    chatNameMap['first'] ?? '',
                                    style: jxTextStyle.headerText(
                                      fontWeight: MFontWeight.bold5.value,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  size: 12,
                                  color: colorTextSecondary,
                                ),
                                Expanded(
                                  child: Text(
                                    chatNameMap['second'] ?? '',
                                    style: jxTextStyle.headerText(
                                      fontWeight: MFontWeight.bold5.value,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : objectMgr.userMgr.isMe(widget.message.send_id)
                              ? Text(
                                  localized(chatInfoYou),
                                  style: jxTextStyle.headerText(
                                    fontWeight: MFontWeight.bold5.value,
                                  ),
                                )
                              : NicknameText(
                                  uid: widget.message.send_id,
                                  isTappable: false,
                                  fontSize: MFontSize.size17.value,
                                  fontWeight: MFontWeight.bold5.value,
                                  overflow: TextOverflow.ellipsis,
                                  groupId: widget.isGroup
                                      ? widget.message.chat_id
                                      : null,
                                ),
                      const SizedBox(height: 4),
                      Visibility(
                        visible: notBlank(transcribeContent),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: getHighlightSpanList(
                                transcribeContent,
                                widget.searchText,
                                jxTextStyle.normalSmallText(
                                  color: colorTextSecondary,
                                ),
                                needCut: notBlank(widget.searchText),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            constructTime(
                              widget.messageVoice.second ~/ 1000,
                              showHour: false,
                            ),
                            style: jxTextStyle.normalSmallText(
                              color: colorTextSecondary,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: jxTextStyle.normalSmallText(
                              color: colorTextSecondary,
                            ),
                          ),
                          Text(
                            FormatTime.getFullDayTime(
                              widget.message.create_time,
                            ),
                            style: jxTextStyle.normalSmallText(
                              color: colorTextSecondary,
                            ),
                          ),
                        ],
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
