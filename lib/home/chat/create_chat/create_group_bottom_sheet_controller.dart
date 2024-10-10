import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:azlistview/azlistview.dart';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/im/chat_info/more_vert/custom_cupertino_date_picker.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/api/group.dart' as group_api;
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/profile_photo_picker.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/primary_button.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_item.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/main.dart';

class CreateGroupBottomSheetController extends GetxController {
  CreateGroupBottomSheetController();

  final Rx<GroupType> groupType = GroupType.NOR.obs;
  final RxBool encryptionSetting = false.obs;

  final TextEditingController searchController = TextEditingController();

  final TextEditingController groupNameTextController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  final ScrollController selectedMembersController = ScrollController();
  final ScrollController scrollController = ScrollController();

  late List<User> users;
  RxList<User> userList = <User>[].obs;
  RxList<AZItem> azFilterList = <AZItem>[].obs;
  RxList<User> selectedMembers = <User>[].obs;
  final highlightMember = 0.obs;
  RxInt currentPage = 1.obs;

  final _debouncer = Debounce(const Duration(milliseconds: 400));
  RxBool isSearching = false.obs;
  RxString searchParam = "".obs;

  RxBool groupNameIsEmpty = true.obs;
  final groupPhoto = Rxn<File>();
  AssetPickerConfig? pickerConfig;
  DefaultAssetPickerProvider? provider;
  late final AssetEntity profilePic;

  RxString expiryTimeText = "".obs;
  RxInt expiryTimeDuration = 0.obs;

