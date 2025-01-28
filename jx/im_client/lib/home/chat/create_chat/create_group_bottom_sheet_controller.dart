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
import 'package:jxim_client/api/group.dart' as group_api;
import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/im/chat_info/more_vert/custom_cupertino_date_picker.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/object/upload_ext.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/profile_photo_picker.dart';
import 'package:jxim_client/setting/user_bio/user_bio_controller.dart';
import 'package:jxim_client/utils/album/common_album_controller.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CreateGroupBottomSheetController extends GetxController {
  CreateGroupBottomSheetController();

  late CommonAlbumController commonAlbumController;

  final Rx<GroupType> groupType = GroupType.NOR.obs;
  final RxBool encryptionSetting = false.obs;

  final TextEditingController searchController = TextEditingController();

  final TextEditingController groupNameTextController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  final ScrollController selectedMembersController = ScrollController();
  final ScrollController scrollController = ScrollController();

  late List<User> users, usersIncludeBlocked;
  RxList<User> userList = <User>[].obs;
  RxList<User> userListIncludeBlocked = <User>[].obs;
  RxList<AZItem> azFilterList = <AZItem>[].obs;
  RxList<AZItem> azFilterIncludeBlockedList = <AZItem>[].obs;
  RxList<User> selectedMembers = <User>[].obs;
  final highlightMember = 0.obs;
  RxInt currentPage = 1.obs;

  final _debouncer = Debounce(const Duration(milliseconds: 400));
  RxBool isSearching = false.obs;
  RxString searchParam = "".obs;
  final showSearchOverlay = false.obs;

  RxBool groupNameIsEmpty = true.obs;
  final groupPhoto = Rxn<File>();
  AssetPickerConfig? pickerConfig;
  DefaultAssetPickerProvider? provider;
  late final AssetEntity profilePic;

  RxString expiryTimeText = "".obs;
  RxInt expiryTimeDuration = 0.obs;

  RxBool showEncryptionButton = false.obs;

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
    showEncryptionButton.value = Config().e2eEncryptionEnabled;

    commonAlbumController = Get.findOrPut<CommonAlbumController>(
        CommonAlbumController(),
        tag: commonAlbumTag);

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

  void toggleEncryption(BuildContext context) async {
    vibrate();
    if (encryptionSetting.value) {
      encryptionSetting.toggle();
      return;
    }

    var setupType = await objectMgr.encryptionMgr.isChatEncryptionNewSetup();

    if (setupType == EncryptionSetupPasswordType.abnormal) {
      imBottomToast(
        Get.context!,
        title: localized(noNetworkPleaseTryAgainLater),
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    if (setupType != EncryptionSetupPasswordType.doneSetup) {
      showCustomBottomAlertDialog(
        context,
        subtitle: localized(setupType == EncryptionSetupPasswordType.neverSetup
            ? chatToggleEncMessage
            : chatToggleRequirePrivateKeyMessage),
        items: [
          CustomBottomAlertItem(
            text: localized(setupType == EncryptionSetupPasswordType.neverSetup
                ? chatToggleSetNow
                : chatRecoverNow),
            onClick: () async {
              switch (setupType) {
                case EncryptionSetupPasswordType.neverSetup:
                  Get.toNamed(RouteName.encryptionBackupKeyPage);
                  break;
                case EncryptionSetupPasswordType.anotherDeviceSetup:
                  Get.toNamed(
                    RouteName.encryptionVerificationPage,
                    preventDuplicates: false,
                  );
                  break;
                default:
                  break;
              }
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
    vibrate();
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

    userListIncludeBlocked.value = usersIncludeBlocked
        .where(
          (User user) => objectMgr.userMgr
              .getUserTitle(user)
              .toLowerCase()
              .contains(searchParam.value.toLowerCase()),
        )
        .toList();

    updateAZFriendList();
    if (isSearching.value && searchParam.value == '') {
      showSearchOverlay.value = true;
    } else {
      showSearchOverlay.value = false;
    }
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

    usersIncludeBlocked = objectMgr.userMgr.filterFriendsIncludeBlocked;
    userListIncludeBlocked.value = usersIncludeBlocked;
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

    azFilterIncludeBlockedList.value = userListIncludeBlocked
        .map(
          (e) => AZItem(
            user: e,
            tag: convertToPinyin(objectMgr.userMgr.getUserTitle(e)[0])[0]
                .toUpperCase(),
          ),
        )
        .toList();

    SuspensionUtil.setShowSuspensionStatus(azFilterList);
    SuspensionUtil.setShowSuspensionStatus(azFilterIncludeBlockedList);
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
      if (Config().e2eEncryptionEnabled && encryptionSetting.value) {
        bool canUpdate = await objectMgr.encryptionMgr.isKeyValid(
            objectMgr.encryptionMgr.encryptionPublicKey,
            privateKey: objectMgr.encryptionMgr.encryptionPrivateKey);
        if (!canUpdate) {
          //不能创建加密会话
          Toast.hide();
          encryptionSetting.toggle();
          imBottomToast(
            Get.context!,
            title: localized(keyExpiredForRecovery),
            icon: ImBottomNotifType.warning,
          );
          return;
        }
      }

      //群组创建
      final Group group = await group_api.create(
        name: groupNameTextController.text.trimRight(),
        icon: '',
        type: groupType.value.num,
        expireTime: expiryTimeDuration.value,
      );

      if (groupPhoto.value != null) {
        final String groupImageUrl = group.generateGroupImageUrl();
        final (String? imgUrl, String? gPath) =
            await uploadPhoto(groupPhoto.value!, groupImageUrl);
        if (imgUrl != null) {
          group.icon = removeEndPoint(imgUrl);
          group.iconGaussian = gPath ?? '';

          await group_api.edit(
            groupID: group.uid,
            icon: group.icon,
            iconGausPath: gPath ?? '',
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
      int? chatRound;
      bool chatEncryptionSuccess = false;
      if (Config().e2eEncryptionEnabled && encryptionSetting.value) {
        List<int> userIds = [objectMgr.userMgr.mainUser.uid];
        userIds.addAll(selectedM);
        (chatKey, chatRound) = await objectMgr.encryptionMgr
            .startChatEncryption(userIds, chatId: group.id ?? 0);
        chatEncryptionSuccess =
            await objectMgr.chatMgr.sendChatEncryptionSetting(group.id, 1);
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

        if (Config().e2eEncryptionEnabled &&
            chat != null &&
            chatKey != null &&
            chatRound != null &&
            chatEncryptionSuccess) {
          int activeRound = chatRound;
          String activeKey = chatKey;
          if (activeRound < chat.round) {
            chat.updateChatKey(chatKey, chatRound);
            activeRound = chat.round;
            activeKey =
                objectMgr.encryptionMgr.getCalculatedKey(chat, activeRound);
          }
          //成功创建, 更新数据库
          objectMgr.chatMgr.updateDatabaseEncryptionSetting(
            chat,
            ChatEncryptionFlag.encrypted.value,
            chatKey: chatKey,
            chatRound: chatRound,
            activeChatKey: activeKey,
            activeRound: activeRound,
          );
          objectMgr.messageManager.decryptChat([chat]);
        }

        Toast.hide();
        Get.back();
        if (objectMgr.loginMgr.isDesktop) {
          Get.offAllNamed(RouteName.desktopChatEmptyView, id: 1);
        }
        Toast.showCreateGroupToast(groupType.value.num);
        closePopup();
        Routes.toChat(chat: chat!);
      }
    } on AppException catch (e) {
      Toast.hide();
      imBottomToast(
        navigatorKey.currentContext!,
        title: e.getMessage(),
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
      barrierColor: colorOverlay40,
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

  getCameraPhoto(BuildContext context) async {
    var isGranted = await checkCameraOrPhotoPermission(type: 1);
    if (!isGranted) return;
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

  List<String> filterIncludeBlockedIndexBar() {
    if (isSearching.value || searchParam.isNotEmpty) {
      return [];
    }
    List<String> indexList = [];

    for (AZItem item in azFilterIncludeBlockedList) {
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
    showCustomBottomAlertDialog(
      ctx,
      withHeader: false,
      items: Group().expiredTimeOption.map(
        (e) {
          return CustomBottomAlertItem(
            text: e.title ?? '',
            onClick: () {
              if (e.value == -1) {
                showCustomizeExpiryPopUp();
              } else {
                expiryTimeText.value = e.title ?? '';
                expiryTimeDuration.value = calculateEndOfDayTimestamp(e.value);
              }
            },
          );
        },
      ).toList(),
    );
  }

  void showCustomizeExpiryPopUp() {
    DateTime customizedDate = DateTime.now().add(const Duration(days: 1));
    showModalBottomSheet(
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      context: Get.context!,
      builder: (BuildContext context) {
        return IntrinsicHeight(
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: colorBackground,
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
                              data: CupertinoThemeData(
                                textTheme: CupertinoTextThemeData(
                                  dateTimePickerTextStyle:
                                      jxTextStyle.headerSmallText(),
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
                                color: colorBackground,
                              ),
                              const Spacer(),
                              Container(
                                height: 3,
                                width: double.infinity,
                                color: colorBackground,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: CustomButton(
                      text: localized(buttonConfirm),
                      callBack: () {
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
