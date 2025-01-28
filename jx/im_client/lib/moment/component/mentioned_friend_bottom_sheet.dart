import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/chat/create_chat/create_group_bottom_sheet_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/utils/user_utils.dart';

class MentionedFriendBottomSheet extends StatelessWidget {
  final CreateGroupBottomSheetController controller;
  final Function(List<User> user) confirmCallback;
  final Function() cancelCallback;
  final String title;
  final String placeHolder;

  const MentionedFriendBottomSheet({
    super.key,
    required this.controller,
    required this.confirmCallback,
    required this.cancelCallback,
    required this.title,
    required this.placeHolder,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: firstPage(context),
    );
  }

  Widget firstPage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Container(
        color: colorBackground,
        height: MediaQuery.of(context).size.height * 0.94,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomLeadingIcon(
                    buttonOnPressed: cancelCallback,
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: jxTextStyle.appTitleStyle(
                            color: colorTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      confirmCallback(controller.selectedMembers);
                      // Get.back();
                    },
                    child: OpacityEffect(
                      child: Container(
                        alignment: Alignment.centerRight,
                        width: 70,
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Text(
                          localized(buttonDone),
                          style: jxTextStyle.textStyle17(color: themeColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const CustomDivider(),

            /// Search Bar
            Obx(
              () => AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 40, maxHeight: 120),
                  padding: const EdgeInsets.only(
                    left: 16,
                  ),
                  child: SingleChildScrollView(
                    controller: controller.selectedMembersController,
                    physics: const ClampingScrollPhysics(),
                    child: Wrap(
                      // spacing: 8,
                      children: [
                        ...List.generate(
                          controller.selectedMembers.length,
                          (index) => GestureDetector(
                            onTap: () {
                              if (controller.highlightMember.value !=
                                  controller.selectedMembers[index].uid) {
                                controller.highlightMember.value =
                                    controller.selectedMembers[index].uid;
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                top: 8,
                                left: 0,
                                right: 8,
                              ),
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Stack(
                                key: ValueKey(
                                  controller.selectedMembers[index].uid,
                                ),
                                children: <Widget>[
                                  Container(
                                    // margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: colorTextPrimary.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomAvatar.user(
                                          controller.selectedMembers[index],
                                          size: 22,
                                          headMin: Config().headMin,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                            bottom: 4,
                                            left: 4,
                                            right: 8,
                                          ),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 116,
                                            ),
                                            child: NicknameText(
                                              uid: controller
                                                  .selectedMembers[index].uid,
                                              fontSize: MFontSize.size14.value,
                                              overflow: TextOverflow.ellipsis,
                                              isTappable: false,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Obx(
                                    () => Visibility(
                                      visible: controller
                                              .highlightMember.value ==
                                          controller.selectedMembers[index].uid,
                                      child: Positioned(
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(right: 0),
                                          constraints: const BoxConstraints(
                                            maxWidth: 150,
                                          ),
                                          child: GestureDetector(
                                            onTap: () => controller.onSelect(
                                              context,
                                              null,
                                              controller.selectedMembers[index],
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: themeColor,
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      left: 6,
                                                    ),
                                                    child: Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 4,
                                                      bottom: 4,
                                                      left: 4,
                                                      right: 8,
                                                    ),
                                                    child: Container(
                                                      constraints:
                                                          const BoxConstraints(
                                                        maxWidth: 116,
                                                      ),
                                                      child: NicknameText(
                                                        color: Colors.white,
                                                        uid: controller
                                                            .selectedMembers[
                                                                index]
                                                            .uid,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        fontSize: MFontSize
                                                            .size14.value,
                                                        isTappable: false,
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
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: TextField(
                              contextMenuBuilder: textMenuBar,
                              onTap: () => controller.isSearching(true),
                              controller: controller.searchController,
                              onChanged: controller.onSearchChanged,
                              cursorColor: themeColor,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: placeHolder,
                                hintStyle: jxTextStyle.textStyle14(
                                  color: colorTextSupporting,
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
                        indexBarHeight:
                            MediaQuery.of(context).size.height * 0.95,
                        indexBarOptions: IndexBarOptions(
                          textStyle: TextStyle(
                            color: themeColor,
                            fontSize: 10,
                            fontWeight: MFontWeight.bold5.value,
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
    return Container(
      color: Colors.white,
      child: Column(
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
            child: OverlayEffect(
              child: Row(
                children: [
                  /// CheckBox
                  Obx(
                    () => Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: CheckTickItem(
                        isCheck: controller.selectedMembers.contains(user),
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
                            headMin: Config().headMin,
                          ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(
                              // top: 12,
                              // bottom: 12,
                              left: 12,
                              right: 20,
                            ),
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              border: offstage
                                  ? Border(
                                      top: BorderSide(
                                        color:
                                            colorTextPrimary.withOpacity(0.2),
                                        width: 0.33,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                NicknameText(
                                  key: ValueKey(user?.uid ?? 0),
                                  uid: user?.uid ?? 0,
                                  isTappable: false,
                                  fontSize: MFontSize.size16.value,
                                  fontWeight: MFontWeight.bold6.value,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  UserUtils.onlineStatus(user?.lastOnline ?? 0),
                                  style: jxTextStyle.textStyle12(
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
        ],
      ),
    );
  }

  /// create alphabet bar
  Widget buildHeader(String tag) => Container(
        color: colorBackground,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        alignment: Alignment.centerLeft,
        height: 30,
        child: Text(
          tag,
          softWrap: false,
          style: jxTextStyle.textStyle14(color: colorTextSecondary),
        ),
      );
}
