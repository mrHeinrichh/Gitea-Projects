import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';

class JoinInvitationBottomSheet extends StatelessWidget {
  final Group group;
  final String userName;
  final bool isFriend;

  const JoinInvitationBottomSheet({
    super.key,
    required this.group,
    required this.userName,
    this.isFriend = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomShareBottomSheetView(
      leading: CustomTextButton(
        localized(buttonCancel),
        onClick: () => Get.back(result: false),
      ),
      showDoneButton: false,
      showMainHeader: true,
      topWidget: CustomAvatar.group(group, size: 100.0),
      headerText: group.name,
      subHeaderText: isFriend
          ? localized(willJoinGroupSoon)
          : localized(
              becomeFriendJoinGroup,
              params: [userName],
            ),
      showLink: false,
      primaryButtonText:
          isFriend ? localized(joinGroup) : localized(addFriendJoinGroup),
      secondaryButtonText: localized(notJoinYet),
      primaryButtonOnTap: () => Get.back(result: true),
      secondaryButtonOnTap: () => Get.back(result: false),
    );
  }
}
