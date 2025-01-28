import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/api/wallet_services.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/models/enum/moment_available_day.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/object/wallet/wallet_settings_bean.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_bottom_sheet.dart';

class PrivacySecurityController extends GetxController {
  final SettingServices _settingServices = SettingServices();
  late final passcodeStatus = Secure.noPassword.obs;
  late final Rx<Privacy> privacyUsername;
  late final Rx<Privacy> privacyPhoneNum;
  late final Rx<Privacy> privacyProfilePic;
  late final Rx<Privacy> privacyLastSeen;
  late final Rx<Privacy> privacyEmailAddress;
  late final Rx<Privacy> privacySearchByUsername;
  late final Rx<Privacy> privacySearchByPhoneNum;
  final privacySecuritySettingPage = PrivacySecuritySettingPage.profilePic.obs;
  final isSelectPrivacySecuritySettingIndex = 0.obs;

  ///二次验证
  final RxBool isPayTwoFactorAuthEnable = false.obs;
  final RxBool emailAuthEnable = false.obs;
  final RxBool phoneAuthEnable = false.obs;
  WalletSettingsBean? settingBean;

  /// claim redPacket action from chatRoom
  String? fromView;
  Chat? chat;

  RxInt momentSelectionIdx = 0.obs;
  final List<SelectionOptionModel> momentSelectionOptionModelList = [
    SelectionOptionModel(
      title: localized(forever),
      value: MomentAvailableDays.forever.value,
      isSelected: false,
    ),
    SelectionOptionModel(
      title: '3 ${localized(days)}',
      value: MomentAvailableDays.threeDays.value,
      isSelected: false,
    ),
    SelectionOptionModel(
      title: localized(timeOneMonth),
      value: MomentAvailableDays.oneMonth.value,
      isSelected: false,
    ),
    SelectionOptionModel(
      title: localized(timeSixMonths),
      value: MomentAvailableDays.halfYear.value,
      isSelected: false,
    ),
  ];

  final List<SelectionOptionModel> profileSelectionOptionModelList = [
    SelectionOptionModel(
      title: localized(psEveryone),
      value: Privacy.everybody.code,
      isSelected: false,
    ),
    SelectionOptionModel(
      title: localized(psMyFriends),
      value: Privacy.myFriend.code,
      isSelected: false,
    ),
    SelectionOptionModel(
      title: localized(psNobody),
      value: Privacy.nobody.code,
      isSelected: false,
    ),
  ];

