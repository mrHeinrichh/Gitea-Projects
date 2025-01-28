import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:azlistview/azlistview.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/api/group.dart' as group_api;
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/task/image/image_mgr.dart';
import 'package:jxim_client/object/azItem.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/setting/profile_photo_picker.dart';
import 'package:jxim_client/utils/debounce.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

import 'package:jxim_client/camera/camerawesome_page.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';

class CreateGroupBottomSheetController extends GetxController {
  /// VARIABLES
  /// Contact搜索 输入控制器
  final TextEditingController searchController = TextEditingController();

  /// 群名字 输入控制器
  final TextEditingController groupNameTextController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  /// 选择成员滚动控制器
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

  /// ==================== 搜索功能 ===================///
  void onSearchChanged(String value) {
    searchParam.value = value;
    _debouncer.call(() => searchLocal());
  }

  void searchLocal() {
    userList.value = users
        .where((User user) => objectMgr.userMgr
            .getUserTitle(user)
            .toLowerCase()
            .contains(searchParam.value.toLowerCase()))
        .toList();
    updateAZFriendList();
  }

  void clearSearching() {
    searchController.clear();
    isSearching.value = false;
    searchParam.value = '';
    searchLocal();
  }

  /// ==================== 朋友列表 ===================///
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
          (User selectedUser) => selectedUser.accountId == user.accountId);
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

  /// ==================== 创建群组 ===================///
  void onCreate(BuildContext context) async {
    if (groupNameIsEmpty.value) return;

    try {
      Toast.show();
      final Group group = await group_api.create(
        name: groupNameTextController.text.trimRight(),
        icon: '',
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
              newGroup: 1);
          await objectMgr.myGroupMgr.getGroupByRemote(group.uid, notify: true);
        }
        groupPhoto.value = null;
      }

      /// 添加成员
      final res = await group_api.addGroupMember(
        groupId: group.uid,
        userIds: selectedMembers.map((e) => e.uid).toList(),
      );

      if (res == "OK") {
        await objectMgr.myGroupMgr.getGroupByRemote(group.uid);
        Chat? chat = await objectMgr.chatMgr
            .getGroupChatById(group.id, remote: true, notify: true);
        Toast.hide();
        if (objectMgr.loginMgr.isDesktop) {
          Get.offAllNamed(RouteName.desktopChatEmptyView, id: 1);
          Routes.toChatDesktop(chat: chat!);
        } else {
          Toast.showCreateGroupToast();
          closePopup();
          Routes.toChat(chat: chat!);
        }
      }
    } on AppException catch (e) {
      Toast.hide();
      Toast.showToast(e.getMessage());
    }
  }

  void onGroupNameChanged(String value) {
    if (groupNameTextController.text.trim().length > 0) {
      groupNameIsEmpty.value = false;
    } else {
      groupNameIsEmpty.value = true;
    }
  }

  /// ==================== 上传图片 ===================///
  void showPickPhotoOption(BuildContext context) {
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

    groupPhoto.value = compressedFile;
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

  clearPhoto() {
    groupPhoto.value = null;
  }

  /// ==================== 通用 ===================///
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
            groupName += '${memberName}';
          } else if (index == selectedMembers.length - 2) {
            groupName += '${memberName}${localized(shareAnd)}';
          } else {
            groupName += '${memberName}, ';
          }
        });
        groupName =
            '${(objectMgr.userMgr.mainUser.alias != '') ? objectMgr.userMgr.mainUser.alias : objectMgr.userMgr.mainUser.nickname}${(selectedMembers.length == 1) ? localized(shareAnd) : ','} $groupName';

        /// 如果群组名字太长，显示空白
        groupName = groupName.length > 30 ? '' : groupName;
      }
      groupNameTextController.text = groupName;
      onGroupNameChanged(groupNameTextController.text);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
          if (groupNameTextController.text.length > 0) {
            groupNameTextController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: groupNameTextController.text.length);
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
}
