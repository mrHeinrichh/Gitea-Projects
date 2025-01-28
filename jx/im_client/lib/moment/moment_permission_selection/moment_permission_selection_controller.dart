import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/component/create_tags_bottom_sheet_controller.dart';
import 'package:jxim_client/moment/component/mentioned_friend_bottom_sheet.dart';
import 'package:jxim_client/moment/component/moment_tag_bottom_sheet.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/models/permission_selection_composite.dart';
import 'package:jxim_client/object/tags.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';

class MomentPermissionSelectionController extends GetxController {
  MomentVisibility momentVisibility;

  int public = 0;
  int specificFriends = 1;
  int hideFromSpecificFriends = 2;
  int private = 3;

  int specificFriendsBest = 1;
  int specificFriendsLabel = 2;

  int hideFriendsBest = 1;
  int hideFriendsLabel = 2;

  List<User> selectedBestFriends = [];
  List<User> selectedHideFromFriends = [];

  List<FriendsLabel> selectedBestFriendsLabel = [];
  List<FriendsLabel> selectedHideFromFriendsLabel = [];

  Rxn<PermissionSelectionComposite?> selectedPermissionSelection = Rxn<PermissionSelectionComposite>();

  List<User> originalSelectedBestFriends = [];
  List<User> originalSelectedHideFromFriends = [];
  List<Tags> originalLabel = [];

  ///所有权限
  Rx<PermissionSelection> permissionSelection = PermissionSelection().obs;

  MomentPermissionSelectionController(this.momentVisibility,List<User> selectedFriends,List<Tags> selectBestLabel) {
    if(momentVisibility == MomentVisibility.specificFriends){
      selectedBestFriends = List.from(selectedFriends);
      originalSelectedBestFriends = List.from(selectedFriends);
      originalLabel = List.from(selectBestLabel);
      for(var tag in selectBestLabel){
        if(objectMgr.tagsMgr.allTagByGroup[tag.uid]==null){
          continue;
        }
        List<User> friends = (objectMgr.tagsMgr.allTagByGroup[tag.uid] as List<User>);
        selectedBestFriendsLabel.add(FriendsLabel(tags:tag,friends: friends));
      }
    }else if(momentVisibility == MomentVisibility.hideFromSpecificFriends){
      selectedHideFromFriends = List.from(selectedFriends);
      originalSelectedHideFromFriends = List.from(selectedFriends);
      originalLabel = List.from(selectBestLabel);
      for(var tag in selectBestLabel){
        if(objectMgr.tagsMgr.allTagByGroup[tag.uid]==null && !objectMgr.tagsMgr.allTags.any((tags)=>tags.uid==tag.uid)){
          continue;
        }
        List<User> friends = objectMgr.tagsMgr.allTagByGroup[tag.uid]==null?[]:(objectMgr.tagsMgr.allTagByGroup[tag.uid] as List<User>);
        selectedHideFromFriendsLabel.add(FriendsLabel(tags:tag,friends: friends));
      }
    }
  }

