import 'dart:io';

import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/im/custom_content/painter/voice_painter.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';

class FavouriteDetailVoice extends StatefulWidget {
  final FavouriteVoice data;

  const FavouriteDetailVoice({
    super.key,
    required this.data,
  });

  @override
  State<FavouriteDetailVoice> createState() => _FavouriteDetailVoiceState();
}

class _FavouriteDetailVoiceState extends State<FavouriteDetailVoice>
    with WidgetsBindingObserver {
  final VolumePlayerService playerService = VolumePlayerService.sharedInstance;
  String? id;

  String? voiceFilePath;

  bool get isPlaying => playerService.isPlaying;

  String get currentPlayingFileName => playerService.currentPlayingFileName;

  String get playbackKey => '${id}_$voiceFilePath';

  double get currentPlayingPosition =>
      playerService.getPlaybackDuration(playbackKey);

  ValueNotifier<double> dragPosition = ValueNotifier<double>(-1.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    id = widget.data.localUrl;

    getVoicePath();

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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    playerService.stopPlayer();
    playerService.resetState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {
      if (isPlaying) {
        playerService.stopPlayer();
        playerService
            .seekTo(playerService.getPlaybackDuration(playbackKey).toInt());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _onPlayer,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          color: colorTextPrimary.withOpacity(0.03),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipOval(
                child: Container(
                  width: 40,
                  height: 40,
                  color: themeColor,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: child.key == const ValueKey('pause')
                          ? Tween<double>(begin: 1, end: 0.5).animate(anim)
                          : Tween<double>(begin: 0.5, end: 1).animate(anim),
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: playbackKey == currentPlayingFileName && isPlaying
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
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 16,
                    ),
                    child: decibelPaint(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    constructTime(
                      widget.data.second ~/ 1000,
                      showHour: false,
                    ),
                    style:
                        jxTextStyle.normalSmallText(color: colorTextSecondary),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget decibelPaint() {
    double percentage = currentPlayingPosition / widget.data.second;
    return RepaintBoundary(
      child: ValueListenableBuilder(
        valueListenable: dragPosition,
        builder: (_, double value, __) {
          return CustomPaint(
            size: Size(
              4.0 * widget.data.decibels.length,
              72,
            ),
            willChange: true,
            painter: VoicePainter(
              decibels: widget.data.decibels.cast<double>(),
              lineColor: themeColor.withOpacity(0.32),
              playColor: themeColor,
              playedProgress: (value != -1 && !playerService.isPlaying)
                  ? value
                  : percentage,
            ),
          );
        },
      ),
    );
  }

  void getVoicePath() async {
    String? cacheUrl = widget.data.localUrl;
    if (cacheUrl != null && cacheUrl.isNotEmpty) {
      voiceFilePath = cacheUrl;
      final f = File(voiceFilePath!);
      if (!f.existsSync()) {
        voiceFilePath = null;
      }
    }

    if (voiceFilePath == null || voiceFilePath!.isEmpty) {
      // voiceFilePath = await downloadMgr.downloadFile(widget.data.url) ?? '';
      DownloadResult result = await downloadMgrV2.download(widget.data.url,
          downloadType: DownloadType.largeFile);
      voiceFilePath = result.localPath;
    }

    setStateOnlyOnPlayingVoiceMessage();
  }

  void setStateOnlyOnPlayingVoiceMessage() {
    ///Optimize FPS
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onPlayer() async {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    playerService.playbackKey = playbackKey;
    if (currentPlayingFileName != playbackKey) {
      if (isPlaying) {
        playerService.stopPlayer();
        await playerService
            .seekTo(playerService.getPlaybackDuration(playbackKey).toInt());
      }
      playerService.setPlaybackDuration(currentPlayingFileName, 0.0);
      if (voiceFilePath == null || voiceFilePath!.isEmpty) {
        // voiceFilePath = await downloadMgr.downloadFile(widget.data.url) ?? '';
        DownloadResult result = await downloadMgrV2.download(widget.data.url,
            downloadType: DownloadType.largeFile);
        voiceFilePath = result.localPath;
      }
      if (voiceFilePath == null || voiceFilePath!.isEmpty) {
        pdebug(localized(voiceFileDownloadFailed));
        return;
      }
      final f = File(voiceFilePath!);
      if (f.existsSync()) {
        playerService.currentPlayingFileName = playbackKey;
        playerService.currentPlayingFile = voiceFilePath!;

        if (playerService.getPlaybackDuration('${id}_null') > 0.0) {
          playerService.setPlaybackDuration(
            playbackKey,
            playerService.getPlaybackDuration('${id}_null'),
          );
          playerService.removePlaybackDuration('${id}_null');
        }
      } else {
        Toast.showToast("语音文件不存在");
        return;
      }

      await playerService.openPlayer(
        shouldEnablePinNotify: false,
        shouldCache: false,
        onFinish: () {
          playerService.removePlaybackDuration(playbackKey);
          setStateOnlyOnPlayingVoiceMessage();
        },
        onProgress: (_) {
          setStateOnlyOnPlayingVoiceMessage();
          // isAudioPinPlaying.value = true;
        },
        onPlayerStateChanged: () {
          setStateOnlyOnPlayingVoiceMessage();
        },
      );
    } else {
      if (isPlaying) {
        playerService.stopPlayer();
        await playerService
            .seekTo(playerService.getPlaybackDuration(playbackKey).toInt());
      } else {
        await playerService.openPlayer(
          shouldEnablePinNotify: false,
          shouldCache: false,
          onFinish: () {
            playerService.removePlaybackDuration(playbackKey);
            setStateOnlyOnPlayingVoiceMessage();
          },
          onProgress: (_) {
            setStateOnlyOnPlayingVoiceMessage();
            // isAudioPinPlaying.value = true;
          },
          onPlayerStateChanged: () {
            setStateOnlyOnPlayingVoiceMessage();
          },
        );
      }
    }

    setStateOnlyOnPlayingVoiceMessage();
  }

  void _onPlayerStateChange(sender, type, data) {
    setStateOnlyOnPlayingVoiceMessage();
  }

  void _onPlayerStatusChange(sender, type, data) {}

  void _onPlayerProgressChange(sender, type, data) {
    setStateOnlyOnPlayingVoiceMessage();
  }
}
