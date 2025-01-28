import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/create_chat/create_chat_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/search_overlay.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_contact_list.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';

class CreateChatBottomSheet extends StatelessWidget {
  const CreateChatBottomSheet({
    super.key,
    this.type = 0,
    required this.controller,
    required this.createGroupCallback,
  });

  final int type;
  final CreateChatController controller;
  final Function(GroupType) createGroupCallback;

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
                      localized(createChat),
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
                  child: GestureDetector(
                    onTap: () {
                      controller.searchController.clear();
                      controller.searchParam.value = '';
                      controller.showSearchOverlay.value = true;
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
            child: Obx(
              () => controller.userList.isEmpty
                  ? Column(
                      children: [
                        createChatOptions(
                          onTap: () {
                            createGroupCallback(GroupType.NOR);
                          },
                          svgIcon: 'group_outlined',
                          title: localized(newChat),
                        ),
                        createChatOptions(
                          title: localized(addFriendTitle),
                          svgIcon: 'add_friends_plus',
                          onTap: () {
                            createGroupCallback(GroupType.FRIEND);
                          },
                          hasBorder: false,
                        ),
                      ],
                    )
                  : controller.azFilterList.isEmpty
                      ? SearchEmptyState(
                          searchText: controller.searchParam.value,
                        )
                      : Stack(
                          children: [
                            Container(
                              color: colorSurface,
                              child: CustomContactList(
                                header: Column(
                                  children: [
                                    createChatOptions(
                                      onTap: () {
                                        createGroupCallback(GroupType.NOR);
                                      },
                                      svgIcon: 'group_outlined',
                                      title: localized(newChat),
                                    ),
                                    createChatOptions(
                                      title: localized(addFriendTitle),
                                      svgIcon: 'add_friends_plus',
                                      onTap: () {
                                        createGroupCallback(GroupType.FRIEND);
                                      },
                                      hasBorder: false,
                                    ),
                                  ],
                                ),
                                contactList: controller.azFilterList,
                                isSearching: controller.isSearching.value,
                                isShowIndexBar: true.obs,
                                isShowingTag: true.obs,
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
    );
  }

  Widget createChatOptions(
      {Function()? onTap,
      required String svgIcon,
      required String title,
      bool hasBorder = true}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: OverlayEffect(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                  child: SvgPicture.asset(
                    'assets/svgs/$svgIcon.svg',
                    width: 40,
                    height: 40,
                    colorFilter: ColorFilter.mode(themeColor, BlendMode.srcIn),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11.0),
                  child: Text(
                    title,
                    style: jxTextStyle.textStyle17(color: themeColor),
                  ),
                )
              ],
            ),
          ),
        ),
        if (hasBorder)
          const Padding(
            padding: EdgeInsets.only(left: 68.0),
            child: CustomDivider(),
          ),
      ],
    );
  }
}
