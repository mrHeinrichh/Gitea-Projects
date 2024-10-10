part of '../upload_util.dart';

class VideoUploadRequest extends UploadChunk {
  // 目标hls地址
  VideoUploadResponse? targetHLSURLs;

  // m3u8是否需要拼本地路径
  final m3u8Local = Platform.isAndroid;

  void Function(double progress)? onCompressProgress;

  // 压缩完成以后的回调
  void Function(String path)? onCompressCallback;

  void Function(int status)? onStatusChange;

  // 视频实际宽度
  int accurateWidth;

  // 视频实际高度
  int accurateHeight;

  // 检查是否已经上传
  bool checkUploadPath(Map<String, dynamic> target_files) {
    targetHLSURLs = VideoUploadResponse.fromJson(target_files);
    if (targetHLSURLs?.uploadedPath != null) {
      return targetHLSURLs!.uploadedPath!.isNotEmpty;
    }

    return false;
  }

  VideoUploadRequest(
    super.sourceFilePath, {
    this.accurateWidth = 0,
    this.accurateHeight = 0,
    required super.cancelToken,
    super.onSendProgress,
    this.onCompressProgress,
    this.onCompressCallback,
    this.onStatusChange,
    super.fileType,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      "file_id": fileId,
      "file_typ": fileType?.value,
      "file_ext": fileExt,
      "total_block": totalBlock,
      "checksums": checksums,
      "is_kiwi_upload": true,
      "is_check_md5": true,
    };
  }
}

class VideoUploadResponse extends UploadResponse {
  String? _sourceFile;

  String? get sourceFile => _sourceFile;
  String? _thumbnail;

  String? get thumbnail => _thumbnail;
  String? _uploadedPath;

  String? get uploadedPath => _uploadedPath;
  List<HlsFormat>? _hls;

  List<HlsFormat>? get hls => _hls;

  VideoUploadResponse.fromJson(Map<String, dynamic> target_files) {
    if (!notBlank(target_files)) return;
    if (target_files.containsKey('hls')) {
      _hls = target_files['hls']
          .map<HlsFormat>((e) => HlsFormat.fromJson(e))
          .toList();
      if (_hls != null && notBlank(_hls)) {
        for (var element in _hls!) {
          // "is_exist": false, (判断m3u8 是否存在)
          // "is_end": false,（判断 m3u8 是否处理完）
          // if (element.isDefault! && element.isExist! && element.isEnd!) {
          if (element.isDefault!) {
            _uploadedPath = element.path!;
            continue;
          }
        }
      }
    }

    if (target_files.containsKey('thumbnail')) {
      _thumbnail = target_files['thumbnail'];
    }

    if (target_files.containsKey('source_file')) {
      _sourceFile = target_files['source_file'];
    }
  }

  bool get isExist =>
      notBlank(_hls) && _hls!.any((element) => element.isExist ?? false);
}

class HlsFormat {
  String? path;
  bool? isExist;
  bool? isEnd;
  bool? isDefault;

  // 视频分辨率
  int? resolution;

  // 视频编码格式
  String? vcodec;

  // 语音编码格式
  String? acodec;

  HlsFormat.fromJson(Map<String, dynamic> json) {
    path = json['path'];
    isExist = json['is_exist'];
    isEnd = json['is_end'];
    isDefault = json['is_default'];
    resolution = json['resolution'];
    vcodec = json['vcodec'];
    acodec = json['acodec'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['path'] = path;
    data['is_exist'] = isExist;
    data['is_end'] = isEnd;
    data['is_default'] = isDefault;
    data['resolution'] = resolution;
    data['vcodec'] = vcodec;
    data['acodec'] = acodec;
    return data;
  }
}

enum VideoResCategory {
  category144('144', '120K', 120),
  category240('240', '250K', 250),
  category360('360', '500K', 500),
  category480('480', '1000K', 1000),
  category720('720', '2000K', 2000),
  category1080('1080', '4000K', 4000);

  const VideoResCategory(this.resolution, this.bitRateRange, this.bitRateValue);

  final String resolution;
  final String bitRateRange;
  final int bitRateValue;
}

// 手机硬件加速选项
enum DeviceHAccels {
  h264_videotoolbox('h264_videotoolbox'),
  h265_videotoolbox('h265_videotoolbox'),
  hevc_videotoolbox('hevc_videotoolbox'),
  hevc_mediacodec('hevc_mediacodec'),
  h264_mediacodec('h264_mediacodec'),
  h265_mediacodec('h265_mediacodec');

  const DeviceHAccels(this.value);

