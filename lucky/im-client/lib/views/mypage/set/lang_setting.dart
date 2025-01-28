import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/language_option_model.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import '../../../home/setting/setting_controller.dart';
import '../../../managers/lang_mgr.dart';
import '../../../utils/config.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../component/click_effect_button.dart';

class LangSetting extends StatefulWidget {
  LangSetting({Key? key}) : super(key: key);

  @override
  State<LangSetting> createState() => _LangSettingState();
}

class _LangSettingState extends State<LangSetting> {
  late List<LanguageOptionModel> languageOptionList;
  Locale systemLocale = objectMgr.langMgr.getSystemLang();
  String langKeyFromLs = objectMgr.langMgr.getLangKey();
  bool isChangeLanguage = false;

  @override
  void initState() {
    super.initState();
    objectMgr.langMgr.on(LangMgr.eventUpdateLang, (_, __, ___) {
      setState(() {});
    });
    initLanguage();
  }

  @override
  void dispose() {
    objectMgr.langMgr.off(LangMgr.eventUpdateLang);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: objectMgr.loginMgr.isDesktop
          ? null
          : PrimaryAppBar(
              title: localized(language),
              onPressedBackBtn: () => languagePageBackTrigger(context),
              trailing: [
                Visibility(
                  visible: isChangeLanguage,
                  child: GestureDetector(
                    onTap: () => showChangeLanguagePopup(),
                    child: OpacityEffect(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          localized(buttonDone),
                          style: jxTextStyle.textStyle17(color: accentColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      body: Column(
        children: [
          if (objectMgr.loginMgr.isDesktop)
            Container(
              height: 52,
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: const Border(
                  bottom: BorderSide(
                    color: JXColors.outlineColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                /// 普通界面
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  OpacityEffect(
                    child: GestureDetector(
                      onTap: () {
                        Get.back(id: 3);
                        Get.find<SettingController>()
                            .desktopSettingCurrentRoute = '';
                        Get.find<SettingController>().selectedIndex.value =
                            101010;
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/svgs/Back.svg',
                              width: 18,
                              height: 18,
                              color: JXColors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localized(buttonBack),
                              style: const TextStyle(
                                fontSize: 13,
                                color: JXColors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    localized(language),
                    style: const TextStyle(
                      fontSize: 16,
                      color: JXColors.black,
                    ),
                  ),
                  Visibility(
                    visible: isChangeLanguage,
                    child: GestureDetector(
                      onTap: () => showChangeLanguagePopup(),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          localized(buttonDone),
                          style:
                              jxTextStyle.textStyleBold17(color: accentColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.white,
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children:
                      languageOptionList.map((e) => createItem(e)).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget createItem(LanguageOptionModel languageOptionModel) {
    return SettingItem(
      onTap: () => changeCurrLang(
        languageOptionModel.languageKey,
        languageOptionModel.locale,
      ),
      title: languageOptionModel.title,
      subtitle: languageOptionModel.content,
      withArrow: false,
      withEffect: true,
      withBorder: languageOptionModel == languageOptionList.last ? false : true,
      rightWidget: languageOptionModel.isSelected
          ? SvgPicture.asset(
              'assets/svgs/check.svg',
              width: 16,
              height: 16,
        colorFilter: ColorFilter.mode(accentColor, BlendMode.srcATop),
            )
          : const SizedBox(),
    );
  }

  void initLanguage() {
    String languageText = "-";
    if (systemLocale.languageCode == LanguageOption.english.value) {
      languageText = localized(settingLangEn);
    } else if (systemLocale.languageCode == LanguageOption.chinese.value) {
      languageText = localized(settingLangZh);
    }

    languageOptionList = [
      LanguageOptionModel(
        title: localized(systemDefault),
        content: "${localized(deviceLanguage)}: $languageText",
        languageKey: LanguageOption.autoDetect.value,
        locale: systemLocale,
        isSelected:
            (langKeyFromLs == LanguageOption.autoDetect.value) ? true : false,
      ),
      LanguageOptionModel(
        title: "English",
        content: localized(settingLangEn),
        languageKey: LanguageOption.english.value,
        locale: const Locale('en', 'US'),
        isSelected:
            (langKeyFromLs == LanguageOption.english.value) ? true : false,
      ),
      LanguageOptionModel(
        title: "简体中文",
        content: localized(settingLangZh),
        languageKey: LanguageOption.chinese.value,
        locale: const Locale('zh', 'CN'),
        isSelected:
            (langKeyFromLs == LanguageOption.chinese.value) ? true : false,
      ),
    ];
  }

  void changeCurrLang(String langKey, Locale locale) {
    setState(() {
      List<LanguageOptionModel> tempList = [];
      for (final languageOption in languageOptionList) {
        languageOption.isSelected = false;
        if (languageOption.languageKey == langKey) {
          languageOption.isSelected = true;
        }
        tempList.add(languageOption);
      }
      languageOptionList = tempList;
      isChangeLanguage = (langKeyFromLs != langKey) ? true : false;
    });
  }

  void languagePageBackTrigger(BuildContext context) {
    if (isChangeLanguage) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return CustomConfirmationPopup(
            title: localized(localized(areYouSureYouWantToDiscard)),
            confirmButtonText: localized(discardButton),
            cancelButtonText: localized(buttonCancel),
            confirmCallback: () => Get.back(),
            cancelCallback: () => Navigator.of(context).pop(),
            confirmButtonColor: errorColor,
            cancelButtonColor: accentColor,
          );
        },
      );
    } else {
      Get.back();
    }
  }

  void showChangeLanguagePopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title: localized(localized(restartHeyTalkToApplyTheChange,params: [Config().appName])),
          confirmButtonText: localized(buttonConfirm),
          cancelButtonText: localized(buttonCancel),
          confirmCallback: () => confirmChangeLanguage(),
          cancelCallback: () => Navigator.of(context).pop(),
          cancelButtonColor: accentColor,
        );
      },
    );
  }

  Future<void> confirmChangeLanguage() async {
    LanguageOptionModel model =
        languageOptionList.firstWhere((element) => element.isSelected == true);

    try {
      final res = await updateLanguage(model.locale.languageCode);
      if (res.success()) {
        if (model.languageKey == LanguageOption.autoDetect.value) {
          objectMgr.langMgr.updateUserDefaultLang(model.locale,
              isSaveLocal: false, fromSetLanguage: true);
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
