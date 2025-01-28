import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_controller.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_floating_player.dart';
import 'package:jxim_client/im/custom_content/video/tencent_video_stream.dart';
import 'package:jxim_client/im/custom_content/video/video_overlay.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/interface/base_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/message_utils.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:path/path.dart' as tc_path;
import 'package:super_player/super_player.dart';

class TencentVideoMgr extends BaseMgr {
  final List<TencentVideoStreamMgr> _streams = []; //大流
  final Map<String, int> _preloadTasks = {};
  final Map<String, List<Function>> _downloadTasks = {};
  final Map<String, List<Function>> _downloadProgressTasks = {};
  final Map<String, List<Function>> _downloadErrorTasks = {};

  static const String hlsExt = ".hls";
  static const String cacheFolder = "TencentVideo";
  static const String tmpCacheFolder = "tp_dp_file";
  static const String encFileName = "encrypt.key";
  static const String encFolder = "enc";

  bool supportPIP = false;

  TencentVideoStreamMgr? get currentStreamMgr => _streams.last;
  TencentVideoStream? pipStream;

  final StreamController<TencentVideoStream> streamController =
      StreamController.broadcast();

  Stream<TencentVideoStream> get onStreamBroadcast => streamController.stream;

  final VideoOverlay overlay = VideoOverlay();

  @override
  Future<void> initialize() async {
    if (objectMgr.loginMgr.isDesktop) return;
    String licenceURL = Config().videoLicenseUrl; // 获取到的 licence url
    String licenceKey = Config().videoLicenseKey; // 获取到的 licence key

    SuperPlayerPlugin.setGlobalLicense(licenceURL, licenceKey);
    SuperPlayerPlugin.setLogLevel(TXLogLevel.LOG_LEVEL_NULL);

    //设置播放引擎的全局缓存目录和缓存大小，//单位MB
    SuperPlayerPlugin.setGlobalMaxCacheSize(1024 * 20);
    if (Platform.isAndroid) {
      SuperPlayerPlugin.setGlobalCacheFolderCustomPath(
        androidAbsolutePath: "${downloadMgr.appDocumentRootPath}/$cacheFolder",
      );
    } else {
      SuperPlayerPlugin.setGlobalCacheFolderCustomPath(
        iOSAbsolutePath: "${downloadMgr.appDocumentRootPath}/$cacheFolder",
      );
    }

    objectMgr.callMgr.on(CallMgr.eventCallStateChanged, _onCallEventChanged);

    TXVodDownloadController.instance.setDownloadObserver((event, info) {
      //events
      // pdebug("Event - $event - Info - $info");
      if (_downloadTasks.isEmpty) return;
      if (_downloadTasks[info.url] == null) return;

      switch (event) {
        case TXVodPlayEvent.EVENT_DOWNLOAD_FINISH:
          List<Function> functions = _downloadTasks[info.url]!;
          if (functions.isNotEmpty) {
            for (var fn in functions) {
              fn.call();
            }
          }
          _downloadTasks.remove(info.url);
          _downloadProgressTasks.remove(info.url);
          _downloadErrorTasks.remove(info.url);
          break;
        case TXVodPlayEvent.EVENT_DOWNLOAD_PROGRESS:
          List<Function>? functions = _downloadProgressTasks[info.url];
          if (functions != null && functions.isNotEmpty) {
            for (var fn in functions) {
              fn.call(info);
            }
          }
        default:
          break;
      }
    }, (errorCode, errorMsg, info) {
      //error, remove for now == do nothing
      if (_downloadErrorTasks.isEmpty) return;
      if (_downloadErrorTasks[info.url] == null) return;

      List<Function> functions = _downloadErrorTasks[info.url]!;
      if (functions.isNotEmpty) {
        for (var fn in functions) {
          fn.call();
        }
      }
      _downloadErrorTasks.remove(info.url);
      _downloadProgressTasks.remove(info.url);
      _downloadTasks.remove(info.url);
    });
  }

