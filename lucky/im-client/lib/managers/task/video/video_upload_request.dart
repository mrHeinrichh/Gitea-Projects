import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/stream_information.dart';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/log/log_mgr.dart';
import 'package:jxim_client/managers/task/base/handle_base.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/io.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/aws_s3/file_upload_info.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:path/path.dart' as path;
import 'package:video_compress/video_compress.dart';

class VideoUploadRequest extends UploadChunk {
  // 目标hls地址
  VideoUploadResponse? targetHLSURLs;

  // m3u8是否需要拼本地路径
  final m3u8_local = Platform.isAndroid;

  void Function(double progress)? onCompressProgress;

  // 传输进度
  ProgressCallback? onSendProgress;

  // 视频压缩分辨率选项
  VideoQuality videoQuality;

  // 压缩完成以后的回调
  void Function(String path)? onCompressCallback;

  void Function(int status)? onStatusChange;

  // 视频实际宽度
  int accurateWidth;

  // 视频实际高度
  int accurateHeight;

  // 检查是否已经上传
  bool checkUploadPath(data, {bool test = false}) {
    if (data != null && notBlank(data)) {
      uploadURLs = data['presign_urls'];
      final target_files = data['target_files'];
      if (notBlank(target_files)) {
        targetHLSURLs = VideoUploadResponse.fromJson(target_files);
      }
    }
    if (targetHLSURLs != null && targetHLSURLs!.uploadedPath != null) {
      return targetHLSURLs!.uploadedPath!.isNotEmpty;
    }

    return false;
  }

  @override
  Future<bool> initAsync() async {
    sourceFilePath = targetFilePath!;
    return await super.initAsync();
  }

