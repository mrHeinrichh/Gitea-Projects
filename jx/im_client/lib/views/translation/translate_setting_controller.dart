import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';

class TranslateSettingController extends GetxController {
  Chat? chat;
  final isTurnOnAutoIncoming = false.obs;
  final isTurnOnAutoOutgoing = false.obs;
  final incomingLanguage = LanguageOption.auto.obs;
  final outgoingLanguage = LanguageOption.auto.obs;
  final incomingVisual = 0.obs;
  final outgoingVisual = 0.obs;
  List languageList = <LanguageOption>[];

  /// -1: no need auto enable
  /// 1: need enable for incoming
  /// 2: need enable for outgoing
  int needAutoEnable = -1;

  TranslateSettingController();

  TranslateSettingController.desktop(dynamic args){
    chat = args[0];
    if (args.length > 1) {
      needAutoEnable = args[1];
    }
  }

  @override
  void onInit() {
    super.onInit();
    if(!objectMgr.loginMgr.isDesktop){
      chat = Get.arguments[0];
      if (Get.arguments.length > 1) {
        needAutoEnable = Get.arguments[1];
      }
    }
    languageList = LanguageOption.values
        .where((option) => option != LanguageOption.systemLanguage)
        .toList();
    isTurnOnAutoIncoming.value = chat!.isAutoTranslateIncoming;
    isTurnOnAutoOutgoing.value = chat!.isAutoTranslateOutgoing;
    if (chat!.currentLocaleIncoming != '') {
      LanguageOption? option = languageList.firstWhereOrNull(
        (option) => option.value == chat!.currentLocaleIncoming,
      );
      if (option != null) {
        incomingLanguage.value = option;
      } else {
        incomingLanguage.value = LanguageOption.auto;
        chat!.currentLocaleIncoming = LanguageOption.auto.value;
      }
    } else {
      chat!.currentLocaleIncoming = LanguageOption.auto.value;
    }
    if (chat!.currentLocaleOutgoing != '') {
      LanguageOption? option = languageList.firstWhereOrNull(
        (option) => option.value == chat!.currentLocaleOutgoing,
      );
      if (option != null) {
        outgoingLanguage.value = option;
      } else {
        outgoingLanguage.value = LanguageOption.auto;
        chat!.currentLocaleOutgoing = LanguageOption.auto.value;
      }
    } else {
      chat!.currentLocaleOutgoing = LanguageOption.auto.value;
    }
    incomingVisual.value = chat!.visualTypeIncoming;
    outgoingVisual.value = chat!.visualTypeOutgoing;
    objectMgr.chatMgr.on(ChatMgr.eventChatTranslateUpdate, _onTranslateUpdate);
    if (needAutoEnable > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _enableAutoSetting();
      });
    }
  }

  _enableAutoSetting() async {
    await Future.delayed(const Duration(milliseconds: 300), () {});
    if (needAutoEnable == 1) {
      isTurnOnAutoIncoming.value = true;
      chat!.isAutoTranslateIncoming = true;
    } else {
      isTurnOnAutoOutgoing.value = true;
      chat!.isAutoTranslateOutgoing = true;
    }
    objectMgr.chatMgr.saveTranslationToChat(chat!);
  }

  autoSettingSwitchChanges(bool isIncoming, bool isTurnOn) {
    if (isIncoming) {
      chat!.isAutoTranslateIncoming = isTurnOn;
      isTurnOnAutoIncoming.value = isTurnOn;
      if (chat!.incoming_idx == 0) {
        chat!.incoming_idx = -1;
      }
    } else {
      chat!.isAutoTranslateOutgoing = isTurnOn;
      isTurnOnAutoOutgoing.value = isTurnOn;
      if (chat!.outgoing_idx == 0) {
        chat!.outgoing_idx = -1;
      }
    }
    objectMgr.chatMgr.saveTranslationToChat(chat!);
  }

  _onTranslateUpdate(_, __, data) {
    if (data is Chat && chat!.chat_id == data.chat_id) {
      if (data.currentLocaleIncoming != '') {
        incomingLanguage.value = languageList.firstWhere(
          (option) => option.value == chat!.currentLocaleIncoming,
        );
      }

      outgoingLanguage.value = languageList.firstWhere(
        (option) => option.value == chat!.currentLocaleOutgoing,
      );

      incomingVisual.value = data.visualTypeIncoming;
      outgoingVisual.value = data.visualTypeOutgoing;
    }
  }

  @override
  void onClose() {
    objectMgr.chatMgr.off(ChatMgr.eventChatTranslateUpdate, _onTranslateUpdate);
    super.onClose();
  }
}
