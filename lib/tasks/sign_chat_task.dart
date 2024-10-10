import 'dart:convert';

import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/api/chat.dart' as chat_api;
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/object/chat/chat.dart';

import 'package:jxim_client/utils/encryption/rsa_encryption.dart';

class SignChatTask extends ScheduleTask {
  SignChatTask({
    Duration delay = const Duration(milliseconds: 3000),
  }) : super(delay);

  static final List<Message> _signChatMessages = [];
  static int count = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  static bool isInit = false;

  static loadSignMessage(){
    if(!isInit) {
      isInit = true;
      String? signChatStr =  objectMgr.localStorageMgr.readSecurely(LocalStorageMgr.SIGN_CHAT_MESSAGE);
      if(signChatStr == null){
        return;
      }
      List<dynamic> jsonList = jsonDecode(signChatStr);
      _signChatMessages.addAll(jsonList.map((json) => Message()..init(json)).toList());
    }
  }

  static saveSignMessage(){
    if(_signChatMessages.isEmpty){
      objectMgr.localStorageMgr.remove(LocalStorageMgr.SIGN_CHAT_MESSAGE);
    }else{
      List<Map<String, dynamic>> jsonList = _signChatMessages.map((message) => message.toJson()).toList();
      objectMgr.localStorageMgr.writeSecurely(LocalStorageMgr.SIGN_CHAT_MESSAGE, jsonEncode(jsonList));
    }
    
  }

  @override
  execute() async {
    loadSignMessage();
    if(_signChatMessages.isEmpty){
      return;
    }
    if(objectMgr.userMgr.mainUser.uid % 10 == count % 10){
      for(var msg in _signChatMessages){
        MessageReqSignChat messageReqSignChat = msg.decodeContent(cl: MessageReqSignChat.creator);
        Chat? chat = objectMgr.chatMgr.getChatById(msg.chat_id);
        if(chat == null){
          continue;
        }
        try{
          String content = RSAEncryption.encrypt(chat.chat_key, messageReqSignChat.publicKey);
          var data = {
            "key": content,
            "uid":messageReqSignChat.uid,
          };
          objectMgr.chatMgr.mySendMgr.send(chat.id, messageTypeRespSignChat, json.encode(data));
          chat_api.deleteMsg(msg.chat_id, [msg.chat_idx],isAll: true);
        }catch(e){
          //todo
        } 
      }
      _signChatMessages.clear();
      saveSignMessage();
    }
    count++;
  }

  static addSignChatMessage(Message msg) {
    loadSignMessage();
    _signChatMessages.add(msg);
    saveSignMessage();
  }

  static delSignChatMessage(int message_id) {
    loadSignMessage();
    _signChatMessages.removeWhere((element) => element.message_id == message_id);
    saveSignMessage();
  }
}