  VideoUploadRequest(super.sourceFilePath,
      {this.accurateWidth = 0,
      this.accurateHeight = 0,
      required super.cancelToken,
      this.onSendProgress,
      this.videoQuality = VideoQuality.DefaultQuality,
      this.onCompressProgress,
      this.onCompressCallback,
      this.onStatusChange,
      super.showOriginal}) {
    file_typ = UploadExt.video;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "file_id": file_id,
      "file_typ": file_typ?.value,
      "file_ext": file_ext,
      "total_block": total_block,
      "checksums": checksums,
      "is_kiwi_upload": true,
      "is_check_md5": true,
      "is_encrypt": is_encrypt,
      "is_original": showOriginal,
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

  VideoUploadResponse.fromJson(Map<String, dynamic> json) {
    if (!notBlank(json)) return;
    if (json.containsKey('hls')) {
      _hls = json['hls'].map<HlsFormat>((e) => HlsFormat.fromJson(e)).toList();
      if (_hls != null && notBlank(_hls)) {
        _hls!.forEach((element) {
          // "is_exist": false, (判断m3u8 是否存在)
          // "is_end": false,（判断 m3u8 是否处理完）
          if (element.isDefault! && element.isExist! && element.isEnd!) {
            _uploadedPath = element.path!;
            return;
          }
        });
      }
    }

    if (json.containsKey('thumbnail')) {
      _thumbnail = json['thumbnail'];
    }

    if (json.containsKey('source_file')) {
      _sourceFile = json['source_file'];
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
  Future<HandleMsg> handleRequest(VideoUploadRequest request) async {
    request.onStatusChange?.call(1);
    // 1、计算md5
    String sourcePath = request.sourceFilePath;
    request.sourceMd5 =
        await compute<String, String?>(calculateMD5FromPath, sourcePath) ?? '';

    if (request.sourceMd5.isEmpty) {
      return HandleMsg(
        false,
        message: '视频压缩-计算md5错误 request: ${request.toJson()}',
      );
    }

    // 2、复制文件 目标文件绝对路径
    request.targetFilePath = await downloadMgr.getTmpCachePath(
      "${request.sourceMd5}${path.extension(sourcePath)}",
      sub: '/video' /* 这里缓存聊天室id*/ + (request.showOriginal ? '/origin' : ''),
      create: false,
    );
    // 3、压缩的目标文件
    String targetCompressFilePath = await downloadMgr.getTmpCachePath(
      "${request.sourceMd5}${path.extension(sourcePath)}",
      sub: '/video/compress' /* + 这里缓存聊天室id */ +
          (request.showOriginal ? '/origin' : ''),
      create: false,
    );

    // 非源文件
    if (!request.showOriginal) {
      // 查看压缩文件在不在
      bool targetCompressFileExist =
          await File(targetCompressFilePath).exists();
      // 缓存没有，或者文件丢了
      if (!targetCompressFileExist) {
        logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
          msg: 'VideoCompressHandler 判断文件是否符合压缩条件',
        ));

        // 获取文件格式信息
        MediaInformationSession infoSession =
            await FFprobeKit.getMediaInformation(sourcePath);
        MediaInformation? mediaInformation = infoSession.getMediaInformation();
        if (mediaInformation == null) {
          return HandleMsg(false,
              message: "压缩获取文件信息失败 request: ${request.toJson()}");
        }

        final List<StreamInformation>? streams = mediaInformation.getStreams();

        if (streams == null || streams.isEmpty) {
          return HandleMsg(false,
              message: "压缩获取文件流信息失败 request: ${request.toJson()}");
        }

        final videoStream =
            streams.firstWhere((stream) => stream.getType() == 'video');
        final audioStream =
            streams.firstWhereOrNull((stream) => stream.getType() == 'audio');

        // 视频宽高
        final int width = request.accurateWidth == 0
            ? videoStream.getAllProperties()!['width']
            : request.accurateWidth;
        final int height = request.accurateHeight == 0
            ? videoStream.getAllProperties()!['height']
            : request.accurateHeight;

        final double ratio = width / height;

        // 是否超过720p
        bool isMore480p = false;
        // 横屏
        if (width > height) {
          isMore480p = width > 854 || height > 480;
        } else {
          isMore480p = height > 480 || width > 854;
        }
        logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
          msg: '判断文件是否符合压缩条件 isMore480p:${isMore480p}',
        ));

        if (isMore480p) {
          final double ratio = width / height;

          // 1. 检查视频是否是高清
          // 是否是高清视频
          bool isHighRes = videoStream.getCodec() == 'hevc';
          // 是否是aac格式的音频
          bool isAac = audioStream?.getCodec() == 'aac';

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
          final videoResHeight = max(width, height);

          VideoResCategory videoCategory =
              getNearestVideoCategory(videoResHeight);

          String? desireBitrate;
          if (bitrate > videoCategory.bitRateValue) {
            desireBitrate = videoCategory.bitRateRange;
          }

          // int? rFrameRate;
          //
          // if (videoStream.getRealFrameRate() != null) {
          //   // 视频帧率
          //   List<String> fRList = (videoStream.getRealFrameRate())!.split('/');
          //   int tempRate = int.parse(fRList[0]) ~/ int.parse(fRList[1]);
          //   if (tempRate > 30) {
          //     rFrameRate = 30;
          //   }
          // }

          // 4. 检查设备支持的硬件加速
          // 检查可用编码格式
          final FFmpegSession codecSupport = await FFmpegKit.execute('-codecs');
          final allCodecList = await codecSupport.getAllLogsAsString() ?? '';

          bool supportH265 = allCodecList.contains('libx265');
          DeviceHAccels? supportHAccels;
          String? supportHAccelsType;
          if (allCodecList.contains(DeviceHAccels.h265_videotoolbox.value)) {
            supportHAccels = DeviceHAccels.h265_videotoolbox;
            supportHAccelsType = supportHAccels.value
                .substring(supportHAccels.value.indexOf('_') + 1);
          } else if (allCodecList
              .contains(DeviceHAccels.h265_mediacodec.value)) {
            supportHAccels = DeviceHAccels.h265_mediacodec;
            supportHAccelsType = supportHAccels.value
                .substring(supportHAccels.value.indexOf('_') + 1);
          } else if (allCodecList
              .contains(DeviceHAccels.hevc_videotoolbox.value)) {
            supportHAccels = DeviceHAccels.hevc_videotoolbox;
            supportHAccelsType = supportHAccels.value
                .substring(supportHAccels.value.indexOf('_') + 1);
          } else if (allCodecList
              .contains(DeviceHAccels.h264_videotoolbox.value)) {
            supportHAccels = DeviceHAccels.h264_videotoolbox;
            supportHAccelsType = supportHAccels.value
                .substring(supportHAccels.value.indexOf('_') + 1);
          } else if (allCodecList
              .contains(DeviceHAccels.h264_mediacodec.value)) {
            supportHAccels = DeviceHAccels.h264_mediacodec;
            supportHAccelsType = supportHAccels.value
                .substring(supportHAccels.value.indexOf('_') + 1);
          }

          // 高清视频但是不支持h265编码
          if (isHighRes && !supportH265) {
            // 直接进行上传,不需要做任何处理
            if (next != null) return await next!.handleRequest(request);
            return HandleMsg(true,
                message: "视频上传压缩直接完成 request: ${request.toJson()}");
          }

          // 5. 压缩
          String videoCompressCommand =
              '-c:v ${supportHAccels != null ? supportHAccels.value : isHighRes ? 'libx265' : 'libx264'}';
          String videoBitrateCommand =
              desireBitrate != null ? '-b:v $desireBitrate' : '';
          String audioCommand = '-c:a ${isAac ? "copy" : "aac"}';
          String scaleCommand = '';

          if (width > height) {
            int scaleWidth =
                (int.parse(videoCategory.resolution) * ratio).toInt();
            if (scaleWidth % 2 != 0.0) {
              scaleWidth += 1;
            }

            scaleCommand =
                'scale=trunc($scaleWidth):${videoCategory.resolution}';
          } else {
            int scaleHeight = int.parse(videoCategory.resolution) ~/ ratio;
            if (scaleHeight % 2 != 0.0) {
              scaleHeight += 1;
            }

            scaleCommand =
                'scale=${videoCategory.resolution}:trunc($scaleHeight)';
          }

          // ${rFrameRate != null ? ",fps=$rFrameRate" : ''}
          String videoFrameCommand = '-vf $scaleCommand';

          final Completer<HandleMsg> completer = Completer<HandleMsg>();

          final compressSavePath =
              targetCompressFilePath.replaceAll('/compress', '/compress/temp');

          await DYio.mkDir(path.dirname(compressSavePath));

          logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
            msg:
                'VideoCompressHandler 开始压缩参数: ${'-y ${supportHAccels != null ? "-hwaccel $supportHAccelsType -hwaccel_output_format $supportHAccelsType" : ''} -i "${sourcePath}" $videoCompressCommand $videoBitrateCommand $audioCommand $videoFrameCommand "$compressSavePath"'}',
          ));

          await FFmpegKit.executeAsync(
            '-y ${supportHAccels != null ? "-hwaccel $supportHAccelsType -hwaccel_output_format $supportHAccelsType" : ''} -i "${sourcePath}" $videoCompressCommand $videoBitrateCommand $audioCommand $videoFrameCommand "$compressSavePath"',
            (completeCallback) async {
              ReturnCode? returnCode = await completeCallback.getReturnCode();
              if (!(returnCode?.isValueCancel() ?? true)) {
                completer.complete(onCompressComplete(
                  request: request,
                  targetCompressFilePath: targetCompressFilePath,
                  compressSavePath: compressSavePath,
                ));
                return;
              }

              completer.completeError(HandleMsg(false,
                  message: "视频压缩被中断 request: ${request.toJson()}"));
            },
            (_) {},
            (Statistics statistics) async {
              if ((request.cancelToken.isCancelled)) {
                FFmpegKit.cancel();
                bool exist = await File(compressSavePath).exists();
                if (exist) {
                  await File(compressSavePath).delete();
                }

                completer.completeError(HandleMsg(false,
                    message: "视频压缩主动取消 request: ${request.toJson()}"));
                return;
              }

              request.onCompressProgress?.call(
                (statistics.getTime() * 100) /
                    (double.parse(mediaInformation.getDuration()!) * 1000),
              );
            },
          );
          return completer.future;
        } else {
          // < 720p 填充压缩文件
          await request.copyLocalFile(
            sourcePath: sourcePath,
            targetPath: targetCompressFilePath,
          );
          request.targetFilePath = targetCompressFilePath;
        }
      } else {
        // 已经压过 指针
        request.targetFilePath = targetCompressFilePath;
      }
    }

    bool exist = await File(request.targetFilePath!).exists();
    if (!exist) {
      // 目标文件进缓存目录
      await request.copyLocalFile(
        sourcePath: sourcePath,
        targetPath: request.targetFilePath,
      );
    }

    request.onCompressProgress?.call(100);

    if (!await request.initAsync()) {
      return HandleMsg(false, message: "构造请求参数失败 request: ${request.toJson()}");
    }

    if (next != null) return await next!.handleRequest(request);

    return HandleMsg(true, message: "视频上传压缩直接完成 request: ${request.toJson()}");
  }

  Future<HandleMsg> onCompressComplete({
    required String compressSavePath,
    required String targetCompressFilePath,
    required VideoUploadRequest request,
  }) async {
    final compressedFile = File(compressSavePath);
    // 判断压缩文件是否存在
    bool exist = await compressedFile.exists();
    if (exist == false) {
      return HandleMsg(false,
          message: "视频压缩文件不存在 request: ${request.toJson()}");
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
      request.targetFilePath = targetCompressFilePath;
      await compressedFile.delete();
    }

    bool exist2 = await File(request.targetFilePath!).exists();
    if (!exist2) {
      // 目标文件进缓存目录
      await request.copyLocalFile(
        sourcePath: request.sourceFilePath,
        targetPath: request.targetFilePath,
      );
    }

    if (!await request.initAsync()) {
      return HandleMsg(false, message: "构造请求参数失败 request: ${request.toJson()}");
    }

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(true, message: "视频上传压缩直接完成 request: ${request.toJson()}");
  }

  /// ========================== 工具类函数 ==========================

  VideoResCategory getNearestVideoCategory(int height) {
    // if (height > 720) {
    //   return VideoResCategory.category720;
    // } else
    if (height > 480) {
      return VideoResCategory.category480;
    } else if (height > 360) {
      return VideoResCategory.category360;
    } else if (height > 240) {
      return VideoResCategory.category240;
    } else {
      return VideoResCategory.category144;
    }
  }
}