  final List<SelectionOptionModel> friendRequestSelectionOptionModelList = [
    SelectionOptionModel(
      title: localized(psEveryone),
      value: Privacy.everybody.code,
      isSelected: false,
    ),
    SelectionOptionModel(
      title: localized(psNobody),
      value: Privacy.nobody.code,
      isSelected: false,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    objectMgr.chatMgr.on(ChatMgr.eventSetPassword, _onSetPassword);

    privacyUsername = Privacy.fromIndex(
      objectMgr.localStorageMgr.read<int?>(showProfileUsername) ?? 0,
    ).obs;
    privacyPhoneNum = Privacy.fromIndex(
      objectMgr.localStorageMgr.read<int?>(showProfilePhoneNumber) ?? 0,
    ).obs;
    privacyProfilePic = Privacy.fromIndex(
      objectMgr.localStorageMgr.read<int?>(showProfilePicture) ?? 0,
    ).obs;
    privacyLastSeen = Privacy.fromIndex(
      (objectMgr.localStorageMgr.read<int?>(showLastSeen) ?? 0),
    ).obs;
    privacySearchByUsername = Privacy.fromIndex(
      (objectMgr.localStorageMgr.read<int?>(searchByUsername) ?? 0),
    ).obs;
    privacySearchByPhoneNum = Privacy.fromIndex(
      (objectMgr.localStorageMgr.read<int?>(searchByPhoneNumber) ?? 0),
    ).obs;

    privacyEmailAddress = Privacy.fromIndex(
      objectMgr.localStorageMgr.read<int?>(showEmailAddress) ?? 0,
    ).obs;

    if (Get.arguments != null) {
      if (Get.arguments['from_view'] != null) {
        fromView = Get.arguments['from_view'];
      }
      if (Get.arguments['chat'] != null) {
        chat = Get.arguments['chat'];
      }
    }

    initPasscode();
    initPrivacySetting();
    initWalletSettings();

    initMomentSettings();
  }

  @override
  void onClose() {
    objectMgr.chatMgr.off(ChatMgr.eventSetPassword, _onSetPassword);
    super.onClose();
  }

  Future<void> initPasscode() async {
    bool? result = objectMgr.localStorageMgr.read(LocalStorageMgr.SET_PASSWORD);
    if (result != null && result) {
      passcodeStatus.value = Secure.eachDay;
    } else {
      final data = await _settingServices.getPasscodeSetting();
      passcodeStatus(data);
      objectMgr.localStorageMgr.write(
        LocalStorageMgr.SET_PASSWORD,
        !passcodeStatus.value.isNoPassword,
      );
    }
  }

  Future<void> initPrivacySetting() async {
    final data = await _settingServices.getPrivacySetting();

    privacyUsername.value = Privacy.fromIndex((data[showProfileUsername]));
    privacyPhoneNum.value = Privacy.fromIndex((data[showProfilePhoneNumber]));
    privacyProfilePic.value = Privacy.fromIndex((data[showProfilePicture]));
    privacyLastSeen.value = Privacy.fromIndex((data[showLastSeen]));
    privacySearchByUsername.value = Privacy.fromIndex((data[searchByUsername]));
    privacySearchByPhoneNum.value =
        Privacy.fromIndex((data[searchByPhoneNumber]));
    privacyEmailAddress.value = Privacy.fromIndex((data[showEmailAddress]));

    objectMgr.localStorageMgr
        .write(showProfileUsername, data[showProfileUsername]);
    objectMgr.localStorageMgr
        .write(showProfilePhoneNumber, data[showProfilePhoneNumber]);
    objectMgr.localStorageMgr
        .write(showProfilePicture, data[showProfilePicture]);
    objectMgr.localStorageMgr.write(showLastSeen, data[showLastSeen]);
    objectMgr.localStorageMgr.write(searchByUsername, data[searchByUsername]);
    objectMgr.localStorageMgr
        .write(searchByPhoneNumber, data[searchByPhoneNumber]);
    objectMgr.localStorageMgr.write(showEmailAddress, data[showEmailAddress]);
  }

  Future<void> updatePrivacySetting(
    String privacyType,
    int privacyStatus,
  ) async {
    final success =
        await _settingServices.updatePrivacySetting(privacyType, privacyStatus);
    if (success) {
      objectMgr.localStorageMgr.write(privacyType, privacyStatus);
      setPrivacyValue(privacyType, privacyStatus);
      Toast.showToast(localized(psPrivacySettingSuccess));
    } else {
      Toast.showToast(localized(psPrivacySettingFailed));
    }
  }

  void handleView() {
    if (passcodeStatus.value.isNoPassword) {
      final Map<String, dynamic> arguments = {};
      if (fromView != null) {
        arguments["from_view"] = fromView;
      }
      if (chat != null) {
        arguments["chat"] = chat;
      }
      if (objectMgr.loginMgr.isDesktop) {
        Get.toNamed(
          RouteName.passcodeIntroSetting,
          arguments: arguments,
          id: 3,
        );
      } else {
        Get.toNamed(
          RouteName.passcodeIntroSetting,
          arguments: arguments,
        );
      }
    } else {
      if (objectMgr.loginMgr.isDesktop) {
        Get.toNamed(RouteName.passcodeSetting, id: 3);
      } else {
        Get.toNamed(RouteName.passcodeSetting);
      }
    }
  }

  void handlePhoneNumView(BuildContext context) {
    for (var item in profileSelectionOptionModelList) {
      item.isSelected = false;
      if (item.value == privacyPhoneNum.value.code) {
        item.isSelected = true;
      }
    }

    Toast.showBottomSheet(
      context: context,
      container: CustomBottomSheet(
        context: context,
        title: localized(psPhoneNumber),
        subTitle: '${localized(whoCanSeeMyPhoneNumber)}?',
        selectionOptionModelList: profileSelectionOptionModelList,
        callback: (int index) {
          checkPrivacyType(
            showProfilePhoneNumber,
            Privacy.fromIndex(profileSelectionOptionModelList[index].value!),
          );
          Get.back();
        },
      ),
    );
  }

  void handleUsernameView(BuildContext context) {
    for (var item in profileSelectionOptionModelList) {
      item.isSelected = false;
      if (item.value == privacyUsername.value.code) {
        item.isSelected = true;
      }
    }

    Toast.showBottomSheet(
      context: context,
      container: CustomBottomSheet(
        context: context,
        title: localized(psUsername),
        subTitle: '${localized(whoCanSeeMyUsername)}?',
        selectionOptionModelList: profileSelectionOptionModelList,
        callback: (int index) {
          checkPrivacyType(
            showProfileUsername,
            Privacy.fromIndex(profileSelectionOptionModelList[index].value!),
          );
          Get.back();
        },
      ),
    );
  }

  void handleProfilePicView(BuildContext context) {
    for (var item in profileSelectionOptionModelList) {
      item.isSelected = false;
      if (item.value == privacyProfilePic.value.code) {
        item.isSelected = true;
      }
    }

    Toast.showBottomSheet(
      context: context,
      container: CustomBottomSheet(
        context: context,
        title: localized(psProfilePicture),
        subTitle: '${localized(whoCanSeeMyProfilePicture)}?',
        selectionOptionModelList: profileSelectionOptionModelList,
        callback: (int index) {
          checkPrivacyType(
            showProfilePicture,
            Privacy.fromIndex(profileSelectionOptionModelList[index].value!),
          );
          Get.back();
        },
      ),
    );
  }

  void handleLastSeenView(BuildContext context) {
    for (var item in profileSelectionOptionModelList) {
      item.isSelected = false;
      if (item.value == privacyLastSeen.value.code) {
        item.isSelected = true;
      }
    }

    Toast.showBottomSheet(
      context: context,
      container: CustomBottomSheet(
        context: context,
        title: localized(psLastSeen),
        subTitle: '${localized(whoCanSeeMyLastSeen)}?',
        selectionOptionModelList: profileSelectionOptionModelList,
        callback: (int index) {
          checkPrivacyType(
            showLastSeen,
            Privacy.fromIndex(profileSelectionOptionModelList[index].value!),
          );
          Get.back();
        },
      ),
    );
  }

  void handleUsernameSearchView(BuildContext context) {
    for (var item in friendRequestSelectionOptionModelList) {
      item.isSelected = false;
      if (item.value == privacySearchByUsername.value.code) {
        item.isSelected = true;
      }
    }

    Toast.showBottomSheet(
      context: context,
      container: CustomBottomSheet(
        context: context,
        title: localized(psUsernameSearch),
        subTitle: '${localized(whoCanSeeMyUsernameViaSearch)}?',
        selectionOptionModelList: friendRequestSelectionOptionModelList,
        callback: (int index) {
          checkPrivacyType(
            searchByUsername,
            Privacy.fromIndex(
              friendRequestSelectionOptionModelList[index].value!,
            ),
          );
          Get.back();
        },
      ),
    );
  }

  void handlePhoneNumSearchView(BuildContext context) {
    for (var item in friendRequestSelectionOptionModelList) {
      item.isSelected = false;
      if (item.value == privacySearchByPhoneNum.value.code) {
        item.isSelected = true;
      }
    }

    Toast.showBottomSheet(
      context: context,
      container: CustomBottomSheet(
        context: context,
        title: localized(psPhoneNumberSearch),
        subTitle: '${localized(whoCanSeeMyPhoneNumberViaSearch)}?',
        selectionOptionModelList: friendRequestSelectionOptionModelList,
        callback: (int index) {
          checkPrivacyType(
            searchByPhoneNumber,
            Privacy.fromIndex(
              friendRequestSelectionOptionModelList[index].value!,
            ),
          );
          Get.back();
        },
      ),
    );
  }

  void checkPrivacyType(
    String privacyType,
    Privacy privacy,
  ) {
    switch (privacy.code) {
      case 1:
        updatePrivacySetting(privacyType, 1);
        break;
      case 2:
        updatePrivacySetting(privacyType, 2);
        break;
      case 3:
        updatePrivacySetting(privacyType, 3);
        break;
      default:
        updatePrivacySetting(privacyType, 1);
    }
  }

  void _onSetPassword(Object sender, Object type, Object? data) async {
    if (data is bool) {
      if (data) {
        initPasscode();
      }
    }
  }

  void setPrivacyValue(String privacyType, int privacyCode) {
    Privacy privacy = Privacy.fromIndex(privacyCode);
    switch (privacyType) {
      case showProfileUsername:
        privacyUsername.value = privacy;
        break;
      case showProfilePhoneNumber:
        privacyPhoneNum.value = privacy;
        break;
      case showProfilePicture:
        privacyProfilePic.value = privacy;
        break;
      case showLastSeen:
        privacyLastSeen.value = privacy;
        break;
      case searchByUsername:
        privacySearchByUsername.value = privacy;
        break;
      case searchByPhoneNumber:
        privacySearchByPhoneNum.value = privacy;
        break;
      case showEmailAddress:
        privacyEmailAddress.value = privacy;
        break;
    }
  }

  /// 安全隱私
  //初始已點選資料
  initSelected() {
    switch (privacySecuritySettingPage.value) {
      case PrivacySecuritySettingPage.profilePic:
        for (int index = 0;
            index < profileSelectionOptionModelList.length;
            index++) {
          var item = profileSelectionOptionModelList[index];
          item.isSelected = false;
          if (item.value == privacyProfilePic.value.code) {
            item.isSelected = true;
            isSelectPrivacySecuritySettingIndex.value = index;
          }
        }
        break;

      case PrivacySecuritySettingPage.phoneNum:
        for (int index = 0;
            index < profileSelectionOptionModelList.length;
            index++) {
          var item = profileSelectionOptionModelList[index];
          item.isSelected = false;
          if (item.value == privacyPhoneNum.value.code) {
            item.isSelected = true;
            isSelectPrivacySecuritySettingIndex.value = index;
          }
        }
        break;

      case PrivacySecuritySettingPage.username:
        for (int index = 0;
            index < profileSelectionOptionModelList.length;
            index++) {
          var item = profileSelectionOptionModelList[index];
          item.isSelected = false;
          if (item.value == privacyUsername.value.code) {
            item.isSelected = true;
            isSelectPrivacySecuritySettingIndex.value = index;
          }
        }
        break;

      case PrivacySecuritySettingPage.lastSeen:
        for (int index = 0;
            index < profileSelectionOptionModelList.length;
            index++) {
          var item = profileSelectionOptionModelList[index];
          item.isSelected = false;
          if (item.value == privacyLastSeen.value.code) {
            item.isSelected = true;
            isSelectPrivacySecuritySettingIndex.value = index;
          }
        }
        break;

      case PrivacySecuritySettingPage.usernameSearch:
        for (int index = 0;
            index < friendRequestSelectionOptionModelList.length;
            index++) {
          var item = friendRequestSelectionOptionModelList[index];
          item.isSelected = false;
          if (item.value == privacySearchByUsername.value.code) {
            item.isSelected = true;
            isSelectPrivacySecuritySettingIndex.value = index;
          }
        }
        break;

      case PrivacySecuritySettingPage.phoneNumSearch:
        for (int index = 0;
            index < friendRequestSelectionOptionModelList.length;
            index++) {
          var item = friendRequestSelectionOptionModelList[index];
          item.isSelected = false;
          if (item.value == privacySearchByPhoneNum.value.code) {
            item.isSelected = true;
            isSelectPrivacySecuritySettingIndex.value = index;
          }
        }
        break;

      case PrivacySecuritySettingPage.emailAddress:
        for (int index = 0;
            index < friendRequestSelectionOptionModelList.length;
            index++) {
          var item = friendRequestSelectionOptionModelList[index];
          item.isSelected = false;
          if (item.value == privacyEmailAddress.value.code) {
            item.isSelected = true;
            isSelectPrivacySecuritySettingIndex.value = index;
          }
        }
        break;
    }
  }

  //選取後的點擊事件處理
  isSelectHandler(index) {
    switch (privacySecuritySettingPage.value) {
      case PrivacySecuritySettingPage.profilePic:
        checkPrivacyType(
          showProfilePicture,
          Privacy.fromIndex(profileSelectionOptionModelList[index].value!),
        );
        break;

      case PrivacySecuritySettingPage.phoneNum:
        checkPrivacyType(
          showProfilePhoneNumber,
          Privacy.fromIndex(profileSelectionOptionModelList[index].value!),
        );
        break;

      case PrivacySecuritySettingPage.username:
        checkPrivacyType(
          showProfileUsername,
          Privacy.fromIndex(profileSelectionOptionModelList[index].value!),
        );
        break;

      case PrivacySecuritySettingPage.lastSeen:
        checkPrivacyType(
          showLastSeen,
          Privacy.fromIndex(profileSelectionOptionModelList[index].value!),
        );
        break;

      case PrivacySecuritySettingPage.usernameSearch:
        checkPrivacyType(
          searchByUsername,
          Privacy.fromIndex(
            friendRequestSelectionOptionModelList[index].value!,
          ),
        );
        break;

      case PrivacySecuritySettingPage.phoneNumSearch:
        checkPrivacyType(
          searchByPhoneNumber,
          Privacy.fromIndex(
            friendRequestSelectionOptionModelList[index].value!,
          ),
        );
        break;

      case PrivacySecuritySettingPage.emailAddress:
        checkPrivacyType(
          showEmailAddress,
          Privacy.fromIndex(profileSelectionOptionModelList[index].value!),
        );
        break;
    }
  }

  //取得對應的資料
  getList() {
    switch (privacySecuritySettingPage.value) {
      case PrivacySecuritySettingPage.profilePic:
      case PrivacySecuritySettingPage.phoneNum:
      case PrivacySecuritySettingPage.username:
      case PrivacySecuritySettingPage.lastSeen:
      case PrivacySecuritySettingPage.emailAddress:
        return profileSelectionOptionModelList;
      case PrivacySecuritySettingPage.usernameSearch:
      case PrivacySecuritySettingPage.phoneNumSearch:
        return friendRequestSelectionOptionModelList;
    }
  }

  //取得對應的資料項目
  getListItem(index) {
    switch (privacySecuritySettingPage.value) {
      case PrivacySecuritySettingPage.profilePic:
      case PrivacySecuritySettingPage.phoneNum:
      case PrivacySecuritySettingPage.username:
      case PrivacySecuritySettingPage.lastSeen:
      case PrivacySecuritySettingPage.emailAddress:
        return profileSelectionOptionModelList[index];
      case PrivacySecuritySettingPage.usernameSearch:
      case PrivacySecuritySettingPage.phoneNumSearch:
        return friendRequestSelectionOptionModelList[index];
    }
  }

  //取得頁面標題
  getTitle() {
    switch (privacySecuritySettingPage.value) {
      case PrivacySecuritySettingPage.profilePic:
        return localized(psProfilePicture);
      case PrivacySecuritySettingPage.phoneNum:
        return localized(psPhoneNumber);
      case PrivacySecuritySettingPage.username:
        return localized(psUsername);
      case PrivacySecuritySettingPage.lastSeen:
        return localized(psLastSeen);
      case PrivacySecuritySettingPage.usernameSearch:
        return localized(psUsernameSearch);
      case PrivacySecuritySettingPage.phoneNumSearch:
        return localized(psPhoneNumberSearch);
      case PrivacySecuritySettingPage.emailAddress:
        return localized(emailAddress);
    }
  }

  //取得頁面副標題
  getSubTitle() {
    switch (privacySecuritySettingPage.value) {
      case PrivacySecuritySettingPage.profilePic:
        return '${localized(whoCanSeeMyProfilePicture)}?';
      case PrivacySecuritySettingPage.phoneNum:
        return '${localized(whoCanSeeMyPhoneNumber)}?';
      case PrivacySecuritySettingPage.username:
        return '${localized(whoCanSeeMyUsername)}?';
      case PrivacySecuritySettingPage.lastSeen:
        return '${localized(whoCanSeeMyLastSeen)}?';
      case PrivacySecuritySettingPage.usernameSearch:
        return '${localized(whoCanSeeMyUsernameViaSearch)}?';
      case PrivacySecuritySettingPage.phoneNumSearch:
        return '${localized(whoCanSeeMyPhoneNumberViaSearch)}?';
      case PrivacySecuritySettingPage.emailAddress:
        return '${localized(whoCanSeeMyEmail)}?';
    }
  }

  /// 钱包二次二次认证设定
  Future<void> initWalletSettings() async {
    final res = await walletServices.getSettings();
    if (res.code == 0) {
      WalletSettingsBean bean = WalletSettingsBean.fromJson(res.data);
      settingBean = bean;
      isPayTwoFactorAuthEnable.value = bean.isPayTwoFactorAuthEnable;
      emailAuthEnable.value = bean.emailAuthEnable == 1;
      phoneAuthEnable.value = bean.phoneAuthEnable == 1;
    }
  }

  void goToAuthMethodView() {
    if (objectMgr.loginMgr.isDesktop) {
      Get.toNamed(RouteName.authMethodView,
              arguments: {
                'emailAuthEmail': settingBean?.emailAuthEmail,
                'emailAuthEnable': settingBean?.emailAuthEnable,
                'phoneAuthContact': settingBean?.phoneAuthContact,
                'phoneAuthCountryCode': settingBean?.phoneAuthCountryCode,
                'phoneAuthEnable': settingBean?.phoneAuthEnable,
              },
              id: 3)
          ?.then((value) {
        initWalletSettings();
        return true;
      });
    } else {
      Get.toNamed(
        RouteName.authMethodView,
        arguments: {
          'emailAuthEmail': settingBean?.emailAuthEmail,
          'emailAuthEnable': settingBean?.emailAuthEnable,
          'phoneAuthContact': settingBean?.phoneAuthContact,
          'phoneAuthCountryCode': settingBean?.phoneAuthCountryCode,
          'phoneAuthEnable': settingBean?.phoneAuthEnable,
        },
      )?.then((value) {
        initWalletSettings();
        return true;
      });
    }
  }

  ///
  String getAuthType() {
    if (emailAuthEnable.value && phoneAuthEnable.value) {
      return localized(all);
    } else if (emailAuthEnable.value && !phoneAuthEnable.value) {
      return localized(emailAddress);
    } else if (!emailAuthEnable.value && phoneAuthEnable.value) {
      return localized(myPasswordPhone);
    }
    return "";
  }

  void goToPaymentTwoFactorAuthView() {
    if (objectMgr.loginMgr.isDesktop) {
      Get.toNamed(RouteName.paymentTwoFactorAuthView,
              arguments: {
                "isPayTwoFactorAuthEnable": isPayTwoFactorAuthEnable.value,
              },
              id: 3)
          ?.then((value) {
        initWalletSettings();
      });
    } else {
      Get.toNamed(
        RouteName.paymentTwoFactorAuthView,
        arguments: {
          "isPayTwoFactorAuthEnable": isPayTwoFactorAuthEnable.value,
        },
      )?.then((value) {
        initWalletSettings();
      });
    }
  }

  // 朋友圈权限
  void initMomentSettings() async{
    await objectMgr.momentMgr.getSetting();
    switch (objectMgr.momentMgr.availableDaysMomentSetting) {
      case MomentAvailableDays.forever:
        momentSelectionOptionModelList.first.isSelected = true;
        momentSelectionIdx.value = 0;
        break;
      case MomentAvailableDays.threeDays:
        momentSelectionOptionModelList[1].isSelected = true;
        momentSelectionIdx.value = 1;
        break;
      case MomentAvailableDays.oneMonth:
        momentSelectionOptionModelList[2].isSelected = true;
        momentSelectionIdx.value = 2;
        break;
      case MomentAvailableDays.halfYear:
        momentSelectionOptionModelList[3].isSelected = true;
        momentSelectionIdx.value = 3;
        break;
      default:
        momentSelectionOptionModelList.first.isSelected = true;
        break;
    }
  }

  void onMomentAvailableDaysUpdate(int index) {
    momentSelectionIdx.value = index;
    for (int i = 0; i < momentSelectionOptionModelList.length; i++) {
      momentSelectionOptionModelList[i].isSelected = false;

      if (i == index) {
        momentSelectionOptionModelList[i].isSelected = true;
      }
    }

    objectMgr.momentMgr.uploadAvailableDays(
      MomentAvailableDays.parseValue(
        momentSelectionOptionModelList[index].value!,
      ),
    );
  }

  Future<void> navigateToEncryptionSetupPage(
      {EncryptionSetupPasswordType? type}) async {
    type ??= await objectMgr.encryptionMgr.isEncryptionNewSetup();

    switch (type) {
      case EncryptionSetupPasswordType.neverSetup:

        /// 1.当在启动app时，setEncryptionKey失败
        /// 2.会造成本地没有储存密钥
        /// 3.重新走init流程
        /// 4.如果还是setEncryptionKey失败，就提示用户重试

        await objectMgr.encryptionMgr.getCipherKey();
        EncryptionSetupPasswordType newType =
            await objectMgr.encryptionMgr.isEncryptionNewSetup();
        if (type == EncryptionSetupPasswordType.neverSetup) {
          imBottomToast(
            Get.context!,
            title: localized(chatInfoPleaseTryAgainLater),
            icon: ImBottomNotifType.warning,
          );
        } else {
          navigateToEncryptionSetupPage(type: newType);
        }
        break;
      case EncryptionSetupPasswordType.anotherDeviceSetup:
        Get.toNamed(RouteName.encryptionVerificationPage);
        break;
      case EncryptionSetupPasswordType.doneSetup:
        Get.toNamed(RouteName.encryptionPrivateKeySettingPage);
        break;
      case EncryptionSetupPasswordType.abnormal:
        imBottomToast(
          Get.context!,
          title: localized(noNetworkPleaseTryAgainLater),
          icon: ImBottomNotifType.warning,
        );
        break;
    }
  }

  void navigateToFriendVerifyPage() {
    Get.toNamed(RouteName.encryptionFriendVerifySettingPage);
  }
}
