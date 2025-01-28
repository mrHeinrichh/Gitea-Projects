import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/language_option_model.dart';
import 'package:jxim_client/object/language_translate_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';

class LanguageController extends GetxController {
  Locale systemLocale = objectMgr.langMgr.getSystemLang();
  String langKeyFromLs = objectMgr.langMgr.getLangKey();
  RxList languageOptionList = <LanguageOptionModel>[].obs;
  RxBool isChangeLanguage = false.obs;

  @override
  void onInit() {
    super.onInit();
    getLanguageList();
  }

  Future<void> getLanguageList() async {
    /// 系统语言
    String languageText = "-";

    List<LanguageTranslateModel> languages = objectMgr.langMgr.languageList;

    if (languages.isNotEmpty) {
      for (final data in languages) {
        LanguageOptionModel item = LanguageOptionModel(
          title: data.languageName,
          content: data.languageTranslateName,
          languageKey: getAppLanguageCode(data.language),
          locale: getAppLocale(data.language),
          isSelected: langKeyFromLs == getAppLanguageCode(data.language),
        );

        languageOptionList.add(item);

        if (systemLocale.languageCode.toLowerCase() ==
            getAppLanguageCode(data.language)) {
          languageText = data.languageTranslateName;
        }
      }
    }

    /// 加上systemLanguage
    languageOptionList.insert(
      0,
      LanguageOptionModel(
        title: localized(systemDefault),
        content: "${localized(deviceLanguage)}: $languageText",
        languageKey: LanguageOption.systemLanguage.value,
        locale: systemLocale,
        isSelected: langKeyFromLs == LanguageOption.systemLanguage.value,
      ),
    );
  }

  void changeCurrLang(String langKey, Locale locale) {
    List<LanguageOptionModel> tempList = [];
    for (final languageOption in languageOptionList) {
      languageOption.isSelected = false;
      if (languageOption.languageKey == langKey) {
        languageOption.isSelected = true;
      }
      tempList.add(languageOption);
    }
    languageOptionList.value = tempList;
    isChangeLanguage.value = langKeyFromLs != langKey;
  }

  Future<void> languagePageBackTrigger() async {
    if (isChangeLanguage.value) {
      showCustomBottomAlertDialog(
        Get.context!,
        subtitle: localized(areYouSureYouWantToDiscard),
        confirmText: localized(discardButton),
        onConfirmListener: Get.back,
      );
    } else {
      Get.back();
    }
  }

  Future<void> showChangeLanguagePopup() async {
    showCustomBottomAlertDialog(
    Get.context!,
      subtitle: localized(restartAppToSwitchLang),
      confirmText: localized(continueProcessing),
      onConfirmListener: confirmChangeLanguage,
    );
  }

  Future<void> confirmChangeLanguage() async {
    LanguageOptionModel model =
        languageOptionList.firstWhere((element) => element.isSelected == true);

    try {
      final res = await updateLanguage(model.locale.languageCode);
      if (res.success()) {
        if (model.languageKey == LanguageOption.systemLanguage.value) {
          objectMgr.langMgr.updateUserDefaultLang(
            model.locale,
            isSaveLocal: false,
            fromSetLanguage: true,
          );
        } else {
          objectMgr.langMgr
              .updateUserDefaultLang(model.locale, fromSetLanguage: true);
        }
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }
}
