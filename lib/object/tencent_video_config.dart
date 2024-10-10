import 'dart:io';

import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:super_player/super_player.dart';

enum ConfigType {
  saveMp4,
  normal,
}

class TencentVideoConfig extends FTXVodPlayConfig {
  int? fileId;
  String url; // 视频链接
  String? thumbnail; //缩略图（暂不用）
  String? thumbnailGausPath; //缩略图的高斯模糊
  bool hasTopSafeArea; // 有没有上方安全间距
  bool hasBottomSafeArea; // 有没有下方安全间距
  double? initialStartTimeInSeconds; //初始播放时间
  bool isLoop; //是否重复播放
  bool enableHardwareDecode; //硬件加载是否开启
  bool enableBitrateAutoAdjust; //自适应码流
  bool autoplay; //是否自动播放
  int width; // 视频长度
  int height; // 视频高度
  bool initialMute; // 初始化后是否静音
  bool isPip;
  ConfigType type;

  Function(TencentVideoStream stream)? onPIPMaximize;

  TencentVideoConfig({
    this.fileId,
    required this.url,
    required this.width,
    required this.height,
    this.thumbnail,
    this.thumbnailGausPath,
    this.hasTopSafeArea = true,
    this.hasBottomSafeArea = true,
    this.initialStartTimeInSeconds,
    this.isLoop = false,
    this.enableHardwareDecode = true,
    this.enableBitrateAutoAdjust = true,
    this.autoplay = true,
    this.initialMute = false,
    this.isPip = false,
    this.onPIPMaximize,
    this.type = ConfigType.normal,
  }) {
    if (url.contains("m3u8")) {
      smoothSwitchBitrate = true; //默认平滑切换码率
      mediaType = TXVodPlayEvent.MEDIA_TYPE_HLS_VOD; // //
    } else {
      mediaType = TXVodPlayEvent.MEDIA_TYPE_FILE_VOD; // 用于提升MP4启播速度
      if (Platform.isIOS && isPip) {
        playerType = PlayerType.AVPLAYER;
      }
    }

    maxPreloadSize = 3000; //默认1mb preload

    firstStartPlayBufferTime = 600000;
    nextStartPlayBufferTime = 600000;
    connectRetryInterval = 3;
    connectRetryCount = 20;
    preferredResolution = width * height;
    enableAccurateSeek = true; // 设置是否精确 seek，默认 true
    progressInterval = 17; // 设置进度回调间隔，单位毫秒
    maxBufferSize = 3000;
  }

  bool get shouldFollowAspectRatioOnExpand {
    if (width >= height) return true;

    double a = 9 / 16;
    double ar = width / height;

    if (ar >= a) return false; // 占满
    double difference = a - ar;
    if (difference < 0.02) {
      return false;
    } else {
      return true;
    }
  }
}