  checkForFloatingPIPClosure(List<Message> videoMessages) async {
    if (pipStream == null) return;
    for (var message in videoMessages) {
      if (message.typ == messageTypeNewAlbum) {
        NewMessageMedia messageMedia =
            message.decodeContent(cl: NewMessageMedia.creator);
        List<AlbumDetailBean> list = messageMedia.albumList ?? [];
        for (AlbumDetailBean bean in list) {
          bean.currentMessage = message;
          final (String url, _, _, _, _, _) =
              await getVideoParams(message, bean);
          if (url == pipStream!.url) {
            closeFloating();
            return;
          }
        }
      } else {
        final (String url, _, _, _, _, _) =
            await getVideoParams(message, message.asset);
        if (url == pipStream!.url) {
          closeFloating();
          return;
        }
      }
    }
  }

  updateAudioSession() async {
    if (!Platform.isIOS) return;
    final audioManager = audio_session.AVAudioSession();
    await audioManager
        .setCategory(audio_session.AVAudioSessionCategory.playback);
    await audioManager.setActive(true);
  }

  removeAudioSession() async {
    if (Platform.isIOS) {
      final audioManager = audio_session.AVAudioSession();
      await audioManager
          .setCategory(audio_session.AVAudioSessionCategory.ambient);
      await audioManager.setActive(true);
    }
  }

  bool checkAllowPlay() {
    if (Get.currentRoute == RouteName.mediaPreviewView) {
      return false;
    }
    return objectMgr.callMgr.currentState.value == CallState.Idle;
  }

  _onCallEventChanged(Object sender, __, Object? data) async {
    if (data is! CallEvent) return;

    switch (data) {
      case CallEvent.CallStart:
      case CallEvent.CallInited:
        pauseAllControllers();
        break;
      default:
        break;
    }
  }

  pauseAllControllers() async {
    final futures = <Future>[];
    for (var streamMgr in _streams) {
      for (var stream in streamMgr.getAllStreams()) {
        if (stream.state.value == TencentVideoState.PLAYING) {
          futures.add(stream.controller.pause());
        }
      }
    }
    if (pipStream != null) {
      if (pipStream!.state.value == TencentVideoState.PLAYING) {
        futures.add(pipStream!.controller.pause());
      }
    }
    await Future.wait(futures);
  }

  resumeAllControllers() async {
    final futures = <Future>[];
    for (var streamMgr in _streams) {
      for (var stream in streamMgr.getAllStreams()) {
        if (stream.controller.isControllerPlaying) {
          stream.controller.notifyParentOnPlayerState(
              TencentVideoState.PAUSED, pipStream!.controller,
              setManuallyPaused: false);
          stream.controller.isControllerPlaying = false;
          futures.add(stream.controller.play());
        }
      }
    }
    if (pipStream != null) {
      if (pipStream!.controller.isControllerPlaying) {
        pipStream!.controller.notifyParentOnPlayerState(
            TencentVideoState.PAUSED, pipStream!.controller,
            setManuallyPaused: false);
        pipStream!.controller.isControllerPlaying = false;
        pipStream!.controller.play();
      }
    }
    await Future.wait(futures);
  }

  bool isAnyControllerPlaying() {
    if (objectMgr.loginMgr.isDesktop) return false;
    bool anyPlaying = false;

    for (var streamMgr in _streams) {
      for (var stream in streamMgr.getAllStreams()) {
        if (stream.state.value == TencentVideoState.PLAYING) {
          anyPlaying = true;
          return anyPlaying;
        }
      }
    }

    if (pipStream != null) {
      if (pipStream!.state.value == TencentVideoState.PLAYING) {
        anyPlaying = true;
      }
    }

    return anyPlaying;
  }

  removePreloadTask(String preloadUrl) {
    if (objectMgr.loginMgr.isDesktop) return;
    int? taskId = _preloadTasks[preloadUrl];
    if (taskId != null) {
      TXVodDownloadController.instance.stopPreLoad(taskId);
    }
  }

