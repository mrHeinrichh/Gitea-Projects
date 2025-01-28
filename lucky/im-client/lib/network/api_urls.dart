import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// api接口网络相关
final apiUrls = ApiUrls();

const _PersistenceKey = '56c51dbc887d0487f942e6fca95108e4';

/// 加密持久化
class _Util {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  _Util() {
    // mypdebug('解密:${decrypt2Base64(_ApiUrlsHost)}');
  }

  ///AES+Base64加密
  String encrypt2Base64(String data, {String? keyStr}) {
    if (data == null || data.isEmpty) {
      return data;
    }
    var encrypted = encrypt(keyStr ?? _PersistenceKey, data);
    var content = const Base64Encoder().convert(encrypted);
    return content;
  }

  ///AES+Base64解密
  String decrypt2Base64(String? data, {String? keyStr}) {
    if (data == null || data.isEmpty) {
      return data ?? '';
    }
    final r = RegExp('\n');
    var newData = data.replaceAll(r, '');
    var decrypted = const Base64Decoder().convert(newData);
    var content = decrypt(keyStr ?? _PersistenceKey, decrypted);
    return content;
  }

  ///AES加密
  Uint8List encrypt(String keyStr, String data) {
    final key = Uint8List.fromList(keyStr.codeUnits);
    var params = PaddedBlockCipherParameters(KeyParameter(key), null);
    final encryptionCipher = PaddedBlockCipher('AES/ECB/PKCS7');
    encryptionCipher.init(true, params);
    var encryData = utf8.encode(data);
    return encryptionCipher.process(Uint8List.fromList(encryData));
  }

  ///AES解密
  String decrypt(String keyStr, Uint8List data) {
    final key = Uint8List.fromList(keyStr.codeUnits);
    CipherParameters params =
        PaddedBlockCipherParameters(KeyParameter(key), null);
    BlockCipher decryptionCipher = PaddedBlockCipher('AES/ECB/PKCS7');
    decryptionCipher.init(false, params);
    var decrypted = utf8.decode(decryptionCipher.process(data));
    return decrypted;
  }

  bool _isSpare = false;
  set isSpare(bool b) {
    _isSpare = b;
  }

  bool get isSpare => _isSpare;

  Future<String> getString(String key) async {
    var ekey = encrypt2Base64(key);
    var val;
    final prefs = await _prefs;
    try {
      var s = prefs.getString(ekey);
      val = decrypt2Base64(s!);
    } catch (e) {
      mypdebug('getString:$e');
    }
    return val ?? "";
  }

  Future<void> setString(String key, String value) async {
    var eKey = encrypt2Base64(key);
    final prefs = await _prefs;
    if (value != null && value != "") {
      var eValue = encrypt2Base64(value);
      await prefs.setString(eKey, eValue);
    } else {
      await prefs.remove(eKey);
    }
  }

  Future<void> setMap(String key, Map data) async {
    var value = jsonEncode(data);
    setString(key, value);
  }

  Future<Map?> getMap(String key) async {
    try {
      var str = await getString(key);
      if (str == null || str == "") {
        return null;
      }
      return jsonDecode(str);
    } catch (e) {
      mypdebug("getMap :$e");
    }
    return null;
  }


  Future<Map?> httpGetJson(Uri url) async {
    for (var i = 0; i < 1; i++) {
      try {
        var rep = await httpGet(url);
        if (rep == null) {
          // 如果下载失败,超时等待一下
          // await Future.delayed(Duration(seconds: i + 1));
          continue;
        }

        if (rep is String) {
          rep = decrypt2Base64(rep);
          if (rep != null) {
            // mypdebug('解析域名地址${url.toString()}');
            return jsonDecode(rep);
          }
        }
      } catch (e) {
        mypdebug('httpGetJson jsonDecode:$e');
      }
    }
    return null;
  }

