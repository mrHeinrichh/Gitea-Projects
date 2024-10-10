import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/controller/date_time_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/utils/format_date_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class DateTimeView extends GetView<DateTimeController> {
  const DateTimeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: colorBackground,
        appBar: PrimaryAppBar(
          title: localized(dateTime),
          trailing: [
            Visibility(
              visible: controller.timeFormat.value !=
                      controller.timeFormatFromLs ||
                  controller.dateFormat.value != controller.dateFormatFromLs,
              child: GestureDetector(
                onTap: () => controller.changeFormat(),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    localized(buttonDone),
                    style: jxTextStyle.textStyle17(color: themeColor),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: ListView(
                  children: [
                    /// Time Format
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(localized(timeFormat)),
                          Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                SettingItem(
                                  onTap: () => controller.setTimeFormat(
                                      DateTimeStyle.twentyFourFormat.value),
                                  title: FormatDateTime.timerConverter(
                                      timeFormat:
                                          DateTimeStyle.twentyFourFormat.value,
                                      timestamp: controller.currentDateTime),
                                  subtitle: localized(twentyFourHourTime),
                                  withArrow: false,
                                  rightWidget: controller.timeFormat.value ==
                                          DateTimeStyle.twentyFourFormat.value
                                      ? SvgPicture.asset(
                                          'assets/svgs/check.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: ColorFilter.mode(
                                            themeColor,
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : const SizedBox(),
                                ),
                                SettingItem(
                                  onTap: () => controller.setTimeFormat(
                                      DateTimeStyle.twelveFormat.value),
                                  title: FormatDateTime.timerConverter(
                                      timeFormat:
                                          DateTimeStyle.twelveFormat.value,
                                      timestamp: controller.currentDateTime),
                                  subtitle: localized(twelveHourTime),
                                  withArrow: false,
                                  rightWidget: controller.timeFormat.value ==
                                          DateTimeStyle.twelveFormat.value
                                      ? SvgPicture.asset(
                                          'assets/svgs/check.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: ColorFilter.mode(
                                            themeColor,
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : const SizedBox(),
                                  withBorder: false,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Date Format
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(localized(dateFormat)),
                          Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                SettingItem(
                                  onTap: () => controller.setDateFormat(
                                      DateTimeStyle.ddmmyyyySlash.value),
                                  title: FormatDateTime.timerConverter(
                                      timeFormat:
                                          DateTimeStyle.ddmmyyyySlash.value,
                                      timestamp: controller.currentDateTime),
                                  subtitle: 'dd/mm/yyyy',
                                  withArrow: false,
                                  rightWidget: controller.dateFormat.value ==
                                          DateTimeStyle.ddmmyyyySlash.value
                                      ? SvgPicture.asset(
                                          'assets/svgs/check.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: ColorFilter.mode(
                                            themeColor,
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : const SizedBox(),
                                ),
                                SettingItem(
                                  onTap: () => controller.setDateFormat(
                                      DateTimeStyle.mmddyyyySlash.value),
                                  title: FormatDateTime.timerConverter(
                                      timeFormat:
                                          DateTimeStyle.mmddyyyySlash.value,
                                      timestamp: controller.currentDateTime),
                                  subtitle: 'mm/dd/yyyy',
                                  withArrow: false,
                                  rightWidget: controller.dateFormat.value ==
                                          DateTimeStyle.mmddyyyySlash.value
                                      ? SvgPicture.asset(
                                          'assets/svgs/check.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: ColorFilter.mode(
                                            themeColor,
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : const SizedBox(),
                                ),
                                SettingItem(
                                  onTap: () => controller.setDateFormat(
                                      DateTimeStyle.ddmmyyyyDash.value),
                                  title: FormatDateTime.timerConverter(
                                      timeFormat:
                                          DateTimeStyle.ddmmyyyyDash.value,
                                      timestamp: controller.currentDateTime),
                                  subtitle: 'dd-mm-yyyy',
                                  withArrow: false,
                                  rightWidget: controller.dateFormat.value ==
                                          DateTimeStyle.ddmmyyyyDash.value
                                      ? SvgPicture.asset(
                                          'assets/svgs/check.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: ColorFilter.mode(
                                            themeColor,
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : const SizedBox(),
                                ),
                                SettingItem(
                                  onTap: () => controller.setDateFormat(
                                      DateTimeStyle.mmddyyyyDash.value),
                                  title: FormatDateTime.timerConverter(
                                      timeFormat:
                                          DateTimeStyle.mmddyyyyDash.value,
                                      timestamp: controller.currentDateTime),
                                  subtitle: 'mm-dd-yyyy',
                                  withArrow: false,
                                  rightWidget: controller.dateFormat.value ==
                                          DateTimeStyle.mmddyyyyDash.value
                                      ? SvgPicture.asset(
                                          'assets/svgs/check.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: ColorFilter.mode(
                                            themeColor,
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : const SizedBox(),
                                ),
                                SettingItem(
                                  onTap: () => controller.setDateFormat(
                                      DateTimeStyle.ddmmmyyyy.value),
                                  title: FormatDateTime.timerConverter(
                                      timeFormat: DateTimeStyle.ddmmmyyyy.value,
                                      timestamp: controller.currentDateTime),
                                  subtitle: localized(ddmmmyyyyformat),
                                  withArrow: false,
                                  rightWidget: controller.dateFormat.value ==
                                          DateTimeStyle.ddmmmyyyy.value
                                      ? SvgPicture.asset(
                                          'assets/svgs/check.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: ColorFilter.mode(
                                            themeColor,
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : const SizedBox(),
                                ),
                                SettingItem(
                                  onTap: () => controller.setDateFormat(
                                      DateTimeStyle.mmmddyyyy.value),
                                  title: FormatDateTime.timerConverter(
                                      timeFormat: DateTimeStyle.mmmddyyyy.value,
                                      timestamp: controller.currentDateTime),
                                  subtitle: localized(mmmddyyyyformat),
                                  withArrow: false,
                                  rightWidget: controller.dateFormat.value ==
                                          DateTimeStyle.mmmddyyyy.value
                                      ? SvgPicture.asset(
                                          'assets/svgs/check.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: ColorFilter.mode(
                                            themeColor,
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: colorTextSecondary,
        ),
      ),
    );
  }
}