// 计算md5
class VideoCalculateMD5Handler
    extends RequestUploadCompressHandlerBase<VideoUploadRequest> {
  VideoCalculateMD5Handler(super.next);

  @override
  Future<HandleMsg> handleRequest(VideoUploadRequest request) async {
    logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
      msg: 'VideoCalculateMD5Handler start',
    ));
    // 每个分片md5的存储变量
    List<Uint8List> md5List = [];

    request.md5CacheKey = request.showOriginal
        ? '/sourceMd5 ${request.sourceMd5}_original'
        : '/sourceMd5 ${request.sourceMd5}_${request.videoQuality.index}';
    logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
      msg: 'VideoCalculateMD5Handler 尝试获取缓存 key: ${request.md5CacheKey}',
    ));
    Map<String, dynamic>? map;
    try {
      map = objectMgr.localStorageMgr
          .read<Map<String, dynamic>>(request.md5CacheKey);
    } catch (e) {
      objectMgr.localStorageMgr.remove(request.md5CacheKey);
    }

    if (map == null ||
        map.isEmpty ||
        !notBlank(map['checksums']) ||
        map['file_id'] == null) {
      final file = File(request.targetFilePath!);
      final openedFile = await file.open();
      const chunkSize = 5 * 1024 * 1024; // 5MB
      int totalSize = file.lengthSync();

      logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
        msg: 'VideoCalculateMD5Handler 开始计算分片md5',
      ));
      // for 循环文件分片
      for (int index = 0; index < request.total_block!; index++) {
        final start = index * chunkSize;

        final byte = await (await openedFile.setPosition(start))
            .readSync(min(totalSize - start, chunkSize));

        // 计算每个分片的md5
        md5List.add(await compute(calculateMD5Bytes, byte));
      }

      if (request.sourceMd5.isNotEmpty && request.showOriginal) {
        request.file_id = request.sourceMd5;
      } else {
        request.file_id =
            await compute<String, String?>(calculateMD5FromPath, file.path) ??
                '';
      }

      // 赋值给 request.file_id
      request.checksums = md5List.map((e) => convert.base64Encode(e)).toList();
      await objectMgr.localStorageMgr.write<Map<String, dynamic>>(
          request.md5CacheKey,
          {'checksums': request.checksums, 'file_id': request.file_id});
    } else {
      request.file_id = map['file_id']!;
      request.checksums = [...map['checksums']];
    }

    request.finishFileKey = 'finish_${request.file_id}';
    request.onCompressCallback?.call(request.targetFilePath!);

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(true, message: "计算md5直接完成 request: ${request.toJson()}");
  }
}

