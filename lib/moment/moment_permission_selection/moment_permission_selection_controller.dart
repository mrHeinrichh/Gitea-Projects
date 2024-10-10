import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/moment/component/mentioned_friend_bottom_sheet.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/moment/models/permission_selection_composite.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class MomentPermissionSelectionController extends GetxController {
  int public = 0;
  int specificFriends = 1;
  int hideFromSpecificFriends = 2;
  int private = 3;
  int specificFriendsBest = 1;
  int specificFriendsLabel = 2;

  List<User> selectedBestFriends = [];
  List<User> selectedHideFromFriends = [];

  Rxn<PermissionSelectionComposite?> selectedPermissionSelection =
      Rxn<PermissionSelectionComposite>();

  ///所有权限
  Rx<PermissionSelection> permissionSelection = PermissionSelection().obs;

  @override
  void onInit() {
    super.onInit();

    ///初始化預設項目.
    ///部分可見
    PermissionSelection specificFriends = PermissionSelection();
    specificFriends.momentVisibility = MomentVisibility.specificFriends;
    PermissionItem specificTitle =
        PermissionItem(MomentVisibility.specificFriends);
    specificFriends.addPermissionSelectionComponent(specificTitle);

    ///部分可見-好友，底下不會有子標籤
    PermissionItem best = PermissionItem(MomentVisibility.best);

    ///部分可見-標籤，底下還會有子標籤所以用PermissionSelection
    PermissionSelection label = PermissionSelection();
    label.momentVisibility = MomentVisibility.label;
    PermissionItem labelTitle = PermissionItem(MomentVisibility.label);
    label.addPermissionSelectionComponent(labelTitle);

    specificFriends.addPermissionSelectionComponent(best);
    specificFriends.addPermissionSelectionComponent(label);

    PermissionSelection hideFromSpecificFriends = PermissionSelection();
    hideFromSpecificFriends.momentVisibility =
        MomentVisibility.hideFromSpecificFriends;
    PermissionItem hideTitle =
        PermissionItem(MomentVisibility.hideFromSpecificFriends);
    hideFromSpecificFriends.addPermissionSelectionComponent(hideTitle);

    permissionSelection.value.addPermissionSelectionComponent(
      PermissionItem(MomentVisibility.public),
    );
    permissionSelection.value.addPermissionSelectionComponent(specificFriends);
    permissionSelection.value
        .addPermissionSelectionComponent(hideFromSpecificFriends);
    permissionSelection.value.addPermissionSelectionComponent(
      PermissionItem(MomentVisibility.private),
    );

    selectedPermissionSelection.value =
        permissionSelection.value.components.first;

    // addLabel();
  }

  void onMentionedFriends(MomentVisibility aMomentVisibility) async {
    CreateGroupBottomSheetController createGroupBottomSheetController =
        Get.put(CreateGroupBottomSheetController());
    if (aMomentVisibility == MomentVisibility.best) {
      if (selectedBestFriends.isNotEmpty) {
        createGroupBottomSheetController.selectedMembers
            .assignAll(selectedBestFriends);
      }
    } else {
      if (selectedHideFromFriends.isNotEmpty) {
        createGroupBottomSheetController.selectedMembers
            .assignAll(selectedHideFromFriends);
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
          placeHolder: aMomentVisibility == MomentVisibility.best
              ? localized(momentSpecificFriends)
              : localized(momentHideFromFriends),
          controller: createGroupBottomSheetController,
          confirmCallback: (List<User> selectedFriends) {
            if (aMomentVisibility == MomentVisibility.best) {
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

  onItemTap(PermissionSelectionComposite aPermissionItem) {
    if (aPermissionItem.momentVisibility == MomentVisibility.public) {
      selectedPermissionSelection.value =
          permissionSelection.value.components[public];
    } else if (aPermissionItem.momentVisibility ==
        MomentVisibility.specificFriends) {
      selectedPermissionSelection.value =
          permissionSelection.value.components[specificFriends];
    } else if (aPermissionItem.momentVisibility ==
        MomentVisibility.hideFromSpecificFriends) {
      selectedPermissionSelection.value =
          permissionSelection.value.components[hideFromSpecificFriends];
      onMentionedFriends(aPermissionItem.momentVisibility);
    } else if (aPermissionItem.momentVisibility == MomentVisibility.private) {
      selectedPermissionSelection.value =
          permissionSelection.value.components[private];
    } else if (aPermissionItem.momentVisibility == MomentVisibility.best) {
      onMentionedFriends(aPermissionItem.momentVisibility);
    } else if (aPermissionItem.momentVisibility == MomentVisibility.label) {
      imBottomToast(
        Get.context!,
        title: "開發中",
        icon: ImBottomNotifType.warning,
      );
    }

    update(["permissionSelection"], true);
  }

  addSelectedFriends(List<User> selectedFriends) {
    PermissionSelection sf = permissionSelection
        .value.components[specificFriends] as PermissionSelection;
    PermissionItem best = sf.components[specificFriendsBest] as PermissionItem;
    best.selectedFriends.assignAll(selectedFriends);
    update(["permissionSelection"], true);
  }

  addSelectedFriendsForHideFrom(List<User> selectedFriends) {
    PermissionSelection hf = permissionSelection
        .value.components[hideFromSpecificFriends] as PermissionSelection;
    PermissionItem hide = hf.components[0] as PermissionItem;
    hide.selectedFriends.assignAll(selectedFriends);
    update(["permissionSelection"], true);
  }

  addSelectedLabel(List<FriendsLabel> friendsLabel) {
    PermissionSelection sf = permissionSelection
        .value.components[specificFriends] as PermissionSelection;
    PermissionSelection label =
        sf.components[specificFriendsLabel] as PermissionSelection;
    for (var perLabel in friendsLabel) {
      PermissionItem temp = PermissionItem(MomentVisibility.subLabel);
      temp.addName(perLabel.tags);
      temp.selectedFriends.assignAll(perLabel.friends);
      label.addPermissionSelectionComponent(temp);
    }
    update(["permissionSelection"], true);
  }

  addLabel() {
    List<FriendsLabel> friendsLabel = [];
    friendsLabel.add(
      FriendsLabel(
        tags: "摯友",
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
        tags: "親友",
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

class FriendsLabel {
  String tags = "";
  List<User> friends = [];

  FriendsLabel({required this.tags, required this.friends});
}
