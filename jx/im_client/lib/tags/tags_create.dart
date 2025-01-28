import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_view.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/tags_mgr.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/tags/tags_create_item.dart';
import 'package:jxim_client/tags/tags_friend_bottom_sheet.dart';
import 'package:jxim_client/tags/tags_management_controller.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:vibration/vibration.dart';

class TagsCreate extends StatefulWidget {
  final Tags? tags;

  final TagsManagementController controller;

  const TagsCreate(this.controller,{super.key, this.tags});

  @override
  State<TagsCreate> createState() => _TagsCreateState();
}

class _TagsCreateState extends State<TagsCreate> {
  late final TextEditingController nameController;

  final RxBool isNameEmpty = true.obs;

  late Tags? editedTags;

  RxBool isExist = false.obs;

  List<Tags> allTags = <Tags>[];

  final RxList<User> userList = <User>[].obs;

  final RxList<User> editList = <User>[].obs;

  late bool isEditMode;

  bool isEditedFromServer = false;
  bool isVibration = false;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.tags != null;
    editedTags = widget.tags;

    objectMgr.tagsMgr.on(TagsMgr.TAGS_NOTIFY_UPDATE, _onTagsNotify);

    nameController = TextEditingController(text: editedTags?.tagName ?? '');

    isNameEmpty.value = nameController.text.isEmpty;

    userList.add(getHeaderUser());

    _initGroupTagsList();