  addPreloadTask(
    Uri? preloadUri, {
    double preloadMb = 2,
    int width = 0,
    int height = 0,
  }) async {
    if (objectMgr.loginMgr.isDesktop) return;

    if (preloadUri == null) return;

    if (hasPreloadedVideo(preloadUri.toString())) return;

    if (_preloadTasks[preloadUri.path] != null) return; //已经预加载不用重复

    int taskId = await TXVodDownloadController.instance.startPreLoad(
      preloadUri.toString(),
      preloadMb,
      width * height,
      onCompleteListener: (int taskId, String url) {
        // pdebug('taskID=${taskId} ,url=${url}');
        removePreloadTask(preloadUri.path);
      },
      onErrorListener: (int taskId, String url, int code, String msg) {
        // pdebug('taskID=${taskId} ,url=${url}, code=${code} , msg=${msg}');
        //暂不做处理
      },
    );

    _preloadTasks[preloadUri.path] = taskId;
  }

  //上传视频的同时，把上传视频的tmp路径搬到S3的相对路径
  bool moveFile(String uploadFilePath, String s3AbsolutePath,
      {bool isVideo = true}) {
    String extension = tc_path.extension(s3AbsolutePath);
    if (extension.toLowerCase() != '.m3u8') return false;
    String savePath = downloadMgr.getSavePath(s3AbsolutePath);
    final fileRelativeFolder = tc_path.dirname(savePath);
    String fileSavePath;
    if (isVideo) {
      fileSavePath = savePath.replaceAll(extension, ".mp4");
    } else {
      fileSavePath = savePath;
    }

    final Directory directory = Directory(fileRelativeFolder);
    try {
      File? f = File(uploadFilePath);
      if (!f.existsSync()) return false;

      if (!directory.existsSync()) {
        //create directory if it doesnt already exist
        directory.createSync(recursive: true);
      }

      //复制到s3相对路径
      f.copySync(fileSavePath);
    } catch (e) {
      pdebug('An error occurred: $e');
      return false;
    }

    return true;
  }

  addLog(String url1, String url2, String errorMsg) {
    objectMgr.logMgr.logVideoMgr.addMetrics(
      LogVideoMsg(
        msg:
            "uid:${objectMgr.userMgr.mainUser.uid} \n\n version: ${appVersionUtils.currentAppVersion} \n\n $errorMsg",
        mediaType: "$url1 - $url2",
        executionTime: 0,
      ),
    );
  }

  Future<String> checkFailedSave(String urlPath, String s3Path) async {
    if (downloadMgrV2.getLocalPath(getMp4Path(urlPath)) != null) {
      return "合并mp4过程 - 文件属于mp4，视频本就存在，但是还是报错";
    }

    String md5 = makeMD5(s3Path);
    md5 = Platform.isIOS
        ? md5.toUpperCase()
        : md5.toLowerCase(); // iOS is uppercase while android is lowercase
    String dirPath =
        "${downloadMgr.appDocumentRootPath}/$cacheFolder/$md5$hlsExt";

    final Directory directory = Directory(dirPath);
    if (directory.existsSync()) {
      File? m3u8;
      List<Directory> ts = [];
      directory.listSync(recursive: false).forEach((FileSystemEntity entity) {
        if (entity is Directory) {
          ts.add(entity);
        } else if (entity is File && entity.path.contains(".m3u8")) {
          m3u8 = entity;
        }
      });
      if (ts.isEmpty) {
        return "合并mp4过程 - 找不到TS文件夹";
      }
      if (m3u8 == null) {
        return "合并mp4过程 - 找不到m3u8文件";
      }

      // ts!, m3u8!, path
      final p = downloadMgr.getSavePath(urlPath);
      final tsDirPath = tc_path.dirname(p);
      final tsToDir = Directory(tsDirPath);
      List<String> items = [];
      List<String> m3u8Items = [];
      try {
        if (!tsToDir.existsSync()) {
          tsToDir.createSync(recursive: true);
        }

        m3u8Items = getM3u8TSFiles(m3u8!);
        for (var dir in ts) {
          dir.listSync(recursive: false).forEach((entity) {
            if (entity.path.endsWith(".ts")) items.add(entity.path);
          });
        }

        items.sort((a, b) {
          String s1 =
              a.split(Platform.pathSeparator).last.replaceAll(".ts", "");
          int index1 = int.parse(s1);

          String s2 =
              b.split(Platform.pathSeparator).last.replaceAll(".ts", "");
          int index2 = int.parse(s2);
          return index1.compareTo(index2);
        });

        if (m3u8Items.length > items.length) {
          String errorString = "缺失文件：";
          for (int i = 0; i < m3u8Items.length; i++) {
            String x = "$i.ts";
            String y = "";
            if (i < items.length) {
              y = items[i];
            }
            if (!y.contains(x)) {
              errorString += x;
              errorString += "，";
            }
          }

          return "合并mp4过程 - 找不到相应TS。 \n\n $errorString";
        }

        return "合并mp4过程 - FFMPEG合成问题";
      } catch (e) {
        return "合并mp4过程 - 报错问题 \n\n $e";
      }
    }
    return "合并mp4过程 - 找不到文件夹目录 - $dirPath";
  }

