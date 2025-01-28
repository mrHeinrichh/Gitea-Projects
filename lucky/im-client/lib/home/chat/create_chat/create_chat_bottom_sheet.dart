import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/create_chat/create_chat_controller.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_contact_list.dart';
import 'package:jxim_client/views/component/search_empty_state.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/views/contact/components/contact_tile.dart';

class CreateChatBottomSheet extends StatelessWidget {
  CreateChatBottomSheet({
    Key? key,
    required this.controller,
    required this.createGroupCallback,
  }) : super(key: key);

  final CreateChatController controller;
  VoidCallback createGroupCallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ObjectMgr.screenMQ!.size.height * 0.94,
      decoration: BoxDecoration(
        color: surfaceBrightColor,
        borderRadius: const BorderRadius.only(
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
                                  jxTextStyle.textStyle17(color: accentColor)),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      localized(createChat),
                      style: jxTextStyle.appTitleStyle(
                          color: JXColors.primaryTextBlack),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(
            () => Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 8,
                top: !controller.isSearching.value ? 0 : 8,
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
                          color: JXColors.iconSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Container(
            height: 1,
            color: JXColors.outlineColor,
          ),
          Expanded(
            child: Obx(
              () => controller.azFilterList.isEmpty
                  ? SearchEmptyState(
                      searchText: controller.searchParam.value,
                    )
                  : Container(
                      color: Colors.white,
                      child: CustomContactList(
                        header: Column(
                          children: [
                            ContactTile(
                              onTap: () {
                                // Navigator.pop(context);
                                createGroupCallback();
                              },
                              icons: Icons.group_outlined,
                              svgIcon: 'group_outlined',
                              title: localized(newChat),
                            ),
                            const CustomDivider(),
                          ],
                        ),
                        contactList: controller.azFilterList,
                        isSearching: controller.isSearching.value,
                        isShowIndexBar: true.obs,
                        isShowingTag: true.obs,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
