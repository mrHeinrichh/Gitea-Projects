import 'package:events_widget/event_dispatcher.dart';

final fileDownloadService = FileDownloadService.sharedInstance;

/// 新增这个类只是为了参照语音下载相关逻辑，处理文件列表里的文件下载也能同步到聊天页里面。
/// 目前没有其他功能，如果需要可以后面逐步增加这个类的功能
class FileDownloadService extends EventDispatcher {
  static final FileDownloadService sharedInstance =
      FileDownloadService._internal();

  FileDownloadService._internal();

  static const String fileDownloadComplete = 'fileDownloadComplete';
}
