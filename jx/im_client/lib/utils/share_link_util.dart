import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:uuid/uuid.dart';

class ShareLinkUtil {
  static Uuid? _uuid;

  static String aesBase64Encode(String plainText) {
    final aesKey = Config().aesKey;
    pdebug('aesKey: $aesKey');
    final key = encrypt.Key.fromUtf8(aesKey); // 32 字节的密钥
    final iv = encrypt.IV.fromUtf8('1234567890123456'); // 16 字节的初始向量

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return Uri.encodeComponent(encrypted.base64);
  }

  static String aesBase64Decode(String encryptedTextBase64) {
    final aesKey = Config().aesKey;
    final key = encrypt.Key.fromUtf8(aesKey);
    final iv = encrypt.IV.fromUtf8('1234567890123456'); // 16 字节的初始向量

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );
    // 解码 Base64 编码的字符串
    final encryptedBytes =
        base64.decode(Uri.decodeComponent(encryptedTextBase64));

    // 使用加密器解密
    final encrypted = encrypt.Encrypted(encryptedBytes);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);

    return decrypted;
  }

  static String generateFriendShareLink(int? userId, {String accountId = ''}) {
    assert(userId != null, 'GenerateFriendShareLink: user id cannot be null!');
    final data = <String, dynamic>{
      "uid": userId,
      "action": 0,
    };
    if (accountId.isNotEmpty) {
      data['profile'] = accountId;
    }
    final json = jsonEncode(data);
    final encodeJson = aesBase64Encode(json);
    final host = Uri.parse(Config().officialUrl).host;
    // "https://heytalk.info/",
    // heytalk.info/me/$encodeJson
    return '$host/me/$encodeJson';
  }

  static String localGenerateGroupShareLinkWithoutEncryption(String url) {
    List<String> urls = extractLinkFromText(url);
    assert(urls.isNotEmpty, 'collectDataFromUrl: urls cannot be empty!');
    List<String> list = urls.first.split('/');
    list.removeLast();

    Map<String, dynamic> map = collectDataFromUrl(url);
    if (notBlank(map['chatKey'])) {
      map.remove('chatKey');
    } else {
      return url;
    }

    final json = jsonEncode(map);
    final encodeJson = aesBase64Encode(json);
    list.add(encodeJson);

    return list.join("/");
  }

  static String localGenerateGroupShareLinkWithEncryption(
      String url, String chatKey) {
    List<String> urls = extractLinkFromText(url);
    assert(urls.isNotEmpty, 'collectDataFromUrl: urls cannot be empty!');
    List<String> list = urls.first.split('/');
    list.removeLast();

    Map<String, dynamic> map = collectDataFromUrl(url);
    if (notBlank(chatKey)) {
      map['chatKey'] = chatKey;
    } else {
      return url;
    }

    final json = jsonEncode(map);
    final encodeJson = aesBase64Encode(json);
    list.add(encodeJson);

    return list.join("/");
  }

  static String generateGroupShareLink(int? userId, int? groupId) {
    assert(userId != null, 'GenerateGroupShareLink: user id cannot be null!');
    assert(groupId != null, 'GenerateGroupShareLink: group id cannot be null!');
    _uuid ??= const Uuid();
    Map<String, dynamic> map = {
      "uid": userId,
      "gid": groupId,
      "action": 1,
      "id": _uuid?.v1(),
    };

    final json = jsonEncode(map);
    final encodeJson = aesBase64Encode(json);
    final host = Uri.parse(Config().officialUrl).host;

    return '$host/me/$encodeJson';
  }

  static String? getQueryParam(String url, String param) {
    RegExp regExp = RegExp('[?&]$param=([^&]*)');
    Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }

  static Map<String, dynamic> collectDataFromUrl(String text) {
    try {
      List<String> urls = extractLinkFromText(text);
      assert(urls.isNotEmpty, 'collectDataFromUrl: urls cannot be empty!');
      final list = urls.first.split('/');
      final dataList = list.last.split('&');
      final encryptedTextBase64 = dataList.first;
      final dataMap = jsonDecode(aesBase64Decode(encryptedTextBase64));
      return dataMap;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static bool isGroupShareLink(String url) {
    final dataMap = collectDataFromUrl(url);
    return dataMap['gid'] != null && dataMap['gid'] != '';
  }

  static bool isMatchShareLink(String text) {
    final host = Uri.parse(Config().officialUrl).host;
    final link = '$host/me/';
    final linkReg = RegExp(r'(' + link + r')');
    final isMatch = linkReg.hasMatch(text);
    return isMatch;
  }

  static bool isMatchLink(String text) {
    final isMatch = extractLinkFromText(text).isNotEmpty;
    return isMatch;
  }

  static List<String> extractLinkFromText(String text) {
    const pattern =
        r'((https?):\/\/)?([a-zA-Z0-9.-]+\.[a-zA-Z]{2,6})(\/[^\s]*)?';
    final linkReg = RegExp(pattern);
    Iterable<RegExpMatch> matches = linkReg.allMatches(text);
    List<String> urls = matches.map((match) => match.group(0)!).toList();
    return urls;
  }
}
