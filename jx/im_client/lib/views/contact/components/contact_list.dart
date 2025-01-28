import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/search_overlay.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_contact_list.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/views/contact/components/contact_tile.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';

class ContactList extends GetWidget<ContactController> {
  const ContactList({super.key});

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (notification) {
        double pixels = 0;
        if (notification is OverscrollNotification ||
            notification is ScrollUpdateNotification) {
          pixels = (notification as dynamic).metrics.pixels;
          if (pixels <= controller.previousPixels && pixels <= 0) {
            controller.showSearchingBar.value = true;
          } else {
            controller.showSearchingBar.value = false;
          }
          controller.previousPixels = pixels;
        }
        return false;
      },
      child: Obx(
        () => Column(
          children: [
            Container(
              height: 52.0,
              decoration: const BoxDecoration(
                color: colorBackground,
                border: Border(
                  bottom: BorderSide(
                    width: 0.3,
                    color: colorTextPlaceholder,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SearchingAppBar(
                onTap: () {
                  controller.isSearching(true);
                  if (!notBlank(controller.searchParam.value)) {
                    controller.showSearchOverlay.value = true;
                  }
                },
                onChanged: controller.onSearchChanged,
                onCancelTap: () {
                  controller.searchFocus.unfocus();
                  controller.clearSearching();
                  controller.showSearchOverlay.value = false;
                },
                isSearchingMode: controller.isSearching.value,
                isAutoFocus: false,
                focusNode: controller.searchFocus,
                controller: controller.searchController,
                suffixIcon: Visibility(
                  visible: controller.searchParam.value.isNotEmpty,
                  child: IconButton(
                    onPressed: () {
                      controller.searchController.clear();
                      controller.searchParam.value = '';
                      controller.searchLocal();
                    },
                    icon: SvgPicture.asset(
                      'assets/svgs/close_round_icon.svg',
                      color: colorTextSecondary,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: colorSurface,
                child: controller.azFriendList.isEmpty
                    ? controller.isSearching.value
                        ? SearchEmptyState(
                            searchText: controller.searchParam.value,
                          )
                        : Center(
                            child: Container(
                              color: colorSurface,
                              child: Column(
                                children: [
                                  ContactTile(
                                    onTap: () {
                                      controller.clearProcessedFriendRequest();
                                      controller.checkIsAbleToSelect();
                                      Get.toNamed(
                                        RouteName.friendRequestView,
                                      );
                                    },
                                    title: localized(contactFriendRequest),
                                    count: controller.unreadCount(),
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/svgs/no_contact.svg',
                                          width: 148,
                                          height: 148,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          localized(connectWithFriend),
                                          style: jxTextStyle.headerText(
                                              fontWeight:
                                                  MFontWeight.bold5.value),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          localized(connectFriendDesc),
                                          style: jxTextStyle.headerText(
                                            color: colorTextSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        OverlayEffect(
                                          child: GestureDetector(
                                            onTap: () =>
                                                controller.findContact(context),
                                            child: Text(
                                              localized(findContacts),
                                              style: jxTextStyle.headerText(
                                                  color: themeColor,
                                                  fontWeight:
                                                      MFontWeight.bold5.value),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                    : Stack(
                        children: [
                          CustomContactList(
                            contactList: controller.azFriendList,
                            itemScrollController:
                                controller.itemScrollController,
                            header: !controller.isSearching.value
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      ContactTile(
                                        onTap: () {
                                          controller
                                              .clearProcessedFriendRequest();
                                          controller.checkIsAbleToSelect();
                                          Get.toNamed(
                                              RouteName.friendRequestView);
                                        },
                                        svgWidget: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: SvgPicture.asset(
                                            'assets/svgs/add_friends_plus2.svg',
                                            width: 28,
                                            height: 28,
                                            colorFilter: ColorFilter.mode(
                                                themeColor, BlendMode.srcIn),
                                          ),
                                        ),
                                        title: localized(contactFriendRequest),
                                        count: controller.unreadCount(),
                                        verticalPadding: 8.0,
                                      ),
                                      const CustomDivider(
                                        indent: 68,
                                      ),
                                      ContactTile(
                                        onTap: () {
                                          Get.toNamed(
                                              RouteName.tagsManagementPage);
                                        },
                                        svgWidget: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: SvgPicture.asset(
                                            'assets/svgs/tag.svg',
                                            width: 28,
                                            height: 28,
                                            colorFilter: ColorFilter.mode(
                                                themeColor, BlendMode.srcIn),
                                          ),
                                        ),
                                        title: localized(myEditLabel),
                                        count: 0,
                                        verticalPadding: 8.0,
                                      ),
                                      Obx(() {
                                        return Visibility(
                                          visible:
                                              controller.isCheckedOrder.value ==
                                                  0,
                                          child: const CustomDivider(
                                            indent: 68,
                                          ),
                                        );
                                      }),
                                    ],
                                  )
                                : const SizedBox(),
                            isSearching: controller.isSearching.value,
                            isShowIndexBar:
                                (controller.isCheckedOrder.value == 1).obs,
                            isShowingTag:
                                (controller.isCheckedOrder.value == 1).obs,
                            footer: Container(
                              height: 95,
                              color: colorBackground,
                              child: Center(
                                child: Text(
                                  localized(
                                    totalFriend,
                                    params: [
                                      controller.azFriendList.length.toString(),
                                    ],
                                  ),
                                  style: const TextStyle(
                                    color: Color(0x99121212),
                                  ),
                                ),
                              ),
                            ),
                            emptyState: Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/images/common/empty_result.png',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.fill,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '无结果',
                                    style: jxTextStyle.textStyleBold16(),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '无法搜索到相关结果\n请重试!',
                                    style: jxTextStyle.textStyle12(
                                      color: colorTextSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          /// search overlay
                          Obx(() {
                            return SearchOverlay(
                              isVisible: controller.showSearchOverlay.value,
                              onTapCallback: () {
                                controller.isSearching.value = false;
                                controller.showSearchOverlay.value = false;
                              },
                            );
                          }),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
