import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/app_version.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';
import 'package:jxim_client/views/contact/share_controller.dart';
import 'package:jxim_client/views/contact/share_view.dart';

import '../../api/setting_services.dart';
import '../../data/db_user.dart';
import '../../object/user.dart';
import '../../utils/net/update_block_bean.dart';
import '../../utils/theme/text_styles.dart';
import '../../utils/toast.dart';
import '../../views_desktop/component/DesktopDialog.dart';
import 'package:jxim_client/utils/plugin_manager.dart';

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
  }

  @override
  void onClose() {
    super.onClose();
    objectMgr.off(ObjectMgr.eventAppUpdate, _onAppVersionUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventSetPassword, _onSetPassword);
  }

  void _onAppVersionUpdate(Object sender, Object type, Object? data) {
    if (data is EventAppVersion) {
      isVersionUpdate.value = data.isShow;
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
        PluginManager.shared.checkPasscodeStatus();
      }
    }
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
        // imMiniAppManager.checkWalletPswBeforeOpenWalletPage(context);
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
      case 'inviteFriends':
        if (objectMgr.loginMgr.isDesktop) {
          if (desktopSettingCurrentRoute != RouteName.shareView) {
            selectedIndex.value = 9;
            Get.offAllNamed(RouteName.desktopChatEmptyView,
                predicate: (route) =>
                    route.settings.name == RouteName.desktopChatEmptyView,
                id: 3);
            Get.toNamed(RouteName.shareView, id: 3);
          }
        } else {
          // Get.toNamed(RouteName.shareView);
          Get.bottomSheet(
            GetBuilder(
              init: ShareController(),
              builder: (controller) => const ShareView(),
            ),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        }
        break;
      case 'dateTime':
        Get.toNamed(RouteName.dateTime);
        break;
      case 'channel':
        Get.toNamed(RouteName.reel);
        break;
      default:
    }
  }

  Future<Object?> getLogoutDialog(BuildContext context) {
    return objectMgr.loginMgr.isDesktop
        ? showDialog(
            context: context,
            builder: (BuildContext context) {
              return DesktopDialog(
                  dialogSize: const Size(300, 100),
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
        : showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: localized(mySettingLogout),
                content: Text(
                  localized(youWillNoLongerReceiveMessageAreYouToLogout),
                  style: jxTextStyle.textDialogContent(),
                  textAlign: TextAlign.center,
                ),
                confirmCallback: () => objectMgr.logout(),
              );
            },
          );
  }

  Future<bool> checkPasscodeStatus() async {
    bool? passwordStatus =
        await objectMgr.localStorageMgr.read(LocalStorageMgr.SET_PASSWORD);
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
    String latestVersion =
        (objectMgr.localStorageMgr.read(LocalStorageMgr.LATEST_APP_VERSION) !=
                null)
            ? objectMgr.localStorageMgr.read(LocalStorageMgr.LATEST_APP_VERSION)
            : "0.0.0";
    final currentVersion = await PlatformUtils.getAppVersion();
    final comparisonVersion = currentVersion.compareVersion(latestVersion);

    if (comparisonVersion < 0) {
      isVersionUpdate.value = true;
    } else {
      isVersionUpdate.value = false;
    }
  }
}