// 请求上传地址处理器
class VideoRequestUploadUrlHandler
    extends RequestUploadUrlHandlerBase<VideoUploadRequest> {
  VideoRequestUploadUrlHandler(super.next);

  @override
  Future<HandleMsg> handleRequest(VideoUploadRequest request) async {
    ResponseData response = await uploadPost(
        '/app/api/file/upload_part_presign',
        data: request.toJson(),
        cancelToken: request.cancelToken);
    logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
      msg: 'upload_part_presign 返回结果 response:${response.toJson()}',
    ));
    if (!response.success) {
      if (response.err is CodeException) {
        await objectMgr.localStorageMgr.remove(request.md5CacheKey);
        await File(request.targetFilePath!).delete();
        CodeException codeException = response.err as CodeException;
        return HandleMsg(false,
            message:
                "upload_part_presign 地址请求失败 message: ${codeException.getMessage()} request: ${request.toJson()}");
      } else {
        return HandleMsg(false,
            message: "upload_part_presign 地址请求失败 request: ${request.toJson()}");
      }
    }

    if (request.checkUploadPath(response.data)) {
      HandleMsg handleMsg = HandleMsg(
        true,
        message:
            "upload_part_presign 文件已经存在不需要进行上传 request: ${request.toJson()}",
      );
      await objectMgr.localStorageMgr
          .write(request.finishFileKey, request.file_id);

      return handleMsg;
    }

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(true,
        message: "求upload_part_presign直接完成 request: ${request.toJson()}");
  }
}

