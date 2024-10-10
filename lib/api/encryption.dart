import 'dart:convert';
import 'package:jxim_client/end_to_end_encryption/model/encryption_model.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';

Future<CipherKey> getCipherMyKey() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      '/app/api/cipher/key/my',
    );

    if (res.success()) {
      return CipherKey.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> setCipherMyKey(String publicKey,
    {String? encryptedPrivateKey = ''}) async {
  try {
    Map<String, dynamic> data = {};
    data['public_key'] = publicKey;

    if (encryptedPrivateKey != '') {
      data['enc_pk'] = encryptedPrivateKey;
    }

    final ResponseData res = await CustomRequest.doPost(
      '/app/api/cipher/key/set',
      data: data,
    );

    if (res.success()) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    rethrow;
  }
}

Future<List<CipherKey>> getCipherKeys(List<int> userIds) async {
  Map<String, dynamic> dataBody = {};
  dataBody["uids"] = userIds.join(",");

  try {
    final ResponseData res = await CustomRequest.doGet(
      '/app/api/cipher/key/gets',
      data: dataBody,
    );

    if (res.success()) {
      return res.data.map<CipherKey>((e) => CipherKey.fromJson(e)).toList();
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> updateChatCiphers(List<ChatSession> sessions) async {
  try {
    // Map<String, dynamic> data = {};
    List<Map<String, dynamic>> data = [];

    for (ChatSession session in sessions) {
      Map<String, dynamic> d = {};
      d['sessions'] = session.chatKeys.map((item) => item.toJson()).toList();
      d['chat_id'] = session.chatId;
      data.add(d);
    }

    final ResponseData res = await CustomRequest.doPost(
      '/app/api/cipher/chat/update',
      data: data,
    );

    if (res.success()) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    rethrow;
  }
}

Future<ChatKey> getChatCipher(int chatId) async {
  try {
    Map<String, dynamic> data = {};
    data['chat_id'] = chatId;

    final ResponseData res = await CustomRequest.doGet(
      '/app/api/cipher/chat/get',
      data: data,
    );

    if (res.success()) {
      return ChatKey.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<void> requestChatCipher(int chatId, String publicKey) async {
  try {
    Map<String, dynamic> data = {};
    data['chat_id'] = chatId;
    data['public_key'] = publicKey;

    final ResponseData res = await CustomRequest.doPost(
      '/app/api/cipher/chat/request',
      data: data,
    );

    if (res.success()) {
      return;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<List<ChatKey>> getCipherMyChat() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      '/app/api/cipher/chat/my'
    );

    if (res.success()) {
      return res.data.map<ChatKey>((e) => ChatKey.fromJson(e)).toList();
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<FriendAssistData> getFriendAssist(String publicKey, int uid) async {
  Map<String, dynamic> dataMap = {};
  dataMap['public_key'] = publicKey;
  dataMap['uid'] = uid;

  try {
    Map<String, dynamic> data = {};
    data['type'] = 1;
    data['data'] = jsonEncode(dataMap);

    final ResponseData res = await CustomRequest.doPost(
        '/app/api/auth/assist',
      data: data,
    );

    if (res.success()) {
      return FriendAssistData.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> friendAssistVerify(int uid, String code) async {
  try {
    Map<String, dynamic> data = {};
    data['user_id'] = uid;
    data['code'] = code;

    final ResponseData res = await CustomRequest.doPost(
      '/app/api/auth/assist/verify',
      data: data,
    );

    if (res.success()) {
      return true;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<bool> resetPublicPrivateKey({
  required String publicKey,
  String? encPrivateKey,
  required String vcodeToken,
}) async {
  try {
    Map<String, dynamic> data = {};
    data['public_key'] = publicKey;
    data['vcode_token'] = vcodeToken;

    if (notBlank(encPrivateKey)) {
      data['private_key'] = encPrivateKey;
    }

    final ResponseData res = await CustomRequest.doPost(
      '/app/api/auth/cipher/reset',
      data: data,
    );

    if (res.success()) {
      return true;
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}
