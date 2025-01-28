import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/api/chat.dart';
import 'package:jxim_client/api/encryption.dart';
import 'package:jxim_client/end_to_end_encryption/model/encryption_model.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/interface/base_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_list.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/tasks/sign_chat_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/encryption/aes_encryption.dart';
import 'package:jxim_client/utils/encryption/rsa_encryption.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/im_toast/overlay_extension.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_item.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';

/// 1. 检查本地是否有公钥和私钥
/// 2. 后端获取用户的公钥和私钥
/// 3. 检查后端是否有私钥
/// 4. [3的结果-是]：引导去[输入加密密码页面]
/// 5. [3的结果-否]：检查后端是否有公钥
/// 6. [5的结果-是]：引导去[加密验证页面]
/// 7. [5的结果-否]：本地生成公钥和私钥，保存到Local Storage，上传公钥到后端

class EncryptionMgr extends BaseMgr {
  static const String eventResetPairKey = 'eventResetPairKey';
  static const String eventResetPrivateKeyPW = 'eventResetPrivateKeyPW';
  static const String eventBackupKey = 'eventBackupKey';
  static const String decryptFailureEmblem = 'N';

  static const _encryptionChannel = 'jxim/e2eEncryption';
  static const _methodChannel = MethodChannel(_encryptionChannel);

  String encryptionPublicKey = "";
  String encryptionPrivateKey = "";
  String newEncryptionPublicKey = "";
  String hasEncryptedPrivateKey = "";
  static String loginDesktopEncryptionPrivateKey = "";
  static String loginDesktopAESKey = "";
  bool isCheckingCipherKeys = false;
  bool? beEncryptionEnabled;

  Map<int, int> reqSignChatList = {};

  @override
  Future<void> initialize() async {
    if (!Config().e2eEncryptionEnabled) {
      return;
    }

    initEncryptionKey();
    if (objectMgr.socketMgr.isAlreadyPubSocketOpen) {
      _onSocketOpen(null, null, null);
    }
    objectMgr.socketMgr.on(SocketMgr.eventSocketOpen, _onSocketOpen);
  }

  Future<void> _onSocketOpen(a, b, c) async {
    if (!Config().e2eEncryptionEnabled) {
      return;
    }

    if (encryptionPublicKey == "") {
      await getCipherKey();
      objectMgr.chatMgr.event(this, ChatMgr.eventChatListLoaded);
    } else {
      if (encryptionPrivateKey == "") {
        _processDesktopLogin();
        if (notBlank(encryptionPrivateKey)) {
          _processDesktopEncryptionKeys();
          return;
        }
      }
    }

    isCheckingCipherKeys = false;
    event(
      this,
      EncryptionMgr.eventBackupKey,
    );
  }

  @override
  Future<void> cleanup() async {
    if (!Config().e2eEncryptionEnabled) {
      return;
    }

    encryptionPublicKey = "";
    encryptionPrivateKey = "";
    hasEncryptedPrivateKey = "";
    loginDesktopEncryptionPrivateKey = "";
    loginDesktopAESKey = "";
    reqSignChatList.clear();
    _clearAllNativeEncryptionKeys();
    objectMgr.socketMgr.off(SocketMgr.eventSocketOpen, _onSocketOpen);
    clear();
  }

  void initEncryptionKey() async {
    /// 1. 检查本地是否有公钥和私钥
    encryptionPublicKey =
        objectMgr.localStorageMgr.read(LocalStorageMgr.ENCRYPTION_PUBLIC_KEY) ??
            "";
    encryptionPrivateKey = objectMgr.localStorageMgr
            .read(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY) ??
        "";

    readRemoteEncryptionEnabled();
  }

