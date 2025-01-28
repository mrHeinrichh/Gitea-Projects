import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/image/image_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/views/register/components/themedAlertDialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/profile_photo_picker.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';

class NewProfileController extends GetxController {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  Rx<File> avatarFile = File('').obs;
  final isClear = false.obs;
  RxString username = "".obs;
  RxString name = "".obs;

  //判断用户名字的变量
  RxBool isValidated = false.obs; //所有匿名以及用户名都正确

  RxBool isValidName = false.obs; //匿名正确
  RxInt nameLength = 30.obs; //匿名的长度，显示使用

  RxBool isValidUsername = true.obs; //用户名正确
  RxInt usernameLength = 20.obs; //用户名长度，显示使用
  RxBool usernameTaken = false.obs; //用户名被使用
  RxBool usernameLengthError = false.obs; //用户名长度错误
  RxBool usernameFormat = false.obs; //用户名格式错误
  RxBool usernameUnderscore = false.obs; //用户名下划线错误

  //检查用户名字时状态的变量
  RxBool progressRegister = false.obs;
  RxBool checkingUsername = false.obs;
  RxBool registerComplete = false.obs;

  AssetPickerConfig? pickerConfig;
  DefaultAssetPickerProvider? provider;

  //所有用户名格式flag -> true为格式正确
  bool get usernameValidFormat =>
      usernameUnderscore.value &&
      usernameFormat.value &&
      usernameLengthError.value;

  @override
  void onInit() {
    super.onInit();
    usernameController.addListener(() {
      username.value = usernameController.text;
    });
    nameController.addListener(() {
      name.value = nameController.text;
    });
    debounce(username, (_) => checkExistingUser(),
        time: const Duration(milliseconds: 500));

    getInviterInfo();
  }

