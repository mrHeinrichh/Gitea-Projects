import 'dart:convert';

import 'package:jxim_client/end_to_end_encryption/model/encryption_model.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
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
    {String? encryptedPrivateKey}) async {
  try {
    Map<String, dynamic> data = {};
    data['public_key'] = publicKey;

    if (encryptedPrivateKey != null && notBlank(encryptedPrivateKey)) {
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
    List<Map<String, dynamic>> data = [];

    for (ChatSession session in sessions) {
      Map<String, dynamic> d = {};
      d['sessions'] = session.chatKeys.map((item) => item.toJson()).toList();
      d['chat_id'] = session.chatId;
      d['round'] = session.round;
      if (session.chatIdx != null) {
        d['chat_idx'] = session.chatIdx;
      }
      if (session.msgId != null) {
        d['msg_id'] = session.msgId;
      }
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
    if (e is AppException &&
        e.getPrefix() == ErrorCodeConstant.ENCRYPTION_CANNOT_UPDATE_CHAT) {
      return true;
    }
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

Future<void> requestChatCipher(List<int> chatIds, String publicKey) async {
  try {
    Map<String, dynamic> data = {};
    data['chat_ids'] = chatIds;
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
    final ResponseData res =
        await CustomRequest.doGet('/app/api/cipher/chat/my');

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

Future<List<int>> getAnyEmptyChatSessions({
  required List<int> chatIds,
}) async {
  try {
    Map<String, dynamic> data = {};
    data['chat_ids'] = chatIds;

    final ResponseData res = await CustomRequest.doPost(
      '/app/api/cipher/chat/sessions_exist',
      data: data,
    );

    if (res.success()) {
      Map<String, dynamic> results = res.data;
      if (results['chat_without_sessions'] != null) {
        return List<int>.from(results['chat_without_sessions']);
      }
      return [];
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
  bool resign = true,
  required String vcodeToken,
}) async {
  try {
    Map<String, dynamic> data = {};
    data['public_key'] = publicKey;
    data['vcode_token'] = vcodeToken;
    data['resign'] = resign;

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

Future<UnlockCount> getUnlockCount() async {
  try {
    final ResponseData res = await CustomRequest.doGet(
      '/app/api/cipher/key/unlock-count',
    );

    if (res.success()) {
      return UnlockCount.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}

Future<UnlockCount> updateUnlockCount(bool isUnlock) async {
  Map<String, dynamic> data = {};
  data['is_unlock'] = isUnlock;

  try {
    final ResponseData res = await CustomRequest.doPost(
      '/app/api/cipher/key/update-unlock-count',
      data: data,
    );

    if (res.success()) {
      return UnlockCount.fromJson(res.data);
    } else {
      throw AppException(res.message);
    }
  } catch (e) {
    rethrow;
  }
}
