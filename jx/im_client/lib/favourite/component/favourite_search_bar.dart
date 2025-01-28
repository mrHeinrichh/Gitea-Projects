import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/favourite/component/favourite_selected_item.dart';
import 'package:jxim_client/favourite/favourite_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class FavouriteSearchBar extends GetView<FavouriteController> {
  const FavouriteSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(6.0),
      decoration: const BoxDecoration(
        color: colorBackground6,
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      child: Obx(
        () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: controller.isSearching.value
              ? _buildSearchModeContent()
              : _buildNotSearchModeContent(),
        ),
      ),
    );
  }

  Widget _buildNotSearchModeContent() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => controller.onActivateSearchBar(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/svgs/Search_thin.svg',
            color: colorTextSupporting,
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 8),
          Text(
            localized(search),
            style: jxTextStyle.headerText(color: colorTextSupporting),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchModeContent() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => controller.onClickTextField(),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 12.0,
          runSpacing: 4.0,
          children: [
            ...List.generate(
              controller.keyWordList.length,
              (index) => FavouriteSelectedItem(
                model: controller.keyWordList[index],
                callback: () =>
                    controller.removeKeyword(controller.keyWordList[index]),
              ),
            ),
            IntrinsicWidth(
              child: Stack(
                children: [
                  TextField(
                    controller: controller.inputController,
                    focusNode: controller.inputFocusNode,
                    maxLines: 1,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintText: localized(searchKeywords),
                      hintStyle: jxTextStyle.headerText(
                        color: colorTextSupporting,
                      ),
                    ),
                    style: jxTextStyle.headerText(
                      color: colorTextPrimary,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) =>
                        controller.onTextSubmitted(value, requestFocus: false),
                    onTap: () => controller.onClickTextField(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
