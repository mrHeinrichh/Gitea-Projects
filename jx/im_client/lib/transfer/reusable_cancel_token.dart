import 'package:dio/dio.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/transfer/log_util.dart';

class ReusableCancelToken extends CancelToken {
  static final LogUtil _log = LogUtil.module(LogModule.download);

  final CancelToken? _bizCancelToken;
  late CancelToken _downloadCancelToken;
  final DownloadTask _task;

  ReusableCancelToken(this._bizCancelToken, this._task) {
    _downloadCancelToken = CancelToken();
    _bizCancelToken?.whenCancel.then((value) {
      _log.info("User cancel download, taskID: ${_task.simpleID}");
      _downloadCancelToken.cancel();
      _task.dequeue();
    });
  }

  @override
  DioException? get cancelError => _downloadCancelToken.cancelError;

  @override
  RequestOptions? get requestOptions => _downloadCancelToken.requestOptions;

  @override
  bool get isCancelled => _downloadCancelToken.isCancelled;

  @override
  Future<DioException> get whenCancel => _downloadCancelToken.whenCancel;

  @override
  void cancel([Object? reason]) {
    _downloadCancelToken.cancel(reason);
    _downloadCancelToken = CancelToken();
  }
}