  @override
  void onInit() {
    super.onInit();

    ///初始化預設項目.
    ///部分可見
    PermissionSelection specificFriend = PermissionSelection();
    specificFriend.momentVisibility = MomentVisibility.specificFriends;
    PermissionItem specificTitle = PermissionItem(MomentVisibility.specificFriends);
    specificFriend.addPermissionSelectionComponent(specificTitle);

    ///部分可見-好友，底下不會有子標籤
    PermissionItem best = PermissionItem(MomentVisibility.specificBest);

    ///部分可見-標籤，底下還會有子標籤所以用PermissionSelection
    PermissionSelection label = PermissionSelection();
    label.momentVisibility = MomentVisibility.specificLabel;
    PermissionItem labelTitle = PermissionItem(MomentVisibility.specificLabel);

    label.addPermissionSelectionComponent(labelTitle);
    specificFriend.addPermissionSelectionComponent(best);
    specificFriend.addPermissionSelectionComponent(label);

    ///不給誰看
    PermissionSelection hideFromSpecificFriend = PermissionSelection();
    hideFromSpecificFriend.momentVisibility = MomentVisibility.hideFromSpecificFriends;
    PermissionItem hideTitle = PermissionItem(MomentVisibility.hideFromSpecificFriends);

    ///部分可見-好友
    PermissionItem hideBest = PermissionItem(MomentVisibility.hideBest);

    ///部分可見-標籤，底下還會有子標籤所以用PermissionSelection
    PermissionSelection hideLabel = PermissionSelection();
    hideLabel.momentVisibility = MomentVisibility.hideLabel;
    PermissionItem hideLabelTitle = PermissionItem(MomentVisibility.hideLabel);
    hideLabel.addPermissionSelectionComponent(hideLabelTitle);

    hideFromSpecificFriend.addPermissionSelectionComponent(hideTitle);
    hideFromSpecificFriend.addPermissionSelectionComponent(hideBest);
    hideFromSpecificFriend.addPermissionSelectionComponent(hideLabel);

    permissionSelection.value.addPermissionSelectionComponent(PermissionItem(MomentVisibility.public),);

    permissionSelection.value.addPermissionSelectionComponent(specificFriend);
    permissionSelection.value.addPermissionSelectionComponent(hideFromSpecificFriend);

    permissionSelection.value.addPermissionSelectionComponent(PermissionItem(MomentVisibility.private),);

    if(momentVisibility == MomentVisibility.public)
    {
      selectedPermissionSelection.value ??= permissionSelection.value.components[public];
    }else if(momentVisibility == MomentVisibility.specificFriends){
      selectedPermissionSelection.value ??= permissionSelection.value.components[specificFriends];
      addSelectedFriends(selectedBestFriends);
      addSelectedLabel(selectedBestFriendsLabel);
    }
    else if(momentVisibility == MomentVisibility.hideFromSpecificFriends){
      selectedPermissionSelection.value ??= permissionSelection.value.components[hideFromSpecificFriends];
      addSelectedFriendsForHideFrom(selectedHideFromFriends);
      addSelectedLabelForHideFrom(selectedHideFromFriendsLabel);
    }
    else if(momentVisibility == MomentVisibility.private){
      selectedPermissionSelection.value ??= permissionSelection.value.components[private];
    }
    else{
      selectedPermissionSelection.value ??= permissionSelection.value.components[public];
    }
  }

  onItemTap(PermissionSelectionComposite aPermissionItem) {
    if (aPermissionItem.momentVisibility == MomentVisibility.public)
    {
      selectedPermissionSelection.value = permissionSelection.value.components[public];
    }
    else if (aPermissionItem.momentVisibility == MomentVisibility.specificFriends)
    {
      selectedPermissionSelection.value = permissionSelection.value.components[specificFriends];
    }
    else if (aPermissionItem.momentVisibility == MomentVisibility.hideFromSpecificFriends)
    {
      selectedPermissionSelection.value = permissionSelection.value.components[hideFromSpecificFriends];
    }
    else if (aPermissionItem.momentVisibility == MomentVisibility.private)
    {
      selectedPermissionSelection.value = permissionSelection.value.components[private];
    }
    else if (aPermissionItem.momentVisibility == MomentVisibility.specificBest)
    {
      onMentionedFriends(aPermissionItem.momentVisibility);
    }
    else if (aPermissionItem.momentVisibility == MomentVisibility.specificLabel)
    {
      onMentionedTags(aPermissionItem.momentVisibility);
    }
    else if (aPermissionItem.momentVisibility == MomentVisibility.hideBest)
    {
      onMentionedFriends(aPermissionItem.momentVisibility);
    }
    else if (aPermissionItem.momentVisibility == MomentVisibility.hideLabel)
    {
      onMentionedTags(aPermissionItem.momentVisibility);
    }

    update(["permissionSelection"], true);
  }

  void back(context) {
    if(isChange()){
      showCustomBottomAlertDialog(
        context,
        subtitle: localized(momentVisibleAbandonOrNot),
        confirmText: localized(momentVisibleAbandon),
        confirmTextColor: colorRed,
        cancelTextColor: themeColor,
        onConfirmListener: ()=>Get.back(),
      );
    }else{
      Get.back();
    }
  }

  bool isChange(){
      if(selectedPermissionSelection.value?.momentVisibility != momentVisibility){
        return true;
      }else{
        if (momentVisibility == MomentVisibility.specificFriends) {
          if(!listEquals(originalSelectedBestFriends, selectedBestFriends)){
            return true;
          }
          List<Tags> selectedTags = selectedBestFriendsLabel.map((label) => label.tags).toList();
          if(!listEquals(originalLabel, selectedTags)){
            return true;
          }

        } else if(momentVisibility == MomentVisibility.hideFromSpecificFriends){
          if(!listEquals(originalSelectedHideFromFriends, selectedHideFromFriends)){
            return true;
          }
          List<Tags> selectedHideFromTags = selectedHideFromFriendsLabel.map((label) => label.tags).toList();

          if(!listEquals(originalLabel, selectedHideFromTags)){
            return true;
          }

        }else{
          return true;
        }
      }
      return false;
  }

