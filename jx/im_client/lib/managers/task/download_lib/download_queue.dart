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

    String? localFileUrl = downloadMgrV2.getLocalPath(downloadUrl, mini: mini);
    if (localFileUrl != null) {
      return localFileUrl;
    }

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

    int? contentTotal;

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

            contentTotal =
                !response.headers.map.containsKey(Headers.contentLengthHeader)
                    ? null
                    : response.data?.contentLength;

            if (contentTotal != null && contentTotal! > 0) {
              SumDownloadAnalytics.sharedInstance.updateDownloadStatistic(
                AnalyticsHelper.getFileType(contentTotal),
                downloadBytes: contentTotal,
              );
            }
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
            pdebug('触发下载异常=======================> ${e.toString()}');
            rethrow;
          }
        },
        onComplete: (status, str, createTime) => onTaskComplete(
          status,
          str,
          createTime,
          contentTotal,
        ),
        onStart: onTaskStart,
        cancelToken: cancelToken,
      ),
    );

    String? localUrl = await future.then((_) {
      return savePath;
    }).catchError((_) {
      return '';
    });
    localUrl = localUrl == '' ? null : localUrl;
    return localUrl;
  }

  void onTaskComplete(
    QueueDownloadTaskEnum status,
    String str,
    int createTime,
    int? contentTotal,
  ) {
    pdebug("触发下载任务返回结果 QUEUE download Task completed ID:$str status: $status");
    switch (status) {
      case QueueDownloadTaskEnum.finished:
        SumDownloadAnalytics.sharedInstance.updateDownloadStatistic(
          AnalyticsHelper.getFileType(contentTotal),
          downloadSuccessKey: true,
          downloadDuration: DateTime.now().millisecondsSinceEpoch - createTime,
        );
        break;
      case QueueDownloadTaskEnum.failed:
        SumDownloadAnalytics.sharedInstance.updateDownloadStatistic(
          AnalyticsHelper.getFileType(contentTotal),
          downloadFailedKey: true,
          downloadDuration: DateTime.now().millisecondsSinceEpoch - createTime,
        );
        break;
      default:
        break;
    }
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
  'Speedtest'
];
