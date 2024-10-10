import 'dart:convert';

import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/translation_model.dart';
import 'package:jxim_client/object/enums/enum.dart';

class TranslateToController extends GetxController {
  List<LanguageOption> languageList = [];
  final chosenLanguage = LanguageOption.auto.obs;
  Chat? chat;
  Message? message;
  bool incomingChatSettings = true;

  @override
  void onInit() {
    super.onInit();
    languageList = LanguageOption.values
        .where((option) => option != LanguageOption.systemLanguage)
        .toList();
    chat = Get.arguments[0];
    if (Get.arguments[1] is Message) {
      message = Get.arguments[1];
    } else {
      incomingChatSettings = Get.arguments[1];
    }
    getCurrentLanguage();
  }

  getCurrentLanguage() {
    if (chat != null) {
      if (message != null) {
        String currentLocale;
        if (objectMgr.userMgr.isMe(message!.send_id)) {
          if (chat!.translate_outgoing.isNotEmpty) {
            currentLocale =
                jsonDecode(chat!.translate_outgoing)['currentLocale'] ??
                    LanguageOption.auto.value;
          } else {
            currentLocale = LanguageOption.auto.value;
          }
        } else {
          if (chat!.translate_incoming.isNotEmpty) {
            currentLocale =
                jsonDecode(chat!.translate_incoming)['currentLocale'] ??
                    LanguageOption.auto.value;
          } else {
            currentLocale = LanguageOption.auto.value;
          }
        }
        chosenLanguage.value = LanguageOption.values
            .firstWhere((option) => option.value == currentLocale);
      } else {
        if (incomingChatSettings) {
          /// incoming setting
          String currentLocale = 'auto';
          final translateIncoming = chat?.translate_incoming;
          if (translateIncoming?.isNotEmpty == true) {
            final translateIncomingMap = jsonDecode(translateIncoming!);
            currentLocale = translateIncomingMap['currentLocale'] ??
                LanguageOption.auto.value;
          }
          chosenLanguage.value =
              LanguageOption.getByValue(currentLocale) ?? LanguageOption.auto;
        } else {
          /// outgoing setting
          String currentLocale = 'auto';
          final translateOutgoing = chat?.translate_outgoing;
          if (translateOutgoing?.isNotEmpty == true) {
            final translateOutgoingMap = jsonDecode(translateOutgoing!);
            currentLocale = translateOutgoingMap['currentLocale'] ??
                LanguageOption.auto.value;
          }
          chosenLanguage.value =
              LanguageOption.getByValue(currentLocale) ?? LanguageOption.auto;
        }
      }
    }
  }

  onChangeLanguage(LanguageOption selectedLanguage) =>
      chosenLanguage.value = selectedLanguage;

  onTapDoneButton() async {
    if (message != null) {
      TranslationModel? model = message!.getTranslationModel();
      model ??= TranslationModel();
      model.currentLocale = chosenLanguage.value.value;
      int visualType = 0;

      if (notBlank(model.getContent())) {
        if (objectMgr.userMgr.isMe(message!.send_id)) {
          visualType = chat!.visualTypeOutgoing;
        } else {
          visualType = chat!.visualTypeIncoming;
        }
        objectMgr.chatMgr.getMessageTranslation(
          message!.messageContent,
          locale: model.currentLocale == 'auto'
              ? getAutoLocale()
              : model.currentLocale,
          message: message,
          visualType: visualType,
        );
        updateChatLocale();
      } else {
        updateChatLocale();
      }
    } else {
      if (chat != null) {
        if (incomingChatSettings) {
          chat!.currentLocaleIncoming = chosenLanguage.value.value;
        } else {
          chat!.currentLocaleOutgoing = chosenLanguage.value.value;
        }
        objectMgr.chatMgr.saveTranslationToChat(chat!);
      }
    }
    Get.back();
  }

  void updateChatLocale() {
    if (objectMgr.userMgr.isMe(message!.send_id)) {
      chat!.currentLocaleOutgoing = chosenLanguage.value.value;
    } else {
      chat!.currentLocaleIncoming = chosenLanguage.value.value;
    }
    objectMgr.chatMgr.saveTranslationToChat(chat!);
  }
}
