import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/chat/pages/chat_pin_container.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

final isAudioPinPlaying = true.obs;
final audioPinProgressPercent = 0.0.obs;

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

  @override
  void initState() {
    _setAudioListener();
    super.initState();
  }

  void _setAudioListener() {
    _resetAudioListener();

    playerService.onAudioFinish = () {
      isShowAudioPin.value = false;
    };
    playerService.onAudioProgress = (progress) {
      var percent =
          progress.position.inMilliseconds / progress.duration.inMilliseconds;
      audioPinProgressPercent.value = percent;
      isShowAudioPin.value = true;
    };
    playerService.onAudioPlayerStateChanged = () async {
    };
  }

  void _resetAudioListener() {
    playerService.onAudioFinish = null;
    playerService.onAudioProgress = null;
    playerService.onAudioPlayerStateChanged = null;
  }

  @override
  void dispose() {
    _resetAudioListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Offstage(
        offstage: !isShowAudioPin.value,
        child: Container(
          height: 36,
          color: backgroundColor,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          isAudioPinPlaying.value = !isAudioPinPlaying.value;
                          if (!isAudioPinPlaying.value) {
                            playerService.pausePlayer();
                          } else {
                            playerService.resumePlayer();
                          }
                        },
                        child: OpacityEffect(
                          child: SvgPicture.asset(
                            isAudioPinPlaying.value
                                ? 'assets/svgs/Pause.svg'
                                : 'assets/svgs/play_audio.svg',
                            width: 20.0,
                            height: 20.0,
                            colorFilter: const ColorFilter.mode(
                                ImColor.accentColor, BlendMode.srcIn),
                            // color: inputHintTextColor,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ImText(
                            playerService.currentUsrName,
                            fontSize: ImFontSize.small,
                            color: ImColor.black,
                          ),
                          ImText('语音消息',
                              fontSize: ImFontSize.xs, color: ImColor.black48),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          playerService.stopPlayer();
                          playerService.resetPlayer();
                          isShowAudioPin.value = false;
                        },
                        child: OpacityEffect(
                          child: SvgPicture.asset(
                            'assets/svgs/close_icon.svg',
                            width: 20.0,
                            height: 20.0,
                            colorFilter: const ColorFilter.mode(
                                ImColor.black48, BlendMode.srcIn),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              LinearProgressIndicator(
                // key: ,
                value: audioPinProgressPercent.value,
                backgroundColor: Colors.transparent,
                minHeight: 2,
                color: Colors.blue,
              ),
              const Divider(
                height: 1,
                color: ImColor.borderColor,
                thickness: 2,
              ),
            ],
          ),
        ),
      );
    });
  }
}
