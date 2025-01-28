import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';
import 'package:jxim_client/views/contact/local_contact_controller.dart';
import 'package:jxim_client/views/contact/local_contact_view.dart';

class AppContactView extends GetView<LocalContactController> {
  const AppContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return controller.obx(
      (state) {
        return Obx(
          () => controller.showPermission.value
              ? const ContactPermission()
              : controller.appContactList.isNotEmpty
                  ? _buildContactList()
                  : const FriendEmptyState(),
        );
      },
      onLoading: const ContactLoadingProgress(),
    );
  }

  Widget _buildContactList() {
    return ListView.separated(
      itemCount: controller.appContactList.length,
      itemBuilder: (BuildContext context, int index) {
        final User user = controller.appContactList[index];
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ContactCard(
            user: user,
            titleWidget: buildContactTitleWidget(user, isFriend: true),
            subTitle: notBlank(user.localPhoneNumbers)
                ? user.localPhoneNumbers
                : user.contact,
          ),
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
}
