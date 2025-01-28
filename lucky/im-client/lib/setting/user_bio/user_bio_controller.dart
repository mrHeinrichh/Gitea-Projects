import 'dart:io';
import 'dart:typed_data';

import 'package:country_list_pick/support/code_countries_en.dart';
import 'package:country_list_pick/support/code_country.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/task/image/image_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/regular.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/error_code_constant.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/setting/profile_photo_picker.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart' as DPN;

String commonAlbumTag = "200";

class UserBioController extends GetxController {
  final meUser = Rxn<User>();

  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  AssetPickerConfig? pickerConfig;
  DefaultAssetPickerProvider? provider;
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
      .map((s) => Country(
            isMandarin:
                AppLocalizations(objectMgr.langMgr.currLocale).isMandarin(),
            name: s['name'],
            zhName: s['zhName'],
            code: s['code'],
            dialCode: s['dial_code'],
            flagUri: 'flags/${s['code'].toLowerCase()}.png',
          ))
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

  @override
  void onInit() {
    super.onInit();

    commonAlbumController =
        Get.find<CommonAlbumController>(tag: commonAlbumTag);

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
    super.onClose();
    usernameController.dispose();
    countryController.dispose();
    phoneController.dispose();
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

    Size fileSize = await getImageCompressedSize(
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
      String? imgUrl = await uploadPhoto(avatarFile.value!, uploadKey);
      if (notBlank(imgUrl)) {
        String? cachePath = cacheMediaMgr.checkLocalFile(
          imgUrl!,
          mini: Config().messageMin,
        );

        if (cachePath == null) {
          await cacheMediaMgr.downloadMedia(
            imgUrl,
            mini: Config().messageMin,
          );
        }

        data['profile_pic'] = removeEndPoint(imgUrl);
      }
    }

    try {
      final User updatedUser = await updateUserDetail(data);
      objectMgr.userMgr.onUserChanged([updatedUser], notify: true);
      isLoading(false);
      Get.back();
      // Toast.showSnackBar(context: context, message: localized(profileUpdated));
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: localized(profileUpdated), icon: ImBottomNotifType.success);
    } on AppException catch (e) {
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: e.getMessage(), icon: ImBottomNotifType.warning);
      // Toast.showToast(e.getMessage());
      isLoading(false);
    }
  }

  /*
 * 上传图片
 */
  Future<String?> uploadPhoto(File imageFile, String uploadKey) async {
    final String? imageUrl = await imageMgr.upload(
      imageFile.path,
      0,
      0,
      showOriginal: true,
    );

    return imageUrl;
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
    if (value[0] == '_') {
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
        .where((element) =>
            element.name!.toLowerCase().contains(value.toLowerCase()) ||
            element.dialCode!.contains(value) ||
            element.zhName.toString().contains(value))
        .toList();
  }

  void selectCountry(int index) {
    Get.back();
    country.value = updatedCountryList[index];
    phoneController.clear();
    numberLengthError.value = true;
    phoneController.clear();
  }

  ///检查电话号码是否有被用过
  Future<void> checkPhoneNumber(String phoneNumber) async {
    if (country.value!.dialCode == meUser.value?.countryCode &&
        phoneNumber.replaceAll(' ', '') == meUser.value?.contact) {
      //一样的电话号码
      existingNumber.value = false;
      numberLengthError.value = true;
      wrongPhone.value = false;
    } else {
      //不一样的电话号码
      bool validPhone = false;

      final frPhone1 = DPN.PhoneNumber.parse(
          '${country.value?.dialCode} $phoneNumber',
          callerCountry: DPN.IsoCode.fromJson(
              country.value?.code ?? country.value!.code!));
      validPhone = frPhone1.isValid(type: DPN.PhoneNumberType.mobile);

      if (!validPhone) {
        numberLengthError.value = true;
        existingNumber.value = false;
        wrongPhone.value = false;
      } else {
        checkingPhoneNumber.value = true;
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
        }
      }
    }
  }

  ///更改电话号码
  Future<void> changeContact(
      String countryCode, String contact, String vCode) async {
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
  }

  void showPickPhotoOption(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext _context) {
        return CupertinoActionSheet(
          actions: [
            if (!objectMgr.loginMgr.isDesktop)
              Container(
                color: Colors.white,
                child: OverlayEffect(
                  child: CupertinoActionSheetAction(
                    onPressed: () {
                      if (objectMgr.callMgr.getCurrentState() !=
                          CallState.Idle) {
                        Toast.showToast(localized(toastEndCallFirst));
                        return;
                      }
                      getCameraPhoto(context);
                      Navigator.pop(context);
                    },
                    child: Text(
                      localized(takeAPhoto),
                      style: jxTextStyle.textStyle16(color: accentColor),
                    ),
                  ),
                ),
              ),
            Container(
              color: Colors.white,
              child: OverlayEffect(
                child: CupertinoActionSheetAction(
                  onPressed: () async {
                    Get.back();
                    await getGalleryPhoto(context);
                  },
                  child: Text(
                    localized(chooseFromGalley),
                    style: jxTextStyle.textStyle16(color: accentColor),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: !isClear.value,
              child: Container(
                color: Colors.white,
                child: OverlayEffect(
                  child: CupertinoActionSheetAction(
                    onPressed: () {
                      clearPhoto();
                      Get.back();
                      // Navigator.pop(context);
                    },
                    child: Text(
                      localized(deletePhoto),
                      style: jxTextStyle.textStyle16(color: errorColor),
                    ),
                  ),
                ),
              ),
            )
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              // Navigator.pop(context);
              Get.back();
            },
            child: Text(
              localized(buttonCancel),
              style: jxTextStyle.textStyle16(color: accentColor),
            ),
          ),
        );
      },
    );
  }

  getCameraPhoto(BuildContext context) {
    checkPermission(context).then((isGranted) async {
      if (isGranted) {
        // final AssetEntity? entity = await CameraPicker.pickFromCamera(
        //   context,
        //   pickerConfig: CameraPickerConfig(
        //     enableRecording: false,
        //     enableAudio: false,
        //     theme: CameraPicker.themeData(accentColor),
        //     textDelegate: cameraPickerTextDelegateFromLocale(
        //         objectMgr.langMgr.currLocale),
        //   ),
        // );
        final Map<String, dynamic>? res = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => CamerawesomePage()));
        if (res == null) {
          return;
        }

        final AssetEntity? entity = res["result"];
        if (entity == null) {
          return;
        } else {
          processImage(entity);
        }
      }
    });
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
      try {
        pickerConfig = AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.image,
          specialPickerType: SpecialPickerType.noPreview,
          limitedPermissionOverlayPredicate: (permissionState) {
            return false;
          },
        );
        provider = DefaultAssetPickerProvider(
          maxAssets: pickerConfig!.maxAssets,
          pageSize: pickerConfig!.pageSize,
          pathThumbnailSize: pickerConfig!.pathThumbnailSize,
          selectedAssets: pickerConfig!.selectedAssets,
          requestType: pickerConfig!.requestType,
          sortPathDelegate: pickerConfig!.sortPathDelegate,
          filterOptions: pickerConfig!.filterOptions,
        );
        provider!.addListener(() {
          if (provider!.selectedAssets.isNotEmpty) {
            Get.back();
          }
        });
        //初始化共用相冊元件
        commonAlbumController.init(context);
        //取得選取的相片callback
        commonAlbumController.selectedAction = (AssetEntity selectedFile) async {
          //TODO:權宜之計，強制將頁面和彈窗關掉才能顯示剪輯畫面
          Get.until((route) => route.settings.name == RouteName.commonAlbumView);
          Navigator.pop(context);
          // Navigator.pop(context);
          // File? data = await selectedFile.file;
          // String title = await selectedFile.titleAsync;
          // //打開圖片剪輯器
          // final AssetEntity? imageEntity =
          //     await PhotoManager.editor.saveImageWithPath(
          //   data!.path,
          //   title: title,
          // );
          // provider?.selectAsset(imageEntity!);
          provider?.selectAsset(selectedFile);
        };
        //設置共用相冊
        await commonAlbumController.onPrepareMediaPicker();

        checkPermission(context).then((isGranted) {
          if (isGranted) {
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0.w),
              ),
              builder: (context) => ProfilePhotoPicker(
                provider: provider!,
                pickerConfig: pickerConfig!,
                ps: PermissionState.authorized,
                isUseCommonAlbum: true,
              ),
            ).then((asset) async {
              if (provider!.selectedAssets.isNotEmpty) {
                await processImage(provider!.selectedAssets.first);
                provider!.selectedAssets = [];
                provider!.removeListener(() {});
                pickerConfig = null;
                provider = null;
              }
            });
          }
        });
      } catch (e) {
        openSettingPopup(Permissions().getPermissionsName([Permission.camera,Permission.photos]));
      }
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
          final res = await getOTP(contactNumber, country.value!.dialCode!,
              OtpPageType.changePhoneNumber.type);
          if (res) {
            Get.toNamed(
              RouteName.otpView,
              arguments: {
                'from_view': OtpPageType.changePhoneNumber.page,
                'changed_countryCode': country.value!.dialCode!,
                'changed_number': contactNumber,
                'change_phone': true
              },
              // id: 3,
            );
          }
        } on AppException catch (e) {
          Toast.showToast(e.getMessage());
        }
        numberLengthError.value = true;
        phoneController.clear();
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
      for (int i = 0; i < inputText.length; i++) {
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
    int count = inputText.length;

    if (count > 20) {
      count = 20;
    }
    usernameWordCount.value = 20 - count;
  }

  Future<void> addEmailRequestOTP() async {
    if (!invalidEmail.value) {
      try {
        final res = await getOTPByEmail(
            emailController.text, OtpPageType.changeEmail.type);
        if (res) {
          Get.toNamed(
            RouteName.otpView,
            arguments: {
              'from_view': OtpPageType.changeEmail.page,
              'email': emailController.text.trim(),
              'add_email': true
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
}
