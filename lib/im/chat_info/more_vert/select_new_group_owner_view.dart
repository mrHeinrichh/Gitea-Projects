import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/views/contact/components/contact_card.dart';

import 'package:jxim_client/im/chat_info/more_vert/group_new_group_ower_controller.dart';

class SelectNewGroupOwnerView extends StatelessWidget {
  final Group? group;
  final List<User>? membersList;

  const SelectNewGroupOwnerView({
    super.key,
    required this.group,
    required this.membersList,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: SelectNewGroupOwnerController(group, membersList),
      builder: (SelectNewGroupOwnerController controller) {
        return SafeArea(
          bottom: false,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.94,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              color: ImColor.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                topLeft: Radius.circular(12),
              ),
            ),
            child: Obx(
              () => Column(
                children: <Widget>[
                  Container(
                    height: 60,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0XFFF3F3F3),
                    ),
                    child: NavigationToolbar(
                      leading: OpacityEffect(
                        child: SizedBox(
                          width: 70,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                objectMgr.loginMgr.isDesktop
                                    ? Get.back(id: 1)
                                    : Get.back();
                              },
                              behavior: HitTestBehavior.translucent,
                              child: Text(
                                localized(buttonCancel),
                                style:
                                    jxTextStyle.textStyle17(color: themeColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                      middle: Text(
                        localized(choseNewGroupOwner),
                        style: jxTextStyle.textStyleBold17(
                          fontWeight: MFontWeight.bold6.value,
                        ),
                      ),
                    ),
                  ),
                  ColoredBox(
                    color: const Color(0XFFF3F3F3),
                    child: Padding(
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: SvgPicture.asset(
                                'assets/svgs/close_round_icon.svg',
                                width: 20,
                                height: 20,
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Divider(
                    color: colorTextPrimary.withOpacity(0.2),
                    thickness: 0.33,
                    height: 1,
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
                                      controller.azFilterList.length >
                                              (index + 1)
                                          ? controller.azFilterList[index + 1]
                                          : null;
                                  return _buildListItem(
                                    context,
                                    item,
                                    nextItem,
                                    controller,
                                  );
                                },
                                showIndexBar: controller.searchFocus.hasFocus ||
                                    controller.searchParam.isNotEmpty,
                                indexBarOptions: IndexBarOptions(
                                  textStyle: jxTextStyle.textStyleBold10(
                                      color: themeColor),
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
          ),
        );
      },
    );
  }

  /// create contact card
  Widget _buildListItem(
    BuildContext context,
    AZItem item,
    nextItem,
    SelectNewGroupOwnerController controller,
  ) {
    final user = controller.userList
        .where((element) => element?.uid == item.user.uid)
        .firstOrNull;

    return OverlayEffect(
      child: Column(
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => controller.onClickUser(user),
            child: IgnorePointer(
              child: ContactCard(
                key: ValueKey(user?.uid),
                user: user!,
                subTitle: UserUtils.onlineStatus(user.lastOnline),
                withCustomBorder: true,
                isCalling: false,
                leftPadding: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
