import 'package:flutter/material.dart';
import 'package:jxim_client/end_to_end_encryption/setting_info/custom_encryption_bottom_sheet_view.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

class GroupChatEncryptionBottomSheet extends StatefulWidget {
  const GroupChatEncryptionBottomSheet({super.key});

  @override
  State<GroupChatEncryptionBottomSheet> createState() =>
      _GroupChatEncryptionBottomSheet();
}

class _GroupChatEncryptionBottomSheet
    extends State<GroupChatEncryptionBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomEncryptionBottomSheetView(
      leading: null,
      headerText: localized(groupEncryptionInfoHeader),
      subHeaderText: localized(groupEncryptionInfoSubHeader,params: [Config().appName]),
      primaryButtonText: localized(understandMore),
      listItems: [
        localized(groupEncryptionListWordAndAudio),
        localized(groupEncryptionListVideoAndAudio),
        localized(groupEncryptionListLocation),
        localized(newQRCommunity),
      ],
      primaryButtonOnTap: () {
      },
    );
  }
}
