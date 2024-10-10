import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/end_to_end_encryption/friend_list_bottom_sheet/friend_list_bottom_sheet_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/object/az_item.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';

class FriendListBottomSheetView extends StatelessWidget {
  const FriendListBottomSheetView({
    super.key,
    required this.controller,
    required this.callback,
  });

  final FriendListBottomSheetController controller;
  final Function(User) callback;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
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
              height: !controller.isSearching.value ? 58 : 0,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: OpacityEffect(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(localized(cancel),
                              style:
                                  jxTextStyle.textStyle17(color: themeColor)),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '选择好友',
                      style: jxTextStyle.appTitleStyle(color: colorTextPrimary),
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
          const CustomDivider(),
          Expanded(
            child: Obx(() => controller.userList.isEmpty
                ? const Text("No data")
                : controller.azFilterList.isEmpty
                    ? SearchEmptyState(
                        searchText: controller.searchParam.value,
                      )
                    : AzListView(
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
                      )),
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
    return Container(
      color: Colors.white,
      child: Column(
        children: <Widget>[
          Offstage(offstage: offstage, child: buildHeader(tag)),
          GestureDetector(
            onTap: () {
              callback(
                user,
              );
              Get.back();
            },
            child: OverlayEffect(
              child: Row(
                children: <Widget>[
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: CustomAvatar.user(
                        key: ValueKey(user.uid),
                        user,
                        size: 40,
                        headMin: Config().headMin,
                      ),
                    ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 20,
                      ),
                      height: 50,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        border: offstage
                            ? Border(
                                top: BorderSide(
                                  color: colorTextPrimary.withOpacity(0.2),
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
                            key: ValueKey(user!.uid),
                            uid: user.uid,
                            isTappable: false,
                            fontSize: MFontSize.size16.value,
                            fontWeight: MFontWeight.bold6.value,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            UserUtils.onlineStatus(user.lastOnline),
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