  bool hasPreloadedVideo(absolutePath) {
    bool preloaded = false;
    // String dirPath = getTencentCachePath(absolutePath);
    String md5 = makeMD5(absolutePath);
    String md5PathUpper = makeTencentCachePath(md5.toUpperCase());
    String md5PathLower = makeTencentCachePath(md5.toLowerCase());
    Directory directory = Directory(md5PathUpper).existsSync()
        ? Directory(md5PathUpper)
        : Directory(md5PathLower);
    if (directory.existsSync()) {
      File? m3u8;
      Directory? firstTS;
      directory.listSync(recursive: false).forEach((FileSystemEntity entity) {
        if (entity is Directory && entity.path.contains("hls_0_29")) {
          firstTS = entity;
        } else if (entity is File && entity.path.contains(".m3u8")) {
          m3u8 = entity;
        }
      });
      if (firstTS != null && m3u8 != null) {
        String firstTSPath = "${firstTS!.path}/0.ts";
        String tsCfg = "${firstTS!.path}/0.ts.cfg";
        if (firstTSPath != null &&
            File(firstTSPath).existsSync() &&
            !File(tsCfg).existsSync()) {
          preloaded = true;
        }
      }
    }

    return preloaded;
  }

  String getTencentMp4Path(String absoluteMp4Path) {
    String md5 = makeMD5(absoluteMp4Path);
    String ext = tc_path.extension(absoluteMp4Path);
    md5 = Platform.isIOS
        ? md5.toUpperCase()
        : md5.toLowerCase(); // iOS is uppercase while android is lowercase
    String mp4Path = Platform.isIOS
        ? "${downloadMgr.appDocumentRootPath}/$cacheFolder/$tmpCacheFolder/$md5/$md5"
        : "${downloadMgr.appDocumentRootPath}/$cacheFolder/$tmpCacheFolder/$md5$ext/$md5$ext";
    return mp4Path;
  }

  String getTencentCachePath(String absolutePath) {
    String md5 = makeMD5(absolutePath);
    md5 = Platform.isIOS
        ? md5.toUpperCase()
        : md5.toLowerCase(); // iOS is uppercase while android is lowercase
    String dirPath =
        "${downloadMgr.appDocumentRootPath}/$cacheFolder/$md5$hlsExt";
    return dirPath;
  }

  String makeTencentCachePath(String md5) {
    String dirPath =
        "${downloadMgr.appDocumentRootPath}/$cacheFolder/$md5$hlsExt";
    return dirPath;
  }

  bool _copyMp4(String path, String absolutePath) {
    var itemPath =
        path.substring(0, path.lastIndexOf(tc_path.separator)) + "/index.mp4";
    if (downloadMgrV2.getLocalPath(itemPath) != null) return false;
    String mp4Path = getTencentMp4Path(absolutePath);
    File mp4 = File(mp4Path);
    if (!mp4.existsSync()) return false;
    String finalPath = downloadMgr.getSavePath(itemPath);
    Directory finalPathDirectory = Directory(
        finalPath.substring(0, finalPath.lastIndexOf(tc_path.separator)));
    if (!finalPathDirectory.existsSync()) {
      finalPathDirectory.createSync(recursive: true);
    }
    mp4.copySync(finalPath);
    return true;
  }

