import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';
import 'package:jxim_client/managers/task/video/video_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/net/upload_link_info.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/io.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/aws_s3/file_upload_info.dart';
import 'package:jxim_client/utils/net/aws_s3/aws_s3_upload.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class FileUploader {
  Map<String, Task> allTask = {};
  Timer? _timer;
  Timer? _apple4KPendingTimer;

  final maxTaskAmount = 4;
  final Map<String, UploadFile> uploadFileMap = <String, UploadFile>{};
  final Map<String, UploadFile> fileUploadFailed = <String, UploadFile>{};
  final int MAX_RETRY = 3;
  final Map<String, int> retryMap = <String, int>{};

  final Map<int, Map<String, dynamic>> apple4kFilePendingList =
      <int, Map<String, dynamic>>{};
  bool apple4kFileIsConverting = false;

  String applicationDirectory = '';

  Set<String> cancelFile = <String>{};
  Set<int> sendTime = <int>{};

  FileUploader._();

  static final shared = FileUploader._();

  Future<String?> uploadFile(
    UploadFile uploadFile, {
    bool enableCipher = false,
    Function(int bytes, int totalBytes)? onProgress,
    Function(int duration, int TotalDurations)? onConversionProgress,
    Function(String coverUrl)? onCoverUploaded,
    Function(String combinedVideoHash)? onVideoCombined,
  }) async {
    uploadFile.onProgress = onProgress;
    uploadFile.onFormatConverting = onConversionProgress;
    uploadFile.onCoverUploaded = onCoverUploaded;
    uploadFile.onVideoCombined = onVideoCombined;

    final Completer<String> uploadCompleter = Completer<String>();
    if (!notBlank(applicationDirectory)) {
      applicationDirectory =
          (await getApplicationDocumentsDirectory()).absolute.path;
    }

    /// 本地文件夹路径
    final String directoryPath =
        '${applicationDirectory}/${uploadFile.uploadKey}';

    /// id/timestamp_filename
    /// s3文件夹路径
    if (uploadFile.originalAssetType == AssetType.video) {
      await segmentationConfig(uploadFile, directoryPath, uploadCompleter);
      return uploadCompleter.future;
    } else {
      return addTask(uploadFile, enableCipher: enableCipher);
    }
  }

  Future<String?> segmentationConfig(
    UploadFile data,
    String directoryPath,
    Completer<String> uploadCompleter,
  ) async {
    final String sourceM3u8 = '${directoryPath}/${data.originalFileHash}.m3u8';
    final String segmentVideo =
        '${directoryPath}/${data.originalFileHash}_%04d.ts';

    await DYio.mkDir(directoryPath);
    final directory = Directory(directoryPath);

    MediaInformationSession infoSession =
        await FFprobeKit.getMediaInformation('${data.originalPath}');
    MediaInformation? mediaInformation = infoSession.getMediaInformation();
    return videoSegmentation(
      data,
      directory,
      mediaInformation,
      sourceM3u8,
      segmentVideo,
      10,
      false,
      uploadCompleter,
    );
  }

  void launchSegmentationTimer() {
    if (_apple4KPendingTimer != null) {
      return;
    }

    _apple4KPendingTimer =
        Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      launchSegmentation();
    });
  }

  Future launchSegmentation() async {
    if (apple4kFilePendingList.isEmpty) {
      _apple4KPendingTimer?.cancel();
      _apple4KPendingTimer = null;
      return;
    }

    if (apple4kFileIsConverting) return;

    Map<String, dynamic> value = apple4kFilePendingList.values.first;

    videoSegmentation(
      value['data'],
      value['directory'],
      value['mediaInformation'],
      value['sourceM3u8'],
      value['segmentVideo'],
      value['timeSpan'],
      value['hevcAccFormat'],
      value['uploadCompleter'],
    );
  }

  /// 进行视频转码以及分片
  Future<String?> videoSegmentation(
    UploadFile data,
    Directory directory,
    MediaInformation? mediaInformation,
    String sourceM3u8,
    String segmentVideo,
    int timeSpan,
    bool hevcAccFormat,
    Completer<String> uploadCompleter,
  ) async {
    if (hevcAccFormat) {
      apple4kFileIsConverting = true;
      await FFmpegKit.executeAsync(
          '-y -i "${data.originalPath}" -vf "transpose=1" -codec: copy -c:v libx264 -preset ultrafast -crf 24 -r 20 '
          '-map 0 -f segment -segment_time $timeSpan -segment_format mpegts -segment_list "${sourceM3u8}" -segment_list_type m3u8 "${segmentVideo}"',
          (FFmpegSession completeCallback) {
            onCodecComplete(data, directory).then((value) {
              data.onFormatConverting?.call(0, 1);
              apple4kFileIsConverting = false;
              apple4kFilePendingList.remove(data.hashCode);
              uploadCompleter.complete(value);
            });
          },
          (_) {},
          (Statistics statistics) {
            pdebug(
                "【上传文件】 视频4K转码进度: ${(statistics.getTime() * 100) / (double.parse(mediaInformation!.getDuration()!) * 1000).toInt()} %");
            data.onFormatConverting?.call((statistics.getTime() * 100).toInt(),
                (double.parse(mediaInformation.getDuration()!) * 1000).toInt());
          });
    } else {
      pdebug("【上传文件】视频分片中... | ${sourceM3u8}");
      await FFmpegKit.executeAsync(
        '-y -i ${data.originalPath} -codec: copy -start_number 0 -hls_list_size 0 -hls_time 10 -hls_segment_filename ${segmentVideo} -f hls ${sourceM3u8}',
        (FFmpegSession completeCallback) {
          onCodecComplete(data, directory).then((value) {
            uploadCompleter.complete(value);
          });
        },
        (_) {},
        (Statistics statistics) {
          pdebug(
              "【上传文件】 视频转码进度: ${(statistics.getTime() * 100) / (double.parse(mediaInformation!.getDuration()!) * 1000).toInt()} %");
          data.onFormatConverting?.call((statistics.getTime() * 100).toInt(),
              (double.parse(mediaInformation.getDuration()!) * 1000).toInt());
        },
      );
    }
    return uploadCompleter.future;
  }

  Future<String?> onCodecComplete(
    UploadFile data,
    Directory directory,
  ) async {
    List<FileSystemEntity> fileList = directory.listSync();

    List<String> tsFiles = [];
    pdebug("【上传文件】编码完成, 准备上传... | File Number ${fileList.length}");

    List<Future> futureList = [
      ...fileList
          .map(
            (FileSystemEntity file) => Future(() async {
              final videoFile = File(file.path);
              if (!videoFile.existsSync()) {
                data.completer.complete('cancel');
                return null;
              }

              final String fileHash = calculateMD5(videoFile.readAsBytesSync());
              if (file.path.contains('.m3u8')) {
                Task task = Task(
                  data.uploadKey,
                  file.path,
                  fileHash,
                  'application/x-mpegURL',
                  iSegment: true,
                );
                data.m3u8Task = task;
              } else {
                tsFiles.add(file.path);
                Task task = Task(
                  data.uploadKey,
                  file.path,
                  fileHash,
                  'video/MP2T',
                  iSegment: true,
                );
                data.subTaskList.add(task);
              }
            }),
          )
          .toList(),
    ];

    if (fileList.isEmpty) {
      futureList.add(Future(() async {
        final String fileHash =
            calculateMD5(data.originalFile!.readAsBytesSync());

        Task task = Task(
          data.uploadKey,
          data.originalPath!,
          fileHash,
          data.originalFileMimeType ?? '',
          iSegment: false,
          enableCipher: data.originalAssetType == AssetType.image,
        );

        data.m3u8Task = task;
      }));
    }

    await Future.wait(futureList);

    await DYio.mkDir(applicationDirectory + '/${data.uploadKey}');
    final combinedVideoPath = await videoMgr.combineToMp4(
      tsFiles,
      dir: applicationDirectory + '/${data.uploadKey}/',
    );
    final combinedVideoFile = File(combinedVideoPath);

    if (combinedVideoFile.existsSync()) {
      final String combinedHash =
          calculateMD5(combinedVideoFile.readAsBytesSync());
      data.m3u8Task!.fileHash = combinedHash;
    }

    return addTask(data);
  }

  /// ============================== 多线程上传 =================================

  Future<String?> addTask(UploadFile uploadFile,
      {bool enableCipher = false}) async {
    uploadFileMap.putIfAbsent(uploadFile.uploadKey, () => uploadFile);

    List<Task> curTasks = [];
    if (uploadFile.originalAssetType == AssetType.video) {
      File? m3u8SourceFile = uploadFile.m3u8Task != null
          ? File(uploadFile.m3u8Task!.filePath)
          : null;
      final bool m3u8SourceExist = m3u8SourceFile?.existsSync() ?? false;

      if (uploadFile.coverTask != null) {
        File? coverFile = File(uploadFile.coverTask!.filePath);
        final bool coverFileExist = coverFile.existsSync();
        if (!coverFileExist) {
          uploadFile.onFinished?.call('cancel');
          return uploadFile.completer.future;
        }
        final String fileHash = calculateMD5(coverFile.readAsBytesSync());
        uploadFile.coverTask!.fileHash = fileHash;
        pdebug("【上传文件】添加任务 : 缩略图");
        curTasks.add(uploadFile.coverTask!);
      }

      if (m3u8SourceExist) {
        /// 上传segment 视频文件
        curTasks.add(uploadFile.m3u8Task!);
        curTasks.addAll(uploadFile.subTaskList);
        pdebug("【上传文件】添加任务 : 视频分片");
        await uploadFile.calculateSize();
      } else {
        if (uploadFile.originalFile == null) {
          uploadFile.onFinished?.call('cancel');
          return uploadFile.completer.future;
        }

        final String fileHash =
            calculateMD5(uploadFile.originalFile!.readAsBytesSync());

        final compressedFile = await videoCompress(
          uploadFile.originalFile!,
          quality: VideoQuality.Res1280x720Quality,
          savePath: '${DateTime.now().millisecondsSinceEpoch}.mp4',
        );
        if (compressedFile != null) {
          uploadFile.originalFile = compressedFile;
        }

        Task videoTask = Task(
          uploadFile.uploadKey,
          uploadFile.originalPath!,
          fileHash,
          uploadFile.originalFileMimeType ?? '',
          iSegment: true,
        );
        uploadFile.fileTask = videoTask;

        curTasks.add(videoTask);
        pdebug("【上传文件】添加任务 : 视频文件");

        await uploadFile.calculateSize();
      }
    } else if (uploadFile.originalAssetType == AssetType.image) {
      pdebug("【上传文件】获取图片文件");

      final String fileHash =
          calculateMD5(uploadFile.originalFile!.readAsBytesSync());

      Task task = Task(
        uploadFile.uploadKey,
        uploadFile.originalPath ?? '',
        fileHash,
        uploadFile.originalFileMimeType ?? '',
        enableCipher: enableCipher,
        iSegment: true,
      );

      uploadFile.fileTask = task;

      pdebug("【上传文件】添加任务 Image : 图片文件 ${fileHash}");
      curTasks.add(task);
      if (uploadFile.fileTask == null) {
        uploadFile.fileTask = curTasks.first;
      }

      await uploadFile.calculateSize();
    } else {
      if (uploadFile.originalFile == null) {
        uploadFile.onFinished?.call('cancel');
        return uploadFile.completer.future;
      }

      final String fileHash =
          calculateMD5(uploadFile.originalFile!.readAsBytesSync());

      Task task = Task(
        uploadFile.uploadKey,
        uploadFile.originalPath!,
        fileHash,
        uploadFile.originalFileMimeType ?? '',
        iSegment: false,
        enableCipher: uploadFile.originalAssetType == AssetType.image,
      );

      uploadFile.fileTask = task;
      await uploadFile.calculateSize();

      curTasks.add(task);
    }

    // 获取上传Url
    try {
      final List<UploadLinkInfo>? urlInfoList = await getUploadLink(uploadFile);

      if (urlInfoList == null) {
        uploadFile.onFinished?.call('cancel');
        return uploadFile.completer.future;
      }

      for (int i = 0; i < urlInfoList.length; i++) {
        UploadLinkInfo urlInfo = urlInfoList[i];
        if (urlInfo.error.isNotEmpty || urlInfo.code > 0) {
          curTasks[i].resultUrl = urlInfo.path;
          curTasks[i].status = TaskStatus.success;
          _doFinish(curTasks[i], urlInfo.key);
          continue;
        }

        final String fileName = getFileNameWithExtension(urlInfo.path);
        final Task currTask = curTasks[i];
        final String infoKey;
        final String taskKey;
        if (fileName.contains('.m3u8') || fileName.contains('.ts')) {
          final taskFileName = getFileNameWithExtension(urlInfo.path);
          infoKey = urlInfo.key + '/${taskFileName}';
          taskKey = urlInfo.key + '/${taskFileName}';
        } else {
          infoKey = urlInfo.key;
          taskKey = currTask.fileHash;
        }

        if (infoKey == taskKey) {
          curTasks[i].urlInfo = urlInfo;
          if (curTasks[i].status != TaskStatus.success) {
            curTasks[i].onProgress = uploadFile.onProgress;
            await Future.delayed(const Duration(milliseconds: 20));
            doTask(curTasks[i]);
          }
        }
      }
    } on AppException catch (e) {
      pdebug("On Update Error: ${e}");
      uploadFile.onFinished?.call('cancel');
    }

    return uploadFile.completer.future;
  }

  Future<void> doTask(Task task) async {
    task.status = TaskStatus.wait;

    if (!allTask.containsKey(task.filePath)) {
      allTask[task.filePath] = task;
    }

    _runTimer();
  }

  void _runTimer() {
    if (_timer != null) {
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _executePool();
    });
  }

  int _countTask() {
    int doTaskingCount = 0;

    Map<String, Task>.from(allTask).forEach((key, task) {
      switch (task.status) {
        case TaskStatus.running:
        case TaskStatus.retrying:
          doTaskingCount++;
          break;
        default:
          break;
      }
    });
    return doTaskingCount;
  }

  void _executePool() {
    // 当前下载任务,如果正在下载
    int runningCount = _countTask();
    if (runningCount < maxTaskAmount) {
      Map<String, Task>.from(allTask).forEach((filePath, task) {
        if (task.status == TaskStatus.wait && runningCount < maxTaskAmount) {
          runningCount++;
          task.upload().then((resultUrl) {
            _doFinish(task, resultUrl);
          });
        }
      });
    }

    if (allTask.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _doFinish(Task task, String? resultUrl) {
    List<UploadFile> removeUploadFileInfoList = [];
    if (uploadFileMap.containsKey(task.uploadKey)) {
      final fileUploadInfo = uploadFileMap[task.uploadKey]!;
      bool isCompleted = true;
      if (fileUploadInfo.fileTask != null &&
          (fileUploadInfo.fileTask!.status == TaskStatus.wait ||
              fileUploadInfo.fileTask!.status == TaskStatus.running ||
              fileUploadInfo.fileTask!.status == TaskStatus.retrying)) {
        isCompleted = false;
        pdebug("【上传文件】上传File完成状态=========> $isCompleted");
      }

      if (fileUploadInfo.coverTask != null &&
          (fileUploadInfo.coverTask!.status == TaskStatus.wait ||
              fileUploadInfo.coverTask!.status == TaskStatus.running ||
              fileUploadInfo.coverTask!.status == TaskStatus.retrying)) {
        isCompleted = false;
        pdebug("【上传文件】上传Cover完成状态=========> $isCompleted");
      }

      if (fileUploadInfo.m3u8Task != null &&
          (fileUploadInfo.m3u8Task!.status == TaskStatus.wait ||
              fileUploadInfo.m3u8Task!.status == TaskStatus.running ||
              fileUploadInfo.m3u8Task!.status == TaskStatus.retrying)) {
        isCompleted = false;
        pdebug("【上传文件】上传m3u8Task完成状态=========> $isCompleted");
      }

      fileUploadInfo.subTaskList.forEach((segTask) {
        if (segTask.status == TaskStatus.wait ||
            segTask.status == TaskStatus.running ||
            segTask.status == TaskStatus.retrying) {
          isCompleted = false;
          pdebug(
              "【上传文件】上传subTaskList完成状态=========> $segTask - $isCompleted - ${fileUploadInfo.subTaskList.length}");
        }
      });
      pdebug("【上传文件】上传完成状态=========> $isCompleted");
      if (isCompleted) {
        removeUploadFileInfoList.add(fileUploadInfo);

        String? resultUrl = fileUploadInfo.fileTask?.resultUrl;
        pdebug("【上传文件】上传结束回调=========> ${resultUrl}");
        if (fileUploadInfo.m3u8Task != null) {
          resultUrl = fileUploadInfo.m3u8Task?.resultUrl;
        }

        if (fileUploadInfo.coverTask != null) {
          fileUploadInfo.onCoverUploaded
              ?.call(fileUploadInfo.coverTask!.resultUrl ?? '');
        }

        fileUploadInfo.onFinished?.call(resultUrl);
      }
    }

    if (removeUploadFileInfoList.isNotEmpty) {
      removeUploadFileInfoList.forEach((uploadFileInfo) {
        uploadFileMap.remove(uploadFileInfo.uploadKey);
      });
    }
  }

  /// =============================== 辅助函数 =================================

  Future<List<UploadLinkInfo>> getUploadLink(UploadFile uploadFile) async {
    final List<Map<String, dynamic>> segmentFileList = [];

    if (uploadFile.fileTask != null) {
      segmentFileList.add({
        'key': uploadFile.fileTask!.fileHash,
        'file_name': uploadFile.fileTask!.fileHash +
            '.${getFileExtension(uploadFile.fileTask!.filePath)}',
        'ext': uploadFile.uploadExt.value,
        'is_key_file': true,
      });
    }

    if (uploadFile.coverTask != null) {
      segmentFileList.add({
        'key': uploadFile.coverTask!.fileHash,
        'file_name': uploadFile.coverTask!.fileHash +
            '.${getFileExtension(uploadFile.coverTask!.filePath)}',
        'ext': UploadExt.image.value,
        'is_key_file': true,
      });
    }

    if (uploadFile.m3u8Task != null) {
      segmentFileList.add({
        'key': uploadFile.originalFileHash,
        'file_name': getFileNameWithExtension(uploadFile.m3u8Task!.filePath),
        'ext': uploadFile.uploadExt.value,
        'is_key_file': true,
      });
    }

    if (uploadFile.subTaskList.isNotEmpty) {
      // subTask 只有ts切片
      uploadFile.subTaskList.forEach((task) {
        segmentFileList.add({
          'key': uploadFile.originalFileHash,
          'file_name': getFileNameWithExtension(task.filePath),
          'ext': uploadFile.uploadExt.value,
          'is_key_file': false,
        });
      });
    }

    return [];
  }

  bool uploadIsCancel(String fileName, int sendTime) =>
      cancelFile.contains(fileName) || this.sendTime.contains(sendTime);
}

class Task {
  /// 状态 0:待下载 1:下载中 2:下载完成 3:等待别人下载完成
  TaskStatus status = TaskStatus.wait;

  String uploadKey;

  String filePath;

  String fileHash;

  String contentType;

  bool iSegment;

  /// 下载失败重试次数
  int retry = 3;

  String? resultUrl;

  UploadLinkInfo? urlInfo;

  bool enableCipher;

  Function(int bytes, int totalBytes)? onProgress;

  Task(
    this.uploadKey,
    this.filePath,
    this.fileHash,
    this.contentType, {
    this.status = TaskStatus.wait,
    this.iSegment = false,
    this.enableCipher = false,
  });

  Future<String?> upload() async {
    if (urlInfo == null) {
      onUploadFailed();
      return null;
    }

    UploadFile? fileUploadInfo =
        FileUploader.shared.fileUploadFailed[uploadKey];
    if (fileUploadInfo != null) {
      pdebug("【上传文件】上传Task取消: ${this.uploadKey} | ${fileHash}");
      onUploadFailed();
      return null;
    }

    status = TaskStatus.running;
    pdebug("【上传文件】开始上传: ${this.uploadKey} | ${fileHash} | ${enableCipher}");
    final File file = File(filePath);
    try {
      final String? result = await AwsS3().uploadFile(uploadKey, urlInfo!, file,
          enableCipher: enableCipher, onProgress: onProgress);

      if (result == null) {
        if (retry > 0) {
          status = TaskStatus.retrying;
          Future.delayed(const Duration(milliseconds: 300), () => upload());
          retry--;
          pdebug("【上传文件】重试上传: ${this.uploadKey} 重试次数： ${retry}");
        } else {
          pdebug("【上传文件】上传失败: ${this.uploadKey}");
          throw "upload failed";
        }
      } else {
        resultUrl = result;
        status = TaskStatus.success;
        FileUploader.shared.allTask.remove(filePath);
        pdebug("【上传文件】上传成功: ${this.uploadKey} 上传链接: ${result}");
      }
      return result;
    } catch (e) {
      pdebug("【上传文件】上传失败: ${this.uploadKey} | ${this.fileHash}");
      onUploadFailed();
      return null;
    }
  }

  onUploadFailed() {
    status = TaskStatus.failed;

    UploadFile? fileUploadInfo = FileUploader.shared.uploadFileMap[uploadKey];
    if (fileUploadInfo != null) {
      fileUploadInfo.taskFailedList.add(this);
      FileUploader.shared.fileUploadFailed[uploadKey] = fileUploadInfo;
      fileUploadInfo.onFinished?.call('cancel');
    }
    FileUploader.shared.allTask.remove(filePath);
  }
}

enum TaskStatus {
  wait,
  running,
  success,
  retrying,
  failed,
}
