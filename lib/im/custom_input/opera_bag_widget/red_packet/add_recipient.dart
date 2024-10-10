import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';

class AddRecipient extends GetView<RedPacketController> {
  const AddRecipient({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheetContent(
      title: localized(addRecipients),
      showCancelButton: true,
      onCancelClick: () {
        if (controller.isSearching.value) {
          controller.clearSearching();
        }
        Get.back();
      },
      trailing: Obx(
        () => CustomTextButton(
          localized(buttonDone),
          isDisabled: controller.selectedRecipients.isEmpty,
          onClick: () {
            controller.calculateTotalTransfer();
            Get.back();
          },
        ),
      ),
      useBottomSafeArea: false,
      middleChild: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CustomDivider(),

          /// Search Bar
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              controller.searchFocus.requestFocus();
              controller.isSearching(true);
            },
            child: Obx(
              () => AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 40,
                    maxHeight: 120,
                  ),
                  padding: const EdgeInsets.only(left: 16),
                  child: SingleChildScrollView(
                    controller: controller.selectedMembersController,
                    physics: const ClampingScrollPhysics(),
                    child: Wrap(
                      children: [
                        ...List.generate(
                          controller.selectedRecipients.length,
                          (index) => GestureDetector(
                            onTap: () {
                              if (controller.highlightMember.value !=
                                  controller.selectedRecipients[index].uid) {
                                controller.highlightMember.value =
                                    controller.selectedRecipients[index].uid;
                              } else {
                                controller.onSelect(
                                  null,
                                  controller.selectedRecipients[index],
                                );
                              }
                            },
                            child: _buildUserTag(
                              controller.selectedRecipients[index].uid,
                              controller.highlightMember.value ==
                                  controller.selectedRecipients[index].uid,
                            ),
                          ),
                        ),
                        IntrinsicWidth(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: TextField(
                              contextMenuBuilder: textMenuBar,
                              controller: controller.searchController,
                              focusNode: controller.searchFocus,
                              onChanged: controller.onSearchChanged,
                              cursorRadius: const Radius.circular(2),
                              cursorColor: themeColor,
                              style: TextStyle(
                                fontSize: MFontSize.size14.value,
                                color: colorTextPrimary,
                                decorationThickness: 0,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                hintText: localized(contactSearchHint),
                                hintStyle: jxTextStyle.textStyleBold14(
                                  color: colorTextPlaceholder,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const CustomDivider(),

          /// Contact List
          Obx(
            () => (controller.azFilterList.isNotEmpty)
                ? Expanded(
                    child: AzListView(
                      noResultFound: localized(noResultFound),
                      data: controller.azFilterList,
                      itemCount: controller.azFilterList.length,
                      itemBuilder: (context, index) {
                        final item = controller.azFilterList[index];
                        return _buildListItem(context, item);
                      },
                      showIndexBar: controller.isSearching.value ||
                          controller.searchParam.isNotEmpty,
                      indexBarData: controller.filterIndexBar(),
                      indexBarItemHeight: (400 / 28),
                      indexBarHeight: MediaQuery.of(context).size.height * 0.95,
                      indexBarOptions: IndexBarOptions(
                        textStyle: TextStyle(
                          color: themeColor,
                          fontSize: 11,
                          fontWeight: MFontWeight.bold5.value,
                        ),
                      ),
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewPadding.bottom,
                      ),
                    ),
                  )
                : const SearchEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTag(int uid, bool isSelected) {
    return Container(
      key: ValueKey(uid),
      margin: const EdgeInsets.only(top: 8, right: 4),
      constraints: const BoxConstraints(maxWidth: 150, minHeight: 24),
      padding: const EdgeInsets.fromLTRB(1, 1, 8, 1),
      decoration: ShapeDecoration(
        color: isSelected ? themeColor : colorBorder,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isSelected
              ? const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.close,
                    color: colorWhite,
                    size: 16,
                  ),
                )
              : CustomAvatar.normal(
                  uid,
                  size: 22,
                  headMin: Config().headMin,
                ),
          const SizedBox(width: 4),
          Flexible(
            child: NicknameText(
              uid: uid,
              fontSize: MFontSize.size14.value,
              overflow: TextOverflow.ellipsis,
              isTappable: false,
              color: isSelected ? colorWhite : colorTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// create alphabet bar
  Widget _buildHeader(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        tag,
        style: jxTextStyle.textStyle13(color: colorTextSecondary),
      ),
    );
  }

  /// create contact card
  Widget _buildListItem(BuildContext context, AZItem item) {
    final tag = item.getSuspensionTag();
    final offstage = !item.isShowSuspension;
    final user = controller.filterList
        .where((element) => element.uid == item.user.uid)
        .firstOrNull;

    return Column(
      key: ValueKey(user!.uid),
      children: <Widget>[
        Offstage(offstage: offstage, child: _buildHeader(tag)),
        GestureDetector(
          onTap: () {
            if (user == null) return;
            controller.onSelect(
              !controller.selectedRecipients.contains(user),
              user,
            );
          },
          child: ForegroundOverlayEffect(
            child: ColoredBox(
              color: colorWhite,
              child: Row(
                children: [
                  /// CheckBox
                  Obx(
                    () => Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: CheckTickItem(
                        isCheck: controller.selectedRecipients.contains(user),
                      ),
                    ),
                  ),

                  /// Contact Info
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        CustomAvatar.user(
                          key: ValueKey(user.uid),
                          user,
                          size: 40,
                          headMin: Config().headMin,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(right: 20),
                            height: 48,
                            decoration: BoxDecoration(
                              border: offstage
                                  ? const Border(
                                      top: BorderSide(
                                        color: colorBorder,
                                        width: 1,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                NicknameText(
                                  key: ValueKey(user.uid),
                                  uid: user.uid,
                                  isTappable: false,
                                  fontSize: MFontSize.size17.value,
                                  fontWeight: MFontWeight.bold5.value,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  FormatTime.formatTimeFun(user.lastOnline),
                                  style: jxTextStyle.textStyle13(
                                    color: colorTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