// 上传分片处理器
class VideoUploadPartHandler extends UploadPartHandlerBase<VideoUploadRequest> {
  VideoUploadPartHandler(super.next);

  // 所有分片总大小
  int totalSize = 0;

  // 已上传大小
  int uploadedSize = 0;

  @override
  Future<HandleMsg> handleRequest(VideoUploadRequest request) async {
    final file = File(request.targetFilePath!);
    final openedFile = await file.open();
    const chunkSize = 5 * 1024 * 1024; // 5MB
    totalSize = await file.length();

    if (request.uploadURLs!.isNotEmpty) {
      List<Future<bool>> futures = [];
      for (int index = 0; index < request.total_block!; index++) {
        String url = request.uploadURLs!["${index + 1}"] ?? '';
        if (url.isEmpty) {
          uploadedSize += chunkSize;
          continue;
        }

        if (request.cancelToken.isCancelled) {
          return HandleMsg(false,
              message: "上传文件主动取消 request: ${request.toJson()}");
        }

        final start = index * chunkSize;
        final end = min(start + chunkSize, totalSize);

        final byte =
            await (await openedFile.setPosition(start)).readSync(end - start);

        futures.add(request.uploadQueue
            .uploadQueue(byte, url, request.file_ext ?? '.mp4',
                headers: {
                  'Content-MD5': request.checksums[index],
                },
                cancelToken: request.cancelToken,
                onSendProgress: (int bytes, int total) {
          uploadedSize += bytes;
          request.onSendProgress?.call(uploadedSize, totalSize);
        }));
      }

      List<bool> allResults = await Future.wait(futures);

      bool anyFail = allResults.any((element) => element == false);
      openedFile.close();

      if (anyFail) {
        return HandleMsg(false, message: "上传失败 request: ${request.toJson()}");
      }
    }
    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(true, message: "上传s3直接成功 request: ${request.toJson()}");
  }
}

