import 'package:dio/dio.dart';
import 'package:jxim_client/transfer/download_config.dart';

class ProgressCallbackFactory {
  static ProgressCallback newProgressCallback(
      ProgressCallback? progressCallback,
      Stopwatch stopwatch,
      int startPos,
      Function(bool isWeakNet) updateIsWeakNet,
      int? Function() fileLen) {
    int lastElapsedTimeMs = 0;
    int lastBytes = 0;
    int lowSpeedCount = 0;
    return (count, total) {
      if (fileLen() != null) {
        progressCallback?.call(count + startPos, fileLen()!);
      }

      int elapsedTimeMs = stopwatch.elapsedMilliseconds;
      double curSpeed =
          (count - lastBytes) / (elapsedTimeMs - lastElapsedTimeMs) * 1000;
      lastElapsedTimeMs = elapsedTimeMs;
      lastBytes = count;

      if (curSpeed < DownloadConfig().WEAK_NET_SPEED_THRESHOLD_BYTES) {
        lowSpeedCount++;
      } else {
        lowSpeedCount = 0;
      }

      updateIsWeakNet(
          lowSpeedCount > DownloadConfig().WEAK_NET_LOW_SPEED_COUNT_THRESHOLD);
    };
  }
}
