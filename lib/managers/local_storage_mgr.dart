// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:events_widget/event_dispatcher.dart';
import 'package:jxim_client/managers/lang_mgr.dart';
import 'package:jxim_client/utils/local_storage.dart';

class LocalStorageMgr extends EventDispatcher {
  static const String START_APP_TIME = "START_APP_TIME";
  static const String PUSH_MESSAGE_STATE = "PUSH_MESSAGE_STATE";
  static const String PUSH_MESSAGE_ORDER = "PUSH_MESSAGE_ORDER";
  static const String CHAT_FAKE_DATA = 'CHAT_FAKE_DATA';
  static const String PASTE_IMD_IDX = 'PASTE_IMD_IDX'; //复制图片索引
  static const String CHAT_C2C_KEYS = "CHAT_C2C_KEYS"; // C2C会话key
  static const String RECENT_EMOJIS = "RECENT_EMOJIS"; //最近使用的emoji
  static const String RECENT_STICKERS = "RECENT_STICKERS"; //最近使用的贴纸
  static const String RECENT_GIFS = "RECENT_GIFS"; //最近使用的gif
  static const String ALL_STICKERS = "ALL_STICKERS"; //全部贴纸（下载逻辑用途）
  static const String FAV_STICKERS = "FAV_STICKERS"; //最爱贴纸
  static const String ALL_GIFS = "ALL_GIFS"; //最爱贴纸
  static const String FAV_GIFS = "FAV_GIFS"; //最爱贴纸
  static const String OFFLINE_REQUEST = "OFFLINE_REQUEST"; //离线请求
  static const String PUSH_INFO = "PUSH_NOTIFICATION_INFO";
  static const String LAST_ACTIVE_TIME = "LAST_ACTIVE_TIME"; //最后在线时间
  // static const String TRANSLATION = "TRANSLATION"; //语言
  static const String LATEST_APP_VERSION = "LATEST_APP_VERSION"; //最新版本号
  static const String MIN_APP_VERSION = "MIN_APP_VERSION"; //最低版本号
  static const String APP_UPDATE_NOTIFICATION =
      "APP_UPDATE_NOTIFICATION"; //最新版本号 (if true -> 有版本更新)
  static const String CONTACT_SORT = "CONTACT_SORT"; //联系人排序
  static const String DEVELOPER_MODE = "DEVELOPER_MODE"; //开发者模式
  static const String QR_CODE_DURATION = "QR_CODE_DURATION"; //扫描二维码时间
  static const String QR_CODE_TIME = "QR_CODE_TIME"; //生成添加好友二维码时间
  static const String QR_CODE_SECRET_URL = "QR_CODE_SECRET_URL"; //添加好友二维码URL
  static const String TIME_FORMAT = "TIME_FORMAT"; //时间格式
  static const String DATE_FORMAT = "DATE_FORMAT"; //日期格式

  static const String WALLET = "WALLET";
  static const String SET_PASSWORD = "SET_PASSWORD";
  static const String HIDE_VALUE = "HIDE_VALUE";

  static const String CHAT_LIST_FETCH_TIME = 'CHAT_LIST_FETCH_TIME_V14';

  //DB的version始终和app version一致，发现不一致，需要检查各个表是否有新的属性增加
  static const String LAST_DB_VERSION = 'LAST_DB_VERSION';

  static const String LAST_APP_VERSION_FOR_DUN = 'LAST_APP_VERSION_FOR_DUN';

  static const String LAST_APP_CALL_LOG = 'LAST_APP_CALL_LOG';

  /// notification
  static const String PRIVATE_CHAT_NOTIFICATION = "PRIVATE_CHAT_NOTIFICATION";
  static const String GROUP_CHAT_NOTIFICATION = "GROUP_CHAT_NOTIFICATION";
  static const String WALLET_NOTIFICATION = "WALLET_NOTIFICATION";
  static const String FRIEND_NOTIFICATION = "FRIEND_NOTIFICATION";
  static const String MESSAGE_SOUND_NOTIFICATION = "MESSAGE_SOUND_NOTIFICATION";

  /// Reel
  static const String REEL_SEARCH_HISTORY = "REEL_SEARCH_HISTORY";

  static const String KEYBOARD_HEIGHT = "KEYBOARD_HEIGHT";

  static const String DOWNLOAD_CACHE_SUB_VALUE = "DOWNLOAD_CACHE_SUB_VALUE";

  static const String MOMENT_TAG = "MOMENT_TAG";
  static const String MOMENT_POST_LIST = "MOMENT_POST_LIST";
  static const String MOMENT_COVER_PATH = "MOMENT_COVER_PATH";
  static const String MOMENT_AVAILABLE_DAYS = "MOMENT_AVAILABLE_DAYS";
  static const String MOMENT_MY_POSTS = "MOMENT_MY_POSTS";
  static const String MOMENT_MY_POSTS_COVER = "MOMENT_MY_POSTS_COVER";
  static const String MOMENT_RETRY_LOG = "MOMENT_RETRY_LOG";

  static const String REEL_POST_LIST = "REEL_POST_LIST";
  static const String REEL_UPLOAD_TAG_LIST = "REEL_UPLOAD_TAG_LIST";

  static const String INSTALL_DATE = "INSTALL_DATE";
  static const String MIRROR_FRONT_CAMERA = "MIRROR_FRONT_CAMERA";

