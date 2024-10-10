import 'dart:convert';
import 'dart:math';

import 'package:events_widget/event_dispatcher.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/api/chat.dart';
import 'package:jxim_client/api/encryption.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/socket_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/end_to_end_encryption/model/encryption_model.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_list.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/encryption/aes_encryption.dart';
import 'package:jxim_client/utils/encryption/rsa_encryption.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_item.dart';

/// 1. 检查本地是否有公钥和私钥
/// 2. 后端获取用户的公钥和私钥
/// 3. 检查后端是否有私钥
/// 4. [3的结果-是]：引导去[输入加密密码页面]
/// 5. [3的结果-否]：检查后端是否有公钥
/// 6. [5的结果-是]：引导去[加密验证页面]
/// 7. [5的结果-否]：本地生成公钥和私钥，保存到Local Storage，上传公钥到后端

class EncryptionMgr extends EventDispatcher implements MgrInterface {
  static const String eventResetPairKey = 'eventResetPairKey';
  static const String eventResetPrivateKeyPW = 'eventResetPrivateKeyPW';

  String encryptionPublicKey = "";
  String encryptionPrivateKey = "";
  String newEncryptionPublicKey = "";
  String hasEncryptedPrivateKey = "";
  bool hasBEPrivateKey = false;
  bool shownVerificationNavigation = false;

  List<int> reqSignChatList = [];

  @override
  Future<void> init() async {
    initEncryptionKey();
    if (objectMgr.socketMgr.isAlreadyPubSocketOpen) {
      _onSocketOpen(null, null, null);
    }
    objectMgr.socketMgr.on(SocketMgr.eventSocketOpen, _onSocketOpen);
  }

  Future<void> _onSocketOpen(a, b, c) async {
    if (encryptionPublicKey == "") {
      await getCipherKey();
      objectMgr.chatMgr.event(this, ChatMgr.eventChatListLoaded);
    }
  }

  @override
  Future<void> logout() async {
    encryptionPublicKey = "";
    encryptionPrivateKey = "";
    hasEncryptedPrivateKey = "";
    reqSignChatList.clear();
    hasBEPrivateKey = false;
    objectMgr.socketMgr.off(SocketMgr.eventSocketOpen, _onSocketOpen);
  }

  @override
  Future<void> register() async {}

  @override
  Future<void> reloadData() async {}

  void initEncryptionKey() async {
    /// 1. 检查本地是否有公钥和私钥
    encryptionPublicKey =
        objectMgr.localStorageMgr.read(LocalStorageMgr.ENCRYPTION_PUBLIC_KEY) ??
            "";
    encryptionPrivateKey = objectMgr.localStorageMgr
            .read(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY) ??
        "";
    shownVerificationNavigation = objectMgr.localStorageMgr.read(LocalStorageMgr.SHOWN_VERIFICATION_NAVIGATION) ?? false;
  }

