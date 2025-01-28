import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';

final KiWiMgr kiwiMgr = KiWiMgr();

class KiWiMgr {
  final MessageLog _messageLog = MessageLog();

  Future<void> initKiwi() async {
    final start = DateTime.now().millisecondsSinceEpoch;
    _messageLog.updateInfo(MessageModule.kiwi, startTime: start);
    await serversUriMgr.initApi();

    _messageLog.updateInfo(
      MessageModule.kiwi,
      endTime: DateTime.now().millisecondsSinceEpoch,
      shouldAddLog: true,
    );
  }
}
