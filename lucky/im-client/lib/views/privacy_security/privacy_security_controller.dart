import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_bottom_sheet.dart';

import '../../api/wallet_services.dart';
import '../../main.dart';
import '../../object/wallet/wallet_settings_bean.dart';
import '../../routes.dart';

class PrivacySecurityController extends GetxController {
  final SettingServices _settingServices = SettingServices();
  late final passcodeStatus = Secure.noPassword.obs;
  late final Rx<Privacy> privacyUsername;
  late final Rx<Privacy> privacyPhoneNum;
  late final Rx<Privacy> privacyProfilePic;
  late final Rx<Privacy> privacyLastSeen;
  late final Rx<Privacy> privacySearchByUsername;
  late final Rx<Privacy> privacySearchByPhoneNum;
  final privacySecuritySettingPage = PrivacySecuritySettingPage.profilePic.obs;
  final isSelectPrivacySecuritySettingIndex = 0.obs;
  final autoDeductNum = 0.obs;

  ///二次验证
  final RxBool isPayTwoFactorAuthEnable = false.obs;
  final RxBool emailAuthEnable = false.obs;
  final RxBool phoneAuthEnable = false.obs;
  WalletSettingsBean? settingBean;

  /// claim redPacket action from chatRoom
  String? fromView;
  Chat? chat;

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
            objectMgr.localStorageMgr.read<int?>(showProfileUsername) ?? 0)
        .obs;
    privacyPhoneNum = Privacy.fromIndex(
            objectMgr.localStorageMgr.read<int?>(showProfilePhoneNumber) ?? 0)
        .obs;
    privacyProfilePic = Privacy.fromIndex(
            objectMgr.localStorageMgr.read<int?>(showProfilePicture) ?? 0)
        .obs;
    privacyLastSeen = Privacy.fromIndex(
            (objectMgr.localStorageMgr.read<int?>(showLastSeen) ?? 0))
        .obs;
    privacySearchByUsername = Privacy.fromIndex(
            (objectMgr.localStorageMgr.read<int?>(searchByUsername) ?? 0))
        .obs;
    privacySearchByPhoneNum = Privacy.fromIndex(
            (objectMgr.localStorageMgr.read<int?>(searchByPhoneNumber) ?? 0))
        .obs;

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
    refreshAutoDeductData();
  }

  @override
  void onClose() {
    super.onClose();
    objectMgr.chatMgr.off(ChatMgr.eventSetPassword, _onSetPassword);
  }

  Future<void> initPasscode() async {
    bool? result =
        await objectMgr.localStorageMgr.read(LocalStorageMgr.SET_PASSWORD);
    if (result != null && result) {
      passcodeStatus.value = Secure.eachDay;
    } else {
      final data = await _settingServices.getPasscodeSetting();
      passcodeStatus(data);
      objectMgr.localStorageMgr.write(
          LocalStorageMgr.SET_PASSWORD, !passcodeStatus.value.isNoPassword);
    }
  }

  Future<void> initPrivacySetting() async {
    final data = await _settingServices.getPrivacySetting();
    final Map<String, dynamic> privacyTypeSetting =
        await _settingServices.getPrivacyTypeSetting();

    privacyUsername.value =
        Privacy.fromIndex((privacyTypeSetting[showProfileUsername]));
    privacyPhoneNum.value =
        Privacy.fromIndex((privacyTypeSetting[showProfilePhoneNumber]));
    privacyProfilePic.value =
        Privacy.fromIndex((privacyTypeSetting[showProfilePicture]));
    privacyLastSeen.value =
        Privacy.fromIndex((privacyTypeSetting[showLastSeen]));
    privacySearchByUsername.value =
        Privacy.fromIndex((privacyTypeSetting[searchByUsername]));
    privacySearchByPhoneNum.value =
        Privacy.fromIndex((privacyTypeSetting[searchByPhoneNumber]));

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
  }

  Future<void> updatePrivacySetting(
      String privacyType, int privacyStatus) async {
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
      if(objectMgr.loginMgr.isDesktop){
        Get.toNamed(
          RouteName.passcodeIntroSetting,
          arguments: arguments,
          id: 3
        );
      }else{
        Get.toNamed(
          RouteName.passcodeIntroSetting,
          arguments: arguments,
        );
      }
    } else {
      if(objectMgr.loginMgr.isDesktop){
        Get.toNamed(RouteName.passcodeSetting,id: 3);
      }else{
        Get.toNamed(RouteName.passcodeSetting);
      }
    }
  }

  void handlePhoneNumView(BuildContext context) {
    profileSelectionOptionModelList.forEach((item) {
      item.isSelected = false;
      if (item.value == privacyPhoneNum.value.code) {
        item.isSelected = true;
      }
    });

    Toast.showBottomSheet(
      context: context,
      container: CustomBottomSheet(
        context: context,
        title: localized(psPhoneNumber),
        subTitle: '${localized(whoCanSeeMyPhoneNumber)}?',
        selectionOptionModelList: profileSelectionOptionModelList,
        callback: (int index) {
          checkPrivacyType(showProfilePhoneNumber,
              Privacy.fromIndex(profileSelectionOptionModelList[index].value!));
          Get.back();
        },
      ),
    );
  }

  void handleUsernameView(BuildContext context) {
    profileSelectionOptionModelList.forEach((item) {
      item.isSelected = false;
      if (item.value == privacyUsername.value.code) {
        item.isSelected = true;
      }
    });

    Toast.showBottomSheet(
      context: context,
      container: CustomBottomSheet(
        context: context,
        title: localized(psUsername),
        subTitle: '${localized(whoCanSeeMyUsername)}?',
        selectionOptionModelList: profileSelectionOptionModelList,
        callback: (int index) {
          checkPrivacyType(showProfileUsername,
              Privacy.fromIndex(profileSelectionOptionModelList[index].value!));
          Get.back();
        },
      ),
    );
  }

  void handleProfilePicView(BuildContext context) {
    profileSelectionOptionModelList.forEach((item) {
      item.isSelected = false;
      if (item.value == privacyProfilePic.value.code) {
        item.isSelected = true;
      }
    });

    Toast.showBottomSheet(
      context: context,
      container: CustomBottomSheet(
        context: context,
        title: localized(psProfilePicture),
        subTitle: '${localized(whoCanSeeMyProfilePicture)}?',
        selectionOptionModelList: profileSelectionOptionModelList,
        callback: (int index) {
          checkPrivacyType(showProfilePicture,
              Privacy.fromIndex(profileSelectionOptionModelList[index].value!));
          Get.back();
        },
      ),
    );
  }

  void handleLastSeenView(BuildContext context) {
    profileSelectionOptionModelList.forEach((item) {
      item.isSelected = false;
      if (item.value == privacyLastSeen.value.code) {
        item.isSelected = true;
      }
    });

    Toast.showBottomSheet(
      context: context,
      container: CustomBottomSheet(
        context: context,
        title: localized(psLastSeen),
        subTitle: '${localized(whoCanSeeMyLastSeen)}?',
        selectionOptionModelList: profileSelectionOptionModelList,
        callback: (int index) {
          checkPrivacyType(showLastSeen,
              Privacy.fromIndex(profileSelectionOptionModelList[index].value!));
          Get.back();
        },
      ),
    );
  }

  void handleUsernameSearchView(BuildContext context) {
    friendRequestSelectionOptionModelList.forEach((item) {
      item.isSelected = false;
      if (item.value == privacySearchByUsername.value.code) {
        item.isSelected = true;
      }
    });

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
                  friendRequestSelectionOptionModelList[index].value!));
          Get.back();
        },
      ),
    );
  }

  void handlePhoneNumSearchView(BuildContext context) {
    friendRequestSelectionOptionModelList.forEach((item) {
      item.isSelected = false;
      if (item.value == privacySearchByPhoneNum.value.code) {
        item.isSelected = true;
      }
    });

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
                  friendRequestSelectionOptionModelList[index].value!));
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
        for (int index = 0; index < profileSelectionOptionModelList.length; index++) {
          var item = profileSelectionOptionModelList[index];
          item.isSelected = false;
          if (item.value == privacyUsername.value.code) {
            item.isSelected = true;
            isSelectPrivacySecuritySettingIndex.value = index;
          }
        }
        break;

      case PrivacySecuritySettingPage.lastSeen:
        for (int index = 0; index < profileSelectionOptionModelList.length; index++) {
          var item = profileSelectionOptionModelList[index];
          item.isSelected = false;
          if (item.value == privacyLastSeen.value.code) {
            item.isSelected = true;
            isSelectPrivacySecuritySettingIndex.value = index;
          }
        }
        break;

      case PrivacySecuritySettingPage.usernameSearch:
        for (int index = 0; index < friendRequestSelectionOptionModelList.length; index++) {
          var item = friendRequestSelectionOptionModelList[index];
          item.isSelected = false;
          if (item.value == privacySearchByUsername.value.code) {
            item.isSelected = true;
            isSelectPrivacySecuritySettingIndex.value = index;
          }
        }
        break;

      case PrivacySecuritySettingPage.phoneNumSearch:
        for (int index = 0; index < friendRequestSelectionOptionModelList.length; index++) {
          var item = friendRequestSelectionOptionModelList[index];
          item.isSelected = false;
          if (item.value == privacySearchByPhoneNum.value.code) {
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
        checkPrivacyType(showProfilePicture,
            Privacy.fromIndex(profileSelectionOptionModelList[index].value!));
        break;

      case PrivacySecuritySettingPage.phoneNum:
        checkPrivacyType(showProfilePhoneNumber,
            Privacy.fromIndex(profileSelectionOptionModelList[index].value!));
        break;

      case PrivacySecuritySettingPage.username:
        checkPrivacyType(showProfileUsername,
            Privacy.fromIndex(profileSelectionOptionModelList[index].value!));
        break;

      case PrivacySecuritySettingPage.lastSeen:
        checkPrivacyType(showLastSeen,
            Privacy.fromIndex(profileSelectionOptionModelList[index].value!));
        break;

      case PrivacySecuritySettingPage.usernameSearch:
        checkPrivacyType(
            searchByUsername,
            Privacy.fromIndex(
                friendRequestSelectionOptionModelList[index].value!));
        break;

      case PrivacySecuritySettingPage.phoneNumSearch:
        checkPrivacyType(
            searchByPhoneNumber,
            Privacy.fromIndex(
                friendRequestSelectionOptionModelList[index].value!));
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

      ///
    } else {
      showWarningToast("${res.message}");
    }
  }

  void goToAuthMethodView() {
    Get.toNamed(RouteName.authMethodView, arguments: {
      'emailAuthEmail': settingBean?.emailAuthEmail,
      'emailAuthEnable': settingBean?.emailAuthEnable,
      'phoneAuthContact': settingBean?.phoneAuthContact,
      'phoneAuthCountryCode': settingBean?.phoneAuthCountryCode,
      'phoneAuthEnable': settingBean?.phoneAuthEnable,
    })?.then((value) {
      initWalletSettings();
      return true;
    });
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
    Get.toNamed(RouteName.paymentTwoFactorAuthView, arguments: {
      "isPayTwoFactorAuthEnable": isPayTwoFactorAuthEnable.value
    })?.then((value) {
      initWalletSettings();
    });
  }

  void goToPaymentAutoDeductionView(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              PaymentAutoDeductView.providerPage(),
        )).then((value) {
      refreshAutoDeductData();
      return true;
    });
  }

  getListNum() {
    if (autoDeductNum.value == 0) {
      return "";
    }
    return "${autoDeductNum.value}";
  }

  Future<void> refreshAutoDeductData() async {
    Map<String,dynamic> map = {
      "page": 1,
      "limit": Constants.defaultSize,
    };
    dynamic res = await postAutoDeductionList(map);
    if (res.code == 0) {
      AutoDeductBean autoDeductBean = AutoDeductBean.fromJson(res.data);
      autoDeductNum.value = autoDeductBean.totalCnt ?? 0;
    }else{
      autoDeductNum.value = 0;
    }
  }
}
