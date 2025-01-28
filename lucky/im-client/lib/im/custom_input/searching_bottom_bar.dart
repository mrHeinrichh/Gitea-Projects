import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/theme/text_styles.dart';
import '../../utils/toast.dart';
import '../../views/scroll_to_index/scroll_to_index.dart';
import 'custom_input_controller.dart';

class SearchingBottomBar extends StatelessWidget {
  final int listIdx;
  final CustomInputController controller;

  const SearchingBottomBar({
    Key? key,
    required this.listIdx,
    required this.controller,
  }) : super(key: key);

  // ================================= 工具 ====================================
  void searchDate() {
    Get.back();
    var dateIndex;
    for (int i = 0;
        i < controller.chatController.combinedMessageList.length;
        i++) {
      final message = controller.chatController.combinedMessageList[i];
      if (message.create_time > controller.chatController.selectedDate &&
          message.create_time <
              controller.chatController.selectedDate + 86400) {
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
  }

  Widget getText() {
    return Obx(
      () => Container(
        child: controller.chatController.searchedIndexList.isNotEmpty
            ? Text(
                "${controller.chatController.listIndex.value + 1} of ${controller.chatController.searchedIndexList.length}",
                style: jxTextStyle.textStyle16(color: accentColor))
            : const SizedBox(),
      ),
    );
  }

  bool get isAtFirstIdx => listIdx == 0;

  bool get isAtLastIdx =>
      listIdx == controller.chatController.searchedIndexList.length - 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.h),
            child: GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (BuildContext context) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 250.h,
                        color: Colors.transparent,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10.h),
                                  ),
                                  color: Colors.white,
                                ),
                                height: 150.h,
                                child: CupertinoTheme(
                                  data: CupertinoThemeData(
                                    scaffoldBackgroundColor: accentColor,
                                    textTheme: CupertinoTextThemeData(
                                      dateTimePickerTextStyle: TextStyle(
                                          fontSize: 13.sp, color: accentColor),
                                    ),
                                  ),
                                  child: CupertinoDatePicker(
                                    minimumYear: 2000,
                                    initialDateTime: DateTime.now(),
                                    maximumDate: DateTime.now(),
                                    mode: CupertinoDatePickerMode.date,
                                    onDateTimeChanged: changeDate,
                                  ),
                                ),
                              ),
                              SizedBox(height: 15.h),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10.h),
                                  ),
                                  color: Colors.white,
                                ),
                                height: 50.h,
                                child: GestureDetector(
                                  onTap: searchDate,
                                  child: Center(
                                    child: Text(
                                      localized(jumpToDate),
                                      style: TextStyle(
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Container(
                height: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(left: 15.h),
                  child: SvgPicture.asset(
                    'assets/svgs/calendar_icon.svg',
                    width: 24,
                    height: 24,
                    color: accentColor,
                  ),
                  //Icon(Icons.calendar_today_outlined, size: 24),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(left: 8.h),
              child: getText(),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: isAtLastIdx ? null : controller.chatController.nextSearch,
            child: SvgPicture.asset(
              'assets/svgs/arrow_up_icon.svg',
              width: 24,
              height: 24,
              color: isAtLastIdx ? accentColor.withOpacity(0.2) : accentColor,
            ),
          ),
          GestureDetector(
            onTap:
                isAtFirstIdx ? null : controller.chatController.previousSearch,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: SvgPicture.asset(
                'assets/svgs/arrow_down_icon.svg',
                width: 24,
                height: 24,
                color:
                    isAtFirstIdx ? accentColor.withOpacity(0.2) : accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
