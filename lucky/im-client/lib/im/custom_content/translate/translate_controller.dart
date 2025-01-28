import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/lang_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/translate_model.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:translator/translator.dart';

import '../../../api/account.dart';
import '../../../main.dart';
import '../../../object/enums/enum.dart';
import '../../../object/language_option_model.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../utils/toast.dart';
import '../../../utils/utility.dart';

class TranslateController extends GetxController {
  /// 文本
  String oriText;
  RxString translateText = "".obs;
  RxDouble height = 0.5.obs;

  /// 系统语言
  Locale systemLocale = objectMgr.langMgr.getSystemLang();
  String? langKeyFromLs;
  RxInt currentPage = 1.obs;

  /// 语文选项
  RxList<LanguageOptionModel> langOptionList = [
    LanguageOptionModel(
      title: "English",
      content: localized(settingLangEn),
      languageKey: LanguageOption.english.value,
      locale: const Locale('en', 'us'),
      isSelected: false,
    ),
    LanguageOptionModel(
      title: "简体中文",
      content: localized(settingLangZh),
      languageKey: LanguageOption.chinese.value,
      locale: const Locale('zh', 'cn'),
      isSelected: false,
    ),
  ].obs;

  /// variable
  Rx<Locale> selectTranslateLocale = Locale(LanguageOption.auto.value).obs;
  Rx<Locale> translateFromLocale = Locale(LanguageOption.auto.value).obs;
  Rx<Locale> translateToLocale = Locale(LanguageOption.auto.value).obs;

  /// 页面
  static const TRANSLATE_FROM_PAGE = "TRANSLATE_FROM_PAGE";
  static const TRANSLATE_TO_PAGE = "TRANSLATE_TO_PAGE";
  RxString currentTranslatePage = "".obs;

  TranslateController(this.oriText);

  @override
  Future<void> onInit() async {
    super.onInit();

    Translation translation = await GoogleTranslator().translate(oriText);
    Locale? locale =
        (translation.sourceLanguage.code == LanguageOption.auto.value)
            ? langOptionList
                .firstWhereOrNull((element) =>
                    element.languageKey == LanguageOption.english.value)
                ?.locale
            : langCodeToLocale(translation.sourceLanguage.code, '-');
    detectLanguage(locale: locale);
    translateLanguage();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void detectLanguage({Locale? locale}) {
    langOptionList.forEach((languageOption) {
      if (languageOption.locale == locale) {
        translateFromLocale.value = languageOption.locale;
      }
    });
  }

  void translateLanguage() {
    String lang = "";
    langKeyFromLs = objectMgr.localStorageMgr.read(LangMgr.langKey) ??
        "${systemLocale.languageCode}_${systemLocale.countryCode}";
    if (notBlank(langKeyFromLs)) {
      lang = langKeyFromLs ?? "";
    } else {
      lang = "${systemLocale.languageCode}_${systemLocale.countryCode}";
    }

    Locale locale = langCodeToLocale(lang.toLowerCase(), "_");
    setLanguageCode(locale);
  }

  void setLanguageCode(Locale? locale) {
    langOptionList.forEach((languageOption) {
      if (languageOption.locale == locale) {
        translateToLocale.value = languageOption.locale;
      } else {
        if (locale?.languageCode == LanguageOption.english.value &&
            locale?.countryCode == "sg" &&
            languageOption.languageKey == LanguageOption.english.value) {
          translateToLocale.value = languageOption.locale;
        }
      }
    });
    getTranslationText();
  }

  Future<void> getTranslationText() async {
    String langCode = translateToLocale.value.languageCode;
    try {
      final TranslateModel data = await getTranslateText(langCode, oriText);
      translateText.value = data.transText ?? "";
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  void switchPage(int page, {String? translatePage, bool isBack = false}) {
    currentPage.value = page;
    currentTranslatePage.value = translatePage ?? "";

    if (page == 1) {
      selectTranslateLocale.value = Locale(LanguageOption.auto.value);
    } else if (page == 2) {
      if (translatePage == TRANSLATE_FROM_PAGE) {
        selectTranslateLocale.value = translateFromLocale.value;
      } else if (translatePage == TRANSLATE_TO_PAGE) {
        selectTranslateLocale.value = translateToLocale.value;
      }
    }
  }

  void onClickItem(
      String translatePage, LanguageOptionModel languageOptionModel) {
    selectTranslateLocale.value = languageOptionModel.locale;
  }

  void onClickDone() {
    if (currentTranslatePage == TranslateController.TRANSLATE_FROM_PAGE) {
      detectLanguage(locale: selectTranslateLocale.value);
    } else if (currentTranslatePage == TranslateController.TRANSLATE_TO_PAGE) {
      setLanguageCode(selectTranslateLocale.value);
    }
    switchPage(1);
  }
}
