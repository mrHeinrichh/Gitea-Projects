import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/tags_mgr.dart';
import 'package:jxim_client/moment/moment_create/moment_publish_dialog.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/tags/tags_create.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/component.dart';

class TagsManagementController extends GetxController with GetSingleTickerProviderStateMixin {
  // 標籤列表
  final RxList<Tags> tagsList = <Tags>[].obs;

  final RxMap<int,List<User>> allTagByGroup = <int,List<User>>{}.obs;

  final RxMap<int,List<User>> cacheAllTagByGroup = <int,List<User>>{}.obs;

  late final AnimationController editAnimController;

  final RxBool isEditing = false.obs;

  final RxInt dragIndex = (-1).obs;

  final Rx<bool> isSending = false.obs;
  final Rx<bool> isDone = false.obs;
  final Rx<bool> isFailed = false.obs;
  bool isShowLoading = false;

  @override
  void onInit() async
  {
    super.onInit();
    editAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    objectMgr.tagsMgr.syncTags();

    refreshTags();

    objectMgr.tagsMgr.on(TagsMgr.TAGS_CREATE, _onTagsCreate);
    objectMgr.tagsMgr.on(TagsMgr.TAGS_UPDATE, _onTagsChanged);
    objectMgr.tagsMgr.on(TagsMgr.TAGS_DELETE, _onTagsDelete);
    objectMgr.tagsMgr.on(TagsMgr.TAGS_NOTIFY_UPDATE, _onTagsNotify);
  }

  @override
  void onClose() {
    objectMgr.tagsMgr.allTagByGroup = allTagByGroup;
    editAnimController.dispose();
    objectMgr.tagsMgr.off(TagsMgr.TAGS_CREATE, _onTagsCreate);
    objectMgr.tagsMgr.off(TagsMgr.TAGS_UPDATE, _onTagsChanged);
    objectMgr.tagsMgr.off(TagsMgr.TAGS_DELETE, _onTagsDelete);
    objectMgr.tagsMgr.off(TagsMgr.TAGS_NOTIFY_UPDATE, _onTagsNotify);
    super.onClose();
  }

  void refreshTags() async {
    tagsList.clear();
    tagsList.add(getHeader());

    if(objectMgr.tagsMgr.allTags.isEmpty) {
        tagsList.removeWhere((tag) => tag.uid != -1);
    }else{
      tagsList.addAll(objectMgr.tagsMgr.allTags);
    }

    allTagByGroup.value = await objectMgr.tagsMgr.getAllTagByGroup();
  }

  Tags getHeader() {
    return Tags()..uid = -1..tagName = "header";
  }

  Tags getTagByUid(int uid) {
    return tagsList.firstWhere((element) => element.uid == uid, orElse: () => Tags());
  }

  void _onTagsNotify(_, __, data) {
    refreshTags();
  }

  ///data => Tags
  void _onTagsCreate(_, __, data) async
  {
    refreshTags();
    update();
  }

  ///data => Tags
  void _onTagsChanged(_, __, data) async {
    refreshTags();
    update();
  }

  ///data => tags.uuid
  void _onTagsDelete(_, __, data) async
  {
    refreshTags();
    update();
  }

  void onShowLoadingDialog(BuildContext context,{String? loadingKey,String? successKey,String? failedKey}) {
    isSending.value = true;
    isFailed.value = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Obx(
              () => MomentPublishDialog(
            isSending: isSending.value,
            isDone: isDone.value,
            isFailed: isFailed.value,
            sendingLocalizationKey: loadingKey??groupAgoraCallStatusProgress,
            doneLocalizationKey: successKey??momentBtnStatusDone,
            failedLocalizationKey: failedKey??loadFailed,
          ),
        );
      },
    );
    isShowLoading = true;
  }

  void onCloseLoadingDialog(BuildContext context) {
    if (isShowLoading) {
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).pop();
        isShowLoading = false;
      });
    }
  }

  void toggleEdit() {
    isEditing.value = !isEditing.value;
  }

  void onTagsPress(BuildContext context, {Tags? tags}) {
    if (tags != null && isEditing.value) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      isDismissible: false,
      builder: (ctx) => TagsCreate(this,tags: tags),
    ).then((_){
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  }

  void onDeleteTags(BuildContext context, Tags tag) {
    showCustomBottomAlertDialog(
      context,
      subtitle: localized(tagDeleteTag),
      confirmText: localized(buttonDelete),
      confirmTextColor: colorRed,
      cancelTextColor: themeColor,
      onConfirmListener: () => _confirmDeleteTags(tag),
    );
  }

  void _confirmDeleteTags(Tags tag) async {
    bool isSuccess = true;
    bool isDeleted = true;


    onShowLoadingDialog(Get.context!,loadingKey: localized(tagDeleting),successKey: myEditLabelDone,failedKey: localized(tagDeleteFailed));

    try{
       isDeleted = await objectMgr.tagsMgr.deletedTagsToServer([tag]);
    }catch(e){
       isDeleted = false;
    }

    if(isDeleted){
      List<User> users = allTagByGroup[tag.uid]??[];
      if(users.isNotEmpty){
        for(User user in users) {
          for (int i = user.friendTags!.length - 1; i >= 0; i--) {
            if(user.friendTags![i] == tag.uid) {
              user.friendTags!.removeAt(i);
            }
          }
        }
      }

      isSuccess = await objectMgr.tagsMgr.updateContacts(users);

      if(isSuccess){
        await objectMgr.tagsMgr.deleteTags(tag.uid);
        await objectMgr.tagsMgr.syncTags();
        isDone.value = false;
        isSending.value = false;
        isFailed.value = false;
        Future.delayed(const Duration(milliseconds: 600), () {
          onCloseLoadingDialog(Get.context!);
          if (tagsList.length==1 && isEditing.value) {
            isEditing.value = !isEditing.value;
          }
        });
      }
    }
    else{
      isSuccess = false;
    }

   if(!isSuccess){
     isDone.value = false;
     isSending.value = false;
     isFailed.value = true;
     Future.delayed(const Duration(milliseconds: 600), () {
       onCloseLoadingDialog(Get.context!);
       imBottomToast(
         Get.context!,
         title: localized(noNetworkPleaseTryAgainLater),
         icon: ImBottomNotifType.warning,
       );
     });
   }
  }
}