  static const String DATA_AND_STORAGE = "DATA_AND_STORAGE";
  static const String TOTAL_SIZE = "TOTAL_SIZE";

  static const String FAVOURITE_TAG = "FAVOURITE_TAG";

  // 加密
  static const String ENCRYPTION_PUBLIC_KEY = "ENCRYPTION_PUBLIC_KEY";
  static const String ENCRYPTION_PRIVATE_KEY = "ENCRYPTION_PRIVATE_KEY";
  static const String MUTE_PRIVATE_KEY_UPDATE = "MUTE_PRIVATE_KEY_UPDATE";
  static const String SHOWN_VERIFICATION_NAVIGATION = "SHOWN_VERIFICATION_NAVIGATION";
   static const String SIGN_CHAT_MESSAGE = "SIGN_CHAT_MESSAGE";

  final LocalStorage _localStorage = LocalStorage.create();

  //AES加密
  final IV iv = IV.fromLength(16);
  Encrypter encryptor = Encrypter(AES(Key.fromLength(32)));

  // 初始化
  Future<void> init() async {
    await _localStorage.init();
  }

  int _userID = 0;

  /// 用户id
  int get userID => _userID;

  // 初始化用户
  Future<void> initUser(int value) async {
    _userID = value;
  }

  // 获取指定用戶的本地存储key
  String _getKeyByUser(String key) {
    if (_userID != 0) {
      key = "${_userID}_$key";
    }
    return key;
  }

  // 退出登录
  void logout() {
    // 是否需要清理userid
  }

  /// 本地缓存玩家数据
  Future<bool> putLocalTable(String tableName, dynamic data) async {
    return write("localData:$tableName", data);
  }

  Future<bool> delLocalTable(String tableName, [bool private = false]) async {
    if (getLocalTable(tableName) == null) {
      return false;
    }
    return remove("localData:$tableName", private: private);
  }

  List<dynamic>? getLocalTable(String tableName) {
    var value = read<String>("localData:$tableName");
    if (value != null) {
      return jsonDecode(value);
    }
    return null;
  }

  T? getLocalTableByType<T>(String tableName) {
    var value = read<T>("localData:$tableName");
    return value;
  }

  Future<bool> putTemplateTable(String tableName, dynamic data) {
    return putLocalTable(tableName, data);
  }

  List<dynamic>? getTemplateTable(String tableName) {
    return getLocalTable(tableName);
  }

  // 写入本地存储
  Future<bool> write<T>(String key, T value) async {
    if (key == ALL_STICKERS ||
        key == LangMgr.langKey ||
        key == KEYBOARD_HEIGHT ||
        // key == TRANSLATION ||
        key == DEVELOPER_MODE ||
        key == DOWNLOAD_CACHE_SUB_VALUE) {
      return _localStorage.write(key, value);
    }
    return _localStorage.write('${userID}_$key', value);
  }

  // app级别写入本地存储
  Future<bool> globalWrite<T>(String key, T value) async {
    if (key == ALL_STICKERS ||
        key == LangMgr.langKey ||
        key == KEYBOARD_HEIGHT ||
        key == DOWNLOAD_CACHE_SUB_VALUE ||
        key == INSTALL_DATE) {
      return _localStorage.write(key, value);
    }
    return _localStorage.write(key, value);
  }

  // 写入本地存储
  Future<bool> writeSecurely<T>(
    String key,
    T value, {
    bool iSecure = false,
  }) async {
    //加密后把字段存入本地数据库
    final String cipherText = encryptor.encrypt(value as String, iv: iv).base64;
    return _localStorage.write(key, cipherText);
  }

  // 写入本地存储
  Future<bool> remove(String key, {bool private = false}) {
    if (private) {
      key = _getKeyByUser(key);
    }

    return _localStorage.remove(key);
  }

  // 读取本地存储
  T? read<T>(String key) {
    if (key == ALL_STICKERS ||
        key == LangMgr.langKey ||
        key == KEYBOARD_HEIGHT ||
        // key == TRANSLATION ||
        key == DEVELOPER_MODE ||
        key == DOWNLOAD_CACHE_SUB_VALUE) {
      return _localStorage.read(key);
    }
    return _localStorage.read<T>('${userID}_$key');
  }

  // app级别读取本地存储
  T? globalRead<T>(String key) {
    if (key == ALL_STICKERS ||
        key == LangMgr.langKey ||
        key == KEYBOARD_HEIGHT ||
        key == DOWNLOAD_CACHE_SUB_VALUE ||
        key == INSTALL_DATE) {
      return _localStorage.read(key);
    }
    return _localStorage.read<T>(key);
  }

  String? readSecurely(String key) {
    //从数据库获取加密后的字段
    String? result = _localStorage.read<String>(key);
    if (result == null) return null;
    //开始解密
    final List<int> decryptedData =
        encryptor.decryptBytes(Encrypted.fromBase64(result), iv: iv);
    return utf8.decode(decryptedData);
  }

  Set<String>? getKeys() {
    return _localStorage.getKeys();
  }

  Future<bool> cleanAll() {
    return _localStorage.cleanAll();
  }

  Future<void> reload() async {
    return _localStorage.reload();
  }

  Future<bool> writeChatC2CKeys(Map<String, dynamic>? value) {
    return write(CHAT_C2C_KEYS, value);
  }

  Map<String, dynamic>? readChatC2CKeys() {
    return read(CHAT_C2C_KEYS);
  }
}