  addSelectedFriends(List<User> selectedFriends) {
    PermissionSelection sf = permissionSelection.value.components[specificFriends] as PermissionSelection;
    PermissionItem best = sf.components[specificFriendsBest] as PermissionItem;
    best.selectedFriends.assignAll(selectedFriends);
    update(["permissionSelection"], true);
  }

  addSelectedFriendsForHideFrom(List<User> selectedFriends) {
    PermissionSelection hf = permissionSelection.value.components[hideFromSpecificFriends] as PermissionSelection;
    PermissionItem hide = hf.components[hideFriendsBest] as PermissionItem;
    hide.selectedFriends.assignAll(selectedFriends);
    update(["permissionSelection"], true);
  }

  addSelectedLabel(List<FriendsLabel> friendsLabel) {
    PermissionSelection sf = permissionSelection.value.components[specificFriends] as PermissionSelection;
    PermissionSelection label = sf.components[specificFriendsLabel] as PermissionSelection;
    PermissionItem temp  = label.components.first as PermissionItem;
    temp.selectedNames.clear();
    temp.selectedFriends.clear();
    for (var perLabel in friendsLabel) {
      temp.addName(perLabel.tags.tagName);
      for (var user in perLabel.friends){
        temp.addFriend(user);
      }
    }
    update(["permissionSelection"], true);
  }

  addSelectedLabelForHideFrom(List<FriendsLabel> friendsLabel) {
    PermissionSelection sf = permissionSelection.value.components[hideFromSpecificFriends] as PermissionSelection;
    PermissionSelection label = sf.components[hideFriendsLabel] as PermissionSelection;
    PermissionItem temp  = label.components.first as PermissionItem;
    temp.selectedNames.clear();
    temp.selectedFriends.clear();
    for (var perLabel in friendsLabel) {
      temp.addName(perLabel.tags.tagName);
      for (var user in perLabel.friends){
        temp.addFriend(user);
      }
    }
    update(["permissionSelection"], true);
  }

  void onTapFinish() {
    if((selectedPermissionSelection.value?.momentVisibility == MomentVisibility.specificFriends || selectedPermissionSelection.value?.momentVisibility == MomentVisibility.hideFromSpecificFriends)
        && (selectedPermissionSelection.value!.getSelectFriends().isEmpty && selectedPermissionSelection.value!.getSelectLabel().isEmpty)){
      Toast.showToast(localized(momentPermissionRequireAtLeastOne));
      return;
    }

    List<User> selectFriends=[];
    List<User> selectLabelFriends=[];
    List<Tags> selectedLabelName = [];
    if(selectedPermissionSelection.value?.momentVisibility == MomentVisibility.specificFriends){
      PermissionSelection ps = selectedPermissionSelection.value! as PermissionSelection;
      selectFriends = ps.components[specificFriendsBest].getSelectFriends();
      PermissionSelection labelPS = ps.components[specificFriendsLabel] as PermissionSelection;
      selectLabelFriends = labelPS.getSelectFriends();
      selectedLabelName = selectedBestFriendsLabel.map((e) => e.tags).toList();
    }else if(selectedPermissionSelection.value?.momentVisibility == MomentVisibility.hideFromSpecificFriends){
      PermissionSelection ps = selectedPermissionSelection.value! as PermissionSelection;
      selectFriends = ps.components[hideFriendsBest].getSelectFriends();
      PermissionSelection labelPS = ps.components[hideFriendsLabel] as PermissionSelection;
      selectLabelFriends = labelPS.getSelectFriends();
      selectedLabelName = selectedHideFromFriendsLabel.map((e) => e.tags).toList();
    }

    Get.back(result: {
      'momentVisibility': selectedPermissionSelection.value?.momentVisibility,
      'selectFriends': selectFriends,
      'selectLabel': selectedLabelName,
      'selectLabelFriends': selectLabelFriends,
    });
  }