  //播放器缓存完成调用，换成mp4保存到相对路径
  Future<bool> _combineMp4(String path, String absolutePath) async {
    if (downloadMgrV2.getLocalPath(getMp4Path(path)) != null) return false;
    String dirPath = getTencentCachePath(absolutePath);

    final Directory directory = Directory(dirPath);
    if (directory.existsSync()) {
      File? m3u8;
      List<Directory> ts = [];
      directory.listSync(recursive: false).forEach((FileSystemEntity entity) {
        if (entity is Directory) {
          ts.add(entity);
        } else if (entity is File && entity.path.contains(".m3u8")) {
          m3u8 = entity;
        }
      });
      if (ts.isEmpty || m3u8 == null) return false;
      return await combineAllTsToMp4(ts, m3u8!, path);
    }

    return false;
  }

  void onMp4Ready(String path, String absolutePath, Function saveError) {
    var itemPath =
        path.substring(0, path.lastIndexOf(tc_path.separator)) + "/index.mp4";
    if (downloadMgrV2.getLocalPath(itemPath) != null) return;
    addDownloadTask(
      absolutePath,
      onComplete: () async {
        // pdebug("ededed - mp4复制 $absolutePath");
        bool success = _copyMp4(path, absolutePath);
        if (!success) {
          saveError.call();
        }
      },
      saveError: () {
        saveError.call();
      },
    );
  }

  Future<void> stopDownloadTask(String absolutePath) async {
    if (_downloadTasks[absolutePath] != null) {
      TXVodDownloadMediaInfo mediaInfo = TXVodDownloadMediaInfo();
      mediaInfo.url = absolutePath;

      await TXVodDownloadController.instance.stopDownload(mediaInfo);

      // pdebug("ededed - 停止下载任务 - $absolutePath");
      _downloadTasks.remove(absolutePath);
      _downloadProgressTasks.remove(absolutePath);
      var functions = _downloadErrorTasks[absolutePath];
      if (functions != null) {
        for (var fn in functions) {
          fn.call();
        }
      }
      _downloadErrorTasks.remove(absolutePath);
    }
  }

  void addDownloadTask(String absolutePath,
      {Function? onComplete, Function? saveError, Function? onProgress}) async {
    List<Future> futures = [];
    for (var entry in _downloadTasks.entries) {
      futures.add(stopDownloadTask(entry.key));
    }
    await Future.wait(futures);

    // pdebug("ededed - 增加下载任务 （超过两秒/下完补全） - $absolutePath");
    TXVodDownloadMediaInfo mediaInfo = TXVodDownloadMediaInfo();
    mediaInfo.url = absolutePath;

    List<Function> list = [];
    List<Function> errorFns = [];
    List<Function> progressFns = [];

    if (_downloadTasks[absolutePath] != null) {
      //手动下载为全局回调，故加map来控制回调（普通场景+异常场景，异常为播放器等待2秒重试）
      list = _downloadTasks[absolutePath]!;
      errorFns = _downloadErrorTasks[absolutePath]!;
      progressFns = _downloadProgressTasks[absolutePath]!;
    } else {
      _downloadTasks[absolutePath] = list;
      _downloadErrorTasks[absolutePath] = errorFns;
      _downloadProgressTasks[absolutePath] = progressFns;
    }

    if (onComplete != null) {
      list.add(onComplete);
    }

    if (saveError != null) {
      errorFns.add(saveError);
    }

    if (onProgress != null) {
      progressFns.add(onProgress);
    }

    TXVodDownloadController.instance.startDownload(mediaInfo);
  }

