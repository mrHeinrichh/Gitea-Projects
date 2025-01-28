import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';
import 'package:jxim_client/views/contact/friend_request_confirm.dart';
import 'package:jxim_client/views/contact/local_contact_controller.dart';
import 'package:jxim_client/views/contact/local_contact_view.dart';

class DeviceContactView extends GetView<LocalContactController> {
  const DeviceContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return controller.obx(
      (state) {
        return Obx(
          () => controller.showPermission.value
              ? const ContactPermission()
              : controller.deviceContactList.isNotEmpty
                  ? _buildContactList()
                  : const FriendEmptyState(),
        );
      },
      onLoading: const ContactLoadingProgress(),
    );
  }

  Widget _buildContactList() {
    return ListView.separated(
      itemCount: controller.deviceContactList.length,
      itemBuilder: (BuildContext context, int index) {
        final User user = controller.deviceContactList[index];
        return ContactCard(
          user: user,
          titleWidget: buildContactTitleWidget(user),
          subTitle: notBlank(user.localPhoneNumbers)
              ? user.localPhoneNumbers
              : user.contact,
          trailing: [_getTrailing(user)],
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Padding(
          padding: EdgeInsets.only(left: 68),
          child: CustomDivider(),
        );
      },
    );
  }

  Widget _getTrailing(User user) {
    switch (user.relationship) {
      case Relationship.stranger:
        return _buildTrailingButton(localized(buttonAdd), themeColor, () {
          showModalBottomSheet(
            context: Get.context!,
            barrierColor: colorOverlay40,
            backgroundColor: Colors.transparent,
            isDismissible: false,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: FriendRequestConfirm(
                  user: user,
                  confirmCallback: (remark) {
                    objectMgr.userMgr.addFriend(user, remark: remark);
                  },
                  cancelCallback: () {
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          );
        });
      case Relationship.sentRequest:
        return _buildTrailingButton(
            localized(contactVerifying), colorTextPlaceholder, null);

      case Relationship.receivedRequest:
        return _buildTrailingButton(localized(groupCheck), themeColor, () {
          Get.toNamed(
            RouteName.chatInfo,
            arguments: {"uid": user.uid, "id": user.uid},
          );
        });
      default:
        return const SizedBox();
    }
  }

  Widget _buildTrailingButton(String text, Color color, VoidCallback? onTap) {
    Widget child = Container(
      alignment: Alignment.center,
      width: 77,
      height: 32,
      decoration: BoxDecoration(
        color: colorBackground3,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: jxTextStyle.normalText(
          fontWeight: MFontWeight.bold5.value,
          color: color,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }

    return child;
  }
}