// 请求合成处理器
class VideoRequestCompositionHandler
    extends RequestCompositionHandlerBase<VideoUploadRequest> {
  VideoRequestCompositionHandler(super.next);

  @override
  Future<HandleMsg> handleRequest(VideoUploadRequest request) async {
    request.onStatusChange?.call(4);
    ResponseData response = await uploadPost('/app/api/file/upload_part_finish',
        data: request.toJson(), cancelToken: request.cancelToken);
    logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
      msg: 'upload_part_finish 返回结果 response:${response.toJson()}',
    ));
    if (!response.success) {
      if (response.err is CodeException) {
        await objectMgr.localStorageMgr.remove(request.md5CacheKey);
        await File(request.targetFilePath!).delete();
        CodeException codeException = response.err as CodeException;
        return HandleMsg(false,
            message:
                "pload_part_finish 地址请求失败 message: ${codeException.getMessage()} request: ${request.toJson()}");
      } else {
        return HandleMsg(false,
            message: "upload_part_finish 地址请求失败} request: ${request.toJson()}");
      }
    }

    if (request.checkUploadPath(response.data)) {
      // 如果已经合成了直接返回，否则进入轮询等待
      HandleMsg handleMsg = HandleMsg(
        true,
        message:
            "upload_part_finish 文件已经存在不需要进行上传 request: ${request.toJson()}",
      );
      await objectMgr.localStorageMgr
          .write(request.finishFileKey, request.file_id);

      return handleMsg;
    }

    if (next != null) return await next!.handleRequest(request);
    return HandleMsg(
      false,
      message: "upload_part_finish 直接完成 request: ${request.toJson()}",
    );
  }
}

// 轮询合成状态处理器
class VideoPollingCompositionHandler
    extends PollingCompositionHandlerBase<VideoUploadRequest> {
  VideoPollingCompositionHandler(super.next);

  @override
  Future<HandleMsg> handleRequest(VideoUploadRequest request) async {
    DateTime startTime = DateTime.now();
    int doCount = 1;
    while (true) {
      request.onStatusChange?.call(4);

      if (request.cancelToken.isCancelled) {
        return HandleMsg(
          false,
          message: "check_file 被主动取消 request: ${request.toJson()}",
        );
      }
      ResponseData response = await uploadPost('/app/api/file/check_file',
          data: request.toJson(), cancelToken: request.cancelToken);
      logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
        msg: 'check_file 返回结果 response:${response.toJson()}',
      ));
      try {
        if (!response.success) {
          if (response.err is CodeException) {
            await objectMgr.localStorageMgr.remove(request.md5CacheKey);
            await File(request.targetFilePath!).delete();
            CodeException codeException = response.err as CodeException;
            return HandleMsg(
              false,
              message:
                  "check_file 地址请求失败 message: ${codeException.getMessage()} request: ${request.toJson()}",
            );
          } else {
            return HandleMsg(
              false,
              message: "check_file 地址请求失败 request: ${request.toJson()}",
            );
          }
        } else {
          if (request.checkUploadPath(response.data)) {
            request.onStatusChange?.call(5);
            HandleMsg handleMsg = HandleMsg(
              true,
              message: "check_file 文件已经存在不需要进行上传 request: ${request.toJson()}",
            );
            await objectMgr.localStorageMgr
                .write(request.finishFileKey, request.file_id);
            return handleMsg;
          }
        }
      } catch (e) {
        logMgr.logUploadVideoMgr.addMetrics(LogUploadVideoMsg(
          msg: 'check_file 解析错误 response:${response.toJson()}',
        ));
      }

      await Future.delayed(Duration(milliseconds: ++doCount * 100));
      if (doCount > 10) {
        doCount--;
      }

      // Check if timeout exceeded
      if (DateTime.now().difference(startTime) > const Duration(minutes: 10)) {
        return HandleMsg(
          false,
          message: "check_file 轮询合成等待超时 request: ${request.toJson()}",
        );
      }
    }
  }
}

