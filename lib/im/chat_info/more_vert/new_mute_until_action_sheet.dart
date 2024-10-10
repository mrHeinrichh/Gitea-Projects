import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:intl/intl.dart';
import 'package:jxim_client/im/chat_info/more_vert/custom_cupertino_date_picker.dart';

import 'package:jxim_client/im/chat_info/more_vert/more_vert_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class NewMuteUntilActionSheet extends GetView<MoreVertController> {
  const NewMuteUntilActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380.w,
      padding: EdgeInsets.only(bottom: Platform.isAndroid ? 8 : 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
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
                          style: jxTextStyle.textStyle17(color: themeColor),
                        ),
                      ),
                    ),
                  ),
                  middle: Text(
                    localized(muteUtilTitle),
                    style: jxTextStyle.textStyleBold17(),
                  ),
                ),
              ),
            ),
            Expanded(
              child: DurationPicker(),
            ),
            Container(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 12),
              child: Obx(
                () => PrimaryButton(
                  bgColor: themeColor,
                  width: double.infinity,
                  fontSize: MFontSize.size17.value,
                  fontWeight: MFontWeight.bold5.value,
                  title: controller.getBtnTitle(),
                  onPressed: () {
                    controller.goBack(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DurationPicker extends GetWidget<MoreVertController> {
  DurationPicker({super.key});

  String _formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('MM/dd/yy, HH:mm');
    return formatter.format(dateTime);
  }

  final Rx<DateTime> selectedDateTime = DateTime.now().obs;

  @override
  Widget build(BuildContext context) {
    controller.selectedDateFormat.value = _formatDateTime(DateTime.now());
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          child: Transform.scale(
            scale: 1.25,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    fontSize: 13,
                    color: ImColor.black,
                    fontFamily: 'pingfang',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              child: Obx(
                () => CustomCupertinoDatePicker(
                  minimumYear: 2000,
                  key: ValueKey(DateTime.now().minute.toString()),
                  initialDateTime: selectedDateTime.value,
                  mode: CustomCupertinoDatePickerMode.dateAndTime,
                  onDateTimeChanged: (date) {
                    controller.selectedDateFormat.value = _formatDateTime(date);
                    if (date.isBefore(DateTime.now())) {
                      selectedDateTime.value = DateTime.now();
                    } else {
                      selectedDateTime.value = date;
                      vibrate(duration: 50);
                    }
                  },
                  use24hFormat: true,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            children: [
              Container(
                height: 25,
                width: double.infinity,
                color: colorWhite,
              ),
              const Spacer(),
              Container(
                height: 25,
                width: double.infinity,
                color: colorWhite,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
