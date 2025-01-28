import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/pages/chat_pin_container.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/swipeable_page_route.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/component.dart';

final isAudioPinPlaying = true.obs;
final audioPinProgressPercent = 0.0.obs;
final audioSpeed = 1.0.obs;
bool isReadingText = false;
RegExp removePointZeroDouble = RegExp(r'([.]*0)(?!.*\d)');

class RecordAudioControlItem extends StatefulWidget {
  const RecordAudioControlItem({
    super.key,
    required this.isFromHome,
  });

  final bool isFromHome;

  @override
  State<RecordAudioControlItem> createState() => _RecordAudioControlItemState();
}

class _RecordAudioControlItemState extends State<RecordAudioControlItem> {
  String usrName = '';

  late bool isFromHome = widget.isFromHome;

  VolumePlayerService playerService = VolumePlayerService.sharedInstance;

  double get currentPlayingPosition =>
      playerService.getPlaybackDuration(playerService.playbackKey);

  ChatListController get chatListController => Get.find<ChatListController>();

  FancyGestureController get fancyGestureController =>
      Get.find<FancyGestureController>();

  @override
  void initState() {
    playerService.on(
      VolumePlayerService.keyVolumePlayerStatus,
      _onPlayerStatusChange,
    );
    playerService.on(
      VolumePlayerService.keyVolumePlayerProgress,
      _onPlayerProgressChange,
    );

    super.initState();
  }

  @override
  void dispose() {
    playerService.off(
      VolumePlayerService.keyVolumePlayerStatus,
      _onPlayerStatusChange,
    );
    playerService.off(
      VolumePlayerService.keyVolumePlayerProgress,
      _onPlayerProgressChange,
    );

    super.dispose();
  }

  void _onPlayerStatusChange(sender, type, data) async {
    if (data == VolumePlayerServiceType.stop) {
      if (mounted) {
        if (playerService.sendFunctionOnceAtStatusChange) {
          playerService.sendFunctionOnceAtStatusChange = false;
          if (!isReadingText && playerService.currentMessage != null) {
            playerService.autoPlayIfNextAudioExist();
          } else {
            // reset
            isReadingText = false;
          }
        }
      }
    } else if (data == VolumePlayerServiceType.pause) {
      if (mounted) isAudioPinPlaying.value = false;
    } else if (data == VolumePlayerServiceType.play) {
      await playerService.setPlaybackSpeed(audioSpeed.value);
    }
  }

  void _onPlayerProgressChange(sender, type, data) async {
    var progress = data;
    double percent =
        progress.position.inMilliseconds / progress.duration.inMilliseconds;

    if (percent.isNaN) return; //NAN 不触发value 变更
    audioPinProgressPercent.value = percent;
    // isShowAudioPin.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Offstage(
        offstage: !isShowAudioPin.value,
        child: Container(
          height: 36,
          color: colorBackground,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (objectMgr.callMgr.getCurrentState() ==
                            CallState.Idle) {
                          isAudioPinPlaying.value = !isAudioPinPlaying.value;
                          if (!isAudioPinPlaying.value) {
                            await playerService.pausePlayer();
                            if (isReadingText) {
                              objectMgr.chatMgr.event(
                                objectMgr.chatMgr,
                                ChatMgr.messagePauseReading,
                              );
                            }
                          } else {
                            await playerService.resumePlayer();
                            if (isReadingText) {
                              objectMgr.chatMgr.event(
                                objectMgr.chatMgr,
                                ChatMgr.messageContinueRead,
                              );
                            } else {
                              await playerService.seekTo(
                                playerService
                                    .getPlaybackDuration(
                                      playerService.playbackKey,
                                    )
                                    .toInt(),
                              );
                            }
                          }
                        } else {
                          Toast.showToast(localized(toastEndCallFirst));
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        transitionBuilder: (child, anim) => RotationTransition(
                          turns: child.key == const ValueKey('pause')
                              ? Tween<double>(begin: 1, end: 0.5).animate(anim)
                              : Tween<double>(begin: 0.5, end: 1).animate(anim),
                          child: ScaleTransition(scale: anim, child: child),
                        ),
                        child: CustomImage(
                          key: ValueKey(
                            isAudioPinPlaying.value && playerService.isPlaying
                                ? 'pause'
                                : 'play',
                          ),
                          'assets/svgs/${isAudioPinPlaying.value && playerService.isPlaying ? 'pause' : 'play'}_audio.svg',
                          size: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          color: themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 33),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            playerService.currentUsrName,
                            style: jxTextStyle.textStyle12(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isReadingText
                                ? localized(textToVoice)
                                : localized(voiceMsg),
                            style: jxTextStyle.textStyle10(
                              color: colorTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        audioSpeed.value == 2.0
                            ? audioSpeed.value = 1.0
                            : audioSpeed.value += 0.5;

                        imBottomToast(
                          Get.context!,
                          title: localized(
                            theAudioWillPlayAtParamSpeed,
                            params: [
                              audioSpeed.value == 1.0
                                  ? localized(normalText)
                                  : localized(
                                      paramSpeed,
                                      params: [
                                        NumberFormat("#.#")
                                            .format(audioSpeed.value)
                                      ],
                                    )
                            ],
                          ),
                          icon: ImBottomNotifType.INFORMATION,
                        );

                        if (playerService.isPlaying) {
                          await playerService
                              .setPlaybackSpeed(audioSpeed.value);
                          return;
                        }
                        setState(() {});
                      },
                      behavior: HitTestBehavior.opaque,
                      child: OpacityEffect(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const CustomImage(
                              'assets/svgs/voice_speed_multiplier.svg',
                              size: 24,
                              color: colorTextSecondary,
                            ),
                            Text(
                              '${audioSpeed.value.toString().replaceAll(removePointZeroDouble, '')}X',
                              style: jxTextStyle.textStyleBold10(
                                color: colorTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    CustomImage(
                      'assets/svgs/close_thick_outlined_icon.svg',
                      size: 24,
                      color: colorTextSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onClick: () async {
                        playerService
                            .removePlaybackDuration(playerService.playbackKey);
                        playerService.stopPlayer();
                        playerService.resetPlayer();
                        playerService.playbackKey = '';
                        isShowAudioPin.value = false;
                        audioSpeed.value = 1.0;
                        await playerService.setPlaybackSpeed(audioSpeed.value);
                        if (isReadingText) {
                          objectMgr.chatMgr.event(
                            objectMgr.chatMgr,
                            ChatMgr.messageStopAllReading,
                          );
                          isReadingText = false;
                        }

                        if (Platform.isIOS) {
                          fancyGestureController.event.event(
                            this,
                            FancyGestureEvent.ON_EDGE_SWIPE_UPDATE,
                            data: FancyGestureEventType.enable,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: audioPinProgressPercent.value,
                backgroundColor: Colors.transparent,
                minHeight: 2,
                color: themeColor,
              ),
              const CustomDivider(),
            ],
          ),
        ),
      );
    });
  }
}