// 下载文件处理器
class VideoDownloadFileHandler
    extends DownloadFileHandlerBase<VideoUploadRequest> {
  VideoDownloadFileHandler(Handler? next) : super(next);

  @override
  Future<HandleMsg> handleRequest(VideoUploadRequest request) async {
    throw ();
    // VideoUploadResponse? targetHLSURLs = request.targetHLSURLs;
    // String m3u8LocalPath = '';
    // if (targetHLSURLs != null && targetHLSURLs.isExist) {
    //   // 下载m3u8
    //   ConcurrencyLoader concurrencyFileloader =
    //       ConcurrencyLoader(maxConcurrency: 10);
    //   // todo: 下载流程调整
    //   for (var entry in targetHLSURLs.hls!) {
    //     concurrencyFileloader.addTask(
    //       entry.path!,
    //       () => concurrencyFileloader.concurrencyDownloadFile(entry.path!),
    //     );
    //   }

    //   List<TaskResult> allResults = await concurrencyFileloader.waitForAll();
    //   concurrencyFileloader.dispose();
    //   for (TaskResult result in allResults) {
    //     if (result.result == null) {
    //       pdebug("Downloading m3u8 failed for ${result.parameter}");
    //       return HandleMsg(false, "Downloading m3u8 failed...");
    //     }
    //     m3u8LocalPath = result.result!;
    //     // 异步读取并处理 m3u8 文件
    //     File m3u8File = File(result.result);
    //     await processM3U8Content(m3u8File, request.m3u8_local, targetHLSURLs);
    //   }

    //   request.targetHLSURLs = targetHLSURLs;
    // }

    // if (next != null) return await next!.handleRequest(request);
    // // 返回 m3u8本地地址
    // return HandleMsg(true, m3u8LocalPath);
  }

  Future<void> processM3U8Content(
      File m3u8File, bool m3u8Local, VideoUploadResponse targetHLSURLs) async {
    // String m3u8Content = await m3u8File.readAsString();
    // String localDirUrl = m3u8File.parent.path;
    // String replacedContent =
    //     m3u8Content.replaceAllMapped(RegExp(r'(.*)\.ts'), (match) {
    //   String tsFileName = match.group(1)! + ".ts";
    //   if (m3u8Local) {
    //     // 更新路径为本地完整路径
    //     return path.join(localDirUrl, tsFileName);
    //   }
    //   return tsFileName; // 返回仅文件名，假设客户端可以从同一目录解析
    // });

    // // 写入更新后的内容到文件
    // await m3u8File.writeAsString(replacedContent);

    // // 更新 targetHLSURLs 来包括 ts 文件路径
    // List<String> tsFiles = RegExp(r'(.*)\.ts')
    //     .allMatches(replacedContent)
    //     .map((m) => m.group(0)!)
    //     .toList();
    // for (var tsFile in tsFiles) {
    //   if (!targetHLSURLs.tsFiles.containsKey(tsFile)) {
    //     targetHLSURLs.tsFiles[path.basename(tsFile)] =
    //         path.join(localDirUrl, tsFile); // 添加新的 .ts 文件路径
    //   }
    // }
  }
}

// 下载文件处理器 暂时无用
class VideoDownloadTsFileHandler extends Handler<VideoUploadRequest> {
  VideoDownloadTsFileHandler(Handler? next) : super(next);

  @override
  Future<HandleMsg> handleRequest(VideoUploadRequest request) async {
    throw ();
    // assert(false, "Downloading Flow not ready yet...");
    // VideoUploadResponse targetHLSURLs = request.targetHLSURLs!;
    // if (targetHLSURLs.tsFiles.isNotEmpty) {
    //   ConcurrencyLoader concurrencyFileloader =
    //       ConcurrencyLoader(maxConcurrency: 10);
    //   for (var entry in targetHLSURLs.tsFiles.entries) {
    //     // 下载m3u8对应的ts
    //     concurrencyFileloader.addTask("${entry.key}",
    //         () => concurrencyFileloader.concurrencyDownloadFile(entry.value));
    //   }
    //   List<TaskResult> allResults = await concurrencyFileloader.waitForAll();
    //   concurrencyFileloader.dispose();
    //   for (TaskResult result in allResults) {
    //     pdebug(
    //         'downloading ts Task with parameter ${result.parameter} returned result ${result.result}');
    //     if (result.result == null) {
    //       pdebug("downloading m3u8 fail...");
    //       return HandleMsg(false, "downloading ts fail...");
    //     }
    //     targetHLSURLs.tsFiles[result.parameter] = result.result!;
    //   }
    // }

    // if (next != null) return await next!.handleRequest(request);
    // return HandleMsg(
    //     true, M3u8File(targetHLSURLs.tsFiles).._thumbnail = request.thumbnail);
  }
}

class M3u8File {
  String? _m3u8;

  // 视频封面
  String? _thumbnail;

  String? get thumbnail => _thumbnail;
  List<String>? _tsList;

  String? get m3u8 => _m3u8;

  List<String>? get tsList => _tsList;

  M3u8File(Map<String, dynamic> map) {
    assert(map.isNotEmpty);
    _tsList = [];
    for (var entry in map.entries) {
      if (entry.value.contains('.m3u8')) {
        _m3u8 = entry.value;
        continue;
      }
      if (entry.value.contains('.ts')) {
        _tsList!.add(entry.value);
      }
    }
  }
}
