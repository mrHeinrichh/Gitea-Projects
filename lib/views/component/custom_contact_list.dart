import 'dart:collection';

import 'package:azlistview/azlistview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CustomContactList extends StatelessWidget {
  const CustomContactList({
    super.key,
    required this.contactList,
    this.isCalling = false,
    this.header,
    this.footer,
    this.emptyState,
    required this.isSearching,
    required this.isShowIndexBar,
    required this.isShowingTag,
    this.itemScrollController,
  });

  final RxList<AZItem> contactList;
  final Widget? header;
  final Widget? footer;
  final Widget? emptyState;
  final bool isCalling;
  final bool isSearching;
  final RxBool isShowIndexBar;
  final RxBool isShowingTag;
  final ItemScrollController? itemScrollController;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AzListView(
        noResultFound: localized(noResultFound),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        listHeader: header,
        data: contactList,
        itemScrollController: itemScrollController,
        indexBarData: _filterIndexBar(contactList, isShowIndexBar.value),
        itemCount: contactList.length,
        itemBuilder: (context, index) {
          final item = contactList[index];
          final next =
              contactList.length > (index + 1) ? contactList[index + 1] : null;
          return _buildListItem(
            item,
            next,
            index == (contactList.length - 1),
            // isShowingTag!.value,
            context,
          );
        },
        showIndexBar: isSearching,
        listFooter: footer,
        emptyState: emptyState,
        indexBarOptions: IndexBarOptions(
          textStyle: jxTextStyle.textStyleBold10(color: themeColor),
        ),
      ),
    );
  }

  ///
  List<String> _filterIndexBar(List<AZItem> cList, bool isShow) {
    if (!isShow) {
      return [];
    }
    List<String> indexList = [];

    for (AZItem item in cList) {
      String tag = item.tag;
      bool startChar = tag.startsWith(RegExp(r'[a-zA-Z]'));
      if (startChar) {
        indexList.add(tag);
      }
    }
    List<String> resultList = LinkedHashSet<String>.from(indexList).toList();
    resultList.insert(0, '~');
    resultList.add('#');
    return resultList;
  }

  /// create contact card
  Widget _buildListItem(
    AZItem item,
    AZItem? nextItem,
    bool isLastIndex,
    // bool isShowingTag,
    BuildContext context,
  ) {
    final tag = item.getSuspensionTag();
    final nextTag = nextItem != null ? nextItem.getSuspensionTag() : "";
    bool isShowBorder =
        isShowingTag.value ? (tag == nextTag ? true : false) : true;
    final offstage = !item.isShowSuspension;
    final CallLogController callLogController = Get.find<CallLogController>();

    return Column(
      children: <Widget>[
        if (isShowingTag.value)
          Offstage(
            offstage: offstage,
            child: buildHeader(tag),
          ),
        ContactCard(
          key: ValueKey(item.user.uid),
          user: item.user,
          subTitle: objectMgr.onlineMgr.friendOnlineString[item.user.uid] ?? '',
          subTitleColor:
              objectMgr.onlineMgr.friendOnlineString[item.user.uid] ==
                      localized(chatOnline)
                  ? themeColor
                  : colorTextSecondary,
          withCustomBorder: isShowBorder,
          isCalling: isCalling,
          trailing: isCalling
              ? [
                  GestureDetector(
                    onTap: () {
                      if (item.user.deletedAt > 0) {
                        Toast.showToast(localized(userHasBeenDeleted));
                      } else {
                        Navigator.pop(context);
                        callLogController.showCallOptionPopup(
                          context,
                          item.user,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                      ),
                      child: SvgPicture.asset(
                        'assets/svgs/call_outline.svg',
                        color: item.user.deletedAt != 0
                            ? themeColor.withOpacity(0.3)
                            : themeColor,
                      ),
                    ),
                  ),
                ]
              : [],
        ),
      ],
    );
  }

  /// create alphabet bar
  Widget buildHeader(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 30,
      color: colorBackground,
      alignment: Alignment.centerLeft,
      child: Text(
        tag,
        softWrap: false,
        style: jxTextStyle.textStyle12(
          color: colorTextSecondary,
        ),
      ),
    );
  }
}