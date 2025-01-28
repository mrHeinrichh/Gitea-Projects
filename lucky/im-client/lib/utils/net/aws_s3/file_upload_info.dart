import 'dart:async';
import 'dart:io';

import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../file_type_util.dart';
import 'file_uploader.dart';

class UploadFile {
  final String uploadKey;

  AssetType? originalAssetType;

  File? originalFile;
  String? originalPath;
  String? originalFileName;
  String? originalFileExtension;
  String? originalFileMimeType;

  String? originalFileHash;

  int sendTime = 0;

  int width = 0;
  int height = 0;

  Task? fileTask;
  Task? coverTask;
  List<Task> subTaskList = List.empty(growable: true); //视频切片或者image的缩略图
  Task? m3u8Task;

  /// key: filepath
  /// value: bucket destination path
  List<Task> taskFailedList = [];
  int totalBytes = 0;
  int sentBytes = 0;

  // Upload Type
  UploadExt uploadExt = UploadExt.image;

  bool get isFailed => taskFailedList.length > 0;

  Completer<String?> completer = Completer();
  Function(int bytes, int totalBytes)? onProgress;
  Function(int bytes, int totalBytes)? onFormatConverting;
  Function(String coverUrl)? onCoverUploaded;
  Function(String combinedVideoHash)? onVideoCombined;

  Function? onFinished;

  UploadFile(this.uploadKey);

  UploadFile.fromFile(
    this.uploadKey,
    this.uploadExt,
    File file,
    String fileHash,
    AssetType type,
    int width,
    int height,
    int sendTime, {
    String cover = '',
  }) {
    originalAssetType = type;

    originalFile = file;
    originalPath = file.path;
    originalFileHash = fileHash;
    originalFileName = getFileName(file.path);
    originalFileExtension = getFileExtension(file.path).toLowerCase();
    originalFileMimeType = '${type.toName()}/$originalFileExtension';

    this.width = width;
    this.height = height;

    this.sendTime = sendTime;

    if (notBlank(cover)) {
      Task task = Task(uploadKey, cover, '', 'image/*', iSegment: true);
      coverTask = task;
    }

    onFinished = (resultUrl) {
      pdebug('onFinished--------------> $resultUrl, $uploadKey');
      if (!completer.isCompleted) completer.complete(resultUrl);
    };
  }

  calculateSize() async {
    if (m3u8Task != null) {
      File file = File(m3u8Task!.filePath);
      totalBytes += file.lengthSync();
    }

    if (fileTask != null) {
      File file = File(fileTask!.filePath);
      totalBytes += file.lengthSync();
    }

    if (coverTask != null) {
      File file = File(coverTask!.filePath);
      totalBytes += file.lengthSync();
    }

    if (subTaskList.isNotEmpty) {
      subTaskList.forEach((e) {
        File file = File(e.filePath);
        totalBytes += file.lengthSync();
      });
    }
  }
}

enum UploadExt {
  image('Image'),
  video('Video'),
  document('Document'),
  reels('Reels');

  const UploadExt(this.value);

  final String value;
}
