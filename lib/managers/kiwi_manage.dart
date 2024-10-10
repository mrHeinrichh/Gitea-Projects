import 'package:jxim_client/network/servers_uri_mgr.dart';

final KiWiMgr kiwiMgr = KiWiMgr();
class KiWiMgr{
  
    Future<void> initKiwi() async{
      await serversUriMgr.initApi();
    }
}
