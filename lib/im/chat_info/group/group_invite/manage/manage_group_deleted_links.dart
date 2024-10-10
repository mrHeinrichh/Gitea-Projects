import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/group_invite_link_controler.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/component.dart';

class ManageGroupDeletedLinks extends StatefulWidget {
  const ManageGroupDeletedLinks({super.key});

  @override
  State<ManageGroupDeletedLinks> createState() =>
      _ManageGroupDeletedLinksState();
}

class _ManageGroupDeletedLinksState extends State<ManageGroupDeletedLinks> {
  final controller = Get.find<GroupInviteLinkController>();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (controller.invalidLinks.isEmpty) return const SizedBox.shrink();
        return CustomRoundContainer(
          title: localized(deprecatedLink),
          child: Column(
            children: [
              CustomListTile(
                leading: Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: const CustomImage(
                    'assets/svgs/moment_viewer_delete.svg',
                    size: 24,
                    color: colorRed,
                  ),
                ),
                text: localized(removeAllDefunctLinks),
                textColor: colorRed,
                showDivider: true,
                onClick: () {
                  showCustomBottomAlertDialog(
                    context,
                    subtitle: localized(actionRemoveDefunctLinks),
                    confirmText: localized(deleteAll),
                    onConfirmListener: () {
                      controller.deleteAllInvalidLinks();
                    },
                  );
                },
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: controller.invalidLinks.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = controller.invalidLinks[index];
                  final displayLink =
                      (item.name == null || item.name?.isEmpty == true)
                          ? item.link
                          : item.name;
                  return CustomListTile(
                    height: 56,
                    leading: Container(
                      height: 40,
                      width: 40,
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: Colors.black.withOpacity(0.39),
                        shape: const CircleBorder(),
                      ),
                      child: const CustomImage(
                        'assets/svgs/invite_link_outlined.svg',
                        color: colorWhite,
                        size: 20,
                      ),
                    ),
                    text: displayLink ?? '',
                    subText: item.used == 0
                        ? '${localized(notUsed)} · ${localized(revoked)}'
                        : '${localized(invitationLinkIsUsedNum, params: [
                                item.used.toString()
                              ])} · ${localized(revoked)}',
                    showDivider: index != (controller.invalidLinks.length - 1),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