  /// 通过http取得api配置信息
  Future<dynamic> httpGet(Uri url) async {
    //因为正常执行都是成功的，所以不用把这个对象放到循环外
    var httpClient = HttpClient();
    try {
      var request = await httpClient.getUrl(url);
      var rep = await request.close();
      var status = rep.statusCode;
      var utf8Stream = rep.transform(Utf8Decoder());
      var responseBody = await utf8Stream.join();

      //如果没有正确返回则将返回值置空
      if (status != HttpStatus.ok) {
        mypdebug('dartGet status:$status body:$responseBody');
        return null;
      }
      return responseBody;
    } catch (e) {
      mypdebug('httpGet :$e');
      return null;
    } finally {
      httpClient.close();
    }
  }

  /// 测试tcp ip 及端口能不能通
  Future<int> tcping(url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return -1;
      if (!uri.hasScheme) {
        uri.replace(scheme: 'http');
      }
      if (!uri.hasPort) {
        uri.replace(port: uri.isScheme('https') ? 443 : 80);
      }
      mypdebug('过盾tcping测试开始');
      final sock = await Socket.connect(uri.host, uri.port,
          timeout: const Duration(seconds: 5));

      if (sock == null) {
        return -2;
      }
      sock.close();
      return 0;
    } catch (e) {
      mypdebug('过盾tcping测试结束');
      return -3;
    }
  }

  //测试当前地址get请求是否可以访问
  Future<int> geting(url) async {
    var httpClient = HttpClient();
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return -1;
      if (!uri.hasScheme) {
        uri.replace(scheme: 'http');
      }
      if (!uri.hasPort) {
        uri.replace(port: uri.isScheme('https') ? 443 : 80);
      }
      Uri a = uri.replace(path: '/index/hello');
      var request = await httpClient.getUrl(a);
      var rep = await request.close();
      var status = rep.statusCode == 200 ? 0 : rep.statusCode;
      return status;
    } catch (e) {
      return -3;
    }
  }
}

class ApiUrls extends _Util {
  /// api最新主机地址
  String get dunUrl {
    return _dunUrl;
  }

  /// 当前游戏盾密钥
  String get dunKey {
    return _dunKey;
  }

  /// 最新防御节点组
  String get dunKiwiStart {
    // var temp = dataMgr.getConfig(ConfigKeys.kiwiStarts);
    // if (temp == null && !apiUrls.isSpare) {
    //   return '';
    // }
    // if (serviceApi.isAuth! && !apiUrls.isSpare) {
    //   return dataMgr.getConfig(ConfigKeys.kiwiStarts);
    // }
    return _dunKiwiStart;
  }

  String _dunUrl = "";
  String _dunKey = "";
  String _dunKiwiStart = "";

  /// 从json中读取地址,如果盾配置发生变化则需要重新初始化
  Future<bool> fromJson(Map json) async {
    var ret = false;
    var dunKey = json.containsKey('key') ? json['key'] : '';
    if (_dunKey != dunKey) {
      _dunKey = dunKey;
      // key发生变化，需要大退重进
      _needReInit = true;
      ret = true;
    }

    var dunUrl = json.containsKey('api') ? json['api'] : '';
    if (_dunUrl != dunUrl) {
      _dunUrl = dunUrl;
      ret = true;
    }

    var dunKiwiStart = json.containsKey('kiwiStart') ? json['kiwiStart'] : '';
    if (_dunKiwiStart != dunKiwiStart) {
      _dunKiwiStart = dunKiwiStart;
      ret = true;
    }
    // 说明值发生变化
    return Future.value(ret);
  }

  bool _needReInit = false;

  /// 需要重新初始化
  bool get needReInit => _needReInit;

  /// 第一次初始化
  Future<bool> init(String url, String key, String dunKiwiStart) async {
    assert(url.isNotEmpty);

    // final v = await getString('ApiUrls.dunUrl' + _appVersion);
    // if (v == "") {
    //   _dunUrl = url;
    //   _dunKey = key;
    //   _dunKiwiStart = dunKiwiStart;
    //   await _saveToLocal();
    //   return true;
    // }
    //
    // this._dunUrl = await getString('ApiUrls.dunUrl' + _appVersion);
    // if (this._dunUrl == "") {
    //   return false;
    // }
    // this._dunKey = await getString('ApiUrls.dunKey' + _appVersion);
    // this._dunKiwiStart = await getString('ApiUrls.dunKiwiStart' + _appVersion);

    
    _dunUrl = url;
    _dunKey = key;
    _dunKiwiStart = dunKiwiStart;
    await _saveToLocal();
    return true;
  }