  void onMentionedFriends(MomentVisibility aMomentVisibility) async
  {
    CreateGroupBottomSheetController createGroupBottomSheetController = Get.put(CreateGroupBottomSheetController());

    if (aMomentVisibility == MomentVisibility.specificBest) {
      if (selectedBestFriends.isNotEmpty) {
        createGroupBottomSheetController.selectedMembers.assignAll(selectedBestFriends);
      }
    } else {
      if (selectedHideFromFriends.isNotEmpty) {
        createGroupBottomSheetController.selectedMembers.assignAll(selectedHideFromFriends);
      }
    }

    showModalBottomSheet(
      context: Get.context!,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return MentionedFriendBottomSheet(
          title: localized(momentPermissionSelectFriends),
          placeHolder: aMomentVisibility == MomentVisibility.specificBest
              ? localized(momentSpecificFriends)
              : localized(momentHideFromFriends),
          controller: createGroupBottomSheetController,
          confirmCallback: (List<User> selectedFriends) {
            if (aMomentVisibility == MomentVisibility.specificBest) {
              selectedBestFriends.assignAll(selectedFriends);
              addSelectedFriends(selectedFriends);
            } else {
              selectedHideFromFriends.assignAll(selectedFriends);
              addSelectedFriendsForHideFrom(selectedFriends);
            }

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

  void onMentionedTags(MomentVisibility aMomentVisibility)
  {
    CreateTagsBottomSheetController createTagsBottomSheetController = Get.put(CreateTagsBottomSheetController());

    if (aMomentVisibility == MomentVisibility.specificLabel) {
      if (selectedBestFriendsLabel.isNotEmpty) {
        List<Tags> selectedTags = selectedBestFriendsLabel.map((label) => label.tags).toList();
        createTagsBottomSheetController.selectedMembers.assignAll(selectedTags);
      }
    } else {
      if (selectedHideFromFriendsLabel.isNotEmpty) {
        List<Tags> selectedTags = selectedHideFromFriendsLabel.map((label) => label.tags).toList();
        createTagsBottomSheetController.selectedMembers.assignAll(selectedTags);
      }
    }

    showModalBottomSheet(
      context: Get.context!,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return MomentTagBottomSheet(
          title: localized(momentPermissionSelectTags),
          placeHolder: aMomentVisibility == MomentVisibility.specificLabel?localized(momentTagWhoCanSee):localized(momentTagWhoCantSee),
          controller: createTagsBottomSheetController,
          confirmCallback: (Map<int,List<User>> selectedFriends) {
            if (aMomentVisibility == MomentVisibility.specificLabel) {
              selectedBestFriendsLabel = selectedFriends.entries.map((entry) {
                return FriendsLabel(
                  tags: createTagsBottomSheetController.tags.firstWhere((element) => element.uid == entry.key),
                  friends: entry.value,
                );
              }).toList();

              addSelectedLabel(selectedBestFriendsLabel);
            }
            else {
              selectedHideFromFriendsLabel = selectedFriends.entries.map((entry) {
                return FriendsLabel(
                  tags: createTagsBottomSheetController.tags.firstWhere((element) => element.uid == entry.key),
                  friends: entry.value,
                );
              }).toList();

              addSelectedLabelForHideFrom(selectedHideFromFriendsLabel);
            }
            createTagsBottomSheetController.closePopup();
          },
          cancelCallback: () {
            createTagsBottomSheetController.closePopup();
          },
        );
      },
    ).then((value) {
      Get.findAndDelete<CreateTagsBottomSheetController>();
    });
  }

  addLabel() {
    List<FriendsLabel> friendsLabel = [];
    friendsLabel.add(
      FriendsLabel(
        tags: Tags()..tagName = "摯友",
        friends: [
          User()
            ..uid = 3345678
            ..nickname = "Ken",
          User()
            ..uid = 22
            ..nickname = "Tom",
        ],
      ),
    );
    friendsLabel.add(
      FriendsLabel(
        tags: Tags()..tagName ="親友",
        friends: [
          User()
            ..uid = 33
            ..nickname = "Jason",
          User()
            ..uid = 334
            ..nickname = "大伯",
          User()
            ..uid = 334
            ..nickname = "Edson",
        ],
      ),
    );
    addSelectedLabel(friendsLabel);
  }
}

class FriendsLabel
{
  Tags tags;
  List<User> friends = [];
  FriendsLabel({required this.tags, required this.friends});
}
