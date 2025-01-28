import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/component.dart';

class DesktopCreateGroup extends GetView<CreateGroupBottomSheetController> {
  const DesktopCreateGroup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: localized(createNewGroup),
        onPressedBackBtn: () => Get.back(id: 1),
        trailing: [
          Obx(
            () => CustomTextButton(
              localized(buttonNext),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              isDisabled: controller.selectedMembers.isEmpty,
              onClick: () => Get.toNamed('confirmCreateGroup', id: 1),
            ),
          ),
        ],
      ),
      body: Container(
        color: colorBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: SingleChildScrollView(
                  controller: controller.selectedMembersController,
                  physics: const ClampingScrollPhysics(),
                  child: Wrap (
                    crossAxisAlignment: WrapCrossAlignment.center,
                      children: [

                        /// selected user list
                        ...List.generate(
                      controller.selectedMembers.length,
                      (index) => Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4.0, vertical: 2.0),
                            margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => controller.onSelect(context, null,
                                controller.selectedMembers[index],),
                              child: Container(
                                height: 10,
                                width: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.60),
                                ),
                                child: SvgPicture.asset(
                                  'assets/svgs/close_thick_outlined_icon.svg',
                                  color: themeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            NicknameText(
                              color: Colors.white,
                              uid: controller
                                  .selectedMembers[index].uid,
                              fontSize: 13,
                              isTappable: false,
                            ),
                          ],
                        ),
                      ),
                    ),

                        /// Search Field
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10.0),
                          child: IntrinsicWidth(
                            child: TextField(
                              contextMenuBuilder: textMenuBar,
                              onTap: () => controller.isSearching(true),
                              controller: controller.searchController,
                              onChanged: controller.onSearchChanged,
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: localized(whoYouWouldLikeToInvite),
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: colorTextPlaceholder,
                                ),
                              ),
                            ),
                          ),
                        ),
                  ]),
                ),
              ),
            ),

            const CustomDivider(thickness: 0.5),

          /// Contact List
          Obx(
            () => (controller.azFilterList.isNotEmpty)
                ? Expanded(
                    child: Container(
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
                        /// alphabet index bar
                        showIndexBar: controller.isSearching.value ||
                            controller.searchParam.isNotEmpty,
                        indexBarData: controller.filterIndexBar(),
                        indexBarOptions: IndexBarOptions(
                          textStyle: jxTextStyle.tinyText(
                            color: themeColor,
                            fontWeight: MFontWeight.bold5.value,
                          ),
                        ),
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
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                /// CheckBox
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.fromLTRB(8,16,8,16),
                    child: CheckTickItem(
                      isCheck: controller.selectedMembers.contains(user),
                      circleSize: 16,
                      circlePaddingValue: 2,
                      )
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
                          size: 32,
                        ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
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
                                fontSize: 14,
                              ),
                              Text(
                                UserUtils.onlineStatus(user?.lastOnline ?? 0),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: UserUtils.onlineStatus(
                                              user?.lastOnline ?? 0) ==
                                          localized(chatOnline)
                                      ? themeColor
                                      : colorTextSecondary,
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
          style: TextStyle(
              fontSize: 12,
              color: colorTextPrimary.withOpacity(0.44),
              fontWeight: FontWeight.w400,
          ),
        ),
      );
}
