import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_calendar_date_picker2/im_calendar_date_picker2.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/home/chat/pages/chat_view_app_bar.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';

class SearchingAppBar extends StatelessWidget {
  final void Function()? onTap;
  final void Function(PointerDownEvent)? onTapOutside;
  final Function(String)? onChanged;
  final void Function()? onCancelTap;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final TextInputType inputType;
  final bool isAutoFocus;
  final FocusNode? focusNode;
  final String? hintText;
  final bool relyOnFocusNode;
  final bool isSearchingMode;
  final String? tag;
  final double searchBarHeight;
  final bool? isShowCancelText;

  const SearchingAppBar({
    super.key,
    this.onTap,
    this.onTapOutside,
    this.onChanged,
    this.onCancelTap,
    this.controller,
    this.suffixIcon,
    this.inputType = TextInputType.text,
    this.isAutoFocus = true,
    this.focusNode,
    this.hintText,
    this.relyOnFocusNode = true,
    this.isSearchingMode = false,
    this.tag,
    this.searchBarHeight = kSearchHeightMax,
    this.isShowCancelText = true,
  });

  bool get isAtFirstIdx =>
      Get.find<CustomInputController>(tag: tag)
          .chatController
          .listIndex
          .value ==
      0;

  bool get isAtLastIdx =>
      Get.find<CustomInputController>(tag: tag)
          .chatController
          .listIndex
          .value ==
      Get.find<CustomInputController>(tag: tag)
          .chatController
          .searchedIndexList
          .length;

  Widget searchIcon() {
    return GestureDetector(
      onTap: () => objectMgr.loginMgr.isDesktop ? null : onTap!(),
      child: SizedBox(
        width: objectMgr.loginMgr.isDesktop ? 16 : 24,
        height: objectMgr.loginMgr.isDesktop ? 16 : 24,
        child: SvgPicture.asset(
          'assets/svgs/Search_thin.svg',
          color: colorTextSupporting,
        ),
      ),
    );
  }