  Future<void> getCipherKey({int retryTime = 0}) async {
    if (!Config().e2eEncryptionEnabled) {
      return;
    }

    /// 2. 后端获取用户的公钥和私钥
    /// 3. 检查后端是否有私钥

    encryptionPrivateKey = objectMgr.localStorageMgr
            .read(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY) ??
        '';

    if (notBlank(encryptionPrivateKey)) {
      return;
    } else {
      _processDesktopLogin();
      if (notBlank(encryptionPrivateKey)) {
        _processDesktopEncryptionKeys();
        return;
      }
    }

    try {
      CipherKey data = await getCipherMyKey();

      if (data.encPrivate != "") {
        /// 4. [3的结果-是]：引导去[输入加密密码页面]
        hasEncryptedPrivateKey = data.encPrivate ?? '';
        objectMgr.localStorageMgr.write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.BE_ENCRYPTED_KEY, hasEncryptedPrivateKey);

        if (data.public != '') {
          encryptionPublicKey = data.public ?? '';
          objectMgr.localStorageMgr.write(
              LocalStorageMgr.ENCRYPTION_PUBLIC_KEY, encryptionPublicKey);
        }
      } else {
        /// 5. [3的结果-否]：检查后端是否有公钥
        if (data.public != '') {
          /// 6. [5的结果-是]：引导去[加密验证页面]
          bool isEncryptionChatExist = await checkEncryptionChat();
          if (!isEncryptionChatExist) {
            await setEncryptionKey();
          }
        } else {
          await setEncryptionKey();
        }
      }
    } catch (e) {
      if (e is AppException &&
          e.getPrefix() == ErrorCodeConstant.ENCRYPTION_KEY_NOT_EXISTS) {
        await setEncryptionKey();
      } else {
        if (retryTime < 5) {
          await Future.delayed(const Duration(seconds: 1));
          getCipherKey(retryTime: retryTime + 1);
          return;
        }
      }
    }
  }

  String getEncPrivateKey(String privateKey, String password) {
    /// 加密私钥
    String encryptedPrivateKey = '';
    String md5 = makeMD5(password);
    var a = AesEncryption(md5);
    encryptedPrivateKey = a.encrypt(privateKey); // 密码加密后的私钥 传后端
    return encryptedPrivateKey;
  }

  Future<bool> setEncryptionKey({int retryTime = 0}) async {
    /// 7. [5的结果-否]：本地生成公钥和私钥，保存到Local Storage，上传公钥到后端
    /// 明文公钥和私钥
    /// 此流程，完全不上传加密私钥（初始化）

    try {
      final (String publicKey, String privateKey) =
          RSAEncryption.generateKeyPair();
      bool status = false;
      status = await setCipherMyKey(publicKey);
      if (status) {
        saveEncryptionKey(publicKey, privateKey);
        firstTimeUpdateCiphers();
      }

      return status;
    } catch (e) {
      if (retryTime < 5) {
        await Future.delayed(const Duration(seconds: 1));
        setEncryptionKey(retryTime: retryTime + 1);
      }
      return false;
    }
  }

  Future<bool> updateEncryptionPrivateKey(
      String oriPublicKey, String password) async {
    try {
      String encryptedPrivateKey =
          getEncPrivateKey(encryptionPrivateKey, password);

      bool status = false;
      if (encryptedPrivateKey != '') {
        bool canUpdate =
            await isKeyValid(oriPublicKey, privateKey: encryptionPrivateKey);
        if (!canUpdate) {
          //不能更新keys
          imBottomToast(
            Get.context!,
            title: localized(keyExpiredForRecovery),
            icon: ImBottomNotifType.warning,
          );
          return status;
        }

        status = await setCipherMyKey(oriPublicKey,
            encryptedPrivateKey: encryptedPrivateKey);
        event(this, EncryptionMgr.eventBackupKey);
        objectMgr.localStorageMgr.write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
      }

      if (status) {
        hasEncryptedPrivateKey = encryptedPrivateKey;
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.BE_ENCRYPTED_KEY, hasEncryptedPrivateKey);
      }

      return status;
    } catch (e) {
      if (e is AppException &&
          e.getPrefix() == ErrorCodeConstant.ENCRYPTION_CANNOT_UPDATE_KEYS) {
        _resetAndUpdateKeys();
        imBottomToast(
          Get.context!,
          title: localized(keyExpiredForRecovery),
          icon: ImBottomNotifType.warning,
        );
      } else {
        imBottomToast(
          Get.context!,
          title: localized(noNetworkPleaseTryAgainLater),
          icon: ImBottomNotifType.warning,
        );
      }

      rethrow;
    }
  }

  bool saveEncryptionKey(String publicKey, String privateKey) {
    if (publicKey != '' && privateKey != '') {
      savePublicKey(publicKey);
      savePrivateKey(privateKey);
      event(this, EncryptionMgr.eventBackupKey);
      return true;
    } else {
      return false;
    }
  }

  void savePublicKey(String publicKey) {
    if (publicKey != "") {
      encryptionPublicKey = publicKey;
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.ENCRYPTION_PUBLIC_KEY, publicKey);
    }
  }

  void savePrivateKey(String privateKey) {
    if (privateKey != "" && RSAEncryption.isValidPrivateKey(privateKey)) {
      encryptionPrivateKey = privateKey;
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY, privateKey);

      var privateKeyExpired = objectMgr.localStorageMgr
          .read(LocalStorageMgr.PRIVATE_KEY_EXPIRED_KEY);
      if (privateKeyExpired != null) {
        objectMgr.localStorageMgr
            .remove(LocalStorageMgr.PRIVATE_KEY_EXPIRED_KEY, private: true);
      }
    }
  }

  Future<EncryptionSetupPasswordType> isChatEncryptionNewSetup() async {
    if (notBlank(encryptionPrivateKey)) {
      try {
        var qrCodeDownloaded = objectMgr.localStorageMgr
            .read(LocalStorageMgr.PK_QR_CODE_DOWNLOADED_KEY);
        CipherKey data = await getCipherMyKey();
        if (notBlank(data.encPrivate)) {
          if (notBlank(data.public) && data.public != encryptionPublicKey) {
            _resetAndUpdateKeys(key: data);
            return EncryptionSetupPasswordType.anotherDeviceSetup;
          }

          hasEncryptedPrivateKey = data.encPrivate ?? '';
          objectMgr.localStorageMgr
              .write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
          objectMgr.localStorageMgr
              .write(LocalStorageMgr.BE_ENCRYPTED_KEY, hasEncryptedPrivateKey);
          return EncryptionSetupPasswordType.doneSetup;
        } else if (qrCodeDownloaded != null && qrCodeDownloaded == true) {
          if (notBlank(data.public) && data.public != encryptionPublicKey) {
            //QR码下载，但公钥不同，则上传公钥进行替换（以下载QR码为最新密钥）
            bool isEncryptionChatExist = await checkEncryptionChat();
            if (isEncryptionChatExist) {
              _resetAndUpdateKeys(key: data);
              return EncryptionSetupPasswordType.anotherDeviceSetup;
            }
            await setCipherMyKey(encryptionPublicKey);
          }
          return EncryptionSetupPasswordType.doneSetup;
        } else {
          return EncryptionSetupPasswordType.neverSetup;
        }
      } catch (e) {
        if (e is AppException &&
            e.getPrefix() == ErrorCodeConstant.ENCRYPTION_KEY_NOT_EXISTS) {
          return EncryptionSetupPasswordType.neverSetup;
        } else {
          return EncryptionSetupPasswordType.abnormal;
        }
      }
    } else {
      try {
        CipherKey data = await getCipherMyKey();

        if (data.encPrivate != '') {
          hasEncryptedPrivateKey = data.encPrivate ?? '';
          objectMgr.localStorageMgr
              .write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
          objectMgr.localStorageMgr
              .write(LocalStorageMgr.BE_ENCRYPTED_KEY, hasEncryptedPrivateKey);
          if (encryptionPrivateKey == '') {
            return EncryptionSetupPasswordType.anotherDeviceSetup;
          } else {
            return EncryptionSetupPasswordType.doneSetup;
          }
        } else {
          bool isEncryptionChatExist = await checkEncryptionChat();
          if (isEncryptionChatExist) {
            return EncryptionSetupPasswordType.anotherDeviceSetup;
          } else {
            return EncryptionSetupPasswordType.neverSetup;
          }
        }
      } catch (e) {
        if (e is AppException &&
            e.getPrefix() == ErrorCodeConstant.ENCRYPTION_KEY_NOT_EXISTS) {
          return EncryptionSetupPasswordType.neverSetup;
        } else {
          String? bePrivateKey =
              objectMgr.localStorageMgr.read(LocalStorageMgr.BE_ENCRYPTED_KEY);
          if (notBlank(bePrivateKey)) {
            return EncryptionSetupPasswordType.anotherDeviceSetup;
          } else {
            return EncryptionSetupPasswordType.abnormal;
          }
        }
      }
    }
  }

  Future<EncryptionSetupPasswordType> isEncryptionNewSetup() async {
    if (encryptionPrivateKey != '') {
      try {
        CipherKey data = await getCipherMyKey();
        if (notBlank(data.encPrivate) && data.public != encryptionPublicKey) {
          await kickLogoutRemoveCache();
          hasEncryptedPrivateKey = data.encPrivate ?? '';
          objectMgr.localStorageMgr
              .write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
          objectMgr.localStorageMgr
              .write(LocalStorageMgr.BE_ENCRYPTED_KEY, hasEncryptedPrivateKey);
          //以后端的为最新，若有公钥，则清除后保存起来
          encryptionPublicKey = data.public ?? '';
          objectMgr.localStorageMgr.write(
              LocalStorageMgr.ENCRYPTION_PUBLIC_KEY, encryptionPublicKey);

          event(this, EncryptionMgr.eventBackupKey);
          return EncryptionSetupPasswordType.anotherDeviceSetup;
        }
        if (notBlank(data.encPrivate)) {
          hasEncryptedPrivateKey = data.encPrivate ?? '';
          objectMgr.localStorageMgr
              .write(LocalStorageMgr.BE_ENCRYPTED_KEY, hasEncryptedPrivateKey);
        }
      } catch (e) {
        pdebug("有私钥做对比报错 - ${e.toString()}");
      }

      return EncryptionSetupPasswordType.doneSetup;
    }

    if (hasEncryptedPrivateKey != '' && encryptionPrivateKey != '') {
      return EncryptionSetupPasswordType.doneSetup;
    } else {
      try {
        CipherKey data = await getCipherMyKey();

        if (data.encPrivate != '') {
          hasEncryptedPrivateKey = data.encPrivate ?? '';
          objectMgr.localStorageMgr
              .write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
          objectMgr.localStorageMgr
              .write(LocalStorageMgr.BE_ENCRYPTED_KEY, hasEncryptedPrivateKey);
          if (encryptionPrivateKey == '') {
            return EncryptionSetupPasswordType.anotherDeviceSetup;
          } else {
            return EncryptionSetupPasswordType.doneSetup;
          }
        } else {
          bool isEncryptionChatExist = await checkEncryptionChat();
          if (isEncryptionChatExist) {
            return EncryptionSetupPasswordType.anotherDeviceSetup;
          } else {
            return EncryptionSetupPasswordType.neverSetup;
          }
        }
      } catch (e) {
        if (e is AppException &&
            e.getPrefix() == ErrorCodeConstant.ENCRYPTION_KEY_NOT_EXISTS) {
          return EncryptionSetupPasswordType.neverSetup;
        } else {
          String? bePrivateKey =
              objectMgr.localStorageMgr.read(LocalStorageMgr.BE_ENCRYPTED_KEY);
          if (notBlank(bePrivateKey)) {
            return EncryptionSetupPasswordType.anotherDeviceSetup;
          } else {
            return EncryptionSetupPasswordType.abnormal;
          }
        }
      }
    }
  }

  void navigateEncryptionPasswordPage(
      {bool isFromChangePw = false, Function()? successCallback}) {
    Map<String, dynamic> args = {
      'isFromChangePw': isFromChangePw,
    };
    if (successCallback != null) {
      args['successCallback'] = successCallback;
    }
    Get.toNamed(RouteName.encryptionPasswordPage, arguments: args);
  }

  void toastNavigatePage(EncryptionPanelType type) {
    switch (type) {
      case EncryptionPanelType.backup:
        updateSkipBackup();
        Get.toNamed(RouteName.encryptionBackupKeyPage);
        break;
      case EncryptionPanelType.recover:
      case EncryptionPanelType.recoverKick:
        Get.toNamed(RouteName.encryptionVerificationPage, arguments: {
          "hasBack": false,
        });
        break;
      case EncryptionPanelType.none:
        break;
    }
  }

  Future<(String?, int?)> startChatEncryption(List<int> userIds,
      {Chat? chat, int? chatId}) async {
    int cID = chatId ?? chat?.chat_id ?? 0;

    int? currentRound = chat?.activeKeyRound;
    String? chatKey = chat?.activeChatKey;
    // 开启加密前生成或植入会话密钥，并给成员上传后端加密后的会话密钥
    //获取所有用户的公钥
    try {
      if (!notBlank(chatKey)) {
        var (chatKeyRemote, round) = await getChatCipherKey(cID);
        if (chatKeyRemote == EncryptionMgr.decryptFailureEmblem) {
          bool keyValid = await isKeyValid(encryptionPublicKey,
              privateKey: encryptionPrivateKey);
          if (!keyValid) {
            //密钥已不一样，没有必要再轮询下去
            return (null, null);
          }
        }
        // 若没有带入会话密钥，开启加密前需要获取一遍保证没有加过
        if (notBlank(chatKeyRemote) && round != null) {
          currentRound = round;
          chatKey = chatKeyRemote; //N也会走到这里
        }
        if (chat != null && chatKey == EncryptionMgr.decryptFailureEmblem) {
          await addSignRequest({chat.chat_id: chat.round});
        }
      }

      if (chat != null &&
          (!notBlank(chatKey) ||
              chatKey == EncryptionMgr.decryptFailureEmblem)) {
        //只有有聊天室的时候会进来（非创建加密群）
        List<int> emptyChatIds = await getAnyEmptyChatSessions(chatIds: [cID]);
        if (emptyChatIds.isEmpty) {
          // if (chatKey == EncryptionMgr.decryptFailureEmblem)
          //自己没有会话密钥，但聊天室有人有会话密钥
          return ("", chat.round);
        }

        if (chatKey == EncryptionMgr.decryptFailureEmblem) {
          currentRound = chat.round + 1;
          chatKey = null;
        }
      }

      List<CipherKey> data = await getCipherKeys(userIds); //
      if (userIds.contains(objectMgr.userMgr.mainUser.uid)) {
        CipherKey? myKey = data.firstWhereOrNull(
            (element) => element.uid == objectMgr.userMgr.mainUser.uid);
        if (myKey == null) {
          if (notBlank(encryptionPublicKey)) {
            //本地有公钥，上传公钥
            bool status = await setCipherMyKey(encryptionPublicKey);
            if (status) {
              //上传公钥成功，使用自己的公钥继续开启流程
              CipherKey key = CipherKey(
                  uid: objectMgr.userMgr.mainUser.uid,
                  public: encryptionPublicKey);
              data.add(key);
            } else {
              //后端设置不成功，不让开
              return (null, null);
            }
          } else {
            //本地公钥也不存在，不让开
            return (null, null);
          }
        }
      }

      //生成随机会话密钥
      String randomString = notBlank(chatKey)
          ? chatKey!
          : getRandomString(32); // 32 = aes 128, 64 = aes 256 有旧的就用旧的
      List<ChatKey> updatedKeys = [];
      if (data.isEmpty) {
        //数据为空，不跟后端更新会话密钥，直接设置加密会话。
        return (randomString, currentRound);
      }

      for (CipherKey key in data) {
        if (key.public != null) {
          String encrypted = RSAEncryption.encrypt(randomString, key.public!);
          updatedKeys.add(ChatKey(
              uid: key.uid ?? 0,
              session: encrypted,
              chatId: cID,
              round: currentRound));
        }
      }

      ChatSession session = ChatSession(
          chatKeys: updatedKeys, chatId: cID, round: currentRound ?? 0);

      bool success = await updateChatCiphers([session]); // 向后端发起更新用户会话密钥的请求

      if (success) {
        syncAllEncryptionChatKeys();
      }
      //update chat round
      return success ? (randomString, currentRound) : (null, null);
    } catch (e) {
      imBottomToast(
        Get.context!,
        title: localized(noNetworkPleaseTryAgainLater),
        icon: ImBottomNotifType.warning,
      );
    }

    return (null, null);
  }

  Future<ChatSession?> getNewChatCipherForChat(Chat chat) async {
    List<int> users = [];
    if (chat.isSingle) {
      users = [objectMgr.userMgr.mainUser.uid, chat.friend_id];
    } else if (chat.isSaveMsg) {
      users = [objectMgr.userMgr.mainUser.uid];
    } else {
      Group? group = objectMgr.myGroupMgr.getGroupById(chat.chat_id);
      if (group == null) return null;
      users.assignAll(
          group.members.map<int>((e) => e['user_id'] as int).toList());
    }
    List<CipherKey> data = await getCipherKeys(users);
    int newRound = chat.round + 1;

    //生成随机会话密钥
    String randomString =
        getRandomString(32); // 32 = aes 128, 64 = aes 256 有旧的就用旧的
    chat.updateChatKey(randomString, newRound);
    chat.updateActiveChatKey(randomString, newRound);
    List<ChatKey> updatedKeys = [];
    if (data.isEmpty) {
      //数据为空，不跟后端更新会话密钥，直接设置加密会话。
      return null;
    }

    for (CipherKey key in data) {
      if (key.public != null) {
        String encrypted = RSAEncryption.encrypt(randomString, key.public!);
        updatedKeys.add(
            ChatKey(uid: key.uid ?? 0, session: encrypted, round: newRound));
      }
    }

    ChatSession session = ChatSession(
        chatKeys: updatedKeys, chatId: chat.chat_id, round: newRound);

    return session;
  }

  Future<void> checkAndUpdateChatCiphers(List<Chat> chats) async {
    try {
      List<ChatKey> chatCipherKeyList = await getCipherMyChat();
      if (chatCipherKeyList.isNotEmpty) {
        Map<int, int> chatIdsToRequest = {};
        List<Chat> validEncryptedChats = [];
        List<Chat> invalidChats = [];
        for (Chat chat in chats) {
          ChatKey? key = chatCipherKeyList
              .firstWhereOrNull((element) => element.chatId == chat.chat_id);
          if (key != null) {
            String? decryptChatKey = decryptChatCipherKey(key.session ?? '');
            //N
            if (decryptChatKey != null) {
              if (decryptChatKey == decryptFailureEmblem && chat.isEncrypted) {
                invalidChats.add(chat);
              } else {
                chat.updateChatKey(decryptChatKey, key.round ?? 0);
                int currentActiveRound = chat.round;
                String activeKey = getCalculatedKey(chat, currentActiveRound);
                if (notBlank(activeKey)) {
                  chat.updateActiveChatKey(activeKey, currentActiveRound);
                }
                validEncryptedChats.add(chat);
              }
            }
          } else if (chat.isEncrypted) {
            chatIdsToRequest[chat.chat_id] = chat.round;
          }
        }

        if (invalidChats.isNotEmpty) {
          bool keyValid = await isKeyValid(encryptionPublicKey,
              privateKey: encryptionPrivateKey);
          if (keyValid) {
            await objectMgr.encryptionMgr.resetChatSessions(invalidChats);
          } else {
            return;
          }
        }

        if (chatIdsToRequest.isNotEmpty) {
          addSignRequest(chatIdsToRequest);
        }

        if (validEncryptedChats.isNotEmpty) {
          //向原生更新key
          syncAllEncryptionChatKeys();
          //需要更新拉取消息模块，更新chat key
          objectMgr.messageManager.decryptChat(validEncryptedChats);
          objectMgr.chatMgr.decryptChat(validEncryptedChats);
          //需要将chat key存储到数据库
          objectMgr.chatMgr.updateEncryptionKeys(validEncryptedChats);
        }
      } else {
        //完全是空的。并不是报错
        Map<int, int> chatMap = {
          for (var item in chats) item.chat_id: item.round
        };
        addSignRequest(chatMap);
      }
    } catch (e) {
      pdebug(e.toString());
    }
  }

  Future<(String?, int?)> getChatCipherKey(int chatId) async {
    //round 仅用于要求签名
    try {
      ChatKey data = await getChatCipher(chatId);
      if (notBlank(data.session)) {
        return (decryptChatCipherKey(data.session!), data.round);
      }
    } catch (e) {
      if (e is AppException) {
        var codeException = e;
        int eCode = codeException.getPrefix();
        if (eCode == ErrorCodeConstant.ENCRYPTION_KEY_NOT_EXISTS) {
          Chat? chat = objectMgr.chatMgr.getChatById(chatId);
          Map<int, int> map = {};
          if (chat != null && chat.isEncrypted) {
            map[chatId] = chat.round;
            addSignRequest(map);
          } //拉不到chat，就代表数据库还没拉到。拉到后再触发
        }
      } else {
        pdebug(e.toString());
      }
    }

    return (null, null);
  }

  addSignRequest(Map<int, int> chatMap, {bool sendApi = true}) async {
    List<int> filteredIds = [];

    chatMap.forEach((chatId, chatRound) {
      if (!reqSignChatList.keys.contains(chatId)) {
        reqSignChatList[chatId] = chatRound;
        filteredIds.add(chatId);
      } else {
        reqSignChatList[chatId] = chatRound;
      }
    });

    if (filteredIds.isNotEmpty && sendApi) {
      await requestChatUpdateFromFriends(filteredIds);
    }
  }

  removeSignRequest(Chat chat) {
    if (reqSignChatList.keys.contains(chat.chat_id)) {
      if (chat.isEncrypted && !chat.isChatKeyValid) {
        objectMgr.encryptionMgr.checkAndUpdateChatCiphers([chat]);
      }
      reqSignChatList.remove(chat.chat_id);
    }
  }

  clearSignRequest() {
    reqSignChatList.clear();
  }

  Future<bool> requestChatUpdateFromFriends(List<int> chatIds) async {
    if (encryptionPublicKey == null) return false;

    try {
      for (int i = 0; i < 10 && encryptionPublicKey == ""; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (encryptionPublicKey == "") return false;
      await requestChatCipher(chatIds, encryptionPublicKey);
      return true;
    } catch (e) {
      pdebug("requestChatCipher chat id:$chatIds");
      return false;
    }
  }

  Future<void> decryptChatIfNeeded(Chat chat) async {
    if (!chat.isEncrypted) return;
    if (chat.isChatKeyValid) return;
    if (!notBlank(encryptionPrivateKey)) return;

    try {
      final (chatKey, chatRound) = await getChatCipherKey(chat.chat_id);
      if (chatKey != null &&
          chatRound != null &&
          chatKey != EncryptionMgr.decryptFailureEmblem) {
        String activeKey = chatKey;
        int activeRound = chatRound;
        if (activeRound < chat.round) {
          chat.updateChatKey(chatKey, chatRound);
          activeRound = chat.round;
          activeKey = getCalculatedKey(chat, activeRound);
        }
        //有key。
        await objectMgr.chatMgr.updateDatabaseEncryptionSetting(chat, chat.flag,
            chatKey: chatKey,
            chatRound: chatRound,
            activeChatKey: activeKey,
            activeRound: activeRound);
        //需要更新拉取消息模块，更新chat key
        objectMgr.messageManager.decryptChat([chat]);
        //Chat mgr更新内存
        objectMgr.chatMgr.decryptChat([chat]);
      } else if (chatKey == EncryptionMgr.decryptFailureEmblem) {
        //同理，解不开盘查密钥是否有效看是否需要清除数据
        bool keyValid = await isKeyValid(encryptionPublicKey,
            privateKey: encryptionPrivateKey);
        if (keyValid) {
          await objectMgr.encryptionMgr.resetChatSessions([chat]);
          if (chat.isChatKeyValid) {
            //若有重新生成，chatkey将百分百有效。
            await objectMgr.chatMgr
                .updateDatabaseEncryptionSetting(chat, chat.flag);
            objectMgr.messageManager.decryptChat([chat]);
            objectMgr.chatMgr.decryptChat([chat]);
          }
        }
      }
    } catch (e) {
      pdebug("单个聊天室解析key报错 - ${e.toString()}");
    }
  }

  Future<void> decryptChat() async {
    List<Chat> encryptedChats = [];
    try {
      List<ChatKey> chatCipherKeyList = await getCipherMyChat();

      if (chatCipherKeyList.isNotEmpty) {
        for (ChatKey chatKey in chatCipherKeyList) {
          if (chatKey.chatId == null) continue;
          Chat? chat = objectMgr.chatMgr.getChatById(chatKey.chatId!);
          if (chat != null) {
            try {
              String? decryptChatKey =
                  decryptChatCipherKey(chatKey.session ?? '');
              if (decryptChatKey != null) {
                chat.updateChatKey(decryptChatKey, chatKey.round ?? 0);
                int currentActiveRound = chat.round;
                String activeKey = getCalculatedKey(chat, currentActiveRound);
                if (notBlank(activeKey)) {
                  chat.updateActiveChatKey(activeKey, currentActiveRound);
                }

                encryptedChats.add(chat);
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
    } catch (e) {
      pdebug(e.toString());
    }

    if (encryptedChats.isNotEmpty) {
      syncAllEncryptionChatKeys();
      //需要更新拉取消息模块，更新chat key
      objectMgr.messageManager.decryptChat(encryptedChats);
      //Chat mgr更新内存
      objectMgr.chatMgr.decryptChat(encryptedChats);
      //需要将chat key存储到数据库
      objectMgr.chatMgr.updateEncryptionKeys(encryptedChats);
    }
  }

  String? decryptChatCipherKey(String encryptionChatKey) {
    var pk = objectMgr.localStorageMgr
            .read(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY) ??
        "";
    if (!notBlank(pk)) {
      return "";
    }

    try {
      String decrypted = RSAEncryption.decrypt(encryptionChatKey, pk);
      if (decrypted.length == 32) {
        return decrypted;
      } else {
        //保存一道n进数据库。
        return decryptFailureEmblem;
      }
    } catch (e) {
      //todo
      return decryptFailureEmblem;
    }
  }

  static String getRandomString(int length) {
    var chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<bool> checkEncryptionChat() async {
    var hasEncryptedChats =
        objectMgr.localStorageMgr.read(LocalStorageMgr.HAS_ENCRYPTED_CHATS);
    if (hasEncryptedChats != null) {
      return hasEncryptedChats!;
    }

    bool status = false;
    try {
      List<ChatKey> chatCipherKeyList = await getCipherMyChat();
      if (chatCipherKeyList.isNotEmpty) {
        status = true;
      }
      if (!status) {
        final rep = await list(
          objectMgr.userMgr.mainUser.uid,
          startTime: null,
        );
        var chatList = ChatList.fromJson(rep.data);
        if (chatList.data != null) {
          for (var item in chatList.data) {
            if (item['flag'] != null &&
                ChatHelp.hasEncryptedFlag(item['flag'])) {
              status = true;
              break;
            }
          }
        }
      }
      if (status) {
        syncAllEncryptionChatKeys();
      }
      hasEncryptedChats = status;
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.HAS_ENCRYPTED_CHATS, status);
    } catch (e) {
      //无网，尝试使用本地查验
      pdebug(e.toString());
    }

    return status;
  }

  Future<bool> onEncryptionToggle(Chat chat, List<int> userIds) async {
    try {
      if (chat.isEncrypted) {
        //关闭加密
        bool success = await objectMgr.chatMgr.sendChatEncryptionSetting(
            chat.chat_id, ChatEncryptionFlag.previouslyEncrypted.value);
        if (success) {
          await objectMgr.chatMgr.updateDatabaseEncryptionSetting(
              chat, ChatEncryptionFlag.previouslyEncrypted.value);
        }
        imBottomToast(
          Get.context!,
          title: localized(settingConversationTurnedOff),
          icon: ImBottomNotifType.success,
        );
        return true;
      } else {
        var setupType = await isChatEncryptionNewSetup();
        if (setupType == EncryptionSetupPasswordType.abnormal) {
          imBottomToast(
            Get.context!,
            title: localized(noNetworkPleaseTryAgainLater),
            icon: ImBottomNotifType.warning,
          );
          return true;
        }

        if (setupType != EncryptionSetupPasswordType.doneSetup) {
          // var confirmed = false;
          showCustomBottomAlertDialog(
            Get.context!,
            subtitle: localized(
                setupType == EncryptionSetupPasswordType.neverSetup
                    ? chatToggleEncMessage
                    : chatToggleRequirePrivateKeyMessage),
            items: [
              CustomBottomAlertItem(
                text: localized(
                    setupType == EncryptionSetupPasswordType.neverSetup
                        ? chatToggleSetNow
                        : chatRecoverNow),
                onClick: () async {
                  // confirmed = true;
                  switch (setupType) {
                    case EncryptionSetupPasswordType.neverSetup:
                      Get.toNamed(
                        RouteName.encryptionBackupKeyPage,
                        preventDuplicates: false,
                      );
                      break;
                    case EncryptionSetupPasswordType.anotherDeviceSetup:
                      Get.toNamed(
                        RouteName.encryptionVerificationPage,
                      );
                      break;
                    default:
                      break;
                  }
                },
              ),
            ],
            cancelText: localized(cancel),
            thenListener: () async {},
            onCancelListener: () async {},
            onConfirmListener: () async {},
          );
          return true;
        }

        await startChatEncryptionCreation(userIds, chat);
        imBottomToast(
          Get.context!,
          title: localized(settingConversationTurnedOn),
          icon: ImBottomNotifType.success,
        );
        return true;
      }
    } catch (e) {
      imBottomToast(
        Get.context!,
        title: localized(noNetworkPleaseTryAgainLater),
        icon: ImBottomNotifType.warning,
      );
      return true;
    }
  }

  Future<void> startChatEncryptionCreation(List<int> userIds, Chat chat) async {
    //打开加密
    int flag = chat.flag == 0
        ? ChatEncryptionFlag.encrypted.value
        : ChatEncryptionFlag.encrypted.value |
            ChatEncryptionFlag.previouslyEncrypted.value;
    bool success = false;

    final (chatKey, chatRound) = await startChatEncryption(userIds, chat: chat);
    if (chatKey != null && chatRound != null) {
      //成功创建, 更新数据库
      success =
          await objectMgr.chatMgr.sendChatEncryptionSetting(chat.chat_id, flag);
      if (success) {
        int activeRound = chatRound;
        String activeKey = chatKey;
        if (activeRound < chat.round) {
          chat.updateChatKey(chatKey, chatRound);
          activeRound = chat.round;
          activeKey = getCalculatedKey(chat, activeRound);
        }
        objectMgr.chatMgr.updateDatabaseEncryptionSetting(
          chat,
          flag,
          chatKey: chatKey,
          chatRound: chatRound,
          activeChatKey: activeKey,
          activeRound: activeRound,
        );
        objectMgr.messageManager.decryptChat([chat]);
      }
    }
  }

  String getSignedKey(Chat chat) {
    if (!chat.isActiveChatKeyValid) return "";
    try {
      String activeKey = chat.activeChatKey;
      String key =
          splitStringEquallyAndReverse(activeKey, activeKey.length ~/ 4)
              .join('');
      int halfLength = key.length ~/ 2;
      List<String> reversedKeys = splitStringEquallyAndReverse(key, halfLength);
      List<String> reversedActive =
          splitStringEquallyAndReverse(activeKey, halfLength);
      List<String> finalList = [];

      finalList.addAll(reversedKeys.sublist(0, halfLength));
      finalList.addAll(reversedActive.sublist(halfLength));
      finalList.addAll(reversedKeys.sublist(halfLength));
      finalList.addAll(reversedActive.sublist(0, halfLength));
      String reversedJson = jsonEncode(finalList.reversed.toList());
      String json = jsonEncode(finalList);
      String md5 = makeMD5(json);
      String finalString = md5;
      String md5Updated = makeMD5(reversedJson);
      finalString += md5Updated;
      return jsonEncode(
          splitStringEquallyAndReverse(finalString, halfLength * 2));
    } catch (e) {
      pdebug("报错 - ${e.toString()}");
      return "";
    }
  }

  List<List<String>> getSignedList(String signedKey, Chat chat) {
    try {
      int activeNumber = chat.activeKeyRound;
      String eightDigitStringActive = activeNumber.toString().padLeft(8, '0');
      if (eightDigitStringActive.length > 8) {
        eightDigitStringActive =
            eightDigitStringActive.substring(eightDigitStringActive.length - 8);
      }
      String active1 = eightDigitStringActive.substring(0, 2);
      String active2 = eightDigitStringActive.substring(2, 4);
      String active3 = eightDigitStringActive.substring(4, 6);
      String active4 = eightDigitStringActive.substring(6);

      int number = chat.round;
      String eightDigitString = number.toString().padLeft(8, '0');
      if (eightDigitString.length > 8) {
        eightDigitString =
            eightDigitString.substring(eightDigitString.length - 8);
      }
      String r1 = eightDigitString.substring(0, 2);
      String r2 = eightDigitString.substring(2, 4);
      String r3 = eightDigitString.substring(4, 6);
      String r4 = eightDigitString.substring(6);
      List<String> rounds = [
        active1,
        active2,
        active3,
        active4,
        r1,
        r2,
        r3,
        r4
      ];

      List<String> indexedList = jsonDecode(signedKey).cast<String>();
      int jump = indexedList.length ~/ 4;
      List<List<String>> finalList = [];
      for (int i = 0; i < indexedList.length; i += jump) {
        List<String> subList = indexedList.sublist(i, i + jump);
        finalList.add(subList);
      }
      finalList.removeLast();
      finalList.add(rounds);
      return finalList;
    } catch (e) {
      return [
        [""]
      ];
    }
  }

  String signMessage(int chatId) {
    String message = makeMD5(chatId.toString());
    var pk = objectMgr.localStorageMgr
            .read(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY) ??
        "";
    if (!notBlank(pk)) {
      return "";
    }
    return RSAEncryption.signMessage(message, pk);
  }

  bool verifyKeys(String public, String private, int userId) {
    String message = makeMD5(userId.toString());
    String signed = RSAEncryption.signMessage(message, private);
    bool verified = RSAEncryption.verifySignature(message, public, signed);
    return verified;
  }

  String getSignatureText(String signature) {
    if (!notBlank(signature)) return "";
    String bytes = RSAEncryption.getSignatureText(signature);
    return bytes;
  }

  bool verifySignedKey(Chat chat, String json) {
    String signedKey = getSignedKey(chat);
    return signedKey == json;
  }

  Future<bool> verifySignature(Chat chat, String base64Signature) async {
    List<int> users = [];
    if (chat.isSingle) {
      users = [chat.friend_id];
    } else {
      return false;
    }

    List<CipherKey> keys = await getCipherKeys(users);
    if (keys.isEmpty) return false;
    String publicKey = keys.first.public ?? "";

    if (!notBlank(publicKey)) return false;

    String message = makeMD5(chat.chat_id.toString());

    return RSAEncryption.verifySignature(message, publicKey, base64Signature);
  }

  void resetPrivateKey() {
    String title = '';
    String subTitle = '';

    if (encryptionPrivateKey == '') {
      title = localized(encryptionResetKey);
      subTitle = localized(encryptionResetKeyMessage);
    } else {
      title = localized(encryptionReplaceKey);
      subTitle = localized(encryptionReplaceKeyMessage);
    }

    showCustomBottomAlertDialog(
      Get.context!,
      title: title,
      subtitle: subTitle,
      items: [
        CustomBottomAlertItem(
          text: localized(continueProcessing),
          onClick: () {
            getOtp(OtpPageType.encryptionResetKey);
          },
        ),
      ],
    );
  }

  showSending() {
    Toast.showLoadingPopup(
      Get.context!,
      DialogType.loading,
      localized(reelForwardSending),
    );
  }

  void setNewPairKey(String? token) async {
    if (!notBlank(token)) return;

    showSending();

    if (encryptionPrivateKey == '') {
      await resetPairKey(token!);
    } else {
      await replacePairKey(token!);
    }
    objectMgr.localStorageMgr
        .remove(LocalStorageMgr.PK_QR_CODE_DOWNLOADED_KEY, private: true);
    event(this, EncryptionMgr.eventBackupKey);
  }

  Future<void> resetChatSessions(List<Chat> chats,
      {bool sendApi = true}) async {
    if (chats.isEmpty) {
      return;
    }
    List<int> chatIds = [];
    Map<int, int> chatMap = {};
    for (Chat chat in chats) {
      chatIds.add(chat.id);
      chatMap[chat.chat_id] = chat.round;
    }
    await addSignRequest(chatMap, sendApi: sendApi);
    List<int> emptyChatIds = await getAnyEmptyChatSessions(chatIds: chatIds);
    if (emptyChatIds.isNotEmpty) {
      List<ChatSession> allSessions = [];
      List<Future<ChatSession?>> futures = [];

      for (int chatId in emptyChatIds) {
        Chat emptySessionChat =
            chats.firstWhere((element) => element.chat_id == chatId);
        futures.add(getNewChatCipherForChat(emptySessionChat));
      }

      var results = await futures.wait;
      for (var session in results) {
        if (session != null) {
          allSessions.add(session);
        }
      }

      if (allSessions.isNotEmpty) {
        await updateChatCiphers(allSessions);
      }
    }
  }

  Future<void> resetPairKey(String token) async {
    /// 重置公钥和私钥
    if (!notBlank(token)) return;

    final (String newPublicKey, String newPrivateKey) =
        RSAEncryption.generateKeyPair();

    /// call api
    try {
      // 本地chat列表仅用于更新及重置状态
      final chats = await objectMgr.chatMgr.loadAllLocalChats();
      List<Chat> encryptedChats = [];
      Map<int, int> chatMap = {};
      for (var chat in chats) {
        if (chat.isEncrypted) {
          chat.updateChatKey('', 0);
          chat.updateActiveChatKey('', 0);
          encryptedChats.add(chat);
          chatMap[chat.chat_id] = chat.round;
        }
      }

      if (encryptedChats.isNotEmpty) {
        await addSignRequest(chatMap, sendApi: false);
      }

      bool status = await resetPublicPrivateKey(
          publicKey: newPublicKey, vcodeToken: token);
      if (status) {
        savePublicKey(newPublicKey);
        savePrivateKey(newPrivateKey);
        hasEncryptedPrivateKey = '';
        objectMgr.localStorageMgr.remove(LocalStorageMgr.HAS_ENCRYPTED_CHATS,
            private: true); //移除是否有加密会话标识
        objectMgr.localStorageMgr
            .remove(LocalStorageMgr.BE_ENCRYPTED_KEY, private: true);
        _clearAllNativeEncryptionKeys();
        event(this, EncryptionMgr.eventResetPairKey, data: newPrivateKey);

        imBottomToast(
          Get.context!,
          title: localized(encryptionResetKeySuccess),
          icon: ImBottomNotifType.success,
        );

        Get.toNamed(RouteName.encryptionBackupKeyPage);
      } else {
        imBottomToast(
          Get.context!,
          title: localized(encryptionResetKeyFailure),
          icon: ImBottomNotifType.warning,
        );
        return;
      }

      if (encryptedChats.isNotEmpty) {
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.HAS_ENCRYPTED_CHATS, true);
        await resetChatSessions(encryptedChats, sendApi: false);
        await objectMgr.chatMgr
            .updateEncryptionKeys(encryptedChats); //chat key 空
        clearSignRequest();
        event(
          objectMgr.encryptionMgr,
          EncryptionMgr.eventBackupKey,
        );
      }
    } catch (e) {
      dismissAllToast();
      imBottomToast(
        Get.context!,
        title: e.toString(),
        icon: ImBottomNotifType.warning,
      );
    }
  }

  Future<void> replacePairKey(String token) async {
    /// 替换公钥和私钥
    final (String newPublicKey, String newPrivateKey) =
        RSAEncryption.generateKeyPair();
    bool stopNav = false;

    /// 从后端拉取会话密钥
    List<ChatKey> chatCipherKeyList = await getCipherMyChat();

    /// call api
    try {
      bool status = await resetPublicPrivateKey(
          publicKey: newPublicKey, vcodeToken: token, resign: false);
      if (status) {
        List<Chat> encryptedChats = [];
        List<ChatSession> updateChatSession = [];
        List<Chat> invalidChats = [];
        for (ChatKey chatKey in chatCipherKeyList) {
          if (chatKey.chatId == null) continue;
          Chat? chat = objectMgr.chatMgr.getChatById(chatKey.chatId!);
          if (chat != null && chat.isVisible) {
            try {
              String? decryptChatKey =
                  decryptChatCipherKey(chatKey.session ?? '');
              if (decryptChatKey != null &&
                  notBlank(decryptChatKey) &&
                  decryptChatKey != decryptFailureEmblem) {
                if (chat.isChatKeyValid) {
                  decryptChatKey = chat.chatKey;
                  chatKey.round = chat.chatKeyRound;
                }
              } else if (decryptChatKey == decryptFailureEmblem) {
                invalidChats.add(chat);
              }

              if (decryptChatKey != null &&
                  notBlank(decryptChatKey) &&
                  decryptChatKey != decryptFailureEmblem) {
                chat.updateChatKey(decryptChatKey, chatKey.round ?? 0);
                int currentActiveRound = chat.round;
                String activeKey = getCalculatedKey(chat, currentActiveRound);
                if (notBlank(activeKey)) {
                  chat.updateActiveChatKey(activeKey, currentActiveRound);
                }

                encryptedChats.add(chat);
                if (newPublicKey != null) {
                  String encrypted =
                      RSAEncryption.encrypt(decryptChatKey, newPublicKey);
                  ChatKey chatKeyItem = ChatKey(
                      uid: chatKey.uid,
                      session: encrypted,
                      round: chatKey.round);

                  ChatSession session = ChatSession(
                      chatKeys: [chatKeyItem],
                      chatId: chatKey.chatId!,
                      round: chatKey.round ?? 0);
                  updateChatSession.add(session);
                }
              }
            } catch (e) {
              continue;
            }
          }
        }

        if (invalidChats.isNotEmpty) {
          bool resetEncryption = await isKeyValid(encryptionPublicKey,
              privateKey: encryptionPrivateKey);
          if (resetEncryption) {
            //密钥已不一样，没有必要再轮询下去
            return;
          }
        }
        await updateChatCiphers(updateChatSession);
        savePublicKey(newPublicKey);
        savePrivateKey(newPrivateKey);

        if (encryptedChats.isNotEmpty) {
          objectMgr.localStorageMgr
              .write(LocalStorageMgr.HAS_ENCRYPTED_CHATS, true);
          //向原生同步 chat key
          syncAllEncryptionChatKeys();
          //需要更新拉取消息模块，更新chat key
          objectMgr.messageManager.decryptChat(encryptedChats);
          //更新chat 内存
          objectMgr.chatMgr.decryptChat(encryptedChats);
          //需要将chat key存储到数据库
          objectMgr.chatMgr.updateEncryptionKeys(encryptedChats);
        }

        clearSignRequest();

        Get.toNamed(RouteName.encryptionBackupKeyPage);
        stopNav = true;

        imBottomToast(
          Get.context!,
          title: localized(encryptionReplaceKeySuccess),
          icon: ImBottomNotifType.success,
        );
        hasEncryptedPrivateKey = '';
        objectMgr.localStorageMgr
            .remove(LocalStorageMgr.BE_ENCRYPTED_KEY, private: true);
        event(this, EncryptionMgr.eventResetPairKey, data: newPrivateKey);
      } else {
        imBottomToast(
          Get.context!,
          title: localized(encryptionReplaceKeyFailure),
          icon: ImBottomNotifType.warning,
        );
      }

      if (!stopNav) {
        Navigator.of(Get.context!).pop();
      }
    } catch (e) {
      dismissAllToast();
    }
  }

  Future<void> getOtp(OtpPageType otpPageType) async {
    String countryCode = objectMgr.userMgr.mainUser.countryCode;
    String contactNumber = objectMgr.userMgr.mainUser.contact;

    try {
      if (countryCode != "" && contactNumber != "") {
        final res = await getOTP(
          contactNumber,
          countryCode,
          otpPageType.type,
        );
        if (res) {
          Get.toNamed(
            RouteName.otpView,
            arguments: {
              'from_view': otpPageType.page,
            },
          );
        }
      }
    } catch (e) {
      String message = noNetworkPleaseTryAgainLater;
      if (e is CodeException &&
          e.getPrefix() == ErrorCodeConstant.STATUS_OTP_REACH_LIMIT) {
        message = homeOtpMaxLimit;
      } else if (e is CodeException &&
          e.getPrefix() == ErrorCodeConstant.STATUS_OTP_BE_REACH_LIMIT) {
        message = homeOtpBeMaxLimit;
      }
      imBottomToast(
        Get.context!,
        title: localized(message),
        icon: ImBottomNotifType.warning,
      );
    }
  }

  Future<void> kickLogoutRemoveCache() async {
    if (!Config().e2eEncryptionEnabled) {
      return;
    }

    loginDesktopEncryptionPrivateKey = "";
    loginDesktopAESKey = "";
    encryptionPublicKey = "";
    encryptionPrivateKey = "";

    var enc =
        objectMgr.localStorageMgr.read(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY);
    if (enc != null) {
      objectMgr.localStorageMgr
          .remove(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY, private: true);
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.PRIVATE_KEY_EXPIRED_KEY, true);
    }

    /// 清除缓存
    objectMgr.localStorageMgr
        .remove(LocalStorageMgr.PK_QR_CODE_DOWNLOADED_KEY, private: true);
    objectMgr.localStorageMgr
        .remove(LocalStorageMgr.ENCRYPTION_PUBLIC_KEY, private: true);
    objectMgr.localStorageMgr
        .remove(LocalStorageMgr.SKIP_RECOVER_KEY, private: true);
    objectMgr.localStorageMgr
        .remove(LocalStorageMgr.SKIP_BACKUP_KEY, private: true);
    objectMgr.localStorageMgr
        .remove(LocalStorageMgr.HAS_ENCRYPTED_CHATS, private: true);
    objectMgr.localStorageMgr
        .remove(LocalStorageMgr.BE_ENCRYPTED_KEY, private: true);
    _clearAllNativeEncryptionKeys();

    /// chat key
    List<Chat> chats = await objectMgr.chatMgr.loadAllLocalChats();
    List<Chat> encryptedChats = [];

    for (Chat chat in chats) {
      if (notBlank(chat.chat_key)) {
        chat.updateChatKey('', 0);
        chat.updateActiveChatKey('', 0);
        encryptedChats.add(chat);
      }
    }

    await objectMgr.chatMgr.updateEncryptionKeys(encryptedChats);
  }

  String getCalculatedKey(Chat chat, int roundToCheck) {
    if (!chat.isChatKeyValid) return "";
    if (chat.chatKeyRound > roundToCheck) return "";

    String currentKey = "";
    if (chat.isActiveChatKeyValid && roundToCheck >= chat.activeKeyRound) {
      currentKey = chat.activeChatKey;
      int currentRound = chat.activeKeyRound;
      var numberOfTimes = roundToCheck - currentRound;
      for (int i = 0; i < numberOfTimes; i++) {
        currentKey = makeMD5(currentKey);
      }
    } else {
      currentKey = chat.chatKey;
      int currentRound = chat.chatKeyRound;
      var numberOfTimes = roundToCheck - currentRound;
      for (int i = 0; i < numberOfTimes; i++) {
        currentKey = makeMD5(currentKey);
      }
    }
    return currentKey;
  }

  String calculateNewActiveChatKey(
      String currentKey, int currentRound, int roundToCheck) {
    if (currentRound > roundToCheck) return ""; //算也算不出
    if (roundToCheck == currentRound) return currentKey; //一样不必算，直接返回
    var numberOfTimes = roundToCheck - currentRound;
    for (int i = 0; i < numberOfTimes; i++) {
      currentKey = makeMD5(currentKey);
    }
    return currentKey;
  }

  List<String> splitStringEquallyAndReverse(String input, int parts) {
    // Calculate the length of each part
    int length = input.length;
    int partLength = (length / parts)
        .ceil(); // Use ceil to handle cases where string can't be split evenly

    List<String> result = [];

    for (int i = 0; i < length; i += partLength) {
      // Extract substring and add to result
      String split =
          input.substring(i, i + partLength > length ? length : i + partLength);
      result.add(split.split('').reversed.join(''));
    }

    return result;
  }

  EncryptionMessageType getMessageType(Message message, Chat chat) {
    if (!notBlank(encryptionPrivateKey)) {
      return EncryptionMessageType.requireInputPassword;
    }

    if (!chat.isChatKeyValid) {
      if (message.ref_typ == 4) {
        return EncryptionMessageType.defaultFailure;
      }

      int? round = SignChatTask.signChatRound[chat.chat_id];
      if (round == null) {
        return EncryptionMessageType.awaitingFriend;
      }

      try {
        Map<String, dynamic> content = jsonDecode(message.content);
        int? messageRound = content['round'];
        if (messageRound == null) {
          return EncryptionMessageType.defaultFailure;
        }

        if (messageRound >= round) {
          return EncryptionMessageType.awaitingFriend;
        }
      } catch (e) {
        pdebug("消息解不出，当作默认 解不开");
      }
    }

    return EncryptionMessageType.defaultFailure;
  }

  Future<bool> isKeyValid(String publicKey, {String? privateKey}) async {
    if (!notBlank(publicKey)) return true; //增加规避，本地读不到无需进行比对操作

    try {
      CipherKey data = await getCipherMyKey();
      if (notBlank(data.public)) {
        if (privateKey != null && notBlank(privateKey)) {
          //设置了公钥私钥对，不成对并后端有公钥就清空
          bool verified =
              verifyKeys(publicKey, privateKey, objectMgr.userMgr.mainUser.uid);
          if (!verified) {
            _resetAndUpdateKeys(key: data);
            return false;
          }
        }
        if (data.public == publicKey) return true;
        if (notBlank(data.encPrivate)) {
          _resetAndUpdateKeys(key: data);
          return false;
        }
        bool isEncryptionChatExist = await checkEncryptionChat();
        if (isEncryptionChatExist) {
          _resetAndUpdateKeys(key: data);
          return false;
        }
      }
    } catch (e) {
      pdebug("公私钥对查验报错 - ${e.toString()}");
      return false;
    }
    return true;
  }

  _resetAndUpdateKeys({CipherKey? key}) async {
    await kickLogoutRemoveCache();

    if (key != null) {
      if (key.encPrivate != "") {
        //以后端的为最新，若有加密私钥，则清除后保存起来
        hasEncryptedPrivateKey = key.encPrivate ?? '';
        objectMgr.localStorageMgr.write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.BE_ENCRYPTED_KEY, hasEncryptedPrivateKey);
      }
      //以后端的为最新，若有公钥，则清除后保存起来
      encryptionPublicKey = key.public ?? '';
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.ENCRYPTION_PUBLIC_KEY, encryptionPublicKey);
    }

    event(this, EncryptionMgr.eventBackupKey);
  }

  String? processE2EDesktop(String e2eKey) {
    if (!Config().e2eEncryptionEnabled) {
      return null;
    }
    if (!notBlank(e2eKey) || e2eKey.length != 32) {
      return null;
    }
    if (!notBlank(encryptionPrivateKey)) {
      return null;
    }
    try {
      var encObj = AesEncryption(e2eKey);
      String encrypted = encObj.encrypt(encryptionPrivateKey);
      return encrypted;
    } catch (e) {
      pdebug("桌面端生成加密密钥报错 - ${e.toString()}");
    }

    return null;
  }

  static String generateE2eKey() {
    loginDesktopAESKey = EncryptionMgr.getRandomString(32);
    return loginDesktopAESKey;
  }

  _processDesktopLogin() {
    if (!Config().e2eEncryptionEnabled) return;
    if (!notBlank(loginDesktopEncryptionPrivateKey) ||
        !notBlank(loginDesktopAESKey)) return;
    var encObj = AesEncryption(loginDesktopAESKey);
    var encrypted = loginDesktopEncryptionPrivateKey;
    var decrypted = encObj.decrypt(encrypted);

    if (RSAEncryption.isValidPrivateKey(decrypted)) {
      encryptionPrivateKey = decrypted;
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY, decrypted);
    }
    loginDesktopEncryptionPrivateKey = "";
    loginDesktopAESKey = "";
  }

  _processDesktopEncryptionKeys() async {
    try {
      CipherKey data = await getCipherMyKey();
      if (notBlank(data.public)) {
        bool verified = verifyKeys(data.public ?? '', encryptionPrivateKey,
            objectMgr.userMgr.mainUser.uid);
        if (verified) {
          encryptionPublicKey = data.public ?? '';
          objectMgr.localStorageMgr.write(
              LocalStorageMgr.ENCRYPTION_PUBLIC_KEY, encryptionPublicKey);

          if (data.encPrivate != "") {
            hasEncryptedPrivateKey = data.encPrivate ?? '';
            objectMgr.localStorageMgr
                .write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
            objectMgr.localStorageMgr.write(
                LocalStorageMgr.BE_ENCRYPTED_KEY, hasEncryptedPrivateKey);
          }
          decryptChat();
        } else {
          kickLogoutRemoveCache();
        }
      } else {
        kickLogoutRemoveCache();
      }
    } catch (e) {
      pdebug("移动端整到desktop - ${e.toString()}");
    }
  }

  triggerQrCodeDownload() {
    objectMgr.localStorageMgr.write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.PK_QR_CODE_DOWNLOADED_KEY, true);

    event(
      this,
      EncryptionMgr.eventBackupKey,
    );
  }

  updateSkipRecover() {
    objectMgr.localStorageMgr.write(LocalStorageMgr.SKIP_RECOVER_KEY, true);
    event(
      objectMgr.encryptionMgr,
      EncryptionMgr.eventBackupKey,
    );
  }

  Future<EncryptionPanelType> shouldShowPanel() async {
    return EncryptionPanelType.none;
    // if (!(beEncryptionEnabled ?? Config().e2eEncryptionEnabled)) {
    //   return EncryptionPanelType.none;
    // }
    //
    // if (!notBlank(encryptionPrivateKey)) {
    //   //Recover
    //   var skipRecoverKey =
    //       objectMgr.localStorageMgr.read(LocalStorageMgr.SKIP_RECOVER_KEY) ??
    //           false;
    //
    //   if (skipRecoverKey) return EncryptionPanelType.none;
    //   if (notBlank(hasEncryptedPrivateKey)) {
    //     //后端有取过私钥
    //     var recoverKickKey = objectMgr.localStorageMgr
    //         .read(LocalStorageMgr.PRIVATE_KEY_EXPIRED_KEY);
    //     return recoverKickKey != null
    //         ? EncryptionPanelType.recoverKick
    //         : EncryptionPanelType.recover;
    //   } else {
    //     //不知道后端有没有取过，所以需要再取。
    //     try {
    //       CipherKey data = await getCipherMyKey();
    //       if (data.encPrivate != '') {
    //         hasEncryptedPrivateKey = data.encPrivate ?? '';
    //         objectMgr.localStorageMgr
    //             .write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
    //         objectMgr.localStorageMgr.write(
    //             LocalStorageMgr.BE_ENCRYPTED_KEY, hasEncryptedPrivateKey);
    //         var recoverKickKey = objectMgr.localStorageMgr
    //             .read(LocalStorageMgr.PRIVATE_KEY_EXPIRED_KEY);
    //         return recoverKickKey != null
    //             ? EncryptionPanelType.recoverKick
    //             : EncryptionPanelType.recover;
    //       }
    //       if (data.public != '') {
    //         bool isEncryptionChatExist = await checkEncryptionChat();
    //         if (isEncryptionChatExist) {
    //           var recoverKickKey = objectMgr.localStorageMgr
    //               .read(LocalStorageMgr.PRIVATE_KEY_EXPIRED_KEY);
    //           return recoverKickKey != null
    //               ? EncryptionPanelType.recoverKick
    //               : EncryptionPanelType.recover;
    //         }
    //       }
    //
    //       return EncryptionPanelType.none;
    //     } catch (e) {
    //       if (e is AppException &&
    //           e.getPrefix() == ErrorCodeConstant.ENCRYPTION_KEY_NOT_EXISTS) {
    //         return EncryptionPanelType.none; // 后端没有
    //       } else {
    //         String? bePrivateKey = objectMgr.localStorageMgr
    //             .read(LocalStorageMgr.BE_ENCRYPTED_KEY); //网路报错，读本地
    //         if (notBlank(bePrivateKey)) {
    //           var recoverKickKey = objectMgr.localStorageMgr
    //               .read(LocalStorageMgr.PRIVATE_KEY_EXPIRED_KEY);
    //           return recoverKickKey != null
    //               ? EncryptionPanelType.recoverKick
    //               : EncryptionPanelType.recover;
    //         } else {
    //           return EncryptionPanelType.none;
    //         }
    //       }
    //     }
    //   }
    // } else {
    //   //Backup
    //   var skipBackup =
    //       objectMgr.localStorageMgr.read(LocalStorageMgr.SKIP_BACKUP_KEY) ??
    //           false;
    //   if (skipBackup) return EncryptionPanelType.none;
    //   try {
    //     CipherKey data = await getCipherMyKey();
    //     if (notBlank(data.encPrivate)) {
    //       if (data.public != encryptionPublicKey) {
    //         //本地有私钥的情况，
    //         _resetAndUpdateKeys();
    //         return EncryptionPanelType.recoverKick;
    //       }
    //
    //       objectMgr.localStorageMgr
    //           .write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
    //       return EncryptionPanelType.none;
    //     }
    //   } catch (e) {
    //     String? bePrivateKey = objectMgr.localStorageMgr
    //         .read(LocalStorageMgr.BE_ENCRYPTED_KEY); //网路报错，读本地
    //     if (notBlank(bePrivateKey)) {
    //       return EncryptionPanelType.none; //相等于最后后端有，不展示，否则继续查验
    //     }
    //   }
    //
    //   bool hasEncryptedChats = await checkEncryptionChat();
    //   if (!hasEncryptedChats) return EncryptionPanelType.none;
    //   return EncryptionPanelType.backup;
    // }
  }

  toggleEncryptionChatUpdate(bool flag) {
    // flag true的时候，查验变换是否有加密聊天室标识。
    if (flag == false) return;
    var hasEncryptedChats =
        objectMgr.localStorageMgr.read(LocalStorageMgr.HAS_ENCRYPTED_CHATS);
    if (hasEncryptedChats == true) return true;
    objectMgr.localStorageMgr.write(LocalStorageMgr.HAS_ENCRYPTED_CHATS, true);
  }

  updateSkipBackup() {
    objectMgr.localStorageMgr.write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
    event(
      this,
      EncryptionMgr.eventBackupKey,
    );
  }

  scanQRFlow() {
    //扫二维码进来，当作以前备份过私钥（QR码下载），也把跳过标识做个更新（不再触发toast）
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.PK_QR_CODE_DOWNLOADED_KEY, true);
    objectMgr.localStorageMgr.write(LocalStorageMgr.SKIP_BACKUP_KEY, true);
    objectMgr.encryptionMgr.decryptChat();
    event(
      this,
      EncryptionMgr.eventBackupKey,
    );
  }

  readRemoteEncryptionEnabled() {
    //可能后端调取还未初始化user，这时先读取。读取缓存不和账号绑定。
    beEncryptionEnabled =
        objectMgr.localStorageMgr.read(LocalStorageMgr.BE_ENCRYPTION_ENABLED);
  }

  updateRemoteEncryptionEnabled(bool encryptionEnabled) {
    if (beEncryptionEnabled != encryptionEnabled) {
      beEncryptionEnabled = encryptionEnabled;
      objectMgr.localStorageMgr
          .write(LocalStorageMgr.BE_ENCRYPTION_ENABLED, beEncryptionEnabled);
    }
  }

  syncAllEncryptionChatKeys() async {
    if (!notBlank(encryptionPublicKey) || !notBlank(encryptionPrivateKey)) {
      return;
    }
    final chats = await objectMgr.chatMgr.loadAllLocalChats();
    if (chats.isEmpty) return;
    final encryptedChats = chats
        .where((element) => element.isEncrypted && element.isActiveChatKeyValid)
        .toList();
    if (encryptedChats.isEmpty) return;
    Map<String, Map<String, dynamic>> chatMap = {};
    for (var chat in encryptedChats) {
      Map<String, dynamic> keyMap = {};
      keyMap['activeRound'] = chat.activeKeyRound;
      keyMap['round'] = chat.round;
      keyMap['activeKey'] = chat.activeChatKey;
      keyMap['isSingle'] = chat.isSingle;
      chatMap[chat.chat_id.toString()] = keyMap;
    }

    chatMap["encryption_language"] = {
      "image": "📷 ${localized(chatTagPhoto)}", // 2
      "video": "🎬 ${localized(video_call)}", // 4, 24
      "album": "📷 ${localized(album)}", // 8
      "album_onlyVideo":
          "📷 ${localized(chatTagVideoMultiple)}", // 8 (only videos)
      "album_onlyImage":
          "📷 ${localized(chatTagImageMultiple)}", // 8 (only images)
      "voice": "🎤 ${localized(voiceMsg)}", //3
      "file": "📎 ", // 6
      "gif": "📹 GIF", // 25
      "sticker": localized(chatTagSticker), // 5
      "location": "📍 ${localized(attachmentLocation)}", // 7
      "recommendFriend": "👤 ", //15
      "all": localized(chatAll), //at all users
    };

    if (!objectMgr.loginMgr.isDesktop) {
      if (Platform.isIOS) {
        _methodChannel.invokeMethod("syncEncryptionKeys", [chatMap]);
      } else {
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.ANDROID_CHAT_LIST_KEY, chatMap);
      }
    }
  }

  _clearAllNativeEncryptionKeys() {
    if (!objectMgr.loginMgr.isDesktop) {
      if (Platform.isIOS) {
        _methodChannel.invokeMethod("clearEncryptionKeys");
      } else {
        objectMgr.localStorageMgr.remove(LocalStorageMgr.ANDROID_CHAT_LIST_KEY);
      }
    }
  }

  Map<String, dynamic> processMsgText(
      int msgTyp, Map<String, dynamic> content) {
    switch (msgTyp) {
      case messageTypeNewAlbum:
        if (content["albumList"] != null && content["albumList"] is List) {
          var album = content["albumList"];
          String? type;
          int count = album.length;
          bool hasDiffType = false;
          int finalType = 0;
          for (var item in album) {
            if (item["mimeType"] != null && item["mimeType"] is String) {
              if (type != null && type != item["mimeType"]) {
                finalType = 0;
                hasDiffType = true;
                break;
              }
              type = item["mimeType"];
            }
          }

          if (!hasDiffType) {
            finalType = type == "image" ? 1 : 2;
          }
          return {"count": count, "type": finalType};
        }
        break;
      case messageTypeFile:
        if (content["file_name"] != null) {
          return {"file_name": content["file_name"]};
        }
        break;
      case messageTypeRecommendFriend:
        if (content["nick_name"] != null) {
          return {"nick_name": content["nick_name"]};
        }
        break;
      default:
        if (content["text"] != null && content["text"] is String) {
          String text = content["text"];
          return {"text": text.substring(0, 40) + "..."};
        }
        break;
    }
    return {"text": localized(chatPreview)};
  }

  Future<void> firstTimeUpdateCiphers() async {
    try {
      final rep = await list(
        objectMgr.userMgr.mainUser.uid,
        startTime: null,
      );
      var chatList = ChatList.fromJson(rep.data);
      if (chatList.data != null) {
        Map<int, int> encChatMap = {};
        for (var item in chatList.data) {
          if (item['flag'] != null && ChatHelp.hasEncryptedFlag(item['flag'])) {
            encChatMap[item["chat_id"]] = item["round"];
          }
        }
        if (encChatMap.isNotEmpty) {
          addSignRequest(encChatMap);
        }
      }
    } catch (e) {
      pdebug(e.toString());
    }
  }

  @override
  Future<void> recover() async {}

  @override
  Future<void> registerOnce() async {}
}
