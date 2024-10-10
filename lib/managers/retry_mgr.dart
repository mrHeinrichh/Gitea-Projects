
import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/data/db_retry.dart';
import 'package:jxim_client/data/db_interface.dart';
import 'package:jxim_client/data/object_pool.dart';
import 'package:jxim_client/data/shared_remote_db.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/retry.dart';
import 'package:jxim_client/utils/net/offline_retry/retry_util.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:uuid/uuid.dart';

class RetryMgr extends EventDispatcher implements MgrInterface,TemplateMgrInterface,SqfliteMgrInterface
{
  static const String RETRY_PROCESS = 'RetryProcess';

  late SharedRemoteDB _sharedDB;
  late DBInterface _localDB;

  List<Retry> allRetryItems = [];

  @override
  Future<void> init() async {
    final tempRetry = await _localDB.loadAllRetryItems(RetryStatus.SYNCED_NOT_YET);
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBRetry.tableName,
        tempRetry,
      ),
      save: false,
      notify: false,
    );
  }

  @override
  Future<void> register() async {
    _sharedDB = objectMgr.sharedRemoteDB;
    _localDB = objectMgr.localDB;
    registerModel();
    registerSqflite();
  }

  /// 注册模版
  @override
  Future<void> registerModel() async {
    _sharedDB.registerModel(DBRetry.tableName, JsonObjectPool<Retry>(Retry.creator));
  }

  @override
  Future<void> registerSqflite() async {
    _localDB.registerTable('''
        CREATE TABLE IF NOT EXISTS  retry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid INTEGER, 
        api_type TEXT DEFAULT "",
        end_point TEXT DEFAULT "",
        request_data TEXT DEFAULT "",
        synced INTEGER,
        callback_fun TEXT DEFAULT "",
        expired INTEGER,
        replace INTEGER,
        expire_time INTEGER,
        create_time INTEGER,                
        __add_index INTEGER
        );
        ''');
  }

  @override
  Future<void> reloadData() async {
  }

  @override
  Future<void> logout() async {

  }

  //新增Retry
  Future<bool> addRetry(Retry retry) async
  {
    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBRetry.tableName,
        [retry.toJson()],
      ),
      save: true,
      notify: false,
    );
    return true;
  }

  //更新Retry
  Future<void> updateRetry(Retry retry) async
  {
    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptUpdate,
        DBRetry.tableName,
        retry.toJson(),
      ),
      save: true,
      notify: false,
    );
  }

  //刪除Retry的方法
  Future<void> deleteRetry(int uid) async {
    await _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptDelete,
        DBRetry.tableName,
        uid,
      ),
      save: true,
      notify: false,
    );
  }

  ///取得所有Retry的方法:
  ///synced: 0:未同步 1:已同步 -1:同步失敗
  Future<List<Retry>> getAllRetry() async
  {
    List<Map<String, dynamic>> retryList = await _localDB.loadAllRetryItems(RetryStatus.SYNCED_NOT_YET);

    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptReplace,
        DBRetry.tableName,
        retryList,
      ),
      save: false,
      notify: false,
    );

    return retryList.map((e) => Retry.fromJson(e)).toList();
  }

  Future<Retry?> getRetryById(int uid) async
  {
    Map<String, dynamic>? retry = await _localDB.loadRetryItem(uid);

    if(retry != null) {
      return Retry.fromJson(retry);
    }

    return null;
  }

  Future<List<Retry>> getAllEndPointRetry(String endPoint) async
  {
    List<Map<String, dynamic>> retryList = await _localDB.loadRetryItemByEndPoint(endPoint);
    return retryList.map((e) => Retry.fromJson(e)).toList();
  }

  static int generateNumericUUID() {
    String uuid = const Uuid().v4();
    String numericUUID = uuid.replaceAll(RegExp(r'[^0-9]'), '');
    //32位數改取16位數避免後端陣列溢位
    return int.parse(numericUUID.substring(0, 16));
  }
}