  void onDownloadReady(String path, String absolutePath, Function saveError) {
    if (downloadMgrV2.getLocalPath(getMp4Path(path)) != null) return;
    addDownloadTask(
      absolutePath,
      onComplete: () async {
        // pdebug("ededed - mp4 合成 $absolutePath");
        bool success = await _combineMp4(path, absolutePath);
        if (!success) {
          saveError.call();
        }
      },
      saveError: () {
        saveError.call();
      },
    );
  }

  List<String> getM3u8TSFiles(
    File m3u8,
  ) {
    final fileContent = m3u8.readAsLinesSync();
    List<String> s = [];

    for (final line in fileContent) {
      if (line.endsWith('ts')) {
        s.add(line);
      }
    }

    // m3u8.copySync(m3u8Path);
    return s;
  }

  String getMp4Path(String m3u8Path) {
    String extension = tc_path.extension(m3u8Path);
    if (extension.toLowerCase() != '.m3u8') return '';
    final p = downloadMgr.getSavePath(m3u8Path);
    return p.replaceAll(extension, ".mp4");
  }

  Future<bool> combineAllTsToMp4(
      List<Directory> tsDir, File m3u8, String path) async {
    final p = downloadMgr.getSavePath(path);
    final tsDirPath = tc_path.dirname(p);
    final tsToDir = Directory(tsDirPath);
    List<String> items = [];
    List<String> m3u8Items = [];
    try {
      if (!tsToDir.existsSync()) {
        //相对路径有没有相应的文件夹 - 若没有先起一个
        tsToDir.createSync(recursive: true);
      }

      m3u8Items = getM3u8TSFiles(m3u8); // 获取m3u8里所有的ts文件
      for (var dir in tsDir) {
        dir.listSync(recursive: false).forEach((entity) {
          if (entity.path.endsWith(".ts")) {
            items.add(entity.path); // 跳过所有临时文件，只有ts文件算入。
          }
        });
      }

      if (m3u8Items.length > items.length) {
        // pdebug("count mismatch during save, return false");
        return false;
      }

      items.sort((a, b) {
        String s1 = a.split(Platform.pathSeparator).last.replaceAll(".ts", "");
        int index1 = int.parse(s1);

        String s2 = b.split(Platform.pathSeparator).last.replaceAll(".ts", "");
        int index2 = int.parse(s2);
        return index1.compareTo(index2);
      }); //进行先后排序，否则ts文件顺序就会乱

      String s = await videoMgr.combineToMp4(
        items,
        fullUrl: getMp4Path(path),
      );
      if (s.isBlank ?? true) return false;
      return true;
    } catch (e) {
      pdebug('An error occurred: $e');
      objectMgr.tencentVideoMgr.addLog(path, "", "自动合并mp4过程 - 触发了报错。 \n\n $e");
    }
    return false;
  }

  //pip播放器由mgr管理
  _onPlayerEventUpdate(int event, TencentVideoController controller) {
    if (controller != pipStream?.controller) return;
    switch (event) {
      case TXVodPlayEvent.PLAY_EVT_VOD_PLAY_PREPARED:
        pipStream!.hasEnteredPrepared = true;
        pipStream!.state.value = TencentVideoState.PREPARED;
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS:
        if (pipStream!.hasManuallyPaused) return;
        if (pipStream!.isRestarting) return;
        if (pipStream!.isSeekingToEnd) return;

        if (pipStream!.state.value != TencentVideoState.LOADING) {
          //if have entered loading, stop updating to playing
          pipStream!.state.value = TencentVideoState.PLAYING;
        }

        if (!pipStream!.hasUpdatedAudioSession) {
          pipStream!.updateAudioSession();
        }
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_LOADING:
        if (!pipStream!.isRestarting && pipStream!.showPause) {
          pipStream!.state.value = TencentVideoState.LOADING;
        }
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN:
        pipStream!.hasManuallyPaused = false;
        pipStream!.state.value = TencentVideoState.PLAYING;
        break;
      case TXVodPlayEvent.PLAY_EVT_PLAY_END:
        pipStream!.isSeekingToEnd = false;
        pipStream!.state.value = TencentVideoState.END;
        break;
      case TXVodPlayEvent.VOD_PLAY_EVT_SEEK_COMPLETE:
        pipStream!.isRestarting = false;
        pipStream!.showPause = true;
        pipStream!.state.value = controller.previousState;
        break;
      default:
        break;
    }
    if (!streamController.isClosed) {
      streamController.add(pipStream!);
    } else {
      pipStream!.controller.dispose(); //确认关闭了还接收到状态更新，直接让播放器释放
    }
  }

