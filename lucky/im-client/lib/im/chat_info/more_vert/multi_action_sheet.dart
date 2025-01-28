import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:jxim_client/im/chat_info/more_vert/more_vert_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import '../../../utils/color.dart';
import 'package:get/get.dart';

class MuteUntilActionSheet extends GetView<MoreVertController> {
  const MuteUntilActionSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(
        () => Padding(
          padding: EdgeInsets.only(bottom: Platform.isAndroid ? 8 : 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Visibility(
                visible: !controller.isShowPickDate.value,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: DurationPicker(),
                ),
              ),
              Visibility(
                visible: controller.isShowPickDate.value,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: DatePicker(),
                ),
              ),
              // GestureDetector(
              //   onTap: () {
              //
              //     // controller.isShowPickDate.value =
              //     //     !controller.isShowPickDate.value;
              //     // if (controller.isShowPickDate.value) {
              //     //   controller.dayScrollController = FixedExtentScrollController();
              //     //   controller.monthScrollController =
              //     //       FixedExtentScrollController();
              //     //   controller.yearScrollController = FixedExtentScrollController();
              //     // } else {
              //     //   controller.hoursScrollController =
              //     //       FixedExtentScrollController();
              //     //   controller.minScrollController = FixedExtentScrollController();
              //     // }
              //   },
              //   child: Padding(
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
              //     child: Container(
              //       width: double.infinity,
              //       padding: const EdgeInsets.symmetric(vertical: 15),
              //       decoration: BoxDecoration(
              //         color: JXColors.white,
              //         borderRadius: BorderRadius.circular(10),
              //       ),
              //       child: Text(
              //         controller.isShowPickDate.value
              //             ? 'Pick a Time'
              //             : 'Pick a date',
              //         textAlign: TextAlign.center,
              //       ),
              //     ),
              //   ),
              // ),
              GestureDetector(
                onTap: () {
                  int hours = controller.hoursScrollController.selectedItem;
                  int min = controller.minScrollController.selectedItem;
                  DateTime currentDateTime = DateTime.now();
                  final result =
                      currentDateTime.add(Duration(hours: hours, minutes: min));
                  Navigator.pop(context, result.millisecondsSinceEpoch ~/ 1000);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: JXColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      localized(buttonDone),
                      textAlign: TextAlign.center,
                      style: jxTextStyle.textStyle14(color: accentColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DurationPicker extends GetWidget<MoreVertController> {
  const DurationPicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
      decoration: BoxDecoration(
        color: JXColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 100,
              child: CupertinoPicker(
                diameterRatio: 10,
                itemExtent: 32,
                squeeze: 1,
                useMagnifier: true,
                scrollController: controller.hoursScrollController,
                selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                  background: JXColors.lightPurple.withOpacity(0.2),
                  capStartEdge: false,
                  capEndEdge: false,
                ),
                onSelectedItemChanged: (int value) {},
                children: List<Widget>.generate(25, (index) {
                  final number = index;
                  return Center(
                    child: Text(
                      '$number \t \t \t ${localized(hours)}',
                      style: jxTextStyle.textStyle14(color: accentColor),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                height: 100,
                child: CupertinoPicker(
                  diameterRatio: 10,
                  itemExtent: 32,
                  squeeze: 1,
                  scrollController: controller.minScrollController,
                  selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                    background: JXColors.lightPurple.withOpacity(0.2),
                    capStartEdge: false,
                    capEndEdge: false,
                  ),
                  onSelectedItemChanged: (int value) {},
                  children: List<Widget>.generate(60, (index) {
                    final number = index;
                    return Center(
                      child: Text(
                        '$number \t \t \t  ${localized(minutes)}',
                        style: jxTextStyle.textStyle14(color: accentColor),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DatePicker extends GetWidget<MoreVertController> {
  const DatePicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
      decoration: BoxDecoration(
        color: JXColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Container(
                height: 100,
                child: CupertinoPicker(
                  diameterRatio: 10,
                  itemExtent: 32,
                  squeeze: 1,
                  useMagnifier: true,
                  scrollController: controller.dayScrollController,
                  selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                    background: JXColors.lightPurple.withOpacity(0.2),
                    capStartEdge: false,
                    capEndEdge: false,
                  ),
                  onSelectedItemChanged: (int value) {},
                  children: List<Widget>.generate(31, (int index) {
                    final int day = index + 1;
                    return Center(
                      child: Text(
                        '$day',
                        style: const TextStyle(
                          fontSize: 14,
                          color: JXColors.indigo,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                height: 100,
                child: CupertinoPicker(
                  diameterRatio: 10,
                  itemExtent: 32,
                  squeeze: 1,
                  useMagnifier: true,
                  scrollController: controller.monthScrollController,
                  selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                    background: JXColors.lightPurple.withOpacity(0.2),
                    capStartEdge: false,
                    capEndEdge: false,
                  ),
                  onSelectedItemChanged: (int value) {},
                  children: List<Widget>.generate(12, (int index) {
                    final int month = index + 1;
                    return Center(
                      child: Text(
                        localizations.datePickerMonth(month),
                        style: const TextStyle(
                          fontSize: 14,
                          color: JXColors.indigo,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                height: 100,
                child: CupertinoPicker(
                  diameterRatio: 10,
                  itemExtent: 32,
                  squeeze: 1,
                  useMagnifier: true,
                  scrollController: controller.yearScrollController,
                  selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                    background: JXColors.lightPurple.withOpacity(0.2),
                    capStartEdge: false,
                    capEndEdge: false,
                  ),
                  onSelectedItemChanged: (int value) {},
                  children: [
                    Center(
                      child: Text(
                        localizations.datePickerYear(2023),
                        style: const TextStyle(
                          fontSize: 14,
                          color: JXColors.indigo,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        localizations.datePickerYear(2024),
                        style: const TextStyle(
                          fontSize: 14,
                          color: JXColors.indigo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AutoDeleteDurationPicker extends StatelessWidget {
  final FixedExtentScrollController durationPickerController =
      FixedExtentScrollController();
  final controller = Get.find<MoreVertController>();

  AutoDeleteDurationPicker({super.key});

  String getIntervalContent(int index) {
    int interval = controller.autoDeleteCustomSelectionList[index];
    if (interval < 60) {
      return '$interval \t \t \t ${localized(seconds)}';
    } else if (interval < 3600) {
      return '${interval ~/ 60} \t \t \t ${localized(minutes)}';
    } else if (interval < 86400) {
      return '${interval ~/ 3600} \t \t \t ${localized(hours)}';
    } else if (interval < 604800) {
      return '${interval ~/ 86400} \t \t \t ${localized(days)}';
    } else if (interval < 2592000) {
      return '${interval ~/ 604800} \t \t \t ${localized(weeks)}';
    } else {
      return '${interval ~/ 2592000} \t \t \t ${localized(months)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: ObjectMgr.viewPadding!.bottom),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
            decoration: BoxDecoration(
              color: JXColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            height: MediaQuery.of(context).size.height / 4,
            child: CupertinoPicker(
              diameterRatio: 10,
              itemExtent: 32,
              squeeze: 1,
              useMagnifier: true,
              magnification: 1.12,
              scrollController: durationPickerController,
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: JXColors.lightPurple.withOpacity(0.2),
                capStartEdge: false,
                capEndEdge: false,
              ),
              onSelectedItemChanged: (int value) {},
              children: List<Widget>.generate(
                controller.autoDeleteCustomSelectionList.length,
                (int index) {
                  return Center(
                    child: Text(
                      getIntervalContent(index),
                      style: const TextStyle(
                        fontSize: 14,
                        color: JXColors.indigo,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop(
                  controller.autoDeleteCustomSelectionList[
                      durationPickerController.selectedItem]);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: JXColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                localized(buttonDone),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: JXColors.indigo,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              durationPickerController.animateTo(
                0,
                duration: const Duration(milliseconds: 50),
                curve: Curves.easeInOutCubic,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: JXColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                localized(reset),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: JXColors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