  final List<SelectionOptionModel> photoOption = [
    SelectionOptionModel(
      title: localized(takeAPhoto),
    ),
    SelectionOptionModel(
      title: localized(chooseFromGalley),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    getFriendList();
    updateAZFriendList();

    // if (groupType == GroupType.TMP) {
    //
    // }
    expiryTimeText.value = Group()
            .expiredTimeOption
            .firstWhere(
              (element) =>
                  element.value == const Duration(days: 90).inMilliseconds,
            )
            .title ??
        "";
    int duration = Group()
            .expiredTimeOption
            .firstWhere(
              (element) =>
                  element.value == const Duration(days: 90).inMilliseconds,
            )
            .value ??
        0;
    expiryTimeDuration.value = calculateEndOfDayTimestamp(duration);

    scrollController.addListener(() {
      if (FocusManager.instance.primaryFocus!.hasFocus) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  @override
  void dispose() {
    groupNameTextController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void toggleEncryption() async {
    if (encryptionSetting.value) {
      encryptionSetting.toggle();
      return;
    }

    var setupType = await objectMgr.encryptionMgr.isChatEncryptionNewSetup();

    if (setupType != EncryptionSetupPasswordType.doneSetup) {
      if (setupType == EncryptionSetupPasswordType.neverSetup) {
        encryptionSetting.toggle();
        if (objectMgr.localStorageMgr.read(LocalStorageMgr.MUTE_PRIVATE_KEY_UPDATE) == true) {
          return;
        }
      }

      showCustomBottomAlertDialog(
        Get.context!,
        subtitle: localized(setupType == EncryptionSetupPasswordType.neverSetup
            ? chatToggleEncMessage
            : chatToggleRequirePrivateKeyMessage),
        items: [
          CustomBottomAlertItem(
            text: localized(setupType == EncryptionSetupPasswordType.neverSetup
                ? chatToggleSetNow
                : chatVerifyNow),
            onClick: () async {
              // confirmed = true;
              switch (setupType) {
                case EncryptionSetupPasswordType.neverSetup:
                  Get.toNamed(RouteName.encryptionPreSetupPage, arguments: {});
                  break;
                case EncryptionSetupPasswordType.anotherDeviceSetup:
                  Get.toNamed(RouteName.encryptionVerificationPage, arguments: {
                    "encPrivateKey":
                        objectMgr.encryptionMgr.hasEncryptedPrivateKey,
                    "successCallback": () async {
                      encryptionSetting.toggle();
                    },
                  });
                  break;
                default:
                  break;
              }
            },
          ),
          if (setupType == EncryptionSetupPasswordType.neverSetup)
            CustomBottomAlertItem(
              text: localized(chatDontRemindAgain),
              textColor: colorRed,
              onClick: () {
                objectMgr.localStorageMgr
                    .write(LocalStorageMgr.MUTE_PRIVATE_KEY_UPDATE, true);
              },
            ),
        ],
        cancelText: localized(cancel),
        thenListener: () async {},
        onCancelListener: () async {},
        onConfirmListener: () async {},
      );

      return;
    }
    encryptionSetting.toggle();
  }

  void toggleTMP() {
    groupType.value =
        groupType.value == GroupType.TMP ? GroupType.NOR : GroupType.TMP;
  }

  void onSearchChanged(String value) {
    searchParam.value = value;
    _debouncer.call(() => searchLocal());
  }

  void searchLocal() {
    userList.value = users
        .where(
          (User user) => objectMgr.userMgr
              .getUserTitle(user)
              .toLowerCase()
              .contains(searchParam.value.toLowerCase()),
        )
        .toList();
    updateAZFriendList();
  }

  void clearSearching() {
    searchController.clear();
    isSearching.value = false;
    searchParam.value = '';
    searchLocal();
  }

  void getFriendList() {
    users = objectMgr.userMgr.filterFriends;
    userList.value = users;
  }

  void updateAZFriendList() {
    azFilterList.value = userList
        .map(
          (e) => AZItem(
            user: e,
            tag: convertToPinyin(objectMgr.userMgr.getUserTitle(e)[0])[0]
                .toUpperCase(),
          ),
        )
        .toList();

    SuspensionUtil.setShowSuspensionStatus(azFilterList);
  }

  void onSelect(BuildContext context, bool? selected, User user) {
    final indexList = selectedMembers
        .indexWhere((element) => element.accountId == user.accountId);
    if (indexList > -1) {
      selectedMembers.removeWhere(
        (User selectedUser) => selectedUser.accountId == user.accountId,
      );
      highlightMember.value = 0;
    } else {
      if (selectedMembers.length >= 199) {
        Toast.showToast(localized(groupMembersAreLimitedTo200));
        return;
      }

      selectedMembers.add(user);
    }

    searchController.clear();
    searchParam.value = '';
    searchLocal();
    FocusManager.instance.primaryFocus?.unfocus();

    if (selectedMembers.length > 1 && selectedMembersController.hasClients) {
      selectedMembersController.animateTo(
        selectedMembersController.position.maxScrollExtent + 70,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void onCreate(BuildContext context) async {
    if (groupNameIsEmpty.value) return;

    try {
      Toast.show();
      //群组创建
      final Group group = await group_api.create(
        name: groupNameTextController.text.trimRight(),
        icon: '',
        type: groupType.value.num,
        expireTime: expiryTimeDuration.value,
      );

      if (groupPhoto.value != null) {
        final String groupImageUrl = group.generateGroupImageUrl();
        String? imgUrl = await uploadPhoto(groupPhoto.value!, groupImageUrl);
        if (imgUrl != null) {
          group.icon = removeEndPoint(imgUrl);

          await group_api.edit(
            groupID: group.uid,
            icon: group.icon,
            name: groupNameTextController.text,
            newGroup: 1,
          );
          await objectMgr.myGroupMgr.getGroupByRemote(group.uid, notify: true);
        }
        groupPhoto.value = null;
      }

      //group id 就是chat id，设定聊天室密文
      List<int> selectedM = selectedMembers.map((e) => e.uid).toList();
      String? chatKey;
      if (encryptionSetting.value) {
        List<int> userIds = [objectMgr.userMgr.mainUser.uid];
        userIds.addAll(selectedM);
        chatKey = await objectMgr.encryptionMgr
            .createChatEncryption(userIds, group.id ?? 0);
        await objectMgr.chatMgr.remoteSetEncrypted(group.id, 1);
      }

      //加人
      final res = await group_api.addGroupMember(
        groupId: group.uid,
        userIds: selectedM,
      );

      if (res == "OK") {
        await objectMgr.myGroupMgr.getGroupByRemote(group.uid);
        Chat? chat = await objectMgr.chatMgr
            .getGroupChatById(group.id, remote: true, notify: true);

        if (chatKey != null) {
          //成功创建, 更新数据库
          objectMgr.chatMgr.updateEncryptionSettings(
              chat!, ChatEncryptionFlag.encrypted.value,
              chatKey: chatKey, sendApi: false, sender: objectMgr.encryptionMgr);
        }

        Toast.hide();
        Get.back();
        if (objectMgr.loginMgr.isDesktop) {
          Get.offAllNamed(RouteName.desktopChatEmptyView, id: 1);
          Routes.toChat(chat: chat!);
        } else {
          Toast.showCreateGroupToast(groupType.value.num);
          closePopup();
          Routes.toChat(chat: chat!);
        }
      }
    } on AppException catch (e) {
      Toast.hide();
      imBottomToast(
        navigatorKey.currentContext!,
        title: e.getMessage(),
        isStickBottom: false,
      );
    }
  }

  void onGroupNameChanged(String value) {
    if (groupNameTextController.text.trim().isNotEmpty) {
      groupNameIsEmpty.value = false;
    } else {
      groupNameIsEmpty.value = true;
    }
  }

  void showPickPhotoOption(BuildContext context) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: Get.context!,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectionBottomSheet(
          context: context,
          selectionOptionModelList: photoOption,
          callback: (int index) async {
            if (index == 0) {
              if (objectMgr.callMgr.getCurrentState() != CallState.Idle) {
                Toast.showToast(localized(toastEndCallFirst));
                return;
              }
              getCameraPhoto(context);
            } else if (index == 1) {
              await getGalleryPhoto(context);
            }
          },
        );
      },
    );
  }

  getCameraPhoto(BuildContext context) {
    checkPermission().then((isGranted) async {
      if (isGranted) {
        AssetEntity? entity;
        if (await isUseImCamera) {
          entity = await CamerawesomePage.openImCamera(
            isMirrorFrontCamera: isMirrorFrontCamera,
          );
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
      checkPermission().then((isGranted) {
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
        groupPhoto.value = compressedFile;
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

    groupPhoto.value = compressedFile;
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

  clearPhoto() {
    groupPhoto.value = null;
  }

  void closePopup() {
    clearSearching();
    getBack();
    selectedMembers.value = [];
    currentPage.value = 1;
    Get.back();
  }

  void getBack() {
    groupNameIsEmpty(true);
    groupNameTextController.text = '';
    groupPhoto.value = null;
  }

  void switchPage(int page) {
    currentPage.value = page;
    if (page == 1) {
      getBack();
    } else if (page == 2) {
      String groupName = "";
      if (selectedMembers.length <= 4) {
        selectedMembers.asMap().forEach((index, user) {
          String memberName = (user.alias != "") ? user.alias : user.nickname;
          if (index == selectedMembers.length - 1) {
            groupName += memberName;
          } else if (index == selectedMembers.length - 2) {
            groupName += '$memberName${localized(shareAnd)}';
          } else {
            groupName += '$memberName, ';
          }
        });
        groupName =
            '${(objectMgr.userMgr.mainUser.alias != '') ? objectMgr.userMgr.mainUser.alias : objectMgr.userMgr.mainUser.nickname}${(selectedMembers.length == 1) ? localized(shareAnd) : ','} $groupName';

        groupName = groupName.length > 30 ? '' : groupName;
      }
      groupNameTextController.text = groupName;
      onGroupNameChanged(groupNameTextController.text);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
          if (groupNameTextController.text.isNotEmpty) {
            groupNameTextController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: groupNameTextController.text.length,
            );
          }
        }
      });

      selectedMembers.sort(
        (a, b) => multiLanguageSort(
          objectMgr.userMgr.getUserTitle(a),
          objectMgr.userMgr.getUserTitle(b),
        ),
      );
    }
  }

  List<String> filterIndexBar() {
    if (isSearching.value || searchParam.isNotEmpty) {
      return [];
    }
    List<String> indexList = [];

    for (AZItem item in azFilterList) {
      String tag = item.tag;
      bool startChar = tag.startsWith(RegExp(r'[a-zA-Z]'));
      if (startChar) {
        indexList.add(tag);
      }
    }
    List<String> resultList = LinkedHashSet<String>.from(indexList).toList();
    resultList.add('#');
    return resultList;
  }

  void showExpiredTimePopup(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectionBottomSheet(
          context: context,
          selectionOptionModelList: Group().expiredTimeOption,
          callback: (int index) async {
            SelectionOptionModel item = Group().expiredTimeOption[index];
            if (item.value == -1) {
              showCustomizeExpiryPopUp();
            } else {
              expiryTimeText.value = item.title ?? "";
              expiryTimeDuration.value = calculateEndOfDayTimestamp(item.value);
            }
          },
        );
      },
    );
  }

  void showCustomizeExpiryPopUp() {
    DateTime customizedDate = DateTime.now().add(const Duration(days: 1));
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: Get.context!,
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
                        expiryTimeText.value =
                            DateFormat('dd/MM/yy').format(customizedDate);
                        expiryTimeDuration.value =
                            setCustomizeExpiryDuration(customizedDate);
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
}
