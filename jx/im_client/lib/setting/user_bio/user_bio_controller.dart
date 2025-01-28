import 'dart:io';

import 'package:country_list_pick/support/code_countries_en.dart';
import 'package:country_list_pick/support/code_country.dart';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/phone_input_formatter.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/upload_ext.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/profile_photo_picker.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/regex/regular.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart'
    as phone_numbers_parser;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

String commonAlbumTag = "200";

class UserBioController extends GetxController {
  final meUser = Rxn<User>();

  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  final avatarPath = ''.obs;
  final avatarFile = Rxn<File>();
  final isLoading = false.obs;
  final isClear = false.obs;
  final invalidName = false.obs;
  final invalidBio = false.obs;
  RxBool validProfile = false.obs;
  final nameWordCount = 30.obs;
  final descriptionWordCount = 140.obs;
  final usernameWordCount = 20.obs;
  final String nameWordCountKey = "nameWordCountKey";
  final String descriptionWordCountKey = "descriptionWordCountKey";
  RxBool showNameClearBtn = false.obs;
  RxBool showBioClearBtn = false.obs;

  ///username update
  final TextEditingController usernameController = TextEditingController();
  RxBool usernameCorrect = false.obs;
  RxBool usernameError = false.obs;
  RxBool usernameValidated = false.obs;
  RxBool usernameLength = false.obs;
  RxBool usernameFormat = false.obs;
  RxBool usernameUnderscore = false.obs;
  RxString updatedUsername = ''.obs;
  RxString username = ''.obs;

  ///phone number update
  final TextEditingController countryController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
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
  RxList<Country> updatedCountryList = RxList<Country>();
  final bioCountryCode = ''.obs;
  final bioContactNumber = ''.obs;
  final bioEmail = ''.obs;
  Rxn<Country> country = Rxn<Country>();
  String contactNumber = '';
  RxBool existingNumber = false.obs;
  RxBool numberLengthError = true.obs;
  RxBool wrongPhone = false.obs;
  RxBool checkingPhoneNumber = false.obs;
  late CommonAlbumController commonAlbumController;
  final invalidEmail = true.obs;
  final existingEmail = false.obs;
  PhoneCountryData? initialCountryData;
  final FocusNode countryCodeNode = FocusNode();
  final TextEditingController codeController = TextEditingController();
  final isNotCountryAvailable = false.obs;
  bool isEnglish = AppLocalizations(objectMgr.langMgr.currLocale).isEnglish();
  final showClearBtn = false.obs;

  @override
  void onInit() {
    super.onInit();

    ///username update
    getCurrentUser();

    ///phone update
    numberLengthError.value = true;
    if (updatedCountryList.isEmpty) {
      updatedCountryList.value = countryCodeList;
    }
    getCurrentCountry();
  }

  @override
  void onClose() {
    usernameController.dispose();
    countryController.dispose();
    phoneController.dispose();
    Get.findAndDelete<CommonAlbumController>(tag: commonAlbumTag);
    super.onClose();
  }

  void setShowClearBtn(bool showBtn, {required type}) {
    type == 'bio' ? showBioClearBtn(showBtn) : showNameClearBtn(showBtn);
  }

  clearPhoto() {
    avatarPath.value = '';
    avatarFile.value = null;
    validProfile.value = didChangeDetails();
    isClear(true);
  }

  processImage(AssetEntity asset) async {
    File? assetFile = await asset.file;
    if (assetFile != null) {
      File? croppedFile = await cropImage(assetFile);
      if (croppedFile != null) {
        File? compressedFile = await getThumbImageWithPath(
          croppedFile,
          asset.width,
          asset.height,
          savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          sub: 'head',
        );
        avatarFile.value = compressedFile;
        isClear(false);
        validProfile.value = didChangeDetails();
      }
    } else {
      Toast.showToast(localized(photoGetFailed));
    }
  }

  processImageDesktop(File assetFile) async {
    Uint8List initialImageData = assetFile.readAsBytesSync();
    var decodedImage = await decodeImageFromList(initialImageData);

    Size fileSize = getImageCompressedSize(
      decodedImage.width,
      decodedImage.height,
    );

    File? compressedFile = await getThumbImageWithPath(
      assetFile,
      fileSize.width.toInt(),
      fileSize.height.toInt(),
      savePath: '${DateTime.now().millisecondsSinceEpoch}.jpg',
      sub: 'head',
    );

    avatarFile.value = compressedFile;
    isClear(false);
    validProfile.value = didChangeDetails();
  }

