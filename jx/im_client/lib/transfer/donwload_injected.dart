import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';

class DownloadInjected {
  static final DownloadInjected _instance = DownloadInjected._internal();

  static late final LocalStorageMgr _localStorageMgr;

  static late final ServersUriMgr _serversUriMgr;

  static late final SocketMgr _socketMgr;

  DownloadInjected._internal();

  factory DownloadInjected() {
    return _instance;
  }

  static init(ServersUriMgr serversUriMgr, LocalStorageMgr localStorageMgr, SocketMgr socketMgr) {
    _serversUriMgr = serversUriMgr;
    _localStorageMgr = localStorageMgr;
    _socketMgr = socketMgr;
  }

  ServersUriMgr get serversUriMgr => _serversUriMgr;

  LocalStorageMgr get localStorageMgr => _localStorageMgr;

  SocketMgr get socketMgr => _socketMgr;
}
