import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/group/group_invite/group_invite_link_controler.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/group_add_member_controller.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/share_link_bottom_sheet.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/search_overlay.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';

class GroupAddMemberView extends GetView<GroupAddMemberController> {
  const GroupAddMemberView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CustomBottomSheetContent(
        title: localized(
          controller.isMultiplePick.value
              ? chatInfoAddMembers
              : groupSelectAMember,
        ),
        showCancelButton: true,
        onCancelClick: () {
          Get.back(id: objectMgr.loginMgr.isDesktop ? 1 : null);
        },
        trailing: CustomTextButton(
          isDisabled: !(controller.isMultiplePick.value &&
              controller.selectedUser.isNotEmpty),
          localized(buttonDone),
          onClick: () {
            if (controller.selectedUser.isNotEmpty) {
              controller.nextButton();
            }
          },
        ),
        middleChild: Column(
          children: <Widget>[
            CustomInputTags(
              selectedUsers: controller.selectedUser,
              scrollController: controller.selectedUsersController,
              searchController: controller.searchController,
              hintText: localized(whoYouWouldLikeToInvite),
              onSearchChanged: controller.onSearchChanged,
              onUserTagTap: (index) {
                controller.onSelect(controller.selectedUser[index]);
              },
              onSearchTap: () {
                controller.isSearching.value = true;
              },
            ),

            /// Contact List
            Obx(
              () => Expanded(
                child: Container(
                  width: double.infinity,
                  color: colorSurface,
                  child: (controller.azFilterList.isNotEmpty)
                      ? Stack(
                          children: [
                            NotificationListener<ScrollNotification>(
                              onNotification:
                                  (ScrollNotification notification) {
                                if (notification is ScrollStartNotification) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                }
                                return false;
                              },
                              child: AzListView(
                                listHeader: _buildShareLinkListTile(context),
                                noResultFound: localized(noResultFound),
                                data: controller.azFilterList,
                                itemCount: controller.azFilterList.length,
                                itemBuilder: (context, index) {
                                  final item = controller.azFilterList[index];
                                  final nextItem =
                                      controller.azFilterList.length >
                                              (index + 1)
                                          ? controller.azFilterList[index + 1]
                                          : null;
                                  return _buildListItem(
                                      context, item, nextItem);
                                },
                                showIndexBar: controller.searchFocus.hasFocus ||
                                    controller.searchParam.isNotEmpty,
                                indexBarOptions: IndexBarOptions(
                                  textStyle: jxTextStyle.tinyText(
                                      fontWeight: MFontWeight.bold5.value,
                                      color: themeColor),
                                ),
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                              ),
                            ),

                            /// search overlay
                            Obx(() {
                              return SearchOverlay(
                                isVisible: controller.isSearching.value &&
                                    controller.searchParam.isEmpty,
                                onTapCallback: () {
                                  controller.isSearching.value = false;
                                },
                              );
                            }),
                          ],
                        )
                      : Column(
                          children: [
                            _buildShareLinkListTile(context),
                            const SizedBox(height: 32),
                            Text(
                              localized(noUserFound),
                              style: jxTextStyle.textStyleBold17(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              localized(noUserFoundDescription),
                              textAlign: TextAlign.center,
                              style: jxTextStyle.textStyle17(),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomListTile _buildShareLinkListTile(BuildContext context) {
    return CustomListTile(
      leading: Container(
        width: 40,
        alignment: Alignment.center,
        child: CustomImage(
          'assets/svgs/invite_link_outlined.svg',
          size: 24,
          color: themeColor,
        ),
      ),
      text: localized(inviteGroupViaLink),
      textColor: themeColor,
      onClick: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: colorOverlay40,
          builder: (BuildContext context) {
            Get.put(GroupInviteLinkController());
            return const ShareLinkBottomSheet();
          },
        ).then((_) => Get.delete<GroupInviteLinkController>());
      },
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
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  /// CheckBox
                  Obx(
                    () => Visibility(
                      visible: controller.isMultiplePick.value,
                      child: Padding(
                        padding: EdgeInsets.only(right: objectMgr.loginMgr.isDesktop ? 0 : 8),
                        child: CheckTickItem(
                          isCheck: controller.selectedUser.contains(user),
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
                        leftPadding: 0,
                      ),
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
  Widget buildHeader(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 30,
      color: colorBackground,
      alignment: Alignment.centerLeft,
      child: Text(
        tag,
        style: jxTextStyle.textStyle14(color: colorTextSecondary),
      ),
    );
  }
}
