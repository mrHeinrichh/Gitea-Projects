import 'package:flutter/material.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/manage/manage_group_deleted_links.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/manage/manage_group_invite_link.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/manage/manage_group_other_links.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';

class ManageGroupInvitationLinks extends StatelessWidget {
  const ManageGroupInvitationLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetContent(
      title: localized(invitationLink),
      leading: const CustomLeadingIcon(needPadding: false),
      useTopSafeArea: true,
      useBottomSafeArea: false,
      middleChild: CustomScrollableListView(
        padding: EdgeInsets.fromLTRB(
          16,
          24,
          16,
          24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        children: const [
          ManageGroupInviteLink(),
          ManageGroupOtherLinks(),
          ManageGroupDeletedLinks(),
        ],
      ),
    );
  }
}
