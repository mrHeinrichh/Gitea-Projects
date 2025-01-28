import 'package:jxim_client/managers/metrics_mgr.dart';

import 'package:jxim_client/managers/log/log_base.dart';

final LogMgr logMgr = LogMgr();

// 日志管理器统一初始化
class LogMgr {
  final MetricsMgr metricsMgr = MetricsMgr();
  final LogUploadVideoMgr logUploadVideoMgr = LogUploadVideoMgr();
  final LogUploadImageMgr logUploadImageMgr = LogUploadImageMgr();
  final LogDownloadMgr logDownloadMgr = LogDownloadMgr();
  final LogUploadDocmentMgr logUploadDocmentMgr = LogUploadDocmentMgr();
  init() async {
    logMgr.metricsMgr.init();
    logUploadVideoMgr.init();
    logMgr.metricsMgr.init();
    logDownloadMgr.init();
    logUploadImageMgr.init();
    logUploadDocmentMgr.init();
  }
}

// ignore_for_file: public_member_api_docs, sort_constructors_first

class LogUploadVideoMgr extends LoadMgrBase<LogUploadVideoMsg> {}

class LogUploadVideoMsg extends LogMsgBase {
  LogUploadVideoMsg({
    super.type = 'UPLOAD_LOG',
    super.media_type = 'LogUploadVideo',
    required super.msg,
  });
}

class LogUploadImageMgr extends LoadMgrBase<LogUploadImageMsg> {}

class LogUploadImageMsg extends LogMsgBase {
  LogUploadImageMsg({
    super.type = 'UPLOAD_LOG',
    super.media_type = 'LogImage',
    required super.msg,
  });
}

class LogUploadDocmentMgr extends LoadMgrBase<LogUploadDocmentMsg> {}

class LogUploadDocmentMsg extends LogMsgBase {
  LogUploadDocmentMsg({
    super.type = 'UPLOAD_LOG',
    super.media_type = 'LogDocment',
    required super.msg,
  });
}

class LogDownloadMgr extends LoadMgrBase<LogDownloadMsg> {}

class LogDownloadMsg extends LogMsgBase {
  LogDownloadMsg({super.type = 'DOWNLOAD_LOG', required super.msg});
}