  Future<void> getCipherKey() async {
    /// 2. 后端获取用户的公钥和私钥
    /// 3. 检查后端是否有私钥

    encryptionPrivateKey = objectMgr.localStorageMgr
            .read(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY) ??
        '';
    if (encryptionPrivateKey != '') {
      return;
    }

    try {
      CipherKey data = await getCipherMyKey();

      if (data.encPrivate != "") {
        /// 4. [3的结果-是]：引导去[输入加密密码页面]
        hasEncryptedPrivateKey = data.encPrivate ?? '';
        hasBEPrivateKey = true;

        if (data.public != '') {
          encryptionPublicKey = data.public ?? '';
          objectMgr.localStorageMgr.write(
              LocalStorageMgr.ENCRYPTION_PUBLIC_KEY, encryptionPublicKey);
        }
        if (!shownVerificationNavigation) {
          shownVerificationNavigation = true;
          objectMgr.localStorageMgr.write(LocalStorageMgr.SHOWN_VERIFICATION_NAVIGATION, shownVerificationNavigation);
          navigateEncryptionVerificationPage(data);
        }
      } else {
        /// 5. [3的结果-否]：检查后端是否有公钥
        if (data.public != '') {
          /// 6. [5的结果-是]：引导去[加密验证页面]
          bool isEncryptionChatExist = await checkEncryptionChat();
          if (isEncryptionChatExist) {
            if (!shownVerificationNavigation) {
              shownVerificationNavigation = true;
              objectMgr.localStorageMgr.write(LocalStorageMgr.SHOWN_VERIFICATION_NAVIGATION, shownVerificationNavigation);
              navigateEncryptionVerificationPage(data);
            }
          } else {
            await setEncryptionKey();
          }
        } else {
          await setEncryptionKey();
          List<Chat> chats = await getAllSingleEncryptedChats();
          for (var chat in chats) {
            getAndUpdatePublicKey(chat.friend_id);
            objectMgr.chatMgr.updateEncryptionSettings(chat, chat.flag, chatKey: encryptionPrivateKey, sender: this);
            requestChatUpdateFromFriends(chat.chat_id);
          }
        }
      }
    } on AppException catch (e) {
      if (e.getPrefix() == ErrorCodeConstant.ENCRYPTION_KEY_NOT_EXISTS) {
        await setEncryptionKey();
        List<Chat> chats = await getAllSingleEncryptedChats();
        for (var chat in chats) {
          getAndUpdatePublicKey(chat.friend_id);
          objectMgr.chatMgr.updateEncryptionSettings(chat, chat.flag, chatKey: encryptionPrivateKey, sender: this);
          requestChatUpdateFromFriends(chat.chat_id);
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

  Future<bool> setEncryptionKey({String password = ''}) async {
    /// 7. [5的结果-否]：本地生成公钥和私钥，保存到Local Storage，上传公钥到后端
    /// 明文公钥和私钥
    final (String publicKey, String privateKey) =
        RSAEncryption.generateKeyPair();
    bool status = false;

    if (password != "") {
      var encryptedPrivateKey = getEncPrivateKey(privateKey, password);
      status = await setCipherMyKey(publicKey,
          encryptedPrivateKey: encryptedPrivateKey);
      hasBEPrivateKey = true;
    } else {
      status = await setCipherMyKey(publicKey);
    }

    if (status) {
      saveEncryptionKey(publicKey, privateKey);
    }

    return status;
  }

  Future<String> updateEncryptionPrivateKey(
      String oriPublicKey, String password) async {
    String encryptedPrivateKey =
        getEncPrivateKey(encryptionPrivateKey, password);

    bool status = false;
    if (encryptedPrivateKey != '') {
      status = await setCipherMyKey(oriPublicKey,
          encryptedPrivateKey: encryptedPrivateKey);
      hasBEPrivateKey = true;
    }

    if (status) {
      hasEncryptedPrivateKey = encryptedPrivateKey;
      return encryptedPrivateKey;
    } else {
      return '';
    }
  }

  bool saveEncryptionKey(String publicKey, String privateKey) {
    if (publicKey != '' && privateKey != '') {
      savePublicKey(publicKey);
      savePrivateKey(privateKey);
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
    }
  }

  Future<EncryptionSetupPasswordType> isChatEncryptionNewSetup() async {
    if (notBlank(encryptionPrivateKey)) {
      try {
        CipherKey data = await getCipherMyKey();
        if (notBlank(data.encPrivate)) {
          hasEncryptedPrivateKey = data.encPrivate ?? '';
          hasBEPrivateKey = true;
          return EncryptionSetupPasswordType.doneSetup;
        } else {
          return EncryptionSetupPasswordType.neverSetup;
        }
      } on AppException catch (_) {
        return EncryptionSetupPasswordType.neverSetup;
      }
    } else {
      return EncryptionSetupPasswordType.anotherDeviceSetup;
    }
  }

  Future<EncryptionSetupPasswordType> isEncryptionNewSetup() async {
    if (encryptionPrivateKey != '') {
      return EncryptionSetupPasswordType.doneSetup;
    }

    if (hasEncryptedPrivateKey != '' && encryptionPrivateKey != '') {
      return EncryptionSetupPasswordType.doneSetup;
    } else {
      try {
        CipherKey data = await getCipherMyKey();
        if (data.public != '') {
          savePublicKey(data.public!);
        }

        if (data.encPrivate != '') {
          hasEncryptedPrivateKey = data.encPrivate ?? '';
          hasBEPrivateKey = true;
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
      } on AppException catch (_) {
        return EncryptionSetupPasswordType.neverSetup;
      }
    }
  }

  void navigateEncryptionVerificationPage(CipherKey data) {
    Get.toNamed(RouteName.encryptionVerificationPage, arguments: {
      "encPrivateKey": data.encPrivate,
      "hasBack": false,
    });
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

  Future<String?> createChatEncryption(List<int> userIds, int chatId,
      {String? chatKey}) async {
    //获取所有用户的公钥
    try {
      chatKey ??= await getChatCipherKey(chatId);
      List<CipherKey> data = await getCipherKeys(userIds);

      //生成随机会话密钥
      String randomString = notBlank(chatKey)
          ? chatKey!
          : getRandomString(32); // 32 = aes 128, 64 = aes 256 有旧的就用旧的
      List<ChatKey> updatedKeys = [];
      if (data.isEmpty) {
        //数据为空，不跟后端更新会话密钥，直接设置加密会话。
        return randomString;
      }

      Map<int, String> pkMapping = {};
      for (CipherKey key in data) {
        if (key.public != null) {
          String encrypted = RSAEncryption.encrypt(randomString, key.public!);
          updatedKeys.add(ChatKey(uid: key.uid ?? 0, session: encrypted));
          pkMapping[key.uid ?? 0] = key.public ?? '';
        }
      }
      updatePublicKeys(pkMapping);

      ChatSession session = ChatSession(chatKeys: updatedKeys, chatId: chatId);

      bool success = await updateChatCiphers([session]);
      return success ? randomString : null;
    } catch (e) {
      pdebug(e.toString());
    }

    return null;
  }

  Future<void> updatePublicKeys(Map<int, String> data) async {
    List<User> users = [];
    for (var entry in data.entries) {
      User? user = await objectMgr.userMgr.loadUserById(entry.key);
      if (user != null) {
        user.publicKey = entry.value;
        users.add(user);
      }
    }
    objectMgr.userMgr.onUserChanged(users);
  }

  Future<String?> getChatCipherKey(int chatId) async {
    bool chatHasCipher = false;
    try {
      ChatKey data = await getChatCipher(chatId);
      if (notBlank(data.session)) {
        chatHasCipher = true;
        return decryptChatCipherKey(data.session!);
      }
    } catch (e) {
      pdebug(e.toString());
    }
    if (!chatHasCipher) {
      if (reqSignChatList.contains(chatId)) {
        return null;
      }
      reqSignChatList.add(chatId);
      requestChatUpdateFromFriends(chatId);
    }

    return null;
  }

  Future<void> requestChatUpdateFromFriends(int chatId) async {
    try {
      for (int i = 0; i < 10 && encryptionPublicKey == ""; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      requestChatCipher(chatId, encryptionPublicKey);
    } catch (e) {
      pdebug("requestChatCipher chat id:$chatId");
    }
  }

  Future<void> decryptChat() async {
    List<ChatKey> chatCipherKeyList = await getCipherMyChat();
    List<Chat> encryptedChats = [];

    if (chatCipherKeyList.isNotEmpty) {
      for (ChatKey chatKey in chatCipherKeyList) {
        if (chatKey.chatId == null) return;
        Chat? chat = objectMgr.chatMgr.getChatById(chatKey.chatId!);
        if (chat != null) {
          try {
            String? decryptChatKey =
                decryptChatCipherKey(chatKey.session ?? '');
            if (decryptChatKey != null) {
              chat.chat_key = decryptChatKey;
              encryptedChats.add(chat);
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

    final chats = await objectMgr.chatMgr.loadAllLocalChats();
    for (var chat in chats) {
      if (chat.isSingle && chat.isEncrypted) {
        objectMgr.encryptionMgr.getAndUpdatePublicKey(chat.friend_id);
        await objectMgr.chatMgr.updateEncryptionSettings(chat, chat.flag,
            chatKey: encryptionPrivateKey, sender: this);
        encryptedChats.add(chat);
      }
    }
    //需要更新拉取消息模块，更新chat key
    objectMgr.messageManager.decryptChat(encryptedChats);
    //需要将chat key存储到数据库
    objectMgr.chatMgr.updateEncryptionKeys(encryptedChats);
  }

  String? decryptChatCipherKey(String encryptionChatKey) {
    var pk = objectMgr.localStorageMgr
            .read(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY) ??
        "";
    // var pub = objectMgr.localStorageMgr.read(LocalStorageMgr.ENCRYPTION_PUBLIC_KEY) ?? "";
    try {
      String decrypted = RSAEncryption.decrypt(encryptionChatKey, pk);
      if (decrypted.length == 32) {
        // asyncCheckFirstTimeToast();
        return decrypted;
      }
    }catch(e){
      //todo
    }
    return null;
  }

  Future<bool> asyncCheckFirstTimeToast() async {
    if (hasBEPrivateKey) return false;
    try {
      CipherKey data = await getCipherMyKey();
      if (data.encPrivate != "") {
        /// 4. [3的结果-是]：引导去[输入加密密码页面]
        hasEncryptedPrivateKey = data.encPrivate ?? '';
        hasBEPrivateKey = true;
        return false; //已设置过，不必再设置
      } else if (notBlank(encryptionPrivateKey)) {
        return true; //没设置过，有明文私钥，弹
      } else {
        //没设置过，没明文私钥，不弹
        return false;
      }
    } on AppException catch (_) {
      return false;
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
    bool status = false;
    List<ChatKey> chatCipherKeyList = await getCipherMyChat();
    if (chatCipherKeyList.isNotEmpty) {
      status = true;
    } else {
      //查验有没有单聊的加密会话
      List<Chat> chats = await getAllSingleEncryptedChats();
      if (chats.isNotEmpty) {
        status = true;
      }
    }
    return status;
  }

  Future<List<Chat>> getAllSingleEncryptedChats() async {
    List<Chat> encryptedChats = [];
    try {
      final rep = await list(
        objectMgr.userMgr.mainUser.uid,
        startTime: null,
      );

      var chatList = ChatList.fromJson(rep.data);
      List data = chatList.data;
      for (var item in data) {
        Chat? chat = objectMgr.chatMgr.getChatById(item['id']);
        if (chat != null && chat.isSingle && chat.isEncrypted) {
          encryptedChats.add(chat);
        }
      }
    } catch (e) {
      pdebug("获取所有聊天室报错 - ${e.toString()}");
    }

    return encryptedChats;
  }

  Future<bool> onEncryptionToggle(Chat chat, List<int> userIds) async {
    if (chat.isEncrypted) {
      //关闭加密
      objectMgr.chatMgr.updateEncryptionSettings(
          chat, ChatEncryptionFlag.previouslyEncrypted.value, sender: this);
      return true;
    } else {
      var setupType = await isChatEncryptionNewSetup();

      if (setupType != EncryptionSetupPasswordType.doneSetup) {
        // var confirmed = false;
        if (setupType == EncryptionSetupPasswordType.neverSetup) {
          await startChatEncryptionCreation(userIds, chat);
          if (objectMgr.localStorageMgr.read(LocalStorageMgr.MUTE_PRIVATE_KEY_UPDATE) == true) {
            return true;
          }
        }

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
                      : chatVerifyNow),
              onClick: () async{
                // confirmed = true;
                switch (setupType) {
                  case EncryptionSetupPasswordType.neverSetup:
                    Get.toNamed(RouteName.encryptionPreSetupPage, arguments: {

                    });
                    break;
                  case EncryptionSetupPasswordType.anotherDeviceSetup:
                    Get.toNamed(RouteName.encryptionVerificationPage, arguments: {
                      "encPrivateKey":
                      objectMgr.encryptionMgr.hasEncryptedPrivateKey,
                      "successCallback": () async {
                        String? key = await getChatCipherKey(
                            chat.chat_id); //同步私钥后，立马开启加密会话需要重新取会话密钥，否则来不及同步导致会话密钥变更
                        if (key != null) {
                          chat.chat_key = key;
                        }
                        await startChatEncryptionCreation(userIds, chat);
                      },
                    });
                    break;
                  default:
                    break;
                }
              },
            ),
            if (setupType == EncryptionSetupPasswordType.neverSetup)
            CustomBottomAlertItem(
              text: localized(chatDontRemindAgain),
              textColor: colorRed,
              onClick: () {
                objectMgr.localStorageMgr
                    .write(LocalStorageMgr.MUTE_PRIVATE_KEY_UPDATE, true);
              },
            ),
          ],
          cancelText: localized(cancel),
          thenListener: () async {},
          onCancelListener: () async {},
          onConfirmListener: () async {

          },
        );
        return true;
      }

      await startChatEncryptionCreation(userIds, chat);
      return true;
    }
  }

  Future<void> startChatEncryptionCreation(List<int> userIds, Chat chat) async {
    //打开加密
    int flag = chat.flag == 0
        ? ChatEncryptionFlag.encrypted.value
        : ChatEncryptionFlag.encrypted.value |
    ChatEncryptionFlag.previouslyEncrypted.value;
    if (chat.isSingle) {
      bool hasCipherKey = await objectMgr.encryptionMgr.getAndUpdatePublicKey(chat.friend_id);
      if (!hasCipherKey) {
        imBottomToast(
          Get.context!,
          title: localized(encryptionResetKeySuccess),
          icon: ImBottomNotifType.success,
          isStickBottom: true,
        );
        return;
      }
      objectMgr.chatMgr.updateEncryptionSettings(chat, flag, chatKey: encryptionPrivateKey, sender: this);
    } else {
      String? chatKey = await createChatEncryption(userIds, chat.chat_id,
          chatKey: chat.chat_key);
      if (chatKey != null) {
        //成功创建, 更新数据库
        objectMgr.chatMgr.updateEncryptionSettings(chat, flag, chatKey: chatKey, sender: this);
      }
    }

  }

  Future<String> getSignedKey(Chat chat) async{
    if (!notBlank(encryptionPrivateKey)) return "";
    String privateKey = encryptionPrivateKey;
    String code = getRandomString(8);
    int uid = objectMgr.userMgr.mainUser.uid;
    User? friend = await objectMgr.userMgr.loadUserById(chat.friend_id);
    if (friend == null) return "";
    if (!notBlank(friend.publicKey)) return "";
    String selfSigned = RSAEncryption.signMessage(code, privateKey);
    String friendEncrypted = RSAEncryption.encrypt(code, friend.publicKey);
    Map<String, dynamic> items = {
      "uid": uid,
      "code": code,
      "self": selfSigned,
      "friend": friendEncrypted,
    };
    
    return jsonEncode(items);
  }

  String getSignedText(String signedKey) {
    return "";
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

  String getSignatureText(String signature) {
    if (!notBlank(signature)) return "";
    String bytes = RSAEncryption.getSignatureText(signature);
    return bytes;
  }

  Future<bool> verifySignedKey(Chat chat, String json) async{
    Map<String, dynamic> items = jsonDecode(json);
    int? uid = items["uid"];
    String? code = items["code"];
    String? self = items["self"];
    String? friend = items["friend"];

    if (uid == null ||
        code == null ||
        self == null ||
        friend == null ||
        !notBlank(encryptionPrivateKey)) return false;
    User? f = await objectMgr.userMgr.loadUserById(uid);
    if (f == null || !notBlank(f.publicKey)) return false;

    try {
      bool verifiedSignature =
          RSAEncryption.verifySignature(code, f.publicKey, self);
      String decrypted = RSAEncryption.decrypt(friend, encryptionPrivateKey);
      bool decryptVerification = decrypted == code;

      return verifiedSignature && decryptVerification;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifySignature(Chat chat, String base64Signature) async{
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

  void setNewPairKey(String? token) async {
    if (!notBlank(token)) return;

    if (encryptionPrivateKey == '') {
      await resetPairKey(token!);
    } else {
      await replacePairKey(token!);
    }

    final chats = await objectMgr.chatMgr.loadAllLocalChats();
    for (var chat in chats) {
      if (chat.isSingle && chat.isEncrypted) {
        requestChatUpdateFromFriends(chat.chat_id);
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
      bool status = await resetPublicPrivateKey(
          publicKey: newPublicKey, vcodeToken: token);
      if (status) {
        savePublicKey(newPublicKey);
        savePrivateKey(newPrivateKey);
        List<Chat> encryptedChats = [];
        final chats = await objectMgr.chatMgr.loadAllLocalChats();
        for (var chat in chats) {
          if (chat.isSingle && chat.isEncrypted) {
            chat.chat_key = encryptionPrivateKey;
            objectMgr.encryptionMgr.getAndUpdatePublicKey(chat.friend_id);
            objectMgr.chatMgr.updateEncryptionSettings(chat, chat.flag,
                chatKey: encryptionPrivateKey, sender: this);
            encryptedChats.add(chat);
          }
        }
        //需要更新拉取消息模块，更新chat key
        objectMgr.messageManager.decryptChat(encryptedChats);
        //需要将chat key存储到数据库
        objectMgr.chatMgr.updateEncryptionKeys(encryptedChats);
        hasEncryptedPrivateKey = '';
        event(this, EncryptionMgr.eventResetPairKey, data: newPrivateKey);

        imBottomToast(
          Get.context!,
          title: localized(encryptionResetKeySuccess),
          icon: ImBottomNotifType.success,
          isStickBottom: true,
        );
      } else {
        imBottomToast(
          Get.context!,
          title: localized(encryptionResetKeyFailure),
          icon: ImBottomNotifType.warning,
          isStickBottom: true,
        );
      }
    } on AppException catch (e) {
      imBottomToast(
        Get.context!,
        title: e.toString(),
        icon: ImBottomNotifType.warning,
        isStickBottom: true,
      );
    }



  }

  Future<void> replacePairKey(String token) async {
    /// 替换公钥和私钥
    final (String newPublicKey, String newPrivateKey) =
        RSAEncryption.generateKeyPair();

    /// call api
    bool status =
        await resetPublicPrivateKey(publicKey: newPublicKey, vcodeToken: token);
    if (status) {
      /// 从后端拉取会话密钥
      List<ChatKey> chatCipherKeyList = await getCipherMyChat();
      List<Chat> encryptedChats = [];
      List<ChatKey> updatedKeys = [];

      for (ChatKey chatKey in chatCipherKeyList) {
        if (chatKey.chatId == null) return;
        Chat? chat = objectMgr.chatMgr.getChatById(chatKey.chatId!);
        if (chat != null) {
          try {
            String? decryptChatKey =
                decryptChatCipherKey(chatKey.session ?? '');
            if (decryptChatKey != null) {
              chat.chat_key = decryptChatKey;
              encryptedChats.add(chat);
              if (newPublicKey != null) {
                String encrypted =
                    RSAEncryption.encrypt(decryptChatKey, newPublicKey);
                updatedKeys
                    .add(ChatKey(uid: chatKey.uid, session: encrypted));
                // String decrypted = RSAEncryption.decrypt(encrypted, newPrivateKey);
                
                ChatSession session = ChatSession(
                    chatKeys: updatedKeys, chatId: chatKey.chatId!);
                await updateChatCiphers([session]);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
      savePublicKey(newPublicKey);
      savePrivateKey(newPrivateKey);
      final chats = await objectMgr.chatMgr.loadAllLocalChats();
      for (var chat in chats) {
        if (chat.isSingle && chat.isEncrypted) {
          chat.chat_key = encryptionPrivateKey;
          objectMgr.encryptionMgr.getAndUpdatePublicKey(chat.friend_id);
          objectMgr.chatMgr.updateEncryptionSettings(chat, chat.flag,
              chatKey: encryptionPrivateKey, sender: this);
          encryptedChats.add(chat);
        }
      }
      //需要更新拉取消息模块，更新chat key
      objectMgr.messageManager.decryptChat(encryptedChats);
      //需要将chat key存储到数据库
      objectMgr.chatMgr.updateEncryptionKeys(encryptedChats);
      hasEncryptedPrivateKey = '';
      event(this, EncryptionMgr.eventResetPairKey, data: newPrivateKey);

      imBottomToast(
        Get.context!,
        title: localized(encryptionReplaceKeySuccess),
        icon: ImBottomNotifType.success,
        isStickBottom: true,
      );
    } else {
      imBottomToast(
        Get.context!,
        title: localized(encryptionReplaceKeyFailure),
        icon: ImBottomNotifType.warning,
        isStickBottom: true,
      );
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
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  Future<void> checkForFirstTimeToast(Chat chat) async {
    if (!chat.isEncrypted) return;

    bool muted = objectMgr.localStorageMgr
            .read(LocalStorageMgr.MUTE_PRIVATE_KEY_UPDATE) ??
        false;
    if (!muted) {
      bool toShow = await asyncCheckFirstTimeToast();
      if (toShow) {
        showCustomBottomAlertDialog(
          Get.context!,
          subtitle: localized(chatToggleEncMessage),
          items: [
            CustomBottomAlertItem(
              text: localized(chatToggleSetNow),
              onClick: () {
                Get.toNamed(RouteName.encryptionPreSetupPage, arguments: {});
              },
            ),
            CustomBottomAlertItem(
              text: localized(chatDontRemindAgain),
              textColor: colorRed,
              onClick: () {
                objectMgr.localStorageMgr
                    .write(LocalStorageMgr.MUTE_PRIVATE_KEY_UPDATE, true);
              },
            ),
          ],
        );
      } else {
        //后端传递就直接设置不再提示
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.MUTE_PRIVATE_KEY_UPDATE, true);
      }
    }
  }

  Future<bool> getAndUpdatePublicKey(int uid) async {
    List<CipherKey> data = await getCipherKeys([uid]);

    if (data.isEmpty) {
      return false;
    }

    Map<int, String> pkMapping = {};
    for (CipherKey key in data) {
      if (key.public != null) {
        pkMapping[key.uid ?? 0] = key.public ?? '';
      }
    }
    updatePublicKeys(pkMapping);
    return true;
  }

  Future<void> kickLogoutRemoveCache() async {
    /// 清除缓存
    objectMgr.localStorageMgr.remove(LocalStorageMgr.ENCRYPTION_PUBLIC_KEY, private: true);
    objectMgr.localStorageMgr.remove(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY, private: true);

    /// chat key
    List<Chat> chats = await objectMgr.chatMgr.loadAllLocalChats();
    List<Chat> encryptedChats = [];

    for (Chat chat in chats) {
      if (chat.chat_key != null && chat.chat_key != ''){
        chat.chat_key = '';
        encryptedChats.add(chat);
      }
    }
    objectMgr.chatMgr.updateEncryptionKeys(encryptedChats);
  }
}
