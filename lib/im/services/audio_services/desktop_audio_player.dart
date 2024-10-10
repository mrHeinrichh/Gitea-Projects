import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/object/chat/chat.dart';

class DesktopAudioPlayer {
  factory DesktopAudioPlayer.create({
    required int messageId,
    required Chat chat,
  }) =>
      DesktopAudioPlayer._(messageId, chat);

  int messageId;
  final AudioPlayer audioPlayer;
  final BaseChatController chatController;

  DesktopAudioPlayer._(this.messageId, Chat chat)
      : audioPlayer = AudioPlayer(playerId: messageId.toString())
          ..setReleaseMode(ReleaseMode.stop),
        chatController = getController(chat);

  bool get isPlaying => playerState.value == PlayerState.playing;

  bool get isPaused => playerState.value == PlayerState.paused;

  double get duration => _duration;
  double _duration = 0;

  ValueNotifier<PlayerState> playerState =
      ValueNotifier<PlayerState>(PlayerState.stopped);

  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerCompleteSubscription;

  Future<void> openPlayer({
    required Function() durationChanged,
    required Function() onPlayerCompleted,
    required Function(PlayerState) onPlayerStateChanged,
    required String filePath,
  }) async {
    _durationSubscription = audioPlayer.onPositionChanged.listen((duration) {
      _duration = duration.inMilliseconds.toDouble();
      durationChanged();
    });

    _playerCompleteSubscription = audioPlayer.onPlayerComplete.listen((_) {
      playerState.value = PlayerState.stopped;
      stopPlayer(audioPlayer);
      onPlayerCompleted();
    });

    playerState.addListener(() {
      onPlayerStateChanged(playerState.value);
    });
    await playPlayer(filePath);
    chatController.audioPlayersList.add(audioPlayer);
  }

  Future<void> playPlayer(String filePath) async {
    playerState.value = PlayerState.playing;
    await audioPlayer.play(DeviceFileSource(filePath));
    for (var player in chatController.audioPlayersList) {
      if (player != audioPlayer) player.pause();
    }
  }

  Future<void> pausePlayer() async {
    playerState.value = PlayerState.paused;
    await audioPlayer.pause();
  }

  Future<void> resumePlayer() async {
    playerState.value = PlayerState.playing;
    await audioPlayer.resume();
    for (var player in chatController.audioPlayersList) {
      if (player != audioPlayer) player.pause();
    }
  }

  Future<void> stopPlayer(AudioPlayer audioPlayer) async {
    playerState.value = PlayerState.stopped;
    chatController.audioPlayersList.remove(audioPlayer);
  }

  Future<void> seekTo(int milliseconds) async {
    _duration = milliseconds.toDouble();
    await audioPlayer.seek(
      Duration(milliseconds: milliseconds.round()),
    );
  }

  Future<void> disposeStream() async {
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
  }
}

getController(Chat chat) {
  final String tag = chat.chat_id.toString();
  if (chat.typ == chatTypeGroup) {
    return Get.find<GroupChatController>(tag: tag);
  } else {
    return Get.find<SingleChatController>(tag: tag);
  }
}
