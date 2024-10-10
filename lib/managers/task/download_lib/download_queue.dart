part of 'download_util.dart';

class DownLoadQueue {
  Future<String?> downloadQueue(
    String downloadUrl, {
    Duration timeout = const Duration(seconds: 300),
    int? mini,
    Function(int bytes, int totalBytes)? onReceiveProgress,
    int priority = 0, // 任务优先级
    CancelToken? cancelToken,
  }) async {
    if (downloadUrl.isEmpty) {
      return null;
    }
    // 防止拿本地缓存地址去下载
    if (downloadUrl.contains(downloadMgr.appCacheRootPath) ||
        downloadUrl.contains(downloadMgr.appDocumentRootPath)) {
      pdebug(
          '========================================================下载地址错误,请检查 $downloadUrl');
      return null;
    }

    String? localFileUrl = downloadMgr.checkLocalFile(downloadUrl, mini: mini);
    if (localFileUrl != null) {
      return localFileUrl;
    }
    pdebug('触发下载任务=======================> $downloadUrl');

    final savePath = downloadMgr.getSavePath(downloadUrl, mini: mini);

    Uri? finalRedirectUrl;

    final Uri? originUri =
        await downloadMgr.getDownloadUri(downloadUrl, mini: mini);
    if (originUri == null) return null;

    // 过盾下载地址校验
    if (isLocalhost(originUri.host)) {
      bool isValid = false;
      for (String validUrl in _HostValidAddress) {
        if (downloadUrl.contains(validUrl)) {
          isValid = true;
          break;
        }
      }
      if (!isValid) {
        pdebug(
            '========================================================走盾的下载地址错误,请检查 $downloadUrl');
        return null;
      }
    }
    cancelToken ??= CancelToken();
    Future<void> future = queueDownloadTaskMgr.addTask(
      QueueDownloadTask(
        id: originUri.toString(),
        timeout: timeout,
        priority: priority,
        task: (cancelToken, shouldRedirect, timeout) async {
          late final Uri finalUri;
          if (shouldRedirect) {
            finalRedirectUrl ??= await downloadMgr.getDownloadUri(
              downloadUrl,
              mini: mini,
              shouldRedirect: shouldRedirect,
            );
            finalUri = finalRedirectUrl!;
          } else {
            finalUri = originUri;
          }

          try {
            final response = await DioUtil.instance.downloadUriFile(
              finalUri,
              savePath,
              onReceiveProgress: onReceiveProgress,
              cancelToken: cancelToken,
              options: Options(
                sendTimeout: timeout,
                receiveTimeout: timeout,
              ),
            );
            final statusCode = response.statusCode;
            if (statusCode == HttpStatus.ok) {
              return QueueDownloadResultEnum.finished;
            } else if (statusCode == HttpStatus.found ||
                statusCode == HttpStatus.notFound ||
                response.statusCode == HttpStatus.forbidden) {
              return QueueDownloadResultEnum.redirect;
            } else {
              return QueueDownloadResultEnum.failed;
            }
          } on DioException catch (e) {
            final statusCode = e.response?.statusCode;
            // 如果response 不存在直接重试
            if (statusCode == HttpStatus.found ||
                statusCode == HttpStatus.notFound ||
                statusCode == HttpStatus.forbidden) {
              return QueueDownloadResultEnum.redirect;
            }
            rethrow;
          } catch (e) {
            rethrow;
          }
        },
        onComplete: onTaskComplete,
        onStart: onTaskStart,
        cancelToken: cancelToken,
      ),
    );

    final localUrl = await future.then((value) {
      String? localFileUrl =
          downloadMgr.checkLocalFile(downloadUrl, mini: mini);
      if (localFileUrl != null && localFileUrl.isNotEmpty) {
        pdebug('触发下载任务完成=======================> $downloadUrl');
        return localFileUrl;
      } else {
        pdebug('触发下载任务失败=======================> $downloadUrl');
        return null;
      }
    }).catchError((onError) {
      return null;
    });
    pdebug('触发下载任务返回结果=======================> $localUrl');
    return localUrl;
  }

  void onTaskComplete(QueueDownloadTaskEnum status, String str) {
    pdebug("QUEUE download Task completed ID:$str status: $status");
  }

  // 创建一个任务开始回调函数
  void onTaskStart(String str) {
    pdebug("QUEUE download Task started ID:$str");
  }
}

// 走盾有效地址
final _HostValidAddress = [
  'Image',
  'Document',
  'Sticker',
  'Reels',
  'Video',
  'sticker',
  'avatar',
  'group',
  'enc',
  'file',
  'static',
  'app/api',
];
