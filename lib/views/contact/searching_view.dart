import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/extension/extension_expand.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/contact/qr_code_dialog.dart';
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:jxim_client/views/contact/share_controller.dart';
import 'package:jxim_client/views/contact/share_view.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/loading/ball_circle_loading.dart';
import 'package:jxim_client/utils/loading/ball.dart';
import 'package:jxim_client/utils/loading/ball_style.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/views/contact/components/searching_result_list.dart';

class SearchingView extends GetView<SearchContactController> {
  const SearchingView({super.key});

  @override
  Widget build(BuildContext context) {
    Widget buildListTile({
      GestureTapCallback? onTap,
      required String icon,
      required String title,
      required String subtitle,
      bool withBorder = true,
    }) {
      return SettingItem(
        onTap: onTap,
        iconName: icon,
        iconColor: themeColor,
        title: title,
        subtitle: subtitle,
        withBorder: withBorder,
      );
    }

    Widget buildEmptyResult() {
      return Column(
        children: [
          Container(
            height: 30,
            width: double.infinity,
            color: colorBackground,
            padding: const EdgeInsets.only(left: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              localized(result),
              style: TextStyle(
                fontSize: 14,
                color: colorTextSecondary,
                fontWeight: MFontWeight.bold4.value,
              ),
            ),
          ),
          SearchEmptyState(
            searchText: controller.searchParam.value,
            emptyMessage: localized(
              oppsNoResultFoundTryNewSearch,
              params: [(controller.searchParam.value)],
            ),
          ),
        ],
      );
    }

    return Obx(() {
      return Scaffold(
        backgroundColor: colorBackground,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            children: [
              if (controller.isModalBottomSheet &&
                  !controller.isSearching.value)
                const SizedBox(height: 10),
              AnimatedContainer(
                margin: const EdgeInsets.only(bottom: 8),
                duration: const Duration(milliseconds: 100),
                height: controller.isSearching.value ? 0 : 44,
                child: PrimaryAppBar(
                  title: localized(addFriendTitle),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: Color(0x14121212),
                    ),
                  ),
                ),
                child: SearchingAppBar(
                  onTap: () => controller.isSearching(true),
                  onChanged: (value) {
                    controller.isSearchTyping(true);
                    controller.searchParam.value = value;
                  },
                  onCancelTap: () {
                    controller.searchFocus.unfocus();
                    controller.isSearching(false);
                    controller.searchController.clear();
                    controller.searchParam.value = '';
                  },
                  isSearchingMode: controller.isSearching.value,
                  hintText: searchBarPlaceHolder,
                  isAutoFocus: false,
                  focusNode: controller.searchFocus,
                  controller: controller.searchController,
                  suffixIcon: Visibility(
                    visible: controller.searchParam.value.isNotEmpty,
                    child: GestureDetector(
                      onTap: () {
                        controller.searchController.clear();
                        controller.searchParam.value = '';
                        controller.contactSearching();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
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
              AnimatedSize(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOutCubic,
                child: controller.isSearching.value
                    ? const SizedBox()
                    : Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        child: Column(
                          children: [
                            buildListTile(
                              onTap: () {
                                showQRCodeDialog(context);
                              },
                              icon: 'qrCode',
                              title: localized(newQRTitle),
                              subtitle: localized(searchMeQRSubTitle),
                            ),
                            buildListTile(
                              onTap: () => controller.scanQR(),
                              icon: 'scan_rounded',
                              title: localized(scanMe),
                              subtitle: localized(searchScanMeSubTitle),
                            ),
                            buildListTile(
                              onTap: () {
                                if (objectMgr.loginMgr.isDesktop) {
                                  Get.toNamed(RouteName.shareView);
                                } else {
                                  _showShareViewDialog(context);
                                }
                              },
                              icon: 'forward_icon',
                              title: localized(
                                shareHeyTalk,
                                params: [Config().appName],
                              ),
                              subtitle: localized(
                                shareHeyTalkDetails,
                                params: [Config().appName],
                              ),
                              withBorder: true,
                            ),
                            buildListTile(
                              onTap: () => controller.findContact(context),
                              icon: 'find_contacts_icon',
                              title: localized(findContacts),
                              subtitle: localized(connectFriendDesc),
                              withBorder: false,
                            ),
                          ],
                        ),
                      ),
              ),
              Visibility(
                visible: controller.isSearching.value,
                child: Expanded(
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    alignment: Alignment.topCenter,
                    child: controller.contactList.isEmpty &&
                            controller.usernameList.isEmpty
                        ? controller.isSearchTyping.value
                            ? Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: BallCircleLoading(
                                    radius: 10,
                                    ballStyle: BallStyle(
                                      size: 4,
                                      color: themeColor,
                                      ballType: BallType.solid,
                                      borderWidth: 2,
                                      borderColor: themeColor,
                                    ),
                                  ),
                                ),
                              )
                            : controller.searchController.text.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 60),
                                    child: Text(
                                      localized(contactToSearch),
                                      style: jxTextStyle.textStyleBold16(),
                                    ),
                                  )
                                : buildEmptyResult()
                        : SingleChildScrollView(
                            controller: controller.scrollController,
                            child: Column(
                              children: [
                                if (controller.contactList.isNotEmpty)
                                  SearchingResultList(
                                    controller.contactList,
                                    localized(phoneNumber),
                                    isUsername: false,
                                  ),
                                if (controller.usernameList.isNotEmpty)
                                  SearchingResultList(
                                    controller.usernameList,
                                    localized(homeUsername),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future _showShareViewDialog(BuildContext context) {
    return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        Get.lazyPut(() => ShareController());
        return const ShareView();
      },
    ).whenComplete(() => Get.findAndDelete<ShareController>());
  }
}
