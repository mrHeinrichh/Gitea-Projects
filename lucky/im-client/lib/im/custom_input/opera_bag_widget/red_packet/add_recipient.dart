import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/object/azItem.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/views/wallet/components/fullscreen_width_button.dart';
import '../../../../utils/format_time.dart';
import '../../../../utils/theme/text_styles.dart';
import '../../../../views/component/new_appbar.dart';
import '../../../../views/component/searching_app_bar.dart';

class AddRecipient extends GetView<RedPacketController> {
  const AddRecipient({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: backgroundColor,
        appBar: PreferredSize(
          preferredSize: controller.isSearching.value
              ? const Size.fromHeight(0)
              : Size.fromHeight(52.w),
          child: PrimaryAppBar(
            bgColor: Colors.transparent,
            onPressedBackBtn: () {
              if (controller.isSearching.value) {
                controller.clearSearching();
                controller.searchFocus.unfocus();
              }
              Get.back();
            },
            titleWidget: Text(
              localized(addRecipients),
              style: jxTextStyle.appTitleStyle(),
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(
                top: 8,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              child: SearchingAppBar(
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
                      controller.onSearch();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SvgPicture.asset(
                        'assets/svgs/close_round_icon.svg',
                        width: 20,
                        height: 20,
                        color: JXColors.iconSecondaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: controller.selectedRecipients.length > 0 ? 90.w : 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0.w,
                  vertical: 8.0.w,
                ),
                decoration: BoxDecoration(
                  border: customBorder,
                ),
                child: controller.selectedRecipients.length > 0
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        controller: controller.selectedMembersController,
                        physics: const ClampingScrollPhysics(),
                        itemCount: controller.selectedRecipients.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Stack(
                            key: ValueKey(
                              controller.selectedRecipients[index].uid,
                            ),
                            children: <Widget>[
                              Container(
                                width: 50.w,
                                margin: EdgeInsets.only(right: 12.w, top: 5.w),
                                child: Column(
                                  children: <Widget>[
                                    CustomAvatar(
                                      uid: controller
                                          .selectedRecipients[index].uid,
                                      size: 48.w,
                                      headMin: Config().headMin,
                                    ),
                                    NicknameText(
                                      uid: controller
                                          .selectedRecipients[index].uid,
                                      fontSize: 12.sp,
                                    ),
                                  ],
                                ),
                              ),

                              /// Delete Button
                              Positioned(
                                top: 4.0,
                                right: 10.0,
                                child: GestureDetector(
                                  onTap: () => controller.onSelect(
                                    null,
                                    controller.selectedRecipients[index],
                                  ),
                                  child: Container(
                                    width: 20.w,
                                    height: 20.w,
                                    decoration: BoxDecoration(
                                      color: dividerColor,
                                      borderRadius: BorderRadius.circular(20.w),
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: systemColor,
                                      size: 16.w,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      )
                    : null,
              ),
            ),

            /// Contact List
            Expanded(
              child: AzListView(
                noResultFound: localized(noResultFound),
                data: controller.azFilterList,
                itemCount: controller.azFilterList.length,
                itemBuilder: (context, index) {
                  final item = controller.azFilterList[index];
                  return _buildListItem(context, item);
                },
                showIndexBar: controller.isSearching.value,
              ),
            ),

            /// Button
            Container(
              color: surfaceBrightColor,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: FullScreenWidthButton(
                title: localized(buttonNext),
                fontSize: 14,
                fontWeight: MFontWeight.bold5.value,
                buttonColor: controller.selectedRecipients.length > 0
                    ? controller.themedColor.value
                    : controller.themedColor.value.withOpacity(0.2),
                onTap: controller.selectedRecipients.length > 0
                    ? () {
                        Navigator.pop(context);
                        controller.calculateTotalTransfer();
                      }
                    : null,
              ),
            ),
          ],
        ),
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
      children: <Widget>[
        Offstage(offstage: offstage, child: buildHeader(tag)),
        GestureDetector(
          onTap: () {
            controller.onSelect(
              !controller.selectedRecipients.contains(user),
              // Toggle the selected state
              user,
            );
          },
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(
                // left: 16,
                // right: 16,
                // top: 8,
                // bottom: 8,
                ),
            child: Row(
              children: [
                /// CheckBox
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Checkbox(
                      value: controller.selectedRecipients.contains(user),
                      onChanged: null,
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return accentColor;
                        }
                        return Colors.white;
                      }),
                      side: MaterialStateBorderSide.resolveWith(
                          (Set<MaterialState> states) {
                        return const BorderSide(
                            width: 1.5, color: JXColors.outlineColor);
                      }),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0.w),
                      ),
                    ),
                  ),
                ),

                /// Contact Info
                Expanded(
                  child: Row(
                    children: <Widget>[
                      CustomAvatar(
                        key: ValueKey(user?.uid),
                        uid: user!.uid,
                        size: 40,
                        headMin: Config().headMin,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(
                            top: 12,
                            bottom: 12,
                            left: 12,
                            right: 32,
                          ),
                          decoration: BoxDecoration(
                            border: customBorder,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              NicknameText(
                                key: ValueKey(user.uid),
                                uid: user.uid,
                                isTappable: false,
                                fontSize: MFontSize.size16.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                FormatTime.formatTimeFun(user.lastOnline),
                                style: jxTextStyle.textStyle12(
                                  color: JXColors.secondaryTextBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// create alphabet bar
  Widget buildHeader(String tag) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
        alignment: Alignment.centerLeft,
        child: Text(
          '$tag',
          softWrap: false,
          style: jxTextStyle.textStyleBold14(),
        ),
      );
}
