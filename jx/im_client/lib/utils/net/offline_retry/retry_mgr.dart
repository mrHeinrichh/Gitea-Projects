part of 'retry_util.dart';

class RetryMgr extends BaseMgr implements TemplateMgrInterface {
  static const int retry_code = 7533967;

  static const String RETRY_PROCESS = 'RetryProcess';

  late SharedRemoteDB _sharedDB;
  late DBInterface _localDB;

  List<Retry> allRetryItems = [];

  @override
  Future<void> initialize() async {
    final tempRetry =
        await _localDB.loadAllRetryItems(RetryStatus.SYNCED_NOT_YET);
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
  Future<void> registerOnce() async {
    _sharedDB = objectMgr.sharedRemoteDB;
    _localDB = objectMgr.localDB;
    registerModel();
  }

  /// 注册模版
  @override
  Future<void> registerModel() async {
    _sharedDB.registerModel(
        DBRetry.tableName, JsonObjectPool<Retry>(Retry.creator));
  }

  //新增Retry
  Future<bool> addRetry(Retry retry) async {
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
  Future<void> updateRetry(Retry retry) async {
    _sharedDB.applyUpdateBlock(
      UpdateBlockBean.created(
        blockOptUpdate,
        DBRetry.tableName,
        retry.toJson(),
      ),
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
  Future<List<Retry>> getAllRetry() async {
    List<Map<String, dynamic>> retryList =
        await _localDB.loadAllRetryItems(RetryStatus.SYNCED_NOT_YET);

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

  Future<Retry?> getRetryById(int uid) async {
    Map<String, dynamic>? retry = await _localDB.loadRetryItem(uid);

    if (retry != null) {
      return Retry.fromJson(retry);
    }

    return null;
  }

  Future<List<Retry>> getAllEndPointRetry(String endPoint) async {
    List<Map<String, dynamic>> retryList =
        await _localDB.loadRetryItemByEndPoint(endPoint);
    return retryList.map((e) => Retry.fromJson(e)).toList();
  }

  Future<int?> deleteFinishRetry() async {
    return await _localDB.deleteFinishRetry();
  }

  static int generateNumericUUID() {
    String uuid = const Uuid().v4();
    String numericUUID = uuid.replaceAll(RegExp(r'[^0-9]'), '');
    // 32位數改取16位數避免後端陣列溢位
    String truncatedUUID = numericUUID.substring(0, 16);
    BigInt bigIntUUID = BigInt.parse(truncatedUUID);
    return bigIntUUID.toInt();
  }

  @override
  Future<void> cleanup() async {}

  @override
  Future<void> recover() async {}
}