    nameController.addListener(_inputListener);
  }

  @override
  void dispose() {
    nameController.removeListener(_inputListener);
    objectMgr.tagsMgr.off(TagsMgr.TAGS_NOTIFY_UPDATE, _onTagsNotify);
    userList.clear();
    editList.clear();
    super.dispose();
  }

  void _onTagsNotify(_, __, notification) async {
    isEditedFromServer = true;
  }

  void _inputListener() {
    isNameEmpty.value = nameController.text.isEmpty;
    if(!isNameEmpty.value) {
      final newCharacters = nameController.text.characters;
      var length = 0;
      int max = 10;
      for (var character in newCharacters) {
        if (_isChineseCharacter(character)) {
          length += 2;
        } else {
          length += 1;
        }
      }

      if(length >= max && !isVibration) {
        Vibration.vibrate(duration: 100);
        isVibration = true;
      }else{
        if(length < max){
          isVibration = false;
        }
      }

      isExist.value = checkTheTagsExist();
      if (!nameController.value.isComposingRangeValid) {
        nameController.value = nameController.value.copyWith(composing: TextRange.empty);
      }
    }
  }

  bool checkTheTagsExist() {
     bool isExist = false;
    if(isEditMode){
      if(nameController.text.trim() != widget.tags!.tagName && nameController.text.trim().isNotEmpty) {
        isExist = allTags.any((tag) => tag.tagName == nameController.text.trim());
      }
    }else{
       isExist = allTags.any((tag) => tag.tagName == nameController.text.trim());
    }
    return isExist;
  }

  void _initGroupTagsList() async {

    allTags.assignAll(objectMgr.tagsMgr.allTags);

    if(widget.tags==null){
      return;
    }

    if(objectMgr.tagsMgr.allTagByGroup.isNotEmpty) {
      userList.addAll(objectMgr.tagsMgr.allTagByGroup[widget.tags!.uid]!.cast<User>());
      editList.addAll(objectMgr.tagsMgr.allTagByGroup[widget.tags!.uid]!.cast<User>());
    }
  }

  User getHeaderUser() {
    return User()..username = localized(addContact)..uid = -1;
  }

  void onAddTagsTap(BuildContext context) {
    CreateGroupBottomSheetController createGroupBottomSheetController = Get.put(CreateGroupBottomSheetController());
    var temp = List<User>.from(userList.skip(1));
    createGroupBottomSheetController.selectedMembers.assignAll(temp);

    showModalBottomSheet(
      context: Get.context!,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return TagsFriendBottomSheet(
          title: localized(addContact),
          placeHolder: localized(tagAddContact),
          controller: createGroupBottomSheetController,
          confirmCallback: (List<User> selectedFriends)
          {
            userList.assignAll(selectedFriends);
            userList.insert(0, getHeaderUser());
            createGroupBottomSheetController.closePopup();
          },
          cancelCallback: () {
            createGroupBottomSheetController.closePopup();
          },
        );
      },
    ).then((value) {
      Get.findAndDelete<CreateGroupBottomSheetController>();
    });
  }

  void onCreateTags(BuildContext context) async {
    if (nameController.text.trim().isEmpty) {
      imBottomToast(
        context,
        title: localized(tagNameCantEmpty),
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    if(checkTheTagsExist()){
      imBottomToast(
        context,
        title: localized(tagNameExists),
        icon: ImBottomNotifType.warning,
      );
      return;
    }

    bool isUploadSuccess = false;

    if(isUploading){
      return;
    }

    isUploading = true;

    widget.controller.onShowLoadingDialog(Get.context!,loadingKey: momentBtnStatusSending,failedKey: "发布失敗");

    ///Create
    if(!isEditMode){
      Tags tags = Tags();
      tags.tagName = nameController.text.trim();
      tags.type = TagsMgr.TAG_TYPE_MOMENT;
      tags.createAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      tags.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      List<TagResult>? tagResult = await objectMgr.tagsMgr.addTagsToServer(tags);

      if(tagResult!=null && tagResult.isNotEmpty && tagResult.first.isSuccess){
        tags.uid = tagResult.first.id;
        tags.updatedAt = tagResult.first.updated_at;
        tags.createAt = tagResult.first.updated_at;
        for(var user in userList) {
          if(user.uid==-1) {
            continue;
          }
          user.friendTags!.add(tags.uid);
        }
        isUploadSuccess = true;
      }

      if(isUploadSuccess){
        if(userList.length>1){
          isUploadSuccess = await objectMgr.tagsMgr.updateContacts(List<User>.from(userList.skip(1)));
        }

        if(isUploadSuccess) {
          await refreshAllTagByGroupAndServerTags(tags.uid);
          await objectMgr.tagsMgr.addTags(tags);
        }
      }
    }
    else
    {
      List<User> userListWithoutHeader = [];
      userListWithoutHeader = List.from(userList.skip(1));

      ///editList有，但是userList沒有，代表人員被刪除
      List<User> deletedUsers = editList.where((element) => !userListWithoutHeader.contains(element)).toList();
      if(deletedUsers.isNotEmpty){
        for(var user in deletedUsers) {
          //移除在user.friendTags中uid與widget.tags!.uid相同的元素
          user.friendTags!.removeWhere((tag) => tag == widget.tags!.uid);
        }
      }

      ///ediList沒有，但是userList有，代表新增
      List<User> addedUsers = userListWithoutHeader.where((element) => !editList.contains(element)).toList();
      if(addedUsers.isNotEmpty){
        for(var user in addedUsers) {
          user.friendTags!.add(widget.tags!.uid);
        }
      }

      ///檢查標籤是否依舊存在
      Map<String, dynamic>? tag = await objectMgr.tagsMgr.getTagsById(widget.tags!.uid);
      List<User> updateUsers = [...deletedUsers, ...addedUsers];
      if(tag==null){
        //需要新增標籤
        Tags tags = Tags();
        tags.tagName = nameController.text.trim();
        tags.type = TagsMgr.TAG_TYPE_MOMENT;
        tags.createAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        tags.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        List<TagResult>? tagResult = await objectMgr.tagsMgr.addTagsToServer(tags);

        if(tagResult!=null && tagResult.isNotEmpty && tagResult.first.isSuccess)
        {
          tags.uid = tagResult.first.id;
          tags.updatedAt = tagResult.first.updated_at;

          //updateUsers內，所有的User如果欄位內friend_tags有包含editedTags!.uid，則將此uid替換成tags.uid
          for (var user in userListWithoutHeader) {
            user.friendTags!.removeWhere((userTag) => userTag == widget.tags!.uid);
            user.friendTags!.add(tags.uid);
          }

          editedTags = tags;

          isUploadSuccess  = await objectMgr.tagsMgr.updateContacts(userListWithoutHeader);
          if(isUploadSuccess){
            await refreshAllTagByGroupAndServerTags(editedTags!.uid);
            await objectMgr.tagsMgr.addTags(tags);
          }
        }
      }
      else{
        ///如果有被修改過了，代表目前資料庫內此標籤的人員變了，必須先目前此標籤的人員搜尋出來，
        ///在跟目前的userListWithoutHeader做比對，如果有不再userListWithoutHeader的都要刪除
        if(isEditedFromServer){
          List<User>? users = objectMgr.tagsMgr.allTagByGroup[widget.tags!.uid]?.cast<User>();
          List<User> updateUsers = [...userListWithoutHeader,];
          if(users!=null){
            List<User> deletedUsers = users.where((element) => !userListWithoutHeader.contains(element)).toList();
            if(deletedUsers.isNotEmpty){
              for(var user in deletedUsers) {
                //移除在user.friendTags中uid與widget.tags!.uid相同的元素
                user.friendTags!.removeWhere((tag) => tag == widget.tags!.uid);
              }
              updateUsers.addAll(deletedUsers);
            }
          }
          isUploadSuccess =  await objectMgr.tagsMgr.updateContacts(updateUsers);
        }
        else{
          isUploadSuccess = await objectMgr.tagsMgr.updateContacts(updateUsers.isEmpty?userListWithoutHeader:updateUsers);
        }

        if(isUploadSuccess){
          if(nameController.text.trim()!=widget.tags!.tagName) {
            widget.tags!.tagName = nameController.text.trim();
            widget.tags!.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            editedTags!.tagName = nameController.text.trim();
            editedTags!.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          }
          isUploadSuccess = await objectMgr.tagsMgr.editTagsToServer([editedTags!]);
          if(isUploadSuccess){
            await refreshAllTagByGroupAndServerTags(editedTags!.uid);
          }
        }
      }//標籤存在
    }

    if(isUploadSuccess){
      await objectMgr.tagsMgr.syncTags();
      widget.controller.isFailed.value = false;
      widget.controller.isDone.value = false;
      widget.controller.isSending.value = false;
      Future.delayed(const Duration(milliseconds: 600), () {
        widget.controller.onCloseLoadingDialog(Get.context!);
        Get.back();
      });
    }else{
      widget.controller.isFailed.value = true;
      widget.controller.isDone.value = false;
      widget.controller.isSending.value = false;
      Future.delayed(const Duration(milliseconds: 600), () {
        widget.controller.onCloseLoadingDialog(Get.context!);
        imBottomToast(
          Get.context!,
          title: localized(noNetworkPleaseTryAgainLater),
          icon: ImBottomNotifType.warning,
        );
      });
    }
    isUploading = false;
  }

  Future<void> refreshAllTagByGroupAndServerTags(int uid) async {
    widget.controller.allTagByGroup[uid] = List<User>.from(userList.skip(1))..sort((a, b) => a.nickname.compareTo(b.nickname));
    objectMgr.tagsMgr.allTagByGroup[uid] = List<User>.from(userList.skip(1))..sort((a, b) => a.nickname.compareTo(b.nickname));
  }

  void onDeleteTap(BuildContext context, User user) {
    showCustomBottomAlertDialog(
      context,
      confirmText: localized(buttonDelete),
      cancelText: localized(buttonCancel),
      cancelTextColor: themeColor,
      withHeader: false,
      onConfirmListener: () => userList.remove(user),
    );
  }

  bool _isChineseCharacter(String character) {
    final chineseCharacterPattern = RegExp(r'[\u4E00-\u9FA5\u3000-\u303F\uFF00-\uFFEF\u2000-\u206F]');
    return chineseCharacterPattern.hasMatch(character);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.94,
        child: Stack(
          children: <Widget>[
            Container(
              color: colorBackground,
              margin: const EdgeInsets.only(top: 59.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollStartNotification) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                  return false;
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: <Widget>[
                    ///Logo
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/tags_logo.png',
                          width: 84.0,
                          height: 84.0,
                        ),
                      ),
                    ),
                    ///title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(localized(tagName), style: jxTextStyle.normalSmallText(color: colorTextSecondary),),
                      ),
                    ),
                    ///Input name
                    SliverToBoxAdapter(child: _buildCategoryNameInput(context)),

                    ///warn
                    Obx(() {
                      return SliverToBoxAdapter(
                        child: isExist.value
                            ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(localized(tagNameExists), style: jxTextStyle.normalSmallText(color: colorRed),),)
                            :const SizedBox(),
                      );
                    }),

                    ///Subtitle
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 24.0,
                          bottom: 8.0,
                        ),
                        child: Text(localized(tagIncludedFriendsTitle), style: jxTextStyle.normalSmallText(color: colorTextSecondary),),
                      ),
                    ),

                    SlidableAutoCloseBehavior(
                      child: Obx(() => DecoratedSliver(
                        decoration: BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index)
                          {
                            final user = userList[index];
                            if (index == 0) {
                              return _buildAddTags(context, user,);
                            }

                            return TagsCreateItem(
                              key: ValueKey(user.uid),
                              user: user,
                              isLast: index + 1 == userList.length,
                              onDeleteTap: (User user) => onDeleteTap(context, user),
                            );
                          },
                            childCount: userList.length,
                          ),
                        ),
                      ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24,)
                    ),
                  ],
                ),
              ),
            ),

            ///Action bar
            Positioned(
              left: 0.0,
              right: 0.0,
              top: 0.0,
              child: Container(
                height: 60,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: colorBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      left: 0.0,
                      right: 0.0,
                      child: Text(
                        isEditMode
                            ? localized(editTags)
                            : localized(tagAddTags),
                        key: UniqueKey(),
                        textAlign: TextAlign.center,
                        style: jxTextStyle.appTitleStyle(
                          color: colorTextPrimary,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0.0,
                      child: GestureDetector(
                        onTap: () => onCancelEdited(context),
                        child: OpacityEffect(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 24,
                            ),
                            child: Text(
                              localized(cancel),
                              style: jxTextStyle.textStyle17(color: themeColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0.0,
                      child: GestureDetector(
                        onTap: () => onCreateTags(context),
                        child: OpacityEffect(
                          child: Container(
                            padding: const EdgeInsets.only(right: 16.0),
                            alignment: Alignment.centerRight,
                            child: Text(
                              localized(isEditMode ? buttonDone : buttonCreate),
                              style: jxTextStyle.textStyle17(color: themeColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildCategoryNameInput(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.multiline,
        controller: nameController,
        inputFormatters: [
          ChineseCharacterInputFormatter(max: 10),
        ],
        style: jxTextStyle.textStyle17(),
        maxLines: 1,
        maxLength: 10,
        buildCounter: (
            BuildContext context, {
              required int currentLength,
              required int? maxLength,
              required bool isFocused,
            }) {
          return null;
        },
        cursorColor: themeColor,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 9,
          ),
          hintText: localized(chatCategoryHintInput),
          hintStyle: const TextStyle(
            color: colorTextSupporting,
          ),
          suffixIconConstraints: const BoxConstraints(maxHeight: 44),
          suffixIcon: Obx(
                () => isNameEmpty.value
                ? const SizedBox()
                : GestureDetector(
              onTap: nameController.clear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                child: SvgPicture.asset(
                  'assets/svgs/clear_icon.svg',
                  color: colorTextSecondary,
                  width: 20,
                  height: 20,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAddTags(BuildContext context, User aUser)
  {
    return GestureDetector(
      onTap: () => onAddTagsTap(context),
      child: OverlayEffect(
        radius: BorderRadius.circular(8.0),
        child: Container(
          height: 44.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0,),
          child: Row(
            children: <Widget>[
              Container(
                height: 40.0,
                width: 40.0,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/svgs/add.svg',
                  height: 24.0,
                  width: 24.0,
                  colorFilter: ColorFilter.mode(themeColor, BlendMode.srcIn,),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          aUser.username,
                          style: jxTextStyle.textStyle17(color: themeColor,),
                        ),
                      ),
                    ),
                    if (userList.length > 1) const CustomDivider(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onCancelEdited(BuildContext context) async {
    if(checkIsEditing()) {
      showCustomBottomAlertDialog(
        context,
        subtitle: localized(tagAbandonModification),
        confirmText: localized(momentVisibleAbandon),
        confirmTextColor: colorRed,
        cancelTextColor: themeColor,
        onConfirmListener: () => Navigator.of(context).pop(),
      );
    }else{
      Navigator.of(context).pop();
    }
  }

  bool checkIsEditing() {
    //1. Check whether is creating or editing.
    bool isEditing = false;
    //2. If is creating: a.check whether the name is empty
    if(!isEditMode){
      if(!isNameEmpty.value){
        isEditing = true;
      }
    }else{
      //If is editing, a.check whether the name is same as widget.tag.name.
      if(widget.tags!.tagName != nameController.text.trim() && nameController.text.trim().isNotEmpty){
        isEditing = true;
      }
    }

    //Check whether the userList is same as editList.
    if(!isEditing){
      List<User> users = List.from(userList.skip(1));
      isEditing = users.length != editList.length || users.any((localTag) => !editList.any((editList) => editList.uid == localTag.uid));
    }
    return isEditing;
  }
}
