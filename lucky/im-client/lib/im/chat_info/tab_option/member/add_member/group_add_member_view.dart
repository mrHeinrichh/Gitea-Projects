import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/group_add_member_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/azItem.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import '../../../../../utils/theme/text_styles.dart';
import '../../../../../utils/user_utils.dart';
import '../../../../../views/component/new_appbar.dart';
import '../../../../../views/component/searching_app_bar.dart';
import '../../../../../views/contact/components/contact_card.dart';

class GroupAddMemberView extends GetView<GroupAddMemberController> {
  const GroupAddMemberView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: backgroundColor,
        appBar: PrimaryAppBar(
          bgColor: Colors.transparent,
          title: controller.isMultiplePick.value
              ? localized(chatInfoAddMembers)
              : localized(groupSelectAMember),
          trailing: [
            Obx(
              () => Visibility(
                visible: controller.isMultiplePick.value &&
                    controller.selectedUser.length > 0,
                child: GestureDetector(
                  onTap: () {
                    if (controller.selectedUser.length > 0) {
                      controller.nextButton();
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      localized(buttonNext),
                      style: jxTextStyle
                          .textStyle17(color: accentColor)
                          .copyWith(height: 1.2),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
          onPressedBackBtn:
              objectMgr.loginMgr.isDesktop ? () => Get.back(id: 1) : null,
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
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
                        color: JXColors.black48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: controller.isMultiplePick.value,
              child: Obx(
                () => AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: controller.selectedUser.length > 0 ? 90 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: controller.selectedUser.length > 0
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            controller: controller.selectedUsersController,
                            physics: const ClampingScrollPhysics(),
                            itemCount: controller.selectedUser.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Stack(
                                key: ValueKey(
                                  controller.selectedUser[index].uid,
                                ),
                                children: <Widget>[
                                  Container(
                                    width: 70,
                                    margin: const EdgeInsets.only(
                                        right: 10, top: 5),
                                    child: Column(
                                      children: <Widget>[
                                        CustomAvatar(
                                          uid: controller
                                              .selectedUser[index].uid,
                                          size: 40,
                                        ),
                                        NicknameText(
                                          uid: controller
                                              .selectedUser[index].uid,
                                          isTappable: false,
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// Delete Button
                                  Positioned(
                                    top: 5.0,
                                    right: 20.0,
                                    child: GestureDetector(
                                      onTap: () => controller.onSelect(
                                        controller.selectedUser[index],
                                      ),
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: dividerColor,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.black,
                                          size: 16,
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
              ),
            ),

            /// Contact List
            Obx(
              () => Expanded(
                child: Container(
                  color: Colors.white,
                  width: MediaQuery.of(context).size.width,
                  child: (controller.azFilterList.isNotEmpty)
                      ? AzListView(
                          noResultFound: localized(noResultFound),
                          data: controller.azFilterList,
                          itemCount: controller.azFilterList.length,
                          itemBuilder: (context, index) {
                            final item = controller.azFilterList[index];
                            final nextItem =
                                controller.azFilterList.length > (index + 1)
                                    ? controller.azFilterList[index + 1]
                                    : null;
                            return _buildListItem(context, item, nextItem);
                          },
                          showIndexBar: controller.searchFocus.hasFocus ||
                              controller.searchParam.isNotEmpty,
                          indexBarOptions: IndexBarOptions(
                            textStyle:
                                jxTextStyle.textStyleBold10(color: accentColor),
                          ),
                        )
                      : Center(
                          child: Text(
                            localized(addMemberNothingHere),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// create contact card
  Widget _buildListItem(BuildContext context, AZItem item, nextItem) {
    final tag = item.getSuspensionTag();
    final nextTag = nextItem != null ? nextItem.getSuspensionTag() : "";
    final bool isSameTag = tag == nextTag;
    final offstage = !item.isShowSuspension;
    final user = controller.userList
        .where((element) => element?.uid == item.user.uid)
        .firstOrNull;

    return OverlayEffect(
      child: Column(
        children: <Widget>[
          Offstage(offstage: offstage, child: buildHeader(tag)),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => controller.onClickUser(user),
            child: Row(
              children: [
                /// CheckBox
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Visibility(
                      visible: controller.isMultiplePick.value,
                      child: Container(
                        width: 30,
                        child: Checkbox(
                          value: controller.selectedUser.contains(user),
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
                              width: 1.5,
                              color: JXColors.outlineColor,
                            );
                          }),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  ),
                ),

                /// Contact Info
                Expanded(
                  child: IgnorePointer(
                    child: ContactCard(
                      key: ValueKey(user?.uid),
                      user: user!,
                      subTitle: UserUtils.onlineStatus(user.lastOnline),
                      withCustomBorder: isSameTag,
                      isCalling: false,
                      leftPadding: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// create alphabet bar
  Widget buildHeader(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      height: 30,
      color: JXColors.bgPrimaryColor,
      alignment: Alignment.centerLeft,
      child: Text(
        '$tag',
        softWrap: false,
        style: jxTextStyle.textStyle14(
          color: JXColors.secondaryTextBlack,
        ),
      ),
    );
  }
}
