import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/chat_info/more_vert/custom_cupertino_date_picker.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/utils/im_toast/primary_button.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/scroll_to_index/scroll_to_index.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';

class SearchingBottomBar extends StatelessWidget {
  final int listIdx;
  final CustomInputController controller;

  const SearchingBottomBar({
    super.key,
    required this.listIdx,
    required this.controller,
  });

  // ================================= 工具 ====================================

  void searchDate() {
    Get.back();
    int? dateIndex;
    controller.chatController.searchedIndexList.clear();
    for (int i = 0;
        i < controller.chatController.combinedMessageList.length;
        i++) {
      final message = controller.chatController.combinedMessageList[i];
      if (message.create_time > controller.chatController.selectedDate &&
          message.create_time <
              controller.chatController.selectedDate + 86400) {
        controller.chatController.searchedIndexList.add(message);
        dateIndex = i;
      }
    }
    if (dateIndex != null) {
      controller.chatController.messageListController.scrollToIndex(
        dateIndex,
        preferPosition: AutoScrollPosition.end,
      );
    } else {
      Toast.showToast(localized(errorNoMsgPspecialDate));
    }
  }

  void changeDate(DateTime date) {
    controller.chatController.selectedDate =
        (date.toUtc().millisecondsSinceEpoch / 1000);
    vibrate(duration: 50);
  }

  Widget getText() {
    return Obx(
      () => Container(
        child: controller.chatController.searchedIndexList.isNotEmpty ||
                controller.chatController.searchParam.value.isNotEmpty ||
                controller.chatController.searchController.text
                    .startsWith('${localized(chatFrom)}: ')
            ? controller.chatController.isTextTypeSearch.value
                ? Text(
                    controller.chatController.searchedIndexList.isNotEmpty
                        ? "${controller.chatController.listIndex.value + 1}/"
                            "${controller.chatController.searchedIndexList.length}"
                        : localized(noChatResult),
                    style: jxTextStyle.textStyle16(color: colorTextSecondary),
                  )
                : null
            : GestureDetector(
                onTap: () {
                  controller.switchChatSearchType(isTextModeSearch: false);
                },
                behavior: HitTestBehavior.opaque,
                child: controller.chatController is GroupChatController
                    ? SizedBox(
                        height: double.infinity,
                        child: SvgPicture.asset(
                          'assets/svgs/search_user_icon.svg',
                          width: 24,
                          height: 24,
                          color: themeColor,
                        ),
                      )
                    : const SizedBox(),
              ),
      ),
    );
  }

  bool get isAtFirstIdx {
    int length = controller.chatController.searchedIndexList.length;
    bool k = length == 0;
    return k;
  }

  bool get isAtLastIdx {
    int length = controller.chatController.searchedIndexList.length;
    if (length == 0) return true;
    bool k = listIdx == length - 1;
    return k;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              showModalBottomSheet(
                backgroundColor: Colors.transparent,
                context: context,
                builder: (BuildContext context) {
                  return IntrinsicHeight(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: colorTextPrimary.withOpacity(0.2),
                            width: 0.5,
                          ),
                          bottom: BorderSide(
                            color: colorTextPrimary.withOpacity(0.2),
                            width: 0.5,
                          ),
                          left: BorderSide(
                            color: colorTextPrimary.withOpacity(0.2),
                            width: 0.5,
                          ),
                          right: BorderSide(
                            color: colorTextPrimary.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          topLeft: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              height: 60,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 15,
                              ),
                              child: SizedBox(
                                height: 26,
                                child: NavigationToolbar(
                                  leading: SizedBox(
                                    width: 74,
                                    child: OpacityEffect(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          localized(buttonCancel),
                                          style: jxTextStyle.textStyle17(
                                            color: themeColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ClipRRect(
                              child: Stack(
                                children: [
                                  SizedBox(
                                    height: 150,
                                    child: Transform.scale(
                                      scale: 1.25,
                                      child: CupertinoTheme(
                                        data: const CupertinoThemeData(
                                          textTheme: CupertinoTextThemeData(
                                            dateTimePickerTextStyle: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                              fontFamily: 'pingfang',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        child: CustomCupertinoDatePicker(
                                          minimumYear: 2000,
                                          initialDateTime: DateTime.now(),
                                          maximumDate: DateTime.now(),
                                          mode: CustomCupertinoDatePickerMode
                                              .date,
                                          dateOrder: DatePickerDateOrder.ymd,
                                          onDateTimeChanged: changeDate,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 3,
                                          width: double.infinity,
                                          color: colorWhite,
                                        ),
                                        const Spacer(),
                                        Container(
                                          height: 3,
                                          width: double.infinity,
                                          color: colorWhite,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 15.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: PrimaryButton(
                                bgColor: themeColor,
                                width: double.infinity,
                                title: localized(buttonConfirm),
                                onPressed: searchDate,
                              ),
                            ),
                            SizedBox(height: 15.h),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: SizedBox(
                height: double.infinity,
                child: OpacityEffect(
                  child: SvgPicture.asset(
                    'assets/svgs/search_calendar_icon.svg',
                    width: 24,
                    height: 24,
                    color: themeColor,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: getText(),
          ),
          const Spacer(),
          Obx(
            () => GestureDetector(
              onTap: isAtLastIdx ? null : controller.chatController.nextSearch,
              child: OpacityEffect(
                isDisabled: isAtLastIdx,
                child: SvgPicture.asset(
                  'assets/svgs/arrow_up_icon.svg',
                  width: 24,
                  height: 24,
                  color: isAtLastIdx ? themeColor.withOpacity(0.2) : themeColor,
                ),
              ),
            ),
          ),
          Obx(
            () => GestureDetector(
              onTap: isAtFirstIdx
                  ? null
                  : controller.chatController.previousSearch,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.h),
                child: OpacityEffect(
                  isDisabled: isAtFirstIdx,
                  child: SvgPicture.asset(
                    'assets/svgs/arrow_down_icon.svg',
                    width: 24,
                    height: 24,
                    color:
                        isAtFirstIdx ? themeColor.withOpacity(0.2) : themeColor,
                  ),
                ),
              ),
            ),
          ),
          Obx(
            () => controller.chatController.searchedIndexList.isNotEmpty
                ? GestureDetector(
                    onTap: () => controller.switchChatListMode(),
                    child: Container(
                      height: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(right: 12.w),
                      child: OpacityEffect(
                        child: Text(
                          !controller.chatController.isListModeSearch.value
                              ? localized(chatListMode)
                              : localized(chatMode),
                          style: jxTextStyle.textStyle16(
                            color: themeColor,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