  /// 将api的信息持久化到硬盘
  Future<void> _saveToLocal() async {
    assert(this.dunUrl != null);
    // await setString('ApiUrls.dunUrl' + _appVersion, this.dunUrl);
    // if (this.dunKey != null) {
    //   await setString('ApiUrls.dunKey' + _appVersion, this.dunKey);
    // }

    if (this.dunKiwiStart != null) {
      String appVer = await PlatformUtils.getAppVersion();
      await setString('ApiUrls.dunKiwiStart' + appVer, this.dunKiwiStart);
    }
  }

  /// 取api接口的管理器
  _ApiInfoManager? _apiUrlsMgr;

  /// 取得下一个地址
  Future<bool> next(device, channel) async {
    mypdebug("尝试取得新的地址: device:$device channel:$channel");
    // 如果对象还没有初始化初始化一下
    if (_apiUrlsMgr == null) {
      _apiUrlsMgr = _ApiInfoManager();
      await _apiUrlsMgr!.init("$device.$channel".hashCode);
    }

    // 将地址缓存到
    final json = await _apiUrlsMgr!.getInfo(channel);
    if (json == null) {
      // 暂停个1秒再继续
      await Future.delayed(const Duration(seconds: 1));

      // 从apiInfoMgr里面取得地址
      final pos = _apiUrlsMgr!.tryPrevPos();
      mypdebug('_apiUrlsMgr.tryPrevPos 取得新的位置 $pos');
      await _apiUrlsMgr!._saveToLocal();
      if (pos < 0) {
        mypdebug('已经取不到地址了。。 重新开始了');
        //重新初始化地址
        _apiUrlsMgr!.resetPos();
      }
      return false;
    }

    // 解析一下
    fromJson(json);
    mypdebug('最新api 游戏盾配置:$json');

    // 如果从远程读取配置成功，则看一下有没有新的地址, 有的话换一个
    if (json.containsKey('version')) {
      var v = json['version']?.toString();
      final v2 = int.tryParse(v ?? '0') ?? 0;
      _apiUrlsMgr!.upgrade(v2);
    }

    // 存储到硬盘
    await _saveToLocal();

    return true;
  }
}

class _ApiInfoManager extends _Util {
  ///  所有的远程主机，用于组织成一颗树: 如长度,14
  /// 1
  /// 2	2
  /// 3	3	3
  List hosts = [];

  int? _sliceKey;

  /// 换api的在树中的游标深度
  /// 1,0,1 = 2
  /// 1,1,1 = 4
  /// 2,1,2 = 10
  List<int> _pos = [0, 0, 0];

  /// 接口版本号,用于是否更新
  int? _version;

  _ApiInfoManager() {
    assert(_getCursor(pos: [0, 0, 0]) == 0);
    assert(_getCursor(pos: [1, 0, 0]) == 1);
    assert(_getCursor(pos: [2, 0, 0]) == 5);
    assert(_getCursor(pos: [1, 1, 1]) == 4);
    assert(_getCursor(pos: [3, 3, 2]) == 28);
  }

  /// 重置
  Future<void> resetPos() async {
    final depth = _getDepth();

    if (depth == 0) return;

    final slice = _sliceKey! % depth;
    _pos[0] = depth - 1;
    _pos[1] = slice;
    _pos[2] = depth - 1; // 每个片区等于深度的节点数
  }

  _debug() {
    resetPos();
    // 先把所有的地址打印一遍再重置
    var ar = [];
    for (var i = _getCursor(); i >= 0; i = tryPrevPos()) {
      ar.add(i);
    }
    mypdebug('_ApiInfoManager._debug.tryPrevPos ${hosts.length} $ar');
  }