  getInviterInfo() async {
    objectMgr.getInstallInfo();
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
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
      }
    } else {
      Toast.showToast(localized(photoGetFailed));
    }
  }

  Future<String?> uploadPhoto(File imageFile, String uploadKey) async {
    final String? imageUrl = await imageMgr.upload(
      imageFile.path,
      0,
      0,
      showOriginal: true,
    );

    return imageUrl;
  }

  usernameErrorDecider(String value) {
    final int wordsLength = getMessageLength(value);
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
    if (wordsLength < 7 || wordsLength > 20) {
      usernameLengthError.value = false;
    } else {
      usernameLengthError.value = true;
    }
    if (!usernameValidFormat) finalValidation();
  }

  setUsernameValidity(bool value) {
    usernameUnderscore.value = value;
    usernameLengthError.value = value;
    usernameFormat.value = value;
    //没有username时候才会做比较
    if (username.value.isEmpty) {
      finalValidation();
    }
  }

  setNameValidity(bool value) {
    isValidName(value);
    finalValidation();
  }

  finalValidation() async {
    if (username.isEmpty)
      isValidUsername.value = true;
    else {
      if (usernameValidFormat && !usernameTaken.value)
        isValidUsername.value = true;
      else
        isValidUsername.value = false;
    }

    if (isValidName.value && isValidUsername.value)
      isValidated.value = true;
    else
      isValidated.value = false;
  }

  checkExistingUser() async {
    if (username.value.length > 6 && usernameValidFormat) {
      checkingUsername.value = true;
      try {
        final res = await checkUser(usernameController.text);
        if (res) {
          usernameTaken.value = false;
        } else {
          usernameTaken.value = true;
        }
      } on AppException catch (e) {
        usernameTaken.value = true;
        pdebug('[ERROR-name_exist_check]: ${e.getMessage()}');
      }
      finalValidation();
      checkingUsername.value = false;
    } else {
      usernameTaken.value = false;
    }
  }

  getProfileImage(BuildContext context) {
    pickerConfig = AssetPickerConfig(
      maxAssets: 1,
      requestType: RequestType.image,
      limitedPermissionOverlayPredicate: (permissionState) {
        return false;
      },
      specialItemPosition: SpecialItemPosition.prepend,
      specialItemBuilder: (BuildContext context, AssetPathEntity? e, int v) {
        return GestureDetector(
          onTap: () async {
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
              Get.back();
            }
          },
          child: Image.asset('assets/images/mypage/r_dynamics_rect.png'),
        );
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
    checkPermission(context).then(
      (isGranted) {
        if (isGranted) {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                18.0.h,
              ),
            ),
            builder: (context) => ProfilePhotoPicker(
              provider: provider!,
              pickerConfig: pickerConfig!,
              ps: PermissionState.authorized,
            ),
          ).then(
            (asset) async {
              if (provider!.selectedAssets.isNotEmpty) {
                await processImage(provider!.selectedAssets.first);
                provider!.selectedAssets = [];
                provider!.removeListener(() {});
                pickerConfig = null;
                provider = null;
              }
            },
          );
        }
      },
    );
  }

  contactAccessDialog(BuildContext context) async {
    final PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted) {
      showCupertinoModalPopup(
        context: context,
        barrierDismissible: false,
        builder: (context) => ThemedAlertDialog(
          title: '"Jiang Xia" would like to Access Your Contacts',
          content: 'This will be used to manage your contacts',
          cancelButtonText: "Don't allow",
          cancelButtonCallback: () {
            Get.back();
          },
          confirmButtonText: "OK",
          confirmButtonCallback: () async {
            await Permission.contacts.request().isGranted;
            Get.back();
          },
        ),
      );
    }
  }

  register(BuildContext context) async {
    progressRegister.value = true;
    try {
      String profilePic = '';
      if (avatarFile.value.path != '') {
        String uploadKey = objectMgr.userMgr.mainUser.generateAvatarUrl();
        String? imgUrl = await uploadPhoto(avatarFile.value, uploadKey);
        if (imgUrl != null) {
          profilePic = removeEndPoint(imgUrl);
        }
      }

      final user = await objectMgr.loginMgr.registerAccount(
          nickname: nameController.text,
          username: usernameController.text,
          profilePic: profilePic);

      if (objectMgr.loginMgr.account != null) {
        objectMgr.loginMgr.account?.user = user;
        objectMgr.loginMgr.saveAccount(objectMgr.loginMgr.account!);
      }

      /// 由于登出时会clearTables, 因此登录后退出在登录时会重新跑objectMgr.init初始化tables
      // if (SharedRemoteDB.isTableEmpty) {
      await objectMgr.init();
      // }

      if (objectMgr.loginMgr.isLogin) {
        await objectMgr.chatMgr.register();
      }

      objectMgr.socketMgr.updateSocketTime =
          DateTime.now().millisecondsSinceEpoch;
      objectMgr.appInitState.value = AppInitState.idle;
      progressRegister.value = false;
      registerComplete.value = true;
      Get.offAllNamed(RouteName.home);
    } on AppException catch (e) {
      progressRegister.value = false;
      Toast.showToast(e.getMessage(), isStickBottom: false);
    }
  }

  void clearPhoto() {
    avatarFile.value = File('');
  }

  String getUsernameErrorMessage() {
    if (username.value.length == 0) {
      return localized(ifYouDidntProvideAnUsername);
    } else if (!usernameLengthError.value) {
      return localized(usernameMustBetween7to20Characters);
    } else if (!usernameUnderscore.value) {
      return localized(usernameMustStartWithLetterOrNumber);
    } else if (!usernameFormat.value) {
      return localized(usernameInputLettersNumbersAndUnderscoreOnly);
    } else if (usernameTaken.value) {
      return localized(userUsernameTaken);
    } else {
      return '';
    }
  }

  void showPickPhotoOption(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext _context) {
        return CupertinoActionSheet(
          actions: [
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () {
                  getCameraPhoto(context);
                  Navigator.pop(context);
                },
                child: Text(
                  localized(takeAPhoto),
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () {
                  getGalleryPhoto(context);
                  Navigator.pop(context);
                },
                child: Text(
                  localized(chooseFromGalley),
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            ),
            if (avatarFile.value.path.isNotEmpty)
              Container(
                color: Colors.white,
                child: CupertinoActionSheetAction(
                  onPressed: () {
                    clearPhoto();
                    Navigator.pop(context);
                  },
                  child: Text(
                    localized(deletePhoto),
                    style: jxTextStyle.textStyle16(color: errorColor),
                  ),
                ),
              )
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
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

  getGalleryPhoto(BuildContext context) {
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
        final Map<String, dynamic>? resultMap = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => CamerawesomePage()));
        final AssetEntity? entity = resultMap?['result'] as AssetEntity;
        if (entity != null) {
          processImage(entity);
        }
      }
    });
  }
}
