import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/search_contact_controller.dart';
import 'package:jxim_client/views/contact/searching_view.dart';

class SearchUsername extends StatefulWidget {
  const SearchUsername({super.key});

  @override
  State<StatefulWidget> createState() => _SearchUsernameState();
}

class _SearchUsernameState extends State<SearchUsername> {
  SearchContactController get controller => Get.find<SearchContactController>();

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          _usernameTextField(),

          /// Search button
          Obx(() {
            return CustomButton(
              text: localized(searchFriend),
              isDisabled: !controller.enableBtn.value,
              isLoading: controller.isSearching.value,
              callBack: () {
                controller.contactSearching(controller.usernameController.text);
              },
            );
          }),

          // options
          SearchOptionList(controller: controller),
        ],
      ),
    );
  }

  Container _usernameTextField() {
    return Container(
      height: objectMgr.loginMgr.isDesktop ? 48 : 44,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: TextField(
          controller: controller.usernameController,
          contextMenuBuilder: im.textMenuBar,
          textInputAction: TextInputAction.done,
          style: jxTextStyle.headerText(),
          maxLines: 1,
          maxLength: 20,
          buildCounter: (
              BuildContext context, {
                required int currentLength,
                required int? maxLength,
                required bool isFocused,
              }) {
            return null;
          },
          cursorColor: themeColor,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            border: InputBorder.none,
            hintText: localized(contactUsername),
            hintStyle: jxTextStyle.headerText(color: colorTextPlaceholder),
            suffixIcon: GestureDetector(
              onTap: () => controller.clearText(),
              behavior: HitTestBehavior.opaque,
              child: Obx(
                    () => Visibility(
                  visible: controller.showClearBtn.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: SvgPicture.asset(
                      'assets/svgs/clear_icon.svg',
                      color: colorTextSecondary,
                      width: 20,
                      height: 20,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(maxHeight: 44),
          ),
        ),
      ),
    );
  }
}
