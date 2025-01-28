import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/chat/pages/chat_view_app_bar.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/toast.dart';
import '../scroll_to_index/scroll_to_index.dart';

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

  const SearchingAppBar({
    Key? key,
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
  }) : super(key: key);

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
    return UnconstrainedBox(
      child: GestureDetector(
        onTap: () => objectMgr.loginMgr.isDesktop ? onCancelTap : null,
        child: SvgPicture.asset(
          objectMgr.loginMgr.isDesktop
              ? 'assets/svgs/desktop_arrow_right.svg'
              : 'assets/svgs/Search_thin.svg',
          height: 25,
          width: 25,
          color: objectMgr.loginMgr.isDesktop ? accentColor : JXColors.black,
          //fit: BoxFit.,
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
                style: jxTextStyle.textStyle13(
                    color: JXColors.supportingTextBlack))
            : const SizedBox(),
      ),
    );
  }

  Widget buildTextField() {
    return (kSearchHeight.value <= 25 && _isHomeTabIndex()) ? const SizedBox.shrink() : TextField(
      contextMenuBuilder: textMenuBar,
      focusNode: focusNode,
      autofocus: isAutoFocus,
      cursorColor: accentColor,
      onTapOutside: onTapOutside,
      onChanged: onChanged,
      onTap: onTap,
      controller: controller,
      enableInteractiveSelection: isSearchingMode,
      maxLines: 1,
      textInputAction: TextInputAction.search,
      textAlignVertical: TextAlignVertical.center,
      keyboardType: inputType,
      style: const TextStyle(
          decorationThickness: 0,
          decoration: TextDecoration.none,
          color: JXColors.black),
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
                  const SizedBox(
                    width: 4,
                  ),
                  Text(
                    localized(hintText ?? hintSearch),
                    style: jxTextStyle.textStyle16(
                      color: JXColors.secondaryTextBlack,
                    ),
                  )
                ],
              ),
        hintText: localized(hintText ?? hintSearch),
        hintStyle: jxTextStyle.textStyle16(
          color: JXColors.supportingTextBlack,
        ),
        suffixIcon: objectMgr.loginMgr.isDesktop
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  getText(),
                  Obx(
                    () => buildArrowIcon(
                      onTap: Get.find<CustomInputController>(tag: tag)
                          .chatController
                          .previousSearch,
                      isDisabled: isAtFirstIdx,
                      iconPath: 'assets/svgs/arrow_up_icon.svg',
                    ),
                  ),
                  Obx(
                    () => buildArrowIcon(
                      onTap: Get.find<CustomInputController>(tag: tag)
                          .chatController
                          .nextSearch,
                      isDisabled: isAtLastIdx,
                      iconPath: 'assets/svgs/arrow_down_icon.svg',
                    ),
                  ),
                ],
              )
            : suffixIcon,
      ),
    );
  }

  Widget buildArrowIcon({
    required void Function()? onTap,
    required bool isDisabled,
    required String iconPath,
  }) {
    return TextButtonTheme(
      data: TextButtonThemeData(
        style: ButtonStyle(
            padding: MaterialStateProperty.all(EdgeInsets.zero),
            backgroundColor: MaterialStateProperty.all(Colors.transparent),
            overlayColor: MaterialStateProperty.all(JXColors.outlineColor),
            shape: MaterialStateProperty.all(const CircleBorder()),
            visualDensity: VisualDensity.compact,
            minimumSize: MaterialStateProperty.all(const Size(50, 20))),
      ),
      child: TextButton(
        onPressed: isDisabled ? null : onTap,
        child: SvgPicture.asset(
          iconPath,
          width: 20,
          height: 20,
          color: isDisabled
              ? accentColor.withOpacity(0.2)
              : JXColors.secondaryTextBlack,
        ),
      ),
    );
  }

  Widget buildCancelButton() {
    return Visibility(
      visible: isSearchingMode && !objectMgr.loginMgr.isDesktop,
      child: GestureDetector(
        onTap: onCancelTap,
        child: OpacityEffect(
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              localized(buttonCancel),
              style: jxTextStyle.textStyle17(
                color: accentColor,
              ),
            ),
          ),
        ),
      ),
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
              overlayColor: MaterialStateProperty.all(JXColors.outlineColor),
              shape: MaterialStateProperty.all(const CircleBorder()),
              visualDensity: VisualDensity.compact,
              minimumSize: MaterialStateProperty.all(const Size(60, 20))),
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
                color: accentColor,
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
            color: JXColors.supportingTextBlack,
            fontSize: 13,
          ),
          selectedDayHighlightColor: JXColors.blue.withOpacity(0.08),
          selectedDayTextStyle: const TextStyle(
            color: JXColors.blue,
            fontSize: 14,
          ),
          okButtonTextStyle: const TextStyle(color: JXColors.black),
        ),
        dialogSize: const Size(300, 200),
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
        });
    if (result != null) {
      final customInputController = Get.find<CustomInputController>(tag: tag);
      var dateIndex;
      for (int i = 0;
          i < customInputController.chatController.combinedMessageList.length;
          i++) {
        final message =
            customInputController.chatController.combinedMessageList[i];
        if (message.create_time >
                (result[0] as DateTime).toUtc().millisecondsSinceEpoch /
                    1000 &&
            message.create_time <
                (result[0] as DateTime).toUtc().millisecondsSinceEpoch / 1000 +
                    86400) {
          dateIndex = i;
        }
      }
      if (dateIndex != null) {
        customInputController.chatController.messageListController
            .scrollToIndex(
          dateIndex,
          preferPosition: AutoScrollPosition.end,
        );
      } else {
        Toast.showToast(localized(errorNoMsgPspecialDate));
      }
    }
  }

  bool _isHomeTabIndex() {
    if(Get.isRegistered<HomeController>()){
      HomeController homeController = Get.find<HomeController>();
      int index = homeController.pageIndex.value;
      if (index == 0) {
        return isSearchingMode ? false : true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: _isHomeTabIndex() ? kSearchHeight.value : kSearchHeightMax,
            decoration: BoxDecoration(
              color: objectMgr.loginMgr.isDesktop
                  ? JXColors.white
                  : JXColors.bgSearchBarTextField,
              borderRadius: BorderRadius.circular(8),
            ),
            child: buildTextField(),
          ),
        ),
        buildCancelButton(),
        buildCalendarIcon(context),
      ],
    );
  }
}
