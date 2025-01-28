import 'package:jxim_client/transfer/download_channel.dart';
import 'package:jxim_client/transfer/download_config.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_queue.dart';
import 'package:jxim_client/transfer/download_task.dart';

/// 通道拉取任务策略接口
abstract class ChannelPolicy {
  Future<DownloadTask> pull(DownloadQueue queue);

  ChannelType channelType();

  Duration getDioSendTimeoutMs();

  Duration getDioReceiveTimeoutMs();
}

/// 小文件专属通道拉取任务策略
class SmallExclusiveChannelPolicy implements ChannelPolicy {
  @override
  ChannelType channelType() {
    return ChannelType.smallExclusive;
  }

  @override
  Future<DownloadTask> pull(DownloadQueue queue) async {
    return queue.fetchFirstReadyTask(DownloadType.smallFile, false);
  }

  @override
  Duration getDioSendTimeoutMs() {
    return Duration(
        milliseconds: DownloadConfig().SMALL_FILE_DIO_SEND_TIMEOUT_MS);
  }

  @override
  Duration getDioReceiveTimeoutMs() {
    return Duration(
        milliseconds: DownloadConfig().SMALL_FILE_DIO_RECEIVE_TIMEOUT_MS);
  }
}

/// 小文件优先共享通道拉取任务策略
class SmallFirstSharedChannelPolicy implements ChannelPolicy {
  @override
  ChannelType channelType() {
    return ChannelType.smallFirstShared;
  }

  @override
  Future<DownloadTask> pull(DownloadQueue queue) {
    DownloadTask? task =
        queue.tryFetchFirstReadyTask(DownloadType.smallFile, false);
    if (task != null) {
      return Future.value(task);
    }

    return Future.any([
      queue.fetchFirstReadyTask(DownloadType.smallFile, false),
      queue.fetchFirstReadyTask(DownloadType.largeFile, false)
    ]);
  }

  @override
  Duration getDioSendTimeoutMs() {
    return Duration(
        milliseconds: DownloadConfig().LARGE_FILE_DIO_SEND_TIMEOUT_MS);
  }

  @override
  Duration getDioReceiveTimeoutMs() {
    return Duration(
        milliseconds: DownloadConfig().LARGE_FILE_DIO_RECEIVE_TIMEOUT_MS);
  }
}

/// 大文件专属通道拉取任务策略
class LargeChannelPolicy implements ChannelPolicy {
  @override
  ChannelType channelType() {
    return ChannelType.largeExclusive;
  }

  @override
  Future<DownloadTask> pull(DownloadQueue queue) {
    return queue.fetchFirstReadyTask(DownloadType.largeFile, false);
  }

  @override
  Duration getDioSendTimeoutMs() {
    return Duration(
        milliseconds: DownloadConfig().LARGE_FILE_DIO_SEND_TIMEOUT_MS);
  }

  @override
  Duration getDioReceiveTimeoutMs() {
    return Duration(
        milliseconds: DownloadConfig().LARGE_FILE_DIO_RECEIVE_TIMEOUT_MS);
  }
}

/// 后台通道拉取任务策略
class BackgroundChannelPolicy implements ChannelPolicy {
  @override
  ChannelType channelType() {
    return ChannelType.background;
  }

  @override
  Future<DownloadTask> pull(DownloadQueue queue) {
    return queue.fetchFirstReadyTask(DownloadType.background, false);
  }

  @override
  Duration getDioSendTimeoutMs() {
    return Duration(
        milliseconds: DownloadConfig().BACKGROUND_FILE_DIO_SEND_TIMEOUT_MS);
  }

  @override
  Duration getDioReceiveTimeoutMs() {
    return Duration(
        milliseconds: DownloadConfig().BACKGROUND_FILE_DIO_RECEIVE_TIMEOUT_MS);
  }
}

/// 重试通道拉取任务策略
class RetryChannelPolicy implements ChannelPolicy {
  @override
  ChannelType channelType() {
    return ChannelType.retry;
  }

  @override
  Future<DownloadTask> pull(DownloadQueue queue) {
    return Future.any([
      queue.fetchFirstReadyTask(DownloadType.smallFile, true),
      queue.fetchFirstReadyTask(DownloadType.largeFile, true)
    ]);
  }

  @override
  Duration getDioSendTimeoutMs() {
    return Duration(
        milliseconds: DownloadConfig().RETRY_FILE_DIO_SEND_TIMEOUT_MS);
  }

  @override
  Duration getDioReceiveTimeoutMs() {
    return Duration(
        milliseconds: DownloadConfig().RETRY_FILE_DIO_RECEIVE_TIMEOUT_MS);
  }
}