  final String value;
}

// 视频压缩
class VideoCompressHandler
    extends RequestUploadCompressHandlerBase<VideoUploadRequest> {
  VideoCompressHandler(super.next);

  @override
  Future<HandleMsg> handle(VideoUploadRequest request) async {
    String logMsg = '';

    request.cancelToken.whenCancel.then(
      (_) => ImVideoCompressor().cancelCompress(),
    );

    request.onStatusChange?.call(1);
    String sourcePath = request.sourceFilePath;

    String targetCompressFilePath = await downloadMgr.getTmpCachePath(
      "${path.basenameWithoutExtension(sourcePath)}_${min(request.accurateWidth, request.accurateHeight)}${path.extension(sourcePath)}",
      sub: '/video/compress' /* + 这里缓存聊天室id */,
      create: false,
    );

    if (Platform.isMacOS) {
      final compressedFile = await getThumbVideo(
        File(request.sourceFilePath),
        onProgress: request.onCompressProgress,
      );

      // 判断压缩文件是否存在
      bool exist = await compressedFile?.exists() ?? false;
      if (exist == false) {
        return HandleMsg(
          false,
          message: "桌面端视频压缩文件不存在 log_msg:$logMsg request: ${request.toJson()}",
        );
      }

      // 如果压缩以后的文件大于原文件，删除压缩文件
      if (compressedFile!.lengthSync() >
          File(request.sourceFilePath).lengthSync()) {
        await compressedFile.delete();
      } else {
        await request.copyLocalFile(
          sourcePath: compressedFile.path,
          targetPath: targetCompressFilePath,
        );
        request.sourceFilePath = targetCompressFilePath;
        await compressedFile.delete();
      }

      return HandleMsg(
        true,
        message: "桌面端视频压缩完成 log_msg:$logMsg request: ${request.toJson()}",
      );
    }

    if (File(request.cacheFilePath).existsSync()) {
      request.sourceFilePath = request.cacheFilePath;
      return HandleMsg(
        true,
        message: "视频压缩有缓存不需要压  log_msg:$logMsg request: ${request.toJson()}",
      );
    }

    logMsg += '2、创建压缩文件路径 $targetCompressFilePath - ';

    // 查看压缩文件在不在
    bool targetCompressFileExist = await File(targetCompressFilePath).exists();

    logMsg += '3、判断压缩文件是否存在 $targetCompressFileExist - ';

    // 缓存没有，或者文件丢了
    if (!targetCompressFileExist) {
      logMsg += '4、获取文件格式信息 - ';
      // 获取文件格式信息
      MediaInformationSession infoSession =
          await FFprobeKit.getMediaInformation(sourcePath);
      MediaInformation? mediaInformation = infoSession.getMediaInformation();
      if (mediaInformation == null) {
        return HandleMsg(
          false,
          message: "压缩获取文件信息失败 log_msg:$logMsg request: ${request.toJson()}",
        );
      }
      logMsg += '5、获取文件流信息 - ';
      final List<StreamInformation> streams = mediaInformation.getStreams();

      if (streams == null || streams.isEmpty) {
        return HandleMsg(
          false,
          message: "压缩获取文件流信息失败 log_msg:$logMsg request: ${request.toJson()}",
        );
      }

      final videoStream =
          streams.firstWhere((stream) => stream.getType() == 'video');
      // final audioStream =
      //     streams.firstWhereOrNull((stream) => stream.getType() == 'audio');
      final audioStreamAPAC = streams.firstWhereOrNull((element) =>
          element.getAllProperties()!['codec_tag_string'] == "apac");

      logMsg += '6、获取视频尺寸 - ';
      // 视频宽高
      final int width = request.accurateWidth == 0
          ? videoStream.getAllProperties()!['width']
          : request.accurateWidth;
      final int height = request.accurateHeight == 0
          ? videoStream.getAllProperties()!['height']
          : request.accurateHeight;

      Size videoSize = getResolutionSize(
        videoStream.getAllProperties()!['width'],
        videoStream.getAllProperties()!['height'],
        min(width, height),
      );

      // 1. 检查视频是否是高清
      // 是否是高清视频
      // bool isHighRes = videoStream.getCodec() == 'hevc';
      // 是否是aac格式的音频
      // bool isAac = audioStream?.getCodec() == 'aac';

      // 2. 检查视频码率, 高度, 应该压缩到的码率
      // 视频码率
      int bitrate = int.parse(mediaInformation.getBitrate() ?? '0');

      if (bitrate == 0) {
        bitrate = videoStream.getRealFrameRate() != null
            ? int.parse(videoStream.getRealFrameRate()!.split('/')[0])
            : 0;
      }

      // 3. 检查视频应该压缩到哪一个分辨率
      // 视频与编码挂钩的尺寸
      final videoResHeight = min(width, height);

      VideoResCategory videoCategory = getNearestVideoCategory(videoResHeight);
      logMsg += '7、检查编码格式 - ';
      if (bitrate > videoCategory.bitRateValue) {
        // String? desireBitrate;
        // if (bitrate > videoCategory.bitRateValue) {
        //   desireBitrate = videoCategory.bitRateRange;
        // }

        int? rFrameRate;

        if (videoStream.getRealFrameRate() != null) {
          // 视频帧率
          List<String> fRList = (videoStream.getRealFrameRate())!.split('/');
          int tempRate = int.parse(fRList[0]) ~/ int.parse(fRList[1]);
          if (tempRate > 30) {
            rFrameRate = 30;
          }
        }

        // if (Platform.isIOS) {
        // 生成压缩临时文件
        final compressSavePath = await downloadMgr.getTmpCachePath(
          targetCompressFilePath,
          sub: 'temp',
          create: false,
        );

        await ImVideoCompressor().compressVideo(
          request.sourceFilePath,
          compressSavePath,
          videoConfig: {
            ImVideoCompressor.keyVideoBitrate:
                ((bitrate > videoCategory.bitRateValue
                            ? videoCategory.bitRateValue
                            : bitrate) *
                        1000)
                    .toInt(),
            ImVideoCompressor.keyFps: rFrameRate ?? 30.toInt(),
            ImVideoCompressor.keyWidth: videoSize.width.toInt(), // height
            ImVideoCompressor.keyHeight: videoSize.height.toInt(), // width
          },
        );

        final compressedFile = File(compressSavePath);
        // 判断压缩文件是否存在
        bool exist = await compressedFile.exists();
        if (exist == false) {
          return HandleMsg(
            false,
            message:
                "iOS视频压缩文件不存在 log_msg:$logMsg request: ${request.toJson()}",
          );
        }

        // 如果压缩以后的文件大于原文件，删除压缩文件
        if (compressedFile.lengthSync() >
            File(request.sourceFilePath).lengthSync()) {
          await compressedFile.delete();
        } else {
          await request.copyLocalFile(
            sourcePath: compressedFile.path,
            targetPath: targetCompressFilePath,
          );
          request.sourceFilePath = targetCompressFilePath;
          await compressedFile.delete();
          if (audioStreamAPAC != null) {
            request.onCompressCallback?.call(request.sourceFilePath);
          }
        }

        return HandleMsg(
          true,
          message: "iOS视频压缩完成 log_msg:$logMsg request: ${request.toJson()}",
        );
        // }

        /*    4. 检查设备支持的硬件加速
        检查可用编码格式
        final FFmpegSession codecSupport = await FFmpegKit.execute('-codecs');
        final allCodecList = await codecSupport.getAllLogsAsString() ?? '';

        bool supportH265 = allCodecList.contains('libx265');
        DeviceHAccels? supportHAccels;
        String? supportHAccelsType;
        if (allCodecList.contains(DeviceHAccels.h265_videotoolbox.value)) {
          supportHAccels = DeviceHAccels.h265_videotoolbox;
          supportHAccelsType = supportHAccels.value
              .substring(supportHAccels.value.indexOf('_') + 1);
        } else if (allCodecList.contains(DeviceHAccels.h265_mediacodec.value)) {
          supportHAccels = DeviceHAccels.h265_mediacodec;
          supportHAccelsType = supportHAccels.value
              .substring(supportHAccels.value.indexOf('_') + 1);
        } else if (allCodecList
            .contains(DeviceHAccels.hevc_videotoolbox.value)) {
          supportHAccels = DeviceHAccels.hevc_videotoolbox;
          supportHAccelsType = supportHAccels.value
              .substring(supportHAccels.value.indexOf('_') + 1);
        } else if (allCodecList.contains(DeviceHAccels.hevc_mediacodec.value)) {
          supportHAccels = DeviceHAccels.hevc_mediacodec;
          supportHAccelsType = supportHAccels.value
              .substring(supportHAccels.value.indexOf('_') + 1);
        } else if (allCodecList
            .contains(DeviceHAccels.h264_videotoolbox.value)) {
          supportHAccels = DeviceHAccels.h264_videotoolbox;
          supportHAccelsType = supportHAccels.value
              .substring(supportHAccels.value.indexOf('_') + 1);
        } else if (allCodecList.contains(DeviceHAccels.h264_mediacodec.value)) {
          supportHAccels = DeviceHAccels.h264_mediacodec;
          supportHAccelsType = supportHAccels.value
              .substring(supportHAccels.value.indexOf('_') + 1);
        }

        logMsg += '8、检查是否进行压缩 - ';
        // 高清视频但是不支持h265编码
        if (isHighRes && !supportH265) {
          // 直接进行上传,不需要做任何处理

          return HandleMsg(
            true,
            message: "视频不需要压缩 log_msg:$logMsg request: ${request.toJson()}",
          );
        }

        logMsg += '9、拼接压缩参数 - ';
        // 5. 压缩
        String videoCompressCommand =
            '-map 0 -c:v ${supportHAccels != null ? supportHAccels.value : isHighRes ? 'libx265' : 'libx264'}';
        String videoBitrateCommand =
            desireBitrate != null ? '-b:v $desireBitrate' : '';
        String audioCommand = '-c:a ${isAac ? "copy" : "aac"}';
        String scaleCommand = '';

        if (width > height) {
          int scaleWidth = width;
          if (scaleWidth % 2 != 0.0) {
            scaleWidth += 1;
          }

          scaleCommand = 'scale=trunc($scaleWidth):$height';
        } else {
          int scaleHeight = height;
          if (scaleHeight % 2 != 0.0) {
            scaleHeight += 1;
          }

          scaleCommand = 'scale=$width:trunc($scaleHeight)';
        }

        String videoFrameCommand =
            '-vf $scaleCommand${rFrameRate != null ? ",fps=$rFrameRate" : ''}';

        final Completer<HandleMsg> completer = Completer<HandleMsg>();
        request.cancelToken.whenCancel.then((e) {
          if (!completer.isCompleted) {
            completer.completeError(
              HandleMsg(
                false,
                message: "视频压缩被中断 log_msg:$logMsg request: ${request.toJson()}",
              ),
            );
          }
        });
        logMsg += '10、开始进行压缩 - ';
        // 生成压缩临时文件
        final compressSavePath = await downloadMgr
            .getTmpCachePath(targetCompressFilePath, sub: 'temp');

        await DYio.mkDir(path.dirname(compressSavePath));

        Future<HandleMsg> onCompressComplete({
          required String compressSavePath,
          required String targetCompressFilePath,
          required VideoUploadRequest request,
        }) async {
          final compressedFile = File(compressSavePath);
          // 判断压缩文件是否存在
          bool exist = await compressedFile.exists();
          if (exist == false) {
            return HandleMsg(
              false,
              message: "视频压缩文件不存在 log_msg:$logMsg request: ${request.toJson()}",
            );
          }

          // 如果压缩以后的文件大于原文件，删除压缩文件
          if (compressedFile.lengthSync() >
              File(request.sourceFilePath).lengthSync()) {
            await compressedFile.delete();
          } else {
            await request.copyLocalFile(
              sourcePath: compressedFile.path,
              targetPath: targetCompressFilePath,
            );
            request.sourceFilePath = targetCompressFilePath;
            await compressedFile.delete();
          }

          return HandleMsg(
            true,
            message: "视频压缩完成 log_msg:$logMsg request: ${request.toJson()}",
          );
        }

        await FFmpegKit.executeAsync(
          '-y ${supportHAccels != null ? "-hwaccel $supportHAccelsType -hwaccel_output_format $supportHAccelsType" : ''} -i "$sourcePath" $videoCompressCommand $videoBitrateCommand $audioCommand $videoFrameCommand "$compressSavePath"',
          (completeCallback) async {
            ReturnCode? returnCode = await completeCallback.getReturnCode();
            if (!(returnCode?.isValueCancel() ?? true)) {
              if (!completer.isCompleted) {
                completer.complete(
                  onCompressComplete(
                    request: request,
                    targetCompressFilePath: targetCompressFilePath,
                    compressSavePath: compressSavePath,
                  ),
                );
              }
              logMsg += '11、压缩完成 - ';
              return;
            }

            logMsg += '11、压缩中断 - ';

            if (!completer.isCompleted) {
              completer.completeError(
                HandleMsg(
                  false,
                  message:
                      "视频压缩被中断 log_msg:$logMsg request: ${request.toJson()}",
                ),
              );
            }
          },
          (_) {},
          (Statistics statistics) async {
            if ((request.cancelToken.isCancelled)) {
              FFmpegKit.cancel();
              bool exist = await File(compressSavePath).exists();
              if (exist) {
                await File(compressSavePath).delete();
              }
              logMsg += '11、压缩被取消 - ';
              if (!completer.isCompleted) {
                completer.completeError(
                  HandleMsg(
                    false,
                    message:
                        "视频压缩主动取消 log_msg:$logMsg request: ${request.toJson()}",
                  ),
                );
              }
              return;
            }

            request.onCompressProgress?.call(
              (statistics.getTime() * 100) /
                  (double.parse(mediaInformation.getDuration()!) * 1000),
            );
          },
        );
        return completer.future;*/
      } else {
        logMsg += '8、不需要压缩，直接生成文件 - ';
        // 填充压缩文件
        await request.copyLocalFile(
          sourcePath: sourcePath,
          targetPath: targetCompressFilePath,
        );
        request.sourceFilePath = targetCompressFilePath;
      }
    } else {
      logMsg += '3、已经有压缩缓存了，直接生成文件 - ';
      // 已经压过 指针
      request.sourceFilePath = targetCompressFilePath;
    }

    request.onCompressProgress?.call(100);

    return HandleMsg(
      true,
      message: "视频压缩完成  log_msg:$logMsg request: ${request.toJson()}",
    );
  }

  /// ========================== 工具类函数 ==========================

  VideoResCategory getNearestVideoCategory(int height) {
    if (height >= 720) {
      return VideoResCategory.category720;
    } else if (height >= 480) {
      return VideoResCategory.category480;
    } else if (height >= 360) {
      return VideoResCategory.category360;
    } else if (height >= 240) {
      return VideoResCategory.category240;
    } else {
      return VideoResCategory.category144;
    }
  }
}

// 请求上传地址处理器
class VideoRequestUploadUrlHandler
    extends RequestUploadUrlHandlerBase<VideoUploadRequest> {
  VideoRequestUploadUrlHandler(super.next);

  @override
  Future<HandleMsg> handle(VideoUploadRequest request) async {
    request.uploadResponseData = await uploadPost(
      '/app/api/file/upload_part_presign',
      data: request.toJson(),
      cancelToken: request.cancelToken,
    );

    if (!request.uploadResponseData!.success) {
      return HandleMsg(
        false,
        message:
            "请求s3地址失败 response:${request.uploadResponseData!.toJson()} request: ${request.toJson()}",
        isClearAll: true,
      );
    }

    if (request.checkUploadPath(request.uploadResponseData!.target_files)) {
      request.completed = true;
      HandleMsg handleMsg = HandleMsg(
        true,
        message:
            "通知合成成功并返回目标地址 response:${request.uploadResponseData!.toJson()} request: ${request.toJson()}",
      );

      return handleMsg;
    }

    return HandleMsg(
      true,
      message:
          "请求s3地址成功 response:${request.uploadResponseData!.toJson()} request: ${request.toJson()}",
    );
  }
}

class VideoUploadPartHandler extends UploadPartHandler<VideoUploadRequest> {
  VideoUploadPartHandler(super.next);

