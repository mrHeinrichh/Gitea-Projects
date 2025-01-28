import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/moment_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/object/app_version.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/language_translate_model.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views_desktop/component/desktop_dialog.dart';

class SettingController extends GetxController {
  final user = Rxn<User>();
  RxBool isSearching = false.obs;
  final TextEditingController searchController = TextEditingController();
  RxString searchParam = ''.obs;
  final nickname = ''.obs;
  final username = ''.obs;
  final countryCode = ''.obs;
  final contactNumber = ''.obs;
  final isVersionUpdate = false.obs;
  String desktopSettingCurrentRoute = '/fistPage';
  final selectedIndex = 10101010.obs;
  final showReel = false.obs;
  final showWallet = false.obs;
  final languageText = ''.obs;

  // 正在登出
  final isLoggingOut = false.obs;

  RxInt showMomentStrongNotification = 0.obs;
  Rx<MomentNotificationLastInfo?> notificationLastInfo =
      Rx<MomentNotificationLastInfo?>(null);

  @override
  onInit() {
    super.onInit();
    user.value = objectMgr.userMgr.mainUser;
    nickname(user.value?.nickname);
    username(user.value?.username);
    countryCode(user.value?.countryCode);
    contactNumber(user.value?.contact);

    objectMgr.on(ObjectMgr.eventAppUpdate, _onAppVersionUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventSetPassword, _onSetPassword);

    objectMgr.momentMgr.on(
      MomentMgr.MOMENT_NOTIFICATION_UPDATE,
      _onMomentNotificationUpdate,
    );

    initMomentNotification();
    updateExperiment();
    getCurrentLanguage();
  }

  @override
  void onClose() {
    objectMgr.off(ObjectMgr.eventAppUpdate, _onAppVersionUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventSetPassword, _onSetPassword);

    objectMgr.momentMgr.off(
      MomentMgr.MOMENT_NOTIFICATION_UPDATE,
      _onMomentNotificationUpdate,
    );

    super.onClose();
  }

  void _onAppVersionUpdate(Object sender, Object type, Object? data) {
    if (data is EventAppVersion) {
      if (data.updateType == AppVersionUpdateType.revertVersion) {
        isVersionUpdate.value = false;
      } else {
        isVersionUpdate.value = true;
      }
    }
  }

  void _onUserUpdate(Object sender, Object type, Object? data) {
    if (data is User) {
      final user = data;
      if (user.uid == this.user.value?.uid) {
        this.user.value = user;
        nickname(user.nickname);
        username(user.username);
        countryCode(user.countryCode);
        contactNumber(user.contact);
      }
    }
  }

  _onSetPassword(Object sender, Object type, Object? data) async {
    if (data is bool) {
      if (data) {
        checkPasscodeStatus();
      }
    }
  }

  void _onMomentNotificationUpdate(_, __, ___) {
    pdebug('check notification update in setting controller');
    notificationLastInfo.value = objectMgr.momentMgr.notificationLastInfo;
    showMomentStrongNotification.value =
        objectMgr.momentMgr.notificationStrongCount;
  }

  void clearSearching() async {
    isSearching.value = false;
    if (!isSearching.value) {
      searchController.clear();
      searchParam.value = '';
    }
    // searchLocal();
  }

