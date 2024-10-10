import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';

import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';

class DesktopCreateGroup extends GetView<CreateGroupBottomSheetController> {
  const DesktopCreateGroup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 0.0,
            ),
            child: Row(
              children: [
                OpacityEffect(
                  child: GestureDetector(
                    onTap: () {
                      Get.back(id: 1);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.only(left: 10),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/svgs/Back.svg',
                            width: 18,
                            height: 18,
                            color: themeColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            localized(buttonBack),
                            style: TextStyle(
                              fontSize: 13,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      localized(createNewGroup),
                      style: TextStyle(
                        fontSize: 13,
                        color: themeColor,
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => GestureDetector(
                    onTap: () {
                      if (controller.selectedMembers.isNotEmpty) {
                        Get.toNamed('confirmCreateGroup', id: 1);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        localized(buttonNext),
                        style: TextStyle(
                          fontSize: 13,
                          color: (controller.selectedMembers.isNotEmpty)
                              ? themeColor
                              : themeColor.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const CustomDivider(),

          /// selected user list
          Obx(
            () => AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: controller.selectedMembers.isNotEmpty ? 42 : 0,
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 9,
                  bottom: 9,
                ),
                child: controller.selectedMembers.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        controller: controller.selectedMembersController,
                        physics: const ClampingScrollPhysics(),
                        itemCount: controller.selectedMembers.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Stack(
                            key: ValueKey(
                              controller.selectedMembers[index].uid,
                            ),
                            children: <Widget>[
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: colorTextPrimary.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Row(
                                  children: [
                                    CustomAvatar.user(
                                      controller.selectedMembers[index],
                                      size: 22,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 4, bottom: 4, left: 4, right: 8),
                                      child: NicknameText(
                                        uid: controller
                                            .selectedMembers[index].uid,
                                        fontSize: MFontSize.size14.value,
                                        isTappable: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => controller.onSelect(
                                          context,
                                          null,
                                          controller.selectedMembers[index],
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.only(
                                            left: 6,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 4,
                                            bottom: 4,
                                            left: 4,
                                            right: 8),
                                        child: NicknameText(
                                          color: Colors.white,
                                          uid: controller
                                              .selectedMembers[index].uid,
                                          fontSize: MFontSize.size14.value,
                                          isTappable: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : null,
              ),
            ),
          ),

          /// Search Bar
          Container(
            color: colorBackground,
            padding:
                const EdgeInsets.only(top: 40, left: 40, right: 70, bottom: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                contextMenuBuilder: textMenuBar,
                onTap: () => controller.isSearching(true),
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: localized(whoYouWouldLikeToInvite),
                    hintStyle: jxTextStyle.textStyle14(
                      color: colorTextSupporting,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16)),
              ),
            ),
          ),

          /// Contact List
          Obx(
            () => (controller.azFilterList.isNotEmpty)
                ? Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: const BoxDecoration(
                        color: colorBackground,
                      ),
                      child: AzListView(
                        noResultFound: localized(noResultFound),
                        data: controller.azFilterList,
                        itemCount: controller.azFilterList.length,
                        itemBuilder: (context, index) {
                          final item = controller.azFilterList[index];
                          return Container(
                              child: _buildListItem(context, item));
                        },
                        showIndexBar: controller.isSearching.value ||
                            controller.searchParam.isNotEmpty,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(
                        localized(noResultFound),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// create contact card
  Widget _buildListItem(BuildContext context, AZItem item) {
    final tag = item.getSuspensionTag();
    final offstage = !item.isShowSuspension;
    final user = controller.userList
        .where((element) => element.uid == item.user.uid)
        .firstOrNull;

    return Column(
      children: <Widget>[
        Offstage(offstage: offstage, child: buildHeader(tag)),
        GestureDetector(
          onTap: () {
            if (user == null) return;
            controller.onSelect(
              context,
              null,
              user,
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 30),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                /// CheckBox
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Checkbox(
                      value: controller.selectedMembers.contains(user),
                      onChanged: null,
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return themeColor;
                        }
                        return Colors.white;
                      }),
                      side: MaterialStateBorderSide.resolveWith(
                          (Set<MaterialState> states) {
                        return const BorderSide(width: 1.5, color: colorBorder);
                      }),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),

                /// Contact Info
                Expanded(
                  child: Row(
                    children: <Widget>[
                      if (user != null)
                        CustomAvatar.user(
                          key: ValueKey(user.uid),
                          user,
                          size: 40,
                        ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(
                            top: 12,
                            bottom: 12,
                            left: 12,
                            right: 20,
                          ),
                          decoration: BoxDecoration(
                            border: customBorder,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              NicknameText(
                                key: ValueKey(user?.uid),
                                uid: user?.uid ?? 0,
                                isTappable: false,
                                fontSize: MFontSize.size16.value,
                              ),
                              Text(
                                UserUtils.onlineStatus(user?.lastOnline ?? 0),
                                style: jxTextStyle.textStyle12(
                                  color: colorTextSecondary,
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
          tag,
          softWrap: false,
          style: jxTextStyle.textStyleBold14(),
        ),
      );
}
