import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/auto_delete_message_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/views_desktop/component/desktop_dialog.dart';

mixin CustomInputAutoDeleteMixin {
  double bottomMargin = 64.w;
  final selectionOverlay = CupertinoPickerDefaultSelectionOverlay(
    background: Colors.black.withOpacity(0.03),
    capStartEdge: false,
    capEndEdge: false,
  );
  List<AutoDeleteMessageModel> autoDeleteOption = [
    AutoDeleteMessageModel(
      title: '10 ${localized(seconds)}',
      optionType: AutoDeleteDurationOption.tenSecond.optionType,
      duration: AutoDeleteDurationOption.tenSecond.duration,
    ),
    AutoDeleteMessageModel(
      title: '30 ${localized(seconds)}',
      optionType: AutoDeleteDurationOption.thirtySecond.optionType,
      duration: AutoDeleteDurationOption.thirtySecond.duration,
    ),
    AutoDeleteMessageModel(
      title: '1 ${localized(minute)}',
      optionType: AutoDeleteDurationOption.oneMinute.optionType,
      duration: AutoDeleteDurationOption.oneMinute.duration,
    ),
    AutoDeleteMessageModel(
      title: '5 ${localized(minutes)}',
      optionType: AutoDeleteDurationOption.fiveMinute.optionType,
      duration: AutoDeleteDurationOption.fiveMinute.duration,
    ),
    AutoDeleteMessageModel(
      title: '10 ${localized(minutes)}',
      optionType: AutoDeleteDurationOption.tenMinute.optionType,
      duration: AutoDeleteDurationOption.tenMinute.duration,
    ),
    AutoDeleteMessageModel(
      title: '15 ${localized(minutes)}',
      optionType: AutoDeleteDurationOption.fifteenMinute.optionType,
      duration: AutoDeleteDurationOption.fifteenMinute.duration,
    ),
    AutoDeleteMessageModel(
      title: '30 ${localized(minutes)}',
      optionType: AutoDeleteDurationOption.thirtyMinute.optionType,
      duration: AutoDeleteDurationOption.thirtyMinute.duration,
    ),
    AutoDeleteMessageModel(
      title: '1 ${localized(hour)}',
      optionType: AutoDeleteDurationOption.oneHour.optionType,
      duration: AutoDeleteDurationOption.oneHour.duration,
    ),
    AutoDeleteMessageModel(
      title: '2 ${localized(hours)}',
      optionType: AutoDeleteDurationOption.twoHour.optionType,
      duration: AutoDeleteDurationOption.twoHour.duration,
    ),
    AutoDeleteMessageModel(
      title: '6 ${localized(hours)}',
      optionType: AutoDeleteDurationOption.sixHour.optionType,
      duration: AutoDeleteDurationOption.sixHour.duration,
    ),
    AutoDeleteMessageModel(
      title: '12 ${localized(hours)}',
      optionType: AutoDeleteDurationOption.twelveHour.optionType,
      duration: AutoDeleteDurationOption.twelveHour.duration,
    ),
    AutoDeleteMessageModel(
      title: '1 ${localized(day)}',
      optionType: AutoDeleteDurationOption.oneDay.optionType,
      duration: AutoDeleteDurationOption.oneDay.duration,
    ),
    AutoDeleteMessageModel(
      title: '1 ${localized(week)}',
      optionType: AutoDeleteDurationOption.oneWeek.optionType,
      duration: AutoDeleteDurationOption.oneWeek.duration,
    ),
    AutoDeleteMessageModel(
      title: '1 ${localized(month)}',
      optionType: AutoDeleteDurationOption.oneMonth.optionType,
      duration: AutoDeleteDurationOption.oneMonth.duration,
    ),
  ];

  void showAutoDeletePopup(BaseChatController chatController) {
    if (chatController is GroupChatController) {
      if (!(chatController.isAdmin || chatController.isOwner)) {
        im.showWarningToast(
          localized(insufficientPermissions),
          bottomMargin: bottomMargin,
        );
        return;
      }
    }
    FixedExtentScrollController autoDeleteScrollController =
        FixedExtentScrollController();
    final currentAutoDeleteDuration = 0.obs;
    RxInt selectIndex = 0.obs;
    currentAutoDeleteDuration.value = chatController.chat.autoDeleteInterval;

    selectIndex.value = autoDeleteOption
        .indexWhere((item) => item.duration == currentAutoDeleteDuration.value);
    initDefaultSelect(selectIndex, chatController);
    autoDeleteScrollController =
        FixedExtentScrollController(initialItem: selectIndex.value);
    bool autoDeleteIntervalEnable = chatController.chat.autoDeleteEnabled;
    if (objectMgr.loginMgr.isDesktop) {
      showDialog(
        context: chatController.context,
        builder: (context) {
          return DesktopDialog(
            child: Container(
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(
                            Icons.close,
                            color: themeColor,
                            size: 20,
                          ),
                        ),
                        Text(
                          localized(autoDeleteMessage),
                          style: jxTextStyle.textStyleBold16(),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: autoDeleteOption.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Obx(
                          () => ElevatedButtonTheme(
                            data: ElevatedButtonThemeData(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                disabledBackgroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                surfaceTintColor: colorDivider,
                                elevation: 0.0,
                                textStyle: TextStyle(
                                  fontSize: 13,
                                  color: colorTextPrimary,
                                  fontWeight: MFontWeight.bold4.value,
                                ),
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                currentAutoDeleteDuration.value =
                                    autoDeleteOption[index].duration;
                                selectIndex.value = index;
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    CheckTickItem(
                                      isCheck:
                                          currentAutoDeleteDuration.value ==
                                              autoDeleteOption[index].duration,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          border: customBorder,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                        ),
                                        // height: 20,
                                        child: Text(
                                          autoDeleteOption[index].title,

                                          // 設置文本居中對齊
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    alignment: Alignment.centerRight,
                    child: ElevatedButtonTheme(
                      data: ElevatedButtonThemeData(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          disabledBackgroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: colorDivider,
                          elevation: 0.0,
                          textStyle: TextStyle(
                            fontSize: 13,
                            color: colorWhite,
                            fontWeight: MFontWeight.bold4.value,
                          ),
                        ),
                      ),
                      child: ElevatedButton(
                        child: Text(
                          localized(buttonDone),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorWhite,
                            fontWeight: MFontWeight.bold4.value,
                          ),
                        ),
                        onPressed: () {
                          // 在這裡處理按鈕點擊事件，設置Auto Delete選項
                          setAutoDeleteInterval(
                            autoDeleteOption[selectIndex.value].duration,
                            chatController: chatController,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: chatController.context,
        barrierColor: colorOverlay40,
        backgroundColor: colorBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            topLeft: Radius.circular(8),
          ),
        ),
        builder: (context) {
          return SizedBox(
            height: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 60,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      topLeft: Radius.circular(8),
                    ),
                  ),
                  child: SizedBox(
                    height: 26,
                    child: NavigationToolbar(
                      leading: Container(
                        width: 74,
                        alignment: Alignment.centerLeft,
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
                        localized(autoDeleteTimerTitle),
                        style: jxTextStyle.textStyleBold17(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker.builder(
                    scrollController: autoDeleteScrollController,
                    itemExtent: 44,
                    onSelectedItemChanged: (int index) {
                      selectIndex.value = index;
                    },
                    selectionOverlay: selectionOverlay,
                    itemBuilder: (context, index) {
                      AutoDeleteMessageModel item = autoDeleteOption[index];
                      return Obx(() {
                        TextStyle style;
                        if (selectIndex.value == index) {
                          style = TextStyle(
                            fontSize: MFontSize.size20.value,
                            fontWeight: MFontWeight.bold5.value,
                            color: Colors.black,
                            fontFamily: 'pingfang',
                          );
                        } else if (index == selectIndex.value - 1 ||
                            index == selectIndex.value + 1) {
                          style = TextStyle(
                            fontSize: MFontSize.size15.value,
                            fontWeight: MFontWeight.bold4.value,
                            color: Colors.black.withOpacity(0.44),
                            fontFamily: 'pingfang',
                          );
                        } else {
                          style = TextStyle(
                            fontSize: MFontSize.size11.value,
                            fontWeight: MFontWeight.bold4.value,
                            color: Colors.black.withOpacity(0.38),
                            fontFamily: 'pingfang',
                          );
                        }
                        return Center(
                          child: Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: style,
                          ),
                        );
                      });
                    },
                    childCount: autoDeleteOption.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: im.PrimaryButton(
                    bgColor: themeColor,
                    width: double.infinity,
                    fontSize: MFontSize.size17.value,
                    // fontFamily: 'pingfang',
                    fontWeight: MFontWeight.bold5.value,
                    title: localized(setAutoDeleteTimer),
                    onPressed: () {
                      Get.back();
                      // 在這裡處理按鈕點擊事件，設置Auto Delete選項
                      setAutoDeleteInterval(
                        autoDeleteOption[selectIndex.value].duration,
                        chatController: chatController,
                      );
                    },
                  ),
                ),
                if (autoDeleteIntervalEnable)
                  Container(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      top: 13,
                      bottom: 13,
                    ),
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        setAutoDeleteInterval(
                          0,
                          chatController: chatController,
                        );
                      },
                      child: Text(
                        localized(closeAutoDeleteTimer),
                        style: TextStyle(
                          fontSize: MFontSize.size17.value,
                          color: themeColor,
                          fontWeight: MFontWeight.bold4.value,
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom +
                      (Platform.isAndroid ? 12 : 0),
                ),
              ],
            ),
          );
        },
      ).whenComplete(() => autoDeleteScrollController.dispose());
    }
  }

  void setAutoDeleteInterval(
    int duration, {
    String? timeTitle,
    required BaseChatController chatController,
  }) async {
    /// call AutoDeleteMessage API
    int seconds = Duration(seconds: duration).inSeconds;
    final autoDeleteMessageStatus = await ChatHelp.sendAutoDeleteMessage(
      chatId: chatController.chat.id,
      interval: seconds,
    );

    if (autoDeleteMessageStatus) {
      // Get.back();
      String message = "";
      if (seconds == 0) {
        message = localized(alreadyCancelAutoDeleteMsg);
      } else if (seconds < 60) {
        bool isSingular = seconds == 1;
        message = '${localized(
          alreadyCancelAutoDeleteMsgParameter,
          params: [
            "\t${localized(
              isSingular ? secondParam : secondsParam,
              params: [
                "$seconds",
              ],
            )}"
          ],
        )}\t';
      } else if (seconds < 3600) {
        bool isSingular = seconds ~/ 60 == 1;
        message = localized(
          alreadyCancelAutoDeleteMsgParameter,
          params: [
            "\t${localized(
              isSingular ? minuteParam : minutesParam,
              params: [
                "${seconds ~/ 60}",
              ],
            )}\t"
          ],
        );
      } else if (seconds < 86400) {
        bool isSingular = seconds ~/ 3600 == 1;
        message = localized(
          turnOnAutoDeleteMessage,
          params: [
            "\t${localized(
              isSingular ? hourParam : hoursParam,
              params: [
                "${seconds ~/ 3600}",
              ],
            )}\t"
          ],
        );
      } else if (seconds < 2592000) {
        bool isSingular = seconds ~/ 86400 == 1;
        int day = seconds ~/ 86400;
        if (day == 7) {
          message = localized(
            turnOnAutoDeleteMessage,
            params: [
              "\t${timeTitle ?? localized(chatInfo1Week)}\t",
            ],
          );
        } else {
          message = localized(
            turnOnAutoDeleteMessage,
            params: [
              "\t${localized(
                isSingular ? dayParam : daysParam,
                params: [
                  "$day",
                ],
              )}\t"
            ],
          );
        }
      } else {
        bool isSingular = seconds ~/ 2592000 == 1;
        message = localized(
          alreadyCancelAutoDeleteMsgParameter,
          params: [
            "\t${localized(
              isSingular ? monthParam : monthsParam,
              params: [
                "${seconds ~/ 2592000}",
              ],
            )}\t"
          ],
        );
      }

      if (seconds == 0) {
        im.showCloseMuteToast(message, bottomMargin: bottomMargin);
      } else {
        im.showSetMuteToast(message, bottomMargin: bottomMargin);
      }
      //通知資料刷新
      Get.find<CustomInputController>(tag: chatController.chat.id.toString())
          .setAutoDeleteMsgInterval(seconds);
    }
  }

  void initDefaultSelect(RxInt selectIndex, BaseChatController controller) {
    selectIndex.value = 0;
    int? autoDeleteInterval = controller.chat.autoDeleteInterval;
    for (int index = 0; index < autoDeleteOption.length; index++) {
      if (autoDeleteOption[index].duration == autoDeleteInterval) {
        selectIndex.value = index;
        break;
      }
    }
  }
}