  Future<void> onSettingOptionTap(BuildContext context, String? type) async {
    switch (type) {
      case 'myWallet':
        bool status = await checkPasscodeStatus();
        if (status) {
          Get.toNamed(RouteName.walletView);
        } else {
          Get.toNamed(
            RouteName.passcodeIntroSetting,
            arguments: {
              'passcode_type': WalletPasscodeOption.setPasscode.type,
              'from_view': 'wallet_view',
            },
          );
        }
        break;
      case 'settingRecentCall':
        Get.toNamed(RouteName.settingRecentCall);
        break;
      case 'notificationAndSound':
        if (objectMgr.loginMgr.isDesktop) {
          if (desktopSettingCurrentRoute != RouteName.notification) {
            selectedIndex.value = 2;
            Get.offAllNamed(RouteName.desktopChatEmptyView, id: 3);
            Get.toNamed(RouteName.notification, id: 3);
          }
        } else {
          Get.toNamed(RouteName.notification);
        }
        break;
      case 'privacyAndSecurity':
        if (objectMgr.loginMgr.isDesktop) {
          if (desktopSettingCurrentRoute != RouteName.privacySecurity) {
            selectedIndex.value = 3;
            Get.offAllNamed(RouteName.desktopChatEmptyView,
                predicate: (route) =>
                    route.settings.name == RouteName.desktopChatEmptyView,
                id: 3);
            Get.toNamed(RouteName.privacySecurity, id: 3);
          }
        } else {
          Get.toNamed(RouteName.privacySecurity);
        }
        break;
      case 'generalSettings':
        Get.toNamed(RouteName.generalSettings);
      case 'dataAndStorage':
        if (objectMgr.loginMgr.isDesktop) {
          if (desktopSettingCurrentRoute != RouteName.dataStorage) {
            selectedIndex.value = 4;
            Get.offAllNamed(RouteName.desktopChatEmptyView,
                predicate: (route) =>
                    route.settings.name == RouteName.desktopChatEmptyView,
                id: 3);
            Get.toNamed(RouteName.dataStorage, id: 3);
          }
        } else {
          Get.toNamed(RouteName.dataAndStorage);
        }
        break;
      case 'language':
        if (objectMgr.loginMgr.isDesktop) {
          if (desktopSettingCurrentRoute != RouteName.languageView) {
            selectedIndex.value = 5;
            Get.offAllNamed(RouteName.desktopChatEmptyView,
                predicate: (route) =>
                    route.settings.name == RouteName.desktopChatEmptyView,
                id: 3);
            Get.toNamed(RouteName.languageView, id: 3);
          }
        } else {
          Get.toNamed(RouteName.languageView);
        }
        break;
      case 'appearance':
        //Get.toNamed(RouteName.appearanceView);
        Toast.showToast(localized(homeToBeContinue));
        break;
      case 'linkDevices':
        if (objectMgr.loginMgr.isDesktop) {
          if (desktopSettingCurrentRoute != RouteName.linkedDevice) {
            selectedIndex.value = 7;
            Get.offAllNamed(RouteName.desktopChatEmptyView,
                predicate: (route) =>
                    route.settings.name == RouteName.desktopChatEmptyView,
                id: 3);
            Get.toNamed(RouteName.linkedDevice, id: 3);
          }
        } else {
          Get.toNamed(RouteName.linkedDevice);
        }
        break;
      case 'accounts':
        if (objectMgr.loginMgr.isDesktop) {
          if (desktopSettingCurrentRoute != RouteName.userBioSetting) {
            Get.offAllNamed(RouteName.desktopChatEmptyView,
                predicate: (route) =>
                    route.settings.name == RouteName.desktopChatEmptyView,
                id: 3);
            Get.toNamed(RouteName.userBioSetting, id: 3);
          }
        } else {
          Get.toNamed(RouteName.userBioSetting);
        }
        break;
      case 'inviteFriends':
        if (objectMgr.loginMgr.isDesktop) {
          if (desktopSettingCurrentRoute != RouteName.inviteFriends) {
            selectedIndex.value = 9;
            Get.offAllNamed(RouteName.desktopChatEmptyView,
                predicate: (route) =>
                    route.settings.name == RouteName.desktopChatEmptyView,
                id: 3);
            Get.toNamed(RouteName.inviteFriends, id: 3);
          }
        } else {
          Get.toNamed(RouteName.inviteFriends);
        }
        break;
      case 'appInfo':
        if (objectMgr.loginMgr.isDesktop) {
          if (desktopSettingCurrentRoute != RouteName.appInfo) {
            selectedIndex.value = 8;
            Get.offAllNamed(RouteName.desktopChatEmptyView,
                predicate: (route) =>
                    route.settings.name == RouteName.desktopChatEmptyView,
                id: 3);
            Get.toNamed(RouteName.appInfo, id: 3);
          }
        } else {
          Get.toNamed(RouteName.appInfo);
        }
        break;
      case 'logout':
        getLogoutDialog(context);
        break;
      case 'testPage':
        Get.toNamed(RouteName.testPage);
        break;
      // if (objectMgr.loginMgr.isDesktop) {
      //   if (desktopSettingCurrentRoute != RouteName.shareView) {
      //     selectedIndex.value = 9;
      //     Get.offAllNamed(RouteName.desktopChatEmptyView,
      //         predicate: (route) =>
      //             route.settings.name == RouteName.desktopChatEmptyView,
      //         id: 3);
      //     Get.toNamed(RouteName.shareView, id: 3);
      //   }
      // } else {
      //   // Get.toNamed(RouteName.shareView);
      //   Get.bottomSheet(
      //     GetBuilder(
      //       init: ShareController(),
      //       builder: (controller) => const ShareView(),
      //     ),
      //     isScrollControlled: true,
      //     backgroundColor: Colors.transparent,
      //   );
      // }
      case 'networkDiagnose':
        if (objectMgr.loginMgr.isDesktop) {
          if (desktopSettingCurrentRoute != RouteName.networkDiagnose) {
            Get.offAllNamed(RouteName.desktopChatEmptyView,
                predicate: (route) =>
                    route.settings.name == RouteName.desktopChatEmptyView,
                id: 3);
            selectedIndex.value = 10;
            Get.toNamed(RouteName.networkDiagnose, id: 3);
          }
        } else {
          Get.toNamed(RouteName.networkDiagnose);
        }

        break;
      case 'dateTime':
        Get.toNamed(RouteName.dateTime);
        break;
      case 'channel':
        Get.toNamed(RouteName.reel);
        break;
      case 'moment':
        Get.toNamed(RouteName.moment);
        break;
      case 'favourite':
        Get.toNamed(RouteName.favouritePage);
        break;
      case 'chatCategoryFolder':
        Get.toNamed(RouteName.chatCategoryFolderPage);
        break;
      default:
        break;
    }
  }

