import 'package:jxim_client/transfer/download_channel.dart';
import 'package:jxim_client/transfer/download_mgr.dart';

/// 通道开关状态判断策略
abstract class DownloadChannelStatePolicy {
  late final DownloadMgrContext _context;

  DownloadChannelStatePolicy(this._context);

  bool enable(DownloadChannel channel) {
    if(_condition(channel)) {
      return true;
    }

    if (_cancelTaskWhenDownloading()) {
      channel.cancelTask();
    }

    return false;
  }

  bool _condition(DownloadChannel channel);

  bool _cancelTaskWhenDownloading();
}

/// 弱网策略
class WeakNetChannelStatePolicy extends DownloadChannelStatePolicy {
  WeakNetChannelStatePolicy(super._context);

  @override
  bool _condition(DownloadChannel channel) {
    return !_context.weakNet || channel.channelType == ChannelType.smallExclusive;
  }

  @override
  bool _cancelTaskWhenDownloading() {
    return true;
  }
}

/// 无网/连网策略
class NetworkStateChannelStatePolicy extends DownloadChannelStatePolicy {
  NetworkStateChannelStatePolicy(super._context);

  @override
  bool _condition(DownloadChannel channel) {
    return _context.networkOpen;
  }

  @override
  bool _cancelTaskWhenDownloading() {
    return false;
  }
}

/// Wi-Fi/蜂窝网络策略
class NetworkTypeChannelStatePolicy extends DownloadChannelStatePolicy {
  NetworkTypeChannelStatePolicy(super._context);

  @override
  bool _condition(DownloadChannel channel) {
    return _context.netType == NetType.wifi || channel.cellularEnable;
  }

  @override
  bool _cancelTaskWhenDownloading() {
    return false;
  }
}