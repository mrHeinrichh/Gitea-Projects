import 'package:country_list_pick/country_list_pick.dart';
import 'package:country_list_pick/support/code_countries_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/phone_input_formatter.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/friends.dart' as friend_api;
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/im/chat_info/chat_info_view.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/contact/search_phone.dart';
import 'package:jxim_client/views/contact/search_username.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchContactController extends GetxController
    with GetTickerProviderStateMixin {
  final usernameList = <User>[].obs;
  final contactList = <User>[].obs;

  RxBool isSearching = false.obs;
  final searchParam = ''.obs;

  bool isModalBottomSheet = true;
  final isSecondPage = false.obs;

  late final TabController tabController;
  final List<Widget> tabList = [const SearchUsername(), const SearchPhone()];
  final tabTitle = [localized(contactUsername), localized(contactPhone)];
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final List<Country> countryCodeList = countriesEnglish
      .map(
        (s) => Country(
          isMandarin:
              AppLocalizations(objectMgr.langMgr.currLocale).isMandarin(),
          name: s['name'],
          zhName: s['zhName'],
          code: s['code'],
          dialCode: s['dial_code'],
          flagUri: 'flags/${s['code'].toLowerCase()}.png',
        ),
      )
      .toList();
  Rxn<Country> country = Rxn<Country>();
  RxList<Country> updatedCountryList = RxList<Country>();
  PhoneCountryData? initialCountryData;
  bool isEnglish = AppLocalizations(objectMgr.langMgr.currLocale).isEnglish();
  final FocusNode countryCodeNode = FocusNode();
  final TextEditingController codeController = TextEditingController();
  final isNotCountryAvailable = false.obs;
  final showClearBtn = false.obs;
  final enableBtn = false.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: tabList.length, vsync: this);
    tabController.addListener(() {
      clearText();
      FocusManager.instance.primaryFocus?.unfocus();
    });
    usernameController.addListener(_usernameOnChange);
    phoneController.addListener(_phoneOnChange);

    if (updatedCountryList.isEmpty) {
      updatedCountryList.value = countryCodeList;
    }
    getCurrentCountry();

    /// 搜索从信息气泡长按电话号码'Search User' 功能
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments.containsKey('phoneNumber')) {
      tabController.animateTo(1);
      Future.delayed(const Duration(milliseconds: 300), () {
        /// Let tab switch first
        phoneController.text = arguments['phoneNumber'];
        contactSearching(arguments['phoneNumber'], isUsername: false);
        enableBtn.value = true;
      });
      if (arguments.containsKey('isModalBottomSheet')) {
        isModalBottomSheet = arguments['isModalBottomSheet'];
      }
    }
  }

  @override
  onClose() {
    usernameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  contactSearching(String param, {bool isUsername = true}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (isSearching.value) return;

    isSearching.value = true;
    usernameList.clear();
    contactList.clear();
    Map<String, dynamic> resultList = {};
    try {
      if (isUsername) {
        resultList = await friend_api.searchUser(
            param: param.removeAllWhitespace, offset: 0);
      } else {
        resultList = await friend_api.searchPhone(
            contact: param.removeAllWhitespace,
            countryCode: country.value!.dialCode!);
      }
    } catch (e) {
      if (e is AppException) {
        imBottomToast(Get.context!,
            title: e.getMessage(), icon: ImBottomNotifType.INFORMATION);
      } else {
        imBottomToast(Get.context!,
            title: localized(connectionFailedPleaseCheckTheNetwork),
            icon: ImBottomNotifType.INFORMATION);
      }
      isSearching.value = false;
      return;
    }

    User? foundUser;
    if (isUsername) {
      if (resultList['users']!.isNotEmpty) {
        List<User> results = (resultList['users'] as List<dynamic>)
            .map((item) => User.fromJson(item as Map<String, dynamic>))
            .toList();

        for (final user in results) {
          if (user.profilePicture.isNotEmpty &&
              user.profilePictureGaussian.isNotEmpty) {
            await imageMgr.genBlurHashImage(
                user.profilePictureGaussian, user.profilePicture);
          }
        }

        usernameList.addAll(results);
        foundUser = usernameList.first;
      }
    } else {
      if (resultList['user']!.isNotEmpty) {
        final user = User.fromJson(resultList['user']);
        if (user.profilePicture.isNotEmpty &&
            user.profilePictureGaussian.isNotEmpty) {
          await imageMgr.genBlurHashImage(
              user.profilePictureGaussian, user.profilePicture);
        }

        foundUser = user;
      }
    }

    if (foundUser != null) {
      if (foundUser.relationship == Relationship.friend ||
          foundUser.relationship == Relationship.blocked ||
          foundUser.relationship == Relationship.blockByTarget) {
        Get.offNamed(RouteName.chatInfo, arguments: {"uid": foundUser.uid});
      } else {
        showChatInfoInSheet(foundUser.uid, Get.context!);
      }
    } else {
      imBottomToast(Get.context!,
          title: localized(cantFindUser), icon: ImBottomNotifType.INFORMATION);
    }

    isSearching.value = false;
  }

  void _usernameOnChange() {
    String value = usernameController.text;
    if (value.startsWith('@')) {
      value = value.substring(1); // Remove the @
      usernameController.text = value;

      usernameController.selection = TextSelection.fromPosition(
        TextPosition(offset: usernameController.text.length),
      );
    }
    if (value.isNotEmpty) {
      showClearBtn.value = true;
      if (value.isEmpty || value.length > 20) {
        enableBtn.value = false;
      } else {
        if (RegExp(r'^(?=[\w]*$)(?=.*?^[a-zA-Z0-9])(?!.*_.*_)')
            .hasMatch(value)) {
          enableBtn.value = true;
        } else {
          enableBtn.value = false;
        }
      }
    } else {
      showClearBtn.value = false;
      enableBtn.value = false;
    }
  }

  void _phoneOnChange() {
    bool hasText = phoneController.text.isNotEmpty;
    enableBtn.value = hasText;
    showClearBtn.value = hasText;
  }

  void clearText() {
    usernameController.text = '';
    phoneController.text = '';
  }

  ///phone update
  ///country code searching
  void searchCountry(String value) {
    updatedCountryList.value = countryCodeList
        .where(
          (element) =>
              element.name!.toLowerCase().contains(value.toLowerCase()) ||
              element.dialCode!.contains(value) ||
              element.zhName.toString().contains(value),
        )
        .toList();
  }

  void selectCountry(int index) {
    Get.back();
    country.value = updatedCountryList[index];
    initialCountryData =
        PhoneCodes.getPhoneCountryDataByCountryCode(country.value!.code!);
    codeController.text = country.value!.dialCode!;
    update(['phone']);
    phoneController.clear();
    isNotCountryAvailable.value = false;
  }

  ///获取本用户的国际号码
  void getCurrentCountry() async {
    country.value = countryCodeList.firstWhereOrNull(
      (element) =>
          element.dialCode ==
          (objectMgr.userMgr.mainUser.countryCode.isEmpty
              ? "+65"
              : objectMgr.userMgr.mainUser.countryCode),
    );
    initialCountryData =
        PhoneCodes.getPhoneCountryDataByCountryCode(country.value!.code!);
    codeController.text = country.value!.dialCode!;
    update(['phone']);
  }

  scanQR() async {
    if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
      Toast.showToast(localized(toastEndCallFirst));
      return;
    }

    bool ps = await Permissions.request([Permission.camera]);
    if (!ps) return;

    Get.toNamed(
      RouteName.qrCodeScanner,
      arguments: {"isModalBottomSheet": isModalBottomSheet},
      preventDuplicates: false,
    );
  }

  Future<void> findContact(BuildContext context) async {
    if (objectMgr.loginMgr.isDesktop) {
      Get.toNamed(RouteName.shareView);
    } else {
      Get.toNamed(RouteName.localContactView, preventDuplicates: false);
    }
  }

  showChatInfoInSheet(int userID, context) async {
    Get.put(ChatInfoController());
    Get.find<ChatInfoController>().uid = userID;
    Get.find<ChatInfoController>().isModalBottomSheet.value = true;
    Get.find<ChatInfoController>().doInit();
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.94,
            child: ChatInfoView(),
          ),
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Get.findAndDelete<ChatInfoController>();
      });
    });
  }

  void checkCountryCode(String code) {
    for (var element in countryCodeList) {
      if (element.dialCode == code) {
        country.value = element;
        initialCountryData =
            PhoneCodes.getPhoneCountryDataByCountryCode(country.value!.code!);
        update(['phone']);
        objectMgr.loginMgr.countryCode = country.value?.dialCode;
        isNotCountryAvailable.value = false;
        phoneController.clear();
        return;
      } else {
        isNotCountryAvailable.value = true;
        phoneController.clear();
      }
    }
  }
}