  Future<Object?> getLogoutDialog(BuildContext context) {
    return objectMgr.loginMgr.isDesktop
        ? showDialog(
            context: context,
            builder: (BuildContext context) {
              return DesktopDialog(
                  dialogSize: Size(
                      300,
                      hasSecondLine(localized(confirmLogoutFromTheDevice), 275)
                          ? 105
                          : 120),
                  child: DesktopDialogWithButton(
                    title: localized(confirmLogoutFromTheDevice),
                    buttonLeftText: localized(cancel),
                    buttonLeftOnPress: () {
                      Get.back();
                    },
                    buttonRightText: localized(mySettingLogout),
                    buttonRightOnPress: () {
                      objectMgr.logout();
                    },
                  ));
            })
        : showCustomBottomAlertDialog(
            context,
            subtitle: localized(settingLogoutDetail),
            // onConfirmListener: objectMgr.logout,
            // confirmText: localized(mySettingLogout),
            showConfirmButton: false,
            canPopConfirm: false,
            canPopCancel: !isLoggingOut.value,
            items: <Widget>[
              Obx(
                () => CustomButton(
                  text: localized(buttonConfirm),
                  textColor: colorRed,
                  color: Colors.transparent,
                  isLoading: isLoggingOut.value,
                  callBack: () async {
                    isLoggingOut.value = true;
                    try {
                      await objectMgr.logout();
                    } catch (e) {
                      if (e is HttpException) {
                        pdebug("logout error - ${e.message}");
                      }
                    } finally {
                      isLoggingOut.value = false;
                      Get.back();
                    }
                  },
                  fontSize: MFontSize.size20.value,
                  isBold: false,
                ),
              ),
            ],
          );
  }

  bool hasSecondLine(String title, num width) {
    final tp = TextPainter(
      text: TextSpan(text: title),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    return tp.width <
        width; // number is horizontal padding value for the actual widget
  }

  Future<bool> checkPasscodeStatus() async {
    bool? passwordStatus =
        objectMgr.localStorageMgr.read(LocalStorageMgr.SET_PASSWORD);
    if (passwordStatus != null) {
      return passwordStatus;
    } else {
      Secure? data = await SettingServices().getPasscodeSetting();
      if (data != null) {
        objectMgr.localStorageMgr
            .write(LocalStorageMgr.SET_PASSWORD, !data.isNoPassword);
        return !data.isNoPassword;
      }
    }
    return false;
  }

  void checkVersionUpdate() async {
    HeartBeatAppVersion appVersion = await appVersionUtils.getLocalAppDetail();
    String latestVersion = appVersion.version;
    final currentVersion = await PlatformUtils.getAppVersion();
    final comparisonVersion = currentVersion.compareVersion(latestVersion);

    if (comparisonVersion < 0) {
      isVersionUpdate.value = true;
    } else {
      isVersionUpdate.value = false;
    }
  }

  getPrivacy() async {
    final res = await SettingServices().getPrivacySetting();
    await objectMgr.localStorageMgr.write('show_reel', res['show_reel']);
    await objectMgr.localStorageMgr.write('show_wallet', res['show_wallet']);
    updateExperiment();
  }

  updateExperiment() {
    int shouldShowReel = objectMgr.localStorageMgr.read('show_reel') ?? 0;
    int shouldShowWallet = objectMgr.localStorageMgr.read('show_wallet') ?? 0;
    showReel.value = shouldShowReel == 1;
    showWallet.value = shouldShowWallet == 1;
  }

  Future<void> getCurrentLanguage() async {
    String languageCode = objectMgr.langMgr.getLangKey();
    if (!notBlank(languageCode)) {
      languageCode = objectMgr.langMgr.getSystemLang().languageCode;
    }

    List<LanguageTranslateModel> languages = objectMgr.langMgr.languageList;
    if (languages.isNotEmpty) {
      for (var item in languages) {
        if (languageCode == getAppLanguageCode(item.language)) {
          languageText.value = item.languageName;
        }
      }
    }
  }

  void initMomentNotification() {
    notificationLastInfo.value = objectMgr.momentMgr.notificationLastInfo;
    showMomentStrongNotification.value =
        objectMgr.momentMgr.notificationStrongCount;
  }
}
