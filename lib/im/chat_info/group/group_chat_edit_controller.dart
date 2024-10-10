import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/group.dart' as group_api;
import 'package:jxim_client/im/chat_info/more_vert/custom_cupertino_date_picker.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/im/model/group/group_option_model.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/im_toast/primary_button.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/setting/profile_photo_picker.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';

class GroupChatEditController extends GetxController
    with GetSingleTickerProviderStateMixin {
  /// 聊天室数据
  final group = Rxn<Group>();

  /// 群成员数据
  List<User>? groupMemberListData;

  int? chatID;

  /// 群成员权限
  int permission = 0;
  final isExpanded = false.obs;
  final slowModeText = ''.obs;

  RxBool onOffSubList = true.obs;
  final expiryTime = ''.obs;

  /// 群管理员权限
  int admin = 0;
  final totalSendMsgPermission = 0.obs;

  final charLeft = 140.obs;
  final isLoading = false.obs;
  final isClear = false.obs;
  final avatarFile = Rxn<File>();
  final showSubListSection = ShowSubListSection.off.obs;

  final TextEditingController groupNameTextController = TextEditingController();
  final TextEditingController groupDescTextController = TextEditingController();
  AssetPickerConfig? pickerConfig;
  DefaultAssetPickerProvider? provider;
  final groupPhoto = ''.obs;
  final showMsgSubList = false.obs;
  int originalPermission = 0;
  final viewHistoryEnabled = true.obs;
  bool submitting = false;
  bool isScreenshotEnabled = false;

  RxMap<String, dynamic> permissionList = <String, dynamic>{
    // 'Send Message': false,
    forwardMessagePermission: false,
    addMembersPermission: false,
    pinMessagePermission: false,
    changeGroupInformationPermission: false,
  }.obs;

  RxMap<String, dynamic> sendMsgPermissionList = <String, dynamic>{
    sendTextVoicePermission: false,
    sendMediaPermission: false,
    sendStickerGifPermission: false,
    sendDocumentPermission: false,
    sendContactPermission: false,
    sendRedPacketPermission: false,
    sendHyperlinkPermission: false,
  }.obs;

  Map<String, int> slowMode = <String, int>{
    localized(off): 0,
    localized(second10): 10,
    localized(second30): 30,
    localized(minute1): 60,
    localized(minute5): 300,
    localized(minute15): 900,
    localized(hour1): 3600,
  };

  final groupNameIsEmpty = false.obs;

  final speakInterval = 1.obs;
  int originalSpeakInterval = 0;

  RxBool showClearBtn = false.obs;
  RxBool showDecClearBtn = false.obs;
  final highlightExpiring = false.obs;

  GroupChatEditController();

  GroupChatEditController.desktop({
    Group? group,
    int? permission,
    List<User>? groupMemberListData,
  }) {
    if (group != null) {
      this.group.value = group;
    }

    if (permission != null) {
      this.permission = permission;
    }

    if (groupMemberListData != null) {
      this.groupMemberListData = groupMemberListData;
    }
  }

  /// ================================== METHODS ===============================

  @override
  void onInit() async {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments != null) {
      group.value = arguments['group'] as Group;
      permission = arguments['permission'];
      if (group.value!.isTmpGroup) {
        getExpiryTime(group.value!.expireTime);
      }

      if (arguments.containsKey('highlightExpiring')) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          highlightExpiring.value = true;
          Timer(const Duration(seconds: 3), () {
            highlightExpiring.value = false;
          });
        });
      }
    }

    chatID = group.value?.id ?? 0;
    viewHistoryEnabled.value = group.value?.isVisible ?? true;
    admin = group.value?.admin ?? 0;
    permission = group.value?.permission ?? 0;
    speakInterval.value = group.value?.speakInterval ?? 0;
    originalPermission = permission;
    originalSpeakInterval = speakInterval.value;
    groupNameTextController.text = group.value?.name ?? '';
    groupDescTextController.text = group.value?.profile ?? '';
    isScreenshotEnabled =
        GroupPermissionMap.groupPermissionScreenshot.isAllow(permission);
    if (!Config().enableRedPacket) {
      sendMsgPermissionList.remove(sendRedPacketPermission);
    }
    sendMsgPermissionList.remove('changeGroupPermissionScreenshot');
    getPermissionEnabled(permission);
    groupNameTextController.addListener(() {
      if (groupNameTextController.text.trim().isNotEmpty) {
        groupNameIsEmpty.value = false;
      } else {
        groupNameIsEmpty.value = true;
      }
    });
    groupDescTextController.addListener(() {
      onChanged(groupDescTextController.text);
    });
    if (notBlank(group.value?.icon)) {
      groupPhoto(group.value!.icon);
    } else {
      isClear(true);
    }
    getTextFromSlowMode();
    charLeft.value = 140 - groupDescTextController.text.length;
  }

  bool getShowNotificationVariable() {
    switch (showSubListSection.value) {
      case ShowSubListSection.off:
      default:
        return false;
    }
  }

  void setSlowMode(value) {
    speakInterval.value = value;
    getTextFromSlowMode();
  }

  getPermissionEnabled(int permission) {
    int count = 0;
    for (final permissionMap in GroupPermissionMap.values) {
      if (permissionMap.displayNameKey == "changeGroupPermissionScreenshot") {
        continue;
      }
      bool enabled = permissionMap.isAllow(permission);
      if (enabled) {
        if (permissionList[permissionMap.displayNameKey] == null) {
          if (!Config().enableRedPacket &&
              permissionMap.displayNameKey == "sendRedPacketPermission") {
            continue;
          }
          sendMsgPermissionList[permissionMap.displayNameKey] = true;
          count += 1;
        } else {
          permissionList[permissionMap.displayNameKey] = true;
        }
      }
    }
    totalSendMsgPermission.value = count;
    if (count > 0) {
      isExpanded.value = true;
    }
  }

  onOptionTap(BuildContext context, GroupOptionModel option) {
    switch (option.title) {
      case 'Permissions':
        Get.toNamed(
          RouteName.groupChatEditPermission,
          arguments: {
            'group': group.value,
            'permission': group.value!.permission,
          },
        );
        break;
      case 'Administrators':
        Toast.showToast(localized(homeToBeContinue));
        break;
      case 'Removed Users':
        Toast.showToast(localized(homeToBeContinue));
        break;
      case 'Chat History':
        Toast.showToast(localized(homeToBeContinue));
        break;
      default:
        break;
    }
  }

  onPermissionSelected(int index, bool isSendMsg) async {
    int permission = 0;
    if (isSendMsg) {
      sendMsgPermissionList[sendMsgPermissionList.keys.elementAt(index)] =
          !sendMsgPermissionList[sendMsgPermissionList.keys.elementAt(index)];

      // If send text are disable, send hyperlinks will disable too
      if (sendMsgPermissionList.keys.elementAt(index) ==
          GroupPermissionMap.groupPermissionSendTextVoice.displayNameKey) {
        if (!sendMsgPermissionList[
            sendMsgPermissionList.keys.elementAt(index)]) {
          sendMsgPermissionList[GroupPermissionMap
              .groupPermissionSendLink.displayNameKey] = false;
        }
      }
    } else {
      permissionList[permissionList.keys.elementAt(index)] =
          !permissionList[permissionList.keys.elementAt(index)];
    }

    for (final permissionMap in GroupPermissionMap.values) {
      if (permissionList[permissionMap.displayNameKey] != null) {
        if (permissionList[permissionMap.displayNameKey]) {
          permission += permissionMap.value;
        }
      } else if (permissionMap.displayNameKey ==
          GroupPermissionMap.groupPermissionScreenshot.displayNameKey) {
        if (isScreenshotEnabled) {
          permission += permissionMap.value;
        }
      } else {
        if (sendMsgPermissionList[permissionMap.displayNameKey] != null &&
            sendMsgPermissionList[permissionMap.displayNameKey]) {
          permission += permissionMap.value;
        }
      }
    }
    this.permission = permission;
    getPermissionEnabled(permission);
  }

  doChangeViewHistory() async {
    if (!submitting) {
      submitting = true;
      if (group.value != null) {
        try {
          Group? grp = await objectMgr.myGroupMgr.setHistoryVisible(
            group.value!.id,
            !viewHistoryEnabled.value ? 1 : 0,
          );
          if (grp != null) {
            group.value = grp;
            viewHistoryEnabled.value = group.value?.isVisible ?? false;
          }
        } on AppException catch (e) {
          Toast.showToast(e.getMessage());
        }
      }
      submitting = false;
    }
  }

  batchSendMessagePermission(bool isEnable) async {
    int permission = 0;
    sendMsgPermissionList.forEach((key, _) {
      sendMsgPermissionList[key] = isEnable;
    });
    for (final permissionMap in GroupPermissionMap.values) {
      if (permissionList[permissionMap.displayNameKey] != null) {
        if (permissionList[permissionMap.displayNameKey]) {
          permission += permissionMap.value;
        }
      } else if (permissionMap.displayNameKey ==
          GroupPermissionMap.groupPermissionScreenshot.displayNameKey) {
        if (isScreenshotEnabled) {
          permission += permissionMap.value;
        }
      } else {
        if (sendMsgPermissionList[permissionMap.displayNameKey] != null &&
            sendMsgPermissionList[permissionMap.displayNameKey]) {
          permission += permissionMap.value;
        }
      }
    }
    this.permission = permission;
    getPermissionEnabled(permission);
  }

  updatePermission() async {
    if (originalSpeakInterval != speakInterval.value) {
      try {
        await group_api.setSpeakInterval(
          groupId: chatID!,
          interval: speakInterval.value,
        );
        getTextFromSlowMode();
      } on AppException catch (e) {
        Toast.showToast(e.getMessage());
        rethrow;
      }
    }

    if (originalPermission != permission) {
      try {
        await group_api.updateGroupPermission(
          groupId: chatID!,
          permission: permission,
        );
        getPermissionEnabled(permission);
      } on AppException catch (e) {
        Toast.showToast(e.getMessage());
        rethrow;
      }
    }
    if (objectMgr.loginMgr.isDesktop) {
      Get.back(id: 1);
      Get.back(id: 1);
    } else {
      Get.close(2);
    }
  }

  void setShowClearBtn(bool showBtn, {required type}) {
    type == 'name' ? showClearBtn(showBtn) : showDecClearBtn(showBtn);
  }

  /// ================================== 图片处理 ===============================

  processImage(AssetEntity asset) async {
    if (group.value == null) return;

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
  }

  Future<String?> uploadPhoto(File imageFile, String uploadKey) async {
    final String? imageUrl = await imageMgr.upload(
      imageFile.path,
      0,
      0,
      cancelToken: CancelToken(),
    );

    return imageUrl;
  }

  updateGroupInfo() async {
    String name = groupNameTextController.text.trim();
    String profile = groupDescTextController.text.trim();
    String icon = groupPhoto.value;
    if (name == group.value?.name.trim() &&
        profile == group.value?.profile.trim() &&
        icon == group.value?.icon &&
        avatarFile.value == null) {
      //都沒改就不打api
      return;
    }
    isLoading(true);
    FocusManager.instance.primaryFocus?.unfocus();

    String uploadKey = group.value!.generateGroupImageUrl();
    if (avatarFile.value != null) {
      String? imgUrl = await uploadPhoto(avatarFile.value!, uploadKey);
      if (notBlank(imgUrl)) {
        icon = removeEndPoint(imgUrl!);
      }
    }
    try {
      await group_api.edit(
        groupID: chatID!,
        icon: icon,
        name: name,
        profile: profile,
        newGroup: 0,
      );
      // Toast.showToast(localized(successfullyUpdateGroupInfo));
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(successfullyUpdateGroupInfo),
        icon: ImBottomNotifType.success,
      );

      await objectMgr.myGroupMgr.getGroupByRemote(chatID!, notify: true);
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

  onChanged(String value) {
    charLeft(140 - value.trim().length);
    if (groupNameTextController.text.isEmpty) {
      setShowClearBtn(false, type: 'describe');
    } else {
      setShowClearBtn(true, type: 'describe');
    }
  }

  switchExpansion(bool value) => isExpanded.value = value;

  getTextFromSlowMode() {
    final entry = slowMode.entries.firstWhere(
      (entry) => entry.value == speakInterval.value,
      orElse: () => const MapEntry('', -1),
    );

    if (entry.value == speakInterval.value) {
      slowModeText.value = entry.key;
    } else {
      slowModeText.value =
          ''; // Return empty string if a matching entry is not found.
    }
  }

  @override
  void onClose() {
    groupNameTextController.dispose();
    groupDescTextController.dispose();
  }

  Future<void> showPickPhotoOption(BuildContext context) async {
    FocusScope.of(context).unfocus();
    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      items: [
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
          onClick: () {
            getGalleryPhoto(context);
          },
        ),
        Visibility(
          visible: !isClear.value,
          child: CustomBottomAlertItem(
            text: localized(groupEditDeletePhoto),
            textColor: colorRed,
            onClick: () {
              clearPhoto();
            },
          ),
        ),
      ],
    );
  }

  getCameraPhoto(BuildContext context) {
    checkPermission().then((isGranted) async {
      if (isGranted) {
        AssetEntity? entity;
        if (await isUseImCamera) {
          entity = await CamerawesomePage.openImCamera(isMirrorFrontCamera: isMirrorFrontCamera);
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

      checkPermission().then(
        (isGranted) async {
          if (isGranted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
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
  }

  void setShowSubList(bool value) {
    if (getShowNotificationVariable()) {
      switch (showSubListSection.value) {
        case ShowSubListSection.on:
          showMsgSubList.value = value;
          break;
        case ShowSubListSection.off:
          break;
      }
    } else {
      Toast.showToast(
        localized(notifManageMP),
      );
    }

    if (showSubListSection.value != ShowSubListSection.off) {
      showMsgSubList.value = value ? true : false;
    }
  }

  clearPhoto() {
    if (avatarFile.value == null && groupPhoto.value != '') {
      groupPhoto.value = '';
      isClear(true);
    } else if (avatarFile.value != null && groupPhoto.value != '') {
      avatarFile.value = null;
      isClear(false);
    } else {
      avatarFile.value = null;
      isClear(true);
    }
  }

  permissionPageBackTrigger(BuildContext context) {
    if (permission != originalPermission ||
        speakInterval.value != originalSpeakInterval) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return CustomConfirmationPopup(
            title: localized(saveChangesTitle),
            subTitle: localized(saveChangesDesc),
            confirmButtonText: localized(saveButton),
            cancelButtonText: localized(discardButton),
            confirmCallback: () => updatePermission(),
            cancelCallback: () {
              Get.back();
              Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null);
            },
          );
        },
      );
    } else {
      Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null);
    }
  }

  void showCustomizeExpiryPopUp(ctx) {
    DateTime customizedDate = DateTime.now().add(const Duration(days: 1));
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: ctx,
      builder: (BuildContext context) {
        return IntrinsicHeight(
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: colorTextPrimary.withOpacity(0.2),
                width: 0.5,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                topLeft: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height: 60,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 15,
                    ),
                    child: SizedBox(
                      height: 26,
                      child: NavigationToolbar(
                        leading: SizedBox(
                          width: 74,
                          child: OpacityEffect(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                localized(buttonCancel),
                                style:
                                    jxTextStyle.textStyle17(color: themeColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 150,
                          child: Transform.scale(
                            scale: 1.25,
                            child: CupertinoTheme(
                              data: const CupertinoThemeData(
                                textTheme: CupertinoTextThemeData(
                                  dateTimePickerTextStyle: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                    fontFamily: 'pingfang',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              child: CustomCupertinoDatePicker(
                                minimumDate:
                                    DateTime.now().add(const Duration(days: 1)),
                                initialDateTime:
                                    DateTime.now().add(const Duration(days: 1)),
                                mode: CustomCupertinoDatePickerMode.date,
                                dateOrder: DatePickerDateOrder.ymd,
                                onDateTimeChanged: (DateTime date) {
                                  customizedDate = date;
                                },
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Column(
                            children: [
                              Container(
                                height: 3,
                                width: double.infinity,
                                color: colorWhite,
                              ),
                              const Spacer(),
                              Container(
                                height: 3,
                                width: double.infinity,
                                color: colorWhite,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: PrimaryButton(
                      bgColor: themeColor,
                      width: double.infinity,
                      title: localized(buttonConfirm),
                      onPressed: () {
                        int timestamp =
                            setCustomizeExpiryDuration(customizedDate);
                        updateExpiryTime(timestamp, needProcess: false);
                        Get.back();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void updateExpiryTime(int addTimeStamp, {bool needProcess = true}) async {
    try {
      int timestamp = addTimeStamp;
      if (needProcess) {
        timestamp = calculateEndOfDayTimestamp(addTimeStamp);
      }
      int newDate =
          await objectMgr.myGroupMgr.setExpireTime(group.value!.id, timestamp);
      if (newDate > 0) {
        getExpiryTime(newDate);
        imBottomToast(
          Get.context!,
          title: localized(expiryDateHasBeenUpdated),
          icon: ImBottomNotifType.success,
        );
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
  }

  getExpiryTime(int timestamp) {
    expiryTime.value = formatToLocalTime(timestamp);
  }
}

enum ShowSubListSection {
  on(value: 0),
  off(value: 1);

  final int value;

  const ShowSubListSection({required this.value});
}
