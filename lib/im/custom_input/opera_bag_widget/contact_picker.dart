import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ContactPicker extends StatelessWidget {
  final CustomInputController controller;

  const ContactPicker({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetContent(
      showHeader: !controller.chatController.isContactSearching.value,
      title: localized(contact),
      showCancelButton: true,
      useBottomSafeArea: false,
      topChild: CustomSearchBar(
        controller: controller.chatController.searchContactController,
        onClick: () => controller.chatController.isContactSearching(true),
        onChanged: controller.chatController.onSearchContactChanged,
        onClearClick: () {
          controller.chatController.searchContactParam.value = '';
          controller.chatController.getFriendList();
        },
        onCancelClick: () => controller.chatController.clearContactSearching(),
      ),
      showDivider: true,
      middleChild: Obx(() {
        final contactList = buildList();
        return AzListView(
          noResultFound: localized(noResultFound),
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          data: contactList,
          itemScrollController: ItemScrollController(),
          itemCount: controller.chatController.friendList.length,
          itemBuilder: (context, index) {
            final item = contactList[index];
            final next = contactList.length > (index + 1)
                ? contactList[index + 1]
                : null;

            return _buildListItem(
              item,
              next,
              index != contactList.length - 1,
              true,
              context,
            );
          },
          showIndexBar: true,
          listFooter: _buildFooter(),
          emptyState: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              children: [
                Text(
                  localized(noUserFound),
                  style: jxTextStyle.textStyleBold17(),
                ),
                const SizedBox(height: 8),
                Text(
                  localized(noUserFoundDescription),
                  style: jxTextStyle.textStyle17(color: colorTextSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          indexBarOptions: IndexBarOptions(
            textStyle: jxTextStyle.textStyleBold10(color: themeColor),
          ),
        );
      }),
    );
  }

  SizedBox _buildFooter() {
    return SizedBox(
      height: 95,
      child: Center(
        child: Text(
          localized(
            totalFriend,
            params: [controller.chatController.friendList.length.toString()],
          ),
          style: jxTextStyle.textStyle14(color: colorTextSecondary),
        ),
      ),
    );
  }

  List<AZItem> buildList() {
    List<AZItem> list = controller.chatController.friendList
        .map(
          (e) => AZItem(
            user: e,
            tag: convertToPinyin(objectMgr.userMgr.getUserTitle(e)[0])[0]
                .toUpperCase(),
          ),
        )
        .toList();
    SuspensionUtil.setShowSuspensionStatus(list);
    return list;
  }

  /// create contact card
  Widget _buildListItem(
    AZItem item,
    AZItem? nextItem,
    bool withCustomBorder,
    bool isShowingTag,
    BuildContext context,
  ) {
    final tag = item.getSuspensionTag();
    final offstage = !item.isShowSuspension;
    final nextTag = nextItem != null ? nextItem.getSuspensionTag() : "";
    bool isSameTag = tag == nextTag;
    return Column(
      children: <Widget>[
        if (isShowingTag) Offstage(offstage: offstage, child: buildHeader(tag)),
        ColoredBox(
          color: colorWhite,
          child: ContactCard(
            key: ValueKey(item.user.uid),
            user: item.user,
            subTitle: UserUtils.onlineStatus(item.user.lastOnline),
            withCustomBorder: (isShowingTag && isSameTag),
            isCalling: false,
            onTap: () async {
              controller.onSend(
                null,
                isSendContact: true,
                context: context,
                user: item.user,
              );
            },
          ),
        ),
      ],
    );
  }

  /// create alphabet bar
  Widget buildHeader(String tag) => Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        alignment: Alignment.centerLeft,
        child: Text(
          tag,
          style: jxTextStyle.textStyle14(color: colorTextSecondary),
        ),
      );
}