  _onPlayerStateUpdate(
      TencentVideoState state, TencentVideoController controller,
      {bool? setManuallyPaused}) {
    if (controller != pipStream?.controller) return;
    if (state == TencentVideoState.SEEK_TO_END) {
      state = pipStream!.state.value;
      pipStream!.isSeekingToEnd = true;
    }
    if (state == TencentVideoState.MUTE_LOADING) {
      state = pipStream!.state.value;
      pipStream!.showPause = false;
    }
    if (state == TencentVideoState.RESTARTING) {
      pipStream!.isRestarting = true;
      state = TencentVideoState.PLAYING;
    }
    if (state == TencentVideoState.PAUSED) {
      pipStream!.hasManuallyPaused = setManuallyPaused ?? true;
    }
    pipStream!.state.value = state;

    if (!streamController.isClosed) {
      streamController.add(pipStream!);
    } else {
      pipStream!.controller.dispose(); //确认关闭了还接收到状态更新，直接让播放器释放
    }

    if (pipStream!.state.value == TencentVideoState.PAUSED) {
      pipStream!.hasUpdatedAudioSession = false;
    }
  }

  //是否支持PIP
  Future<bool> isDeviceSupportPIP() async {
    int? result = await SuperPlayerPlugin.isDeviceSupportPip();
    return result == TXVodPlayEvent.NO_ERROR;
  }

  //点击PIP，启动PIP程序
  startPipController(TencentVideoStream stream, int index) {
    if (pipStream != null) {
      closeFloating();
    }

    stream.controller.pause();
    stream.controller.notifyParentOnPlayerEvent = _onPlayerEventUpdate;
    stream.controller.notifyParentOnPlayerState = _onPlayerStateUpdate;
    stream.hasUpdatedAudioSession = false;

    stream.isEnteringPIPMode = true;
    pipStream = stream;

    int width = stream.controller.config.width;
    int height = stream.controller.config.height;
    if (width >= height) {
      width = 300;
      height = 183;
    } else {
      width = 171;
      height = 303;
    }

    final child = TencentVideoFloatingPlayer(
      controller: stream.controller,
      index: stream.pageIndex,
      width: width.toDouble(),
      height: height.toDouble(),
    );

    overlay.insert(navigatorKey.currentContext!, child: child);

    stream.controller.play();

    return pipStream!;
  }

  maximizeFloating() {
    if (pipStream == null) return;
    pipStream!.controller.pause();
    overlay.close();
    var stream = pipStream!;
    pipStream = null;
    stream.controller.config.onPIPMaximize!.call(stream);
  }

  void closeFloating() {
    if (pipStream == null) return;

    pipStream!.controller.pause();
    pipStream!.controller.dispose();
    pipStream!.state.value = TencentVideoState.DISPOSED;
    streamController.add(pipStream!);
    overlay.close();
    pipStream = null;
  }

  TencentVideoStreamMgr getStream() {
    var stream = TencentVideoStreamMgr();
    _streams.add(stream);
    return stream;
  }

  disposeStream(TencentVideoStreamMgr stream) {
    stream.dispose();
    _streams.remove(stream);
  }

  disposeAllStreams() {
    for (var stream in _streams) {
      stream.dispose();
    }
    _streams.clear();
  }

  @override
  Future<void> cleanup() async {
    disposeAllStreams();
    closeFloating();
    _preloadTasks.clear();
    objectMgr.callMgr.off(CallMgr.eventCallStateChanged, _onCallEventChanged);
  }

  @override
  Future<void> recover() async {}

  @override
  Future<void> registerOnce() async {}
}