  Widget getText() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Get.find<CustomInputController>(tag: tag)
                .chatController
                .searchedIndexList
                .isNotEmpty
            ? Text(
                "${Get.find<CustomInputController>(tag: tag).chatController.listIndex.value + 1} of ${Get.find<CustomInputController>(tag: tag).chatController.searchedIndexList.length}",
                style: jxTextStyle.headerText(color: colorTextSupporting),
              )
            : const SizedBox(),
      ),
    );
  }

  Widget buildTextField() {
    return (searchBarHeight <= 25 && _isHomeTabIndex())
        ? const SizedBox.shrink()
        : TextField(
            contextMenuBuilder: im.textMenuBar,
            focusNode: focusNode,
            autofocus: isAutoFocus,
            cursorColor: themeColor,
            onTapOutside: onTapOutside,
            onChanged: onChanged == null
                ? null
                : (value) => onChanged!(value.trim()),
            onTap: onTap,
            controller: controller,
            enableInteractiveSelection: true,
            maxLines: 1,
            textInputAction: TextInputAction.search,
            textAlignVertical: TextAlignVertical.center,
            keyboardType: inputType,
            style: TextStyle(
              decorationThickness: 0,
              decoration: TextDecoration.none,
              color: colorTextPrimary,
              fontSize: MFontSize.size17.value,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isCollapsed: true,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36, // Set minimum width
              ),
              prefixIcon: isSearchingMode
                  ? searchIcon()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        searchIcon(),
                        const SizedBox(width: 4),
                        Text(
                          localized(hintText ?? hintSearch),
                          style: jxTextStyle.headerText(
                            color: colorTextSupporting,
                          ),
                        ),
                      ],
                    ),
              hintText: localized(hintText ?? hintSearch),
              hintStyle: jxTextStyle.headerText(
                color: colorTextSupporting,
              ),
              suffixIcon: objectMgr.loginMgr.isDesktop
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        getText(),
                        if (suffixIcon != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: suffixIcon!,
                          )
                      ],
                    )
                  : suffixIcon,
            ),
          );
  }

  Widget buildArrowIcon(
      {required void Function()? onTap,
      required bool isDisabled,
      required String iconPath,
      double? size = 20.0}) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: OpacityEffect(
        isDisabled: isDisabled,
        child: SvgPicture.asset(
          iconPath,
          width: size,
          height: size,
          color: isDisabled
              ? objectMgr.loginMgr.isDesktop
                  ? colorTextSecondary.withOpacity(0.2)
                  : themeColor.withOpacity(0.2)
              : themeColor,
        ),
      ),
    );
  }

  Widget buildCancelButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      child: isSearchingMode &&
              !objectMgr.loginMgr.isDesktop &&
              isShowCancelText == true
          ? GestureDetector(
              onTap: onCancelTap,
              child: OpacityEffect(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    localized(buttonCancel),
                    style: jxTextStyle.textStyle17(
                      color: themeColor,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget buildCalendarIcon(BuildContext context) {
    return Visibility(
      visible: objectMgr.loginMgr.isDesktop,
      child: TextButtonTheme(
        data: TextButtonThemeData(
          style: ButtonStyle(
            padding: MaterialStateProperty.all(EdgeInsets.zero),
            backgroundColor: MaterialStateProperty.all(Colors.transparent),
            overlayColor: MaterialStateProperty.all(colorBackground6),
            shape: MaterialStateProperty.all(const CircleBorder()),
            visualDensity: VisualDensity.compact,
            minimumSize: MaterialStateProperty.all(const Size(60, 20)),
          ),
        ),
        child: TextButton(
          onPressed: () {},
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              FocusManager.instance.primaryFocus?.unfocus();
              calenderOnTap(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: SvgPicture.asset(
                'assets/svgs/calendar_icon.svg',
                width: 24,
                height: 24,
                color: themeColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void calenderOnTap(BuildContext context) async {
    final result = await showCalendarDatePicker2Dialog(
      context: context,
      barrierColor: Colors.transparent,
      config: CalendarDatePicker2WithActionButtonsConfig(
        lastDate: DateTime.now(),
        weekdayLabels: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
        weekdayLabelTextStyle: const TextStyle(
          color: im.ImColor.grey20,
          fontSize: 13,
        ),
        controlsHeight: 40,
        disableMonthPicker: true,
        controlsTextStyle:
            const TextStyle(color: colorTextPrimary, fontSize: 15),
        selectedDayHighlightColor: themeColor.withOpacity(0.12),
        themeColor: themeColor,
        dayBuilder: ({
          required DateTime date,
          BoxDecoration? decoration,
          bool? isDisabled,
          bool? isSelected,
          bool? isToday,
          TextStyle? textStyle,
        }) {
          return Container(
            margin:
                const EdgeInsets.all(3), // Add custom padding to fix overlaps
            alignment: Alignment.center,
            decoration: isSelected == true
                ? BoxDecoration(
                    color: themeColor.withOpacity(0.12), shape: BoxShape.circle)
                : null,
            child: Text(
              '${date.day}',
              style: textStyle?.copyWith(
                  color: isDisabled != true &&
                          isSelected == false &&
                          isToday == false
                      ? colorTextPrimary
                      : null,
                  fontSize: 14),
            ),
          );
        },
        todayTextStyle: TextStyle(color: themeColor),
        selectedDayTextStyle: TextStyle(
          color: themeColor,
          fontSize: 14,
        ),
        okButtonTextStyle: const TextStyle(color: colorTextPrimary),
        cancelButtonTextStyle:
            const TextStyle(color: colorTextSecondary, fontSize: 14),
      ),
      dialogSize: const Size(350, 382),
      value: [],
      borderRadius: BorderRadius.circular(15),
      builder: (context, child) {
        return Stack(
          children: [
            AnimatedPositioned(
              key: GlobalKey(),
              right: 0,
              top: 32,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              child: child!,
            ),
          ],
        );
      },
    );
    if (result != null) {
      final customInputController = Get.find<CustomInputController>(tag: tag);
      int dateIndex = -1;
      for (int i = 0;
          i < customInputController.chatController.combinedMessageList.length;
          i++) {
        final message =
            customInputController.chatController.combinedMessageList[i];
        if (message.create_time >
                (result[0] as DateTime).toUtc().millisecondsSinceEpoch / 1000 &&
            message.create_time <
                (result[0] as DateTime).toUtc().millisecondsSinceEpoch / 1000 +
                    86400) {
          dateIndex = i;
        }
      }
      if (dateIndex != -1) {
        customInputController.chatController.messageListController
            ?.scrollToIndex(
          dateIndex,
          preferPosition: AutoScrollPosition.end,
        );
      } else {
        Toast.showToast(localized(errorNoMsgPspecialDate));
      }
    }
  }

  bool _isHomeTabIndex() {
    if (Get.isRegistered<HomeController>()) {
      HomeController homeController = Get.find<HomeController>();
      int index = homeController.pageIndex.value;
      if (index == 0) {
        return !isSearchingMode;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (objectMgr.loginMgr.isDesktop)
          GestureDetector(
            onTap: () => onCancelTap != null ? onCancelTap!() : null,
            child: Container(
              height: 24,
              width: 24,
              margin: const EdgeInsets.only(left: 6, right: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: themeColor, width: 1.5)),
              child: Icon(
                Icons.close_rounded,
                color: themeColor,
                weight: 1.5,
                size: 9.5 * 2,
              ),
            ),
          ),
        Expanded(
          child: Container(
            height: searchBarHeight,
            decoration: BoxDecoration(
              color: colorBackground6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: buildTextField(),
          ),
        ),
        buildCancelButton(),
        if (objectMgr.loginMgr.isDesktop) ...[
          const SizedBox(width: 12),
          Obx(
            () => buildArrowIcon(
                onTap: Get.find<CustomInputController>(tag: tag)
                    .chatController
                    .previousSearch,
                isDisabled: isAtFirstIdx,
                iconPath: 'assets/svgs/wide_arrow_icon.svg',
                size: 24),
          ),
          const SizedBox(width: 8),
          Obx(
            () => Transform.flip(
              flipY: true,
              child: buildArrowIcon(
                  onTap: Get.find<CustomInputController>(tag: tag)
                      .chatController
                      .nextSearch,
                  isDisabled: isAtLastIdx,
                  iconPath: 'assets/svgs/wide_arrow_icon.svg',
                  size: 24),
            ),
          ),
          const SizedBox(width: 4),
        ],
        buildCalendarIcon(context),
        const SizedBox(width: 4),
      ],
    );
  }
}