  Future<void> onUpdateProfile(BuildContext context) async {
    if (!validProfile.value) return;

    FocusManager.instance.primaryFocus?.unfocus();

    Map<String, dynamic> data = <String, dynamic>{};
    data['nickname'] = nicknameController.text.trim();
    data['bio'] = bioController.text.trim();
    data['profile_pic'] = avatarPath.value;
    if (data['nickname'].trim() == meUser.value?.nickname &&
        data['bio'].trim() == meUser.value?.profileBio &&
        data['profile_pic'] == meUser.value?.profilePicture &&
        avatarFile.value == null) {
      Get.back();
      return;
    }
    isLoading(true);

    String uploadKey = meUser.value!.generateAvatarUrl();
    if (avatarFile.value != null) {
      final (String? imgUrl, String? gPath) =
          await uploadPhoto(avatarFile.value!, uploadKey);
      if (notBlank(imgUrl)) {
        String? cachePath = downloadMgrV2.getLocalPath(
          imgUrl!,
          mini: Config().messageMin,
        );

        if (cachePath == null) {
          await downloadMgrV2.download(
            imgUrl,
            mini: Config().messageMin,
          );
          // await downloadMgr.downloadFile(
          //   imgUrl,
          //   mini: Config().messageMin,
          // );
        }

        data['profile_pic'] = removeEndPoint(imgUrl);
        data['profile_pic_gaussian'] = gPath;
      }
    }

    try {
      final User updatedUser = await updateUserDetail(data);
      objectMgr.userMgr.onUserChanged([updatedUser], notify: true);
      isLoading(false);
      Get.back();
      // Toast.showSnackBar(context: context, message: localized(profileUpdated));
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(profileUpdated),
        icon: ImBottomNotifType.success,
      );
    } on AppException catch (e) {
      imBottomToast(
        navigatorKey.currentContext!,
        title: e.getMessage(),
        icon: ImBottomNotifType.warning,
      );
      // Toast.showToast(e.getMessage());
      isLoading(false);
    }
  }

  /*
 * 上传图片
 */
  Future<(String?, String?)> uploadPhoto(
      File imageFile, String uploadKey) async {
    String? gPath;
    final String? imageUrl = await imageMgr.upload(
      imageFile.path,
      0,
      0,
      storageType: StorageType.avatar,
      cancelToken: CancelToken(),
      onGaussianComplete: (String gausPath) {
        gPath = gausPath;
      },
    );

    return (imageUrl, gPath);
  }

  ///username update
  void checkUsernameAvailability(String value) async {
    Future.delayed(
      const Duration(milliseconds: 250),
      () async {
        if (value.length > 6) {
          try {
            final res = await checkUser(value);
            if (res) {
              usernameCorrect.value = true;
              usernameError.value = false;
            }
          } on CodeException catch (e) {
            if (e.getPrefix() == ErrorCodeConstant.STATUS_USER_ALREADY_EXIST) {
              usernameCorrect.value = false;
              usernameError.value = true;
            } else {
              pdebug('${e.getPrefix()}: ${e.getMessage()}');
            }
          }
        } else {
          usernameCorrect.value = false;
          usernameError.value = false;
        }
        finalValidation();
      },
    );
  }

  ///更改用户名
  Future<void> changeUsername() async {
    try {
      final updatedUser = await updateUsername(updatedUsername.value);
      username.value = updatedUser.username;
      objectMgr.userMgr.onUserChanged([updatedUser], notify: true);
      if (objectMgr.loginMgr.isDesktop) {
        Get.back(id: 3);
      } else {
        Get.back();
      }
      Toast.showToast(localized(homeChangeUsernameSuccess));
    } on AppException catch (e) {
      if (e.getPrefix() ==
          ErrorCodeConstant.STATUS_UPDATE_USERNAME_QUOTA_EXCEEDED) {
        Toast.showToast(localized(homeChangeUsernameOnce));
      } else {
        Toast.showToast(e.getMessage());
      }
    }
  }

  void setUsernameValidity(bool value) {
    usernameUnderscore.value = value;
    usernameLength.value = value;
    usernameFormat.value = value;
    finalValidation();
  }

  ///决定用户名的错误种类
  void usernameErrorDecider(String value) {
    if (value.isEmpty) {
      usernameUnderscore.value = false;
    } else if (value[0] == '_') {
      usernameUnderscore.value = false;
    } else {
      usernameUnderscore.value = true;
    }
    if (RegExp(r'^(?=[\w]*$)(?=.*?^[a-zA-Z0-9])(?!.*_.*_)').hasMatch(value)) {
      usernameFormat.value = true;
    } else {
      usernameFormat.value = false;
    }
    if (value.length < 7 || value.length > 20) {
      usernameLength.value = false;
    } else {
      usernameLength.value = true;
    }
    finalValidation();
  }

  ///最终对比
  void finalValidation() {
    if (usernameUnderscore.value &&
        usernameLength.value &&
        usernameFormat.value &&
        usernameCorrect.value &&
        !usernameError.value &&
        usernameController.text != meUser.value!.username) {
      usernameValidated.value = true;
    } else {
      usernameValidated.value = false;
    }
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
    numberLengthError.value = true;
    isNotCountryAvailable.value = false;
  }

  void clearText() {
    phoneController.text = '';
    checkPhoneNumber('');
  }

  ///检查电话号码是否有被用过
  Future<void> checkPhoneNumber(String phoneNumber) async {
    if (notBlank(phoneNumber)) {
      showClearBtn.value = true;
    } else {
      showClearBtn.value = false;
    }
    if (country.value!.dialCode == meUser.value?.countryCode &&
        phoneNumber.replaceAll(' ', '') == meUser.value?.contact) {
      //一样的电话号码
      existingNumber.value = false;
      numberLengthError.value = true;
      wrongPhone.value = false;
    } else {
      //不一样的电话号码
      bool validPhone = false;

      final frPhone1 = phone_numbers_parser.PhoneNumber.parse(
        '${country.value?.dialCode} $phoneNumber',
        callerCountry: phone_numbers_parser.IsoCode.fromJson(
          country.value?.code ?? country.value!.code!,
        ),
      );
      validPhone =
          frPhone1.isValid(type: phone_numbers_parser.PhoneNumberType.mobile);

      if (!validPhone) {
        numberLengthError.value = true;
        existingNumber.value = false;
        wrongPhone.value = false;
      } else {
        checkingPhoneNumber.value = true;
        update(['phone']);
        try {
          final res = await checkPhone(country.value!.dialCode!, phoneNumber);
          if (res) {
            existingNumber.value = false;
            numberLengthError.value = false;
          }
        } on CodeException catch (e) {
          if (e.getPrefix() == ErrorCodeConstant.STATUS_PHONE_ALREADY_EXIST) {
            existingNumber.value = true;
          } else if (e.getPrefix() ==
              ErrorCodeConstant.STATUS_INVALID_CONTACT) {
            wrongPhone.value = true;
          } else {
            pdebug('${e.getPrefix()}: ${e.getMessage()}');
          }
          numberLengthError.value = false;
        } finally {
          checkingPhoneNumber.value = false;
          update(['phone']);
        }
      }
    }
  }

  ///更改电话号码
  Future<void> changeContact(
    String countryCode,
    String contact,
    String vCode,
  ) async {
    try {
      final updatedUser = await updatePhone(countryCode, contact, vCode);
      bioCountryCode.value = updatedUser.countryCode;
      bioContactNumber.value = updatedUser.contact;
      objectMgr.userMgr.onUserChanged([updatedUser], notify: true);
    } on CodeException {
      rethrow;
    }
  }

  ///获取本用户的资料
  void getCurrentUser() {
    meUser.value = objectMgr.userMgr.mainUser;
    username.value = meUser.value?.username ?? '';
    bioEmail.value = meUser.value?.email ?? '';
    bioCountryCode.value = meUser.value?.countryCode ?? '';
    bioContactNumber.value = meUser.value?.contact ?? '';
    nicknameController.text = meUser.value?.nickname ?? '';
    avatarPath.value = meUser.value?.profilePicture ?? '';
    bioController.text = meUser.value?.profileBio ?? '';
    usernameController.text = meUser.value!.username;
    if (avatarPath.value == '' && avatarFile.value == null) {
      isClear.value = true;
    }

    getWordCount(nameWordCountKey, nicknameController.text);
    getWordCount(descriptionWordCountKey, bioController.text);
    getUsernameWordCount(usernameController.text);
  }

  ///获取本用户的国际号码
  void getCurrentCountry() async {
    country.value = countryCodeList.firstWhereOrNull(
      (element) =>
          element.dialCode ==
          (meUser.value!.countryCode.isEmpty
              ? "+65"
              : meUser.value!.countryCode),
    );
    initialCountryData =
        PhoneCodes.getPhoneCountryDataByCountryCode(country.value!.code!);
    codeController.text = country.value!.dialCode!;
    update(['phone']);
  }

  Future<void> showPickPhotoOption(BuildContext context) async {
    FocusScope.of(context).unfocus();
    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      items: [
        if (!objectMgr.loginMgr.isDesktop)
          CustomBottomAlertItem(
            text: localized(takeAPhoto),
            onClick: () {
              if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
                Toast.showToast(localized(toastEndCallFirst));
                return;
              }
              getCameraPhoto(context);
            },
          ),
        CustomBottomAlertItem(
          text: localized(groupEditFromGallery),
          onClick: () async {
            await getGalleryPhoto(context);
          },
        ),
        Visibility(
          visible: !isClear.value,
          child: CustomBottomAlertItem(
            text: localized(groupEditDeletePhoto),
            textColor: colorRed,
            onClick: clearPhoto,
          ),
        ),
      ],
    );
  }

  getCameraPhoto(BuildContext context) async {
    var isGranted = await checkCameraOrPhotoPermission(type: 1);
    if (!isGranted) return;
    AssetEntity? entity;
    if (await isUseImCamera) {
      entity = await CamerawesomePage.openImCamera(
          isMirrorFrontCamera: isMirrorFrontCamera);
    } else {
      final Map<String, dynamic>? res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const CamerawesomePage(),
        ),
      );
      if (res == null) {
        return;
      }
      entity = res["result"];
    }
    if (entity == null) {
      return;
    } else {
      processImage(entity);
    }
  }

  getGalleryPhoto(BuildContext context) async {
    if (objectMgr.loginMgr.isDesktop) {
      try {
        const XTypeGroup typeGroup = XTypeGroup(
          label: 'images',
          extensions: ['jpg', 'jpeg', 'png'],
        );
        final XFile? file =
            await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

        if (file != null) {
          await processImageDesktop(File(file.path));
        }
      } catch (e) {
        pdebug('.......................$e');
      }
    } else {
      //設置共用相冊
      commonAlbumController = Get.findOrPut<CommonAlbumController>(
          CommonAlbumController(),
          tag: commonAlbumTag);
      if (!await commonAlbumController.onPrepareMediaPicker()) return;

      await showModalBottomSheet(
        context: Get.context ?? context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ProfilePhotoPicker(
          provider: commonAlbumController.assetPickerProvider!,
          pickerConfig: commonAlbumController.pickerConfig!,
          ps: commonAlbumController.ps!,
          isUseCommonAlbum: true,
        ),
      ).then((asset) async {
        if (commonAlbumController
            .assetPickerProvider!.selectedAssets.isNotEmpty) {
          await processImage(
              commonAlbumController.assetPickerProvider!.selectedAssets.first);
          commonAlbumController.assetPickerProvider!.selectedAssets = [];
          commonAlbumController.assetPickerProvider!.removeListener(() {});
          commonAlbumController.pickerConfig = null;
          commonAlbumController.assetPickerProvider = null;
        }
      });
    }
  }

  ///检查名字的格式
  void checkName(String name) {
    getWordCount(nameWordCountKey, name);

    int textLength = 0;
    textLength = getMessageLength(name);

    bool hasForeSpace = Regular.foreWithSpace(name);

    //检查名字格式
    if (textLength < 1 || textLength > 30 || hasForeSpace) {
      invalidName.value = true;
    } else {
      invalidName.value = false;
    }
    checkValidProfile();
  }

  ///检查个人简介的字数
  void checkBio(String bio) {
    getWordCount(descriptionWordCountKey, bio);

    int textLength = 0;
    textLength = getMessageLength(bio);

    if (textLength > 140) {
      invalidBio.value = true;
    } else {
      invalidBio.value = false;
    }
    checkValidProfile();
  }

  ///检查所有的个人资料
  void checkValidProfile() {
    if (!invalidName.value && !invalidBio.value) {
      validProfile.value = didChangeDetails();
    } else {
      validProfile.value = false;
    }
  }

  ///更改电话号码
  Future<void> editPhone() async {
    contactNumber = phoneController.text.replaceAll(' ', '');
    if (contactNumber.length > 1) {
      if (!numberLengthError.value &&
          !existingNumber.value &&
          !wrongPhone.value) {
        try {
          //发送otp到新的手机号码
          final res = await getOTP(
            contactNumber,
            country.value!.dialCode!,
            OtpPageType.changePhoneNumber.type,
          );
          if (res) {
            Get.toNamed(
              RouteName.otpView, id: 3,
              arguments: {
                'from_view': OtpPageType.changePhoneNumber.page,
                'changed_countryCode': country.value!.dialCode!,
                'changed_number': contactNumber,
                'change_phone': true,
              },
              // id: 3,
            );
          }
        } on AppException catch (e) {
          Toast.showToast(e.getMessage());
        } catch (e) {
          if (e is CodeException &&
              e.getPrefix() == ErrorCodeConstant.STATUS_OTP_REACH_LIMIT) {
            Toast.showToast(localized(homeOtpMaxLimit));
          } else if (e is CodeException &&
              e.getPrefix() == ErrorCodeConstant.STATUS_OTP_BE_REACH_LIMIT) {
            Toast.showToast(localized(homeOtpBeMaxLimit));
          }
        }
        numberLengthError.value = true;
        clearText();
      }
    }
  }

  ///一样的用户名，所以更改回去原本的状态
  void isInitialUsername() {
    usernameCorrect.value = false;
    usernameError.value = false;
    usernameValidated.value = false;

    /// check usernameUnderscore,usernameLength,usernameFormat
    usernameErrorDecider(usernameController.text);
  }

  String getPhoneNumber() {
    return bioCountryCode.value.isEmpty && bioContactNumber.value.isEmpty
        ? '-'
        : '${bioCountryCode.value} ${bioContactNumber.value}';
  }

  void getWordCount(String key, String inputText) {
    int count = 0;

    if (inputText.isNotEmpty) {
      for (int i = 0; i < inputText.characters.length; i++) {
        if (inputText[i].isChineseCharacter) {
          count += 2;
        } else {
          count += 1;
        }
      }
    }

    if (key == nameWordCountKey) {
      nameWordCount.value = 30 - ((count > 30) ? 30 : count);
    } else {
      descriptionWordCount.value = 140 - ((count > 140) ? 140 : count);
    }
  }

  void getUsernameWordCount(String inputText) {
    int count = inputText.characters.length;

    if (count > 20) {
      count = 20;
    }
    usernameWordCount.value = 20 - count;
  }

  Future<void> addEmailRequestOTP() async {
    if (!invalidEmail.value) {
      try {
        final res = await getOTPByEmail(
          emailController.text,
          OtpPageType.changeEmail.type,
        );
        if (res) {
          Get.toNamed(
            RouteName.otpView,
            arguments: {
              'from_view': OtpPageType.changeEmail.page,
              'email': emailController.text.trim(),
              'add_email': true,
            },
          );
        }
      } on AppException catch (e) {
        Toast.showToast(e.getMessage());
        invalidEmail.value = true;
      }
      emailController.clear();
    }
  }

  Future<void> verifyEmail(String email) async {
    final RegExp regex = RegExp(
      r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
    );
    if (regex.hasMatch(email)) {
      try {
        final res = await checkEmail(email);
        if (res) {
          existingEmail.value = false;
          invalidEmail.value = false;
        }
      } on CodeException catch (e) {
        if (e.getPrefix() == ErrorCodeConstant.STATUS_EMAIL_ALREADY_EXIST) {
          existingEmail.value = true;
        } else {
          pdebug('${e.getPrefix()}: ${e.getMessage()}');
        }
        invalidEmail.value = true;
      }
    } else {
      invalidEmail.value = true;
    }
  }

  String getEmail() {
    return bioEmail.value.isEmpty ? '-' : bioEmail.value;
  }

  Future<void> addEmail(String email, String vCode) async {
    try {
      final updatedUser = await doUpdateEmail(vCode, email);
      bioEmail.value = updatedUser.email;
      objectMgr.userMgr.onUserChanged([updatedUser], notify: true);
    } on CodeException catch (_) {
      rethrow;
    }
  }

  bool didChangeDetails() {
    if (nicknameController.text != '' &&
        nicknameController.text != meUser.value?.nickname) {
      return true;
    }

    if (bioController.text != meUser.value?.profileBio) {
      return true;
    }

    if (avatarFile.value != null) {
      return true;
    } else {
      if (avatarPath.value != meUser.value?.profilePicture) {
        return true;
      }
    }

    return false;
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
