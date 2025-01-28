import 'package:flutter/material.dart';
import 'package:jxim_client/home/chat/component/message_ui_system.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/home/chat/component/message_ui_component.dart';
import 'package:jxim_client/home/chat/component/message_ui_file.dart';
import 'package:jxim_client/home/chat/component/message_ui_image.dart';
import 'package:jxim_client/home/chat/component/message_ui_saved.dart';
import 'package:jxim_client/home/chat/component/message_ui_small_secretary.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';

class MessageFactory {
  static Widget createComponent(
      {required Message message, String? searchText, required int chatId}) {
     Widget child;

     Chat? chat =  objectMgr.chatMgr.getChatById(chatId);
     if(chat == null){
      return const SizedBox();
     }

    if (chat.typ == chatTypeSystem) {
      child = MessageUISystem(message:message,searchText:searchText,chat:chat);
    } else if (chat.typ == chatTypeSmallSecretary) {
      child = MessageUISmallSecretary(message:message,searchText:searchText,chat:chat);
    } 
    else if (chat.typ == chatTypeSaved) {
      child = MessageUISaved(message:message,searchText:searchText,chat:chat);
    } 
    else if (message.typ == messageTypeImage) {
      child = MessageUIImage(message:message,searchText:searchText,chat:chat);
    } 
    else if (message.typ == messageTypeFile) {
      child = MessageUIFile(message:message,searchText:searchText,chat:chat);
    } 
    else {
      child = MessageUIComponent(chat: chat, searchText: searchText, message: message);
    }

    return child;
  }
}