  @override
  Future<HandleMsg> handle(VideoUploadRequest request) async {
    if (request.uploadResponseData!.uploadURLs.isEmpty &&
        request.targetHLSURLs?.sourceFile != null) {
      return HandleMsg(
        true,
        message:
            '直接通知合成 response:${request.toJson()}  request:${request.toJson()}',
      );
    }

    return super.handle(request);
  }
}

// 请求合成处理器
class VideoRequestCompositionHandler
    extends RequestCompositionHandlerBase<VideoUploadRequest> {
  VideoRequestCompositionHandler(super.next);

  @override
  Future<HandleMsg> handle(VideoUploadRequest request) async {
    request.uploadResponseData = await uploadPost(
      '/app/api/file/upload_part_finish',
      data: request.toJson(),
      cancelToken: request.cancelToken,
    );
    if (!request.uploadResponseData!.success) {
      return HandleMsg(
        false,
        message:
            "通知合成失败 response:${request.uploadResponseData!.toJson()} request: ${request.toJson()}",
        isClearAll: true,
      );
    }

    if (request.checkUploadPath(request.uploadResponseData!.target_files)) {
      request.completed = true;
      HandleMsg handleMsg = HandleMsg(
        true,
        message:
            "通知合成成功并返回目标地址 response:${request.uploadResponseData!.toJson()} request: ${request.toJson()}",
      );

      return handleMsg;
    }

    return HandleMsg(
      false,
      message:
          "通知合成成功 response:${request.uploadResponseData!.toJson()} request: ${request.toJson()}",
    );
  }
}