  /// api管理初始化
  Future<bool> _init(String str, int version) async {
    assert(_sliceKey != null);

    str = decrypt2Base64(str);
    if (str.isEmpty) return false;
    hosts = str
        .split('\n')
        .map((e) => e.trim())
        .where((el) => el.isNotEmpty)
        .toList();
    if (hosts.isEmpty) return false;

    // 打印所有的节点情况
    _debug();

    resetPos();

    // 数据版本号
    _version = version;

    mypdebug('_ApiInfoManager _init:$str, $version');

    await _saveToLocal();

    return true;
  }

  /// 从本地缓存取得api地址信息
  Future<bool> init(k) async {
    _sliceKey = k;
    _version = int.tryParse(await getString('_ApiInfoManager._version'));
    // 如果第一次打开
    if (_version == null || _version == 0) {
      mypdebug('_ApiInfoManager 本地版本为空，初始化：{${Config().kiwiVersion}');
      return _init(Config().kiwiBackupHost, Config().kiwiVersion);
    }

    // hosts = (await getString('_ApiInfoManager.hosts'))
    //     .split('\n')
    //     .map((e) => e.trim())
    //     .where((el) => el.isNotEmpty)
    //     .toList();

    final _t = (await getString('_ApiInfoManager._pos')).split(',');
    for (var i = 0; i < _t.length; i++) {
      _pos[i] = int.tryParse(_t[i])!;
    }

    if (hosts.isEmpty) {
      return false;
    }

    await _saveToLocal();

    return true;
  }

  /// 升级到新的备用地址
  Future<bool> upgrade(int version) async {
    if (version <= _version!) {
      return false;
    }

    mypdebug('远程版本比较新准备更新:$version');
    var uri = _getUri();
    var s = await httpGet(uri.replace(path: "${uri.path}/$version.txt"));
    if (s == null) return false;

    return _init(s, version);
  }

  /// 取树坐标在数组中的位置
  int _getCursor({pos}) {
    pos = (pos ?? _pos);
    int startPos = 0;
    for (var i = 1; i <= pos[0]; i++) {
      startPos += (i * i);
    }
    int val = (pos[0] + 1) * pos[1] + pos[2];
    return startPos + val;
  }

  /// 计算配置树的深度
  int _getDepth() {
    int count = hosts.length;
    int depth = 0;
    while (count > 0) {
      ++depth;
      count -= depth * depth;
    }
    return depth;
  }

  /// 再取一个新的备用地址
  int tryPrevPos({pos}) {
    pos = (pos ?? _pos);
    pos[2]--;
    if (pos[2] >= 0) {
      return _getCursor(pos: pos);
    }
    // 深度上升一级, 片区重新计算, 叶子最近一个
    pos[0]--;
    if (pos[0] < 0) {
      // 退无可退了。。。
      mypdebug('没有新的保留地址了$pos');
      return -1;
    }
    pos[1] = _sliceKey! % (pos[0] + 1);
    pos[2] = pos[0];
    return _getCursor(pos: pos);
  }

  ///
  _getUri() {
    int pos = _getCursor();
    // 位置超了,直接进入下一个
    if (pos == -1) {
      resetPos();
      pdebug('当前标签索引$pos');
    }
    if (pos >= hosts.length || pos == -1) return null;

    String p = hosts[pos];
    return Uri.tryParse(p);
  }

  /// 请求当前节点信息
  Future<Map?> getInfo(String channel) async {
    var uri = _getUri();
    if (uri == null) {
      return null;
    }
    final t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    uri = uri.replace(
      path: '${uri.path}/$channel.data',
      queryParameters: {"t": t.toString()},
    );
    mypdebug('解析域名地址${uri.toString()}');
    return httpGetJson(uri);
  }

  /// 将api的信息持久化到硬盘
  Future<void> _saveToLocal() async {
    // await setString('_ApiInfoManager.hosts', hosts.join('\n'));
    await setString('_ApiInfoManager._pos', _pos.join(','));
    await setString('_ApiInfoManager._version', _version.toString());
  }
}
