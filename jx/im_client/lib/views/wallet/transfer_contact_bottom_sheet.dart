import 'dart:collection';

import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';
import 'package:jxim_client/views/wallet/controller/transfer_controller.dart';

class TransferContactBottomSheet extends StatelessWidget {
  const TransferContactBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final TransferController controller = Get.find<TransferController>();
    return Container(
      height: ObjectMgr.screenMQ!.size.height * 0.95,
      decoration: const BoxDecoration(
        color: colorBackground,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12),
          topLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Obx(
            () => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: !controller.isSearching.value ? 52 : 0,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: OpacityEffect(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            localized(cancel),
                            style: jxTextStyle.textStyle17(
                              color: themeColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      localized(contact),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: MFontWeight.bold6.value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 8,
              top: 8,
            ),
            child: Obx(() {
              return SearchingAppBar(
                onTap: () => controller.isSearching(true),
                onChanged: controller.onSearchChanged,
                onCancelTap: () {
                  controller.searchFocus.unfocus();
                  controller.clearSearching();
                },
                isSearchingMode: controller.isSearching.value,
                isAutoFocus: false,
                focusNode: controller.searchFocus,
                controller: controller.searchController,
                suffixIcon: Visibility(
                  visible: controller.searchParam.value.isNotEmpty,
                  child: GestureDetector(
                    onTap: () {
                      controller.searchController.clear();
                      controller.searchParam.value = '';
                      controller.search();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SvgPicture.asset(
                        'assets/svgs/close_round_icon.svg',
                        width: 20,
                        height: 20,
                        color: colorTextSupporting,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Container(
            height: 1.h,
            color: colorBackground6,
          ),
          Expanded(
            child: Obx(
              () => controller.azFriendList.isEmpty
                  ? SearchEmptyState(
                      searchText: controller.searchController.text,
                      emptyMessage: localized(
                        oppsNoResultFoundTryNewSearch,
                        params: [(controller.searchController.text)],
                      ),
                    )
                  : Container(
                      color: Colors.white,
                      child: Obx(
                        () => AzListView(
                          noResultFound: localized(noResultFound),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          data: controller.azFriendList,
                          indexBarData: _filterIndexBar(
                            controller.azFriendList,
                            true.obs.value,
                          ),
                          itemCount: controller.azFriendList.length,
                          itemBuilder: (context, index) {
                            final item = controller.azFriendList[index];
                            final next =
                                controller.azFriendList.length > (index + 1)
                                    ? controller.azFriendList[index + 1]
                                    : null;
                            return _buildListItem(
                              item,
                              next,
                              index == (controller.azFriendList.length - 1),
                              // isShowingTag!.value,
                              context,
                              controller,
                            );
                          },
                          showIndexBar: controller.isSearching.value,
                          indexBarOptions: IndexBarOptions(
                            textStyle:
                                jxTextStyle.textStyleBold10(color: themeColor),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
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
    TransferController controller,
  ) {
    final tag = item.getSuspensionTag();
    final nextTag = nextItem != null ? nextItem.getSuspensionTag() : "";
    bool isSameTag = tag == nextTag;
    final offstage = !item.isShowSuspension;
    // final CallLogController callLogController = Get.find<CallLogController>();

    return Column(
      children: <Widget>[
        if (true.obs.value)
          Offstage(
            offstage: offstage,
            child: buildHeader(tag),
          ),
        ContactCard(
          key: ValueKey(item.user.uid),
          user: item.user,
          subTitle: (item.user.lastOnline != 0)
              ? FormatTime.formatTimeFun(item.user.lastOnline)
              : "",
          subTitleColor: (FormatTime.isOnline(item.user.lastOnline))
              ? themeColor
              : colorTextSecondary,
          withCustomBorder: (true.obs.value && isSameTag),
          onTap: () {
            ///這邊取得item.user.uid
            controller.setToUserText(
              item.user.uid,
              item.user.nickname,
              item.user.countryCode,
              item.user.contact,
            );
            pdebug('ffff:::${item.user.uid}');
            Navigator.pop(context);
          },
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
        style: jxTextStyle.textStyle14(
          color: colorTextSecondary,
        ),
      ),
    );
  }
}
