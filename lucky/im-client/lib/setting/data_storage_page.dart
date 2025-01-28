import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';

import '../home/setting/setting_controller.dart';
import '../main.dart';
import '../utils/color.dart';
import '../utils/lang_util.dart';
import '../utils/localization/app_localizations.dart';
import '../utils/theme/text_styles.dart';
import '../utils/utility.dart';
import '../views/component/click_effect_button.dart';
import 'package:get/get.dart';

import '../views_desktop/component/DesktopDialog.dart';

class DataStoragePage extends StatefulWidget {
  const DataStoragePage({super.key});

  @override
  State<DataStoragePage> createState() => _DataStoragePageState();
}

class _DataStoragePageState extends State<DataStoragePage> {
  int totalUsage = 0;
  int touchedIndex = 99;
  int mediaUsage = 0;
  int dataUsage = 0;

  @override
  void initState() {
    getTotal();
    super.initState();
  }

  void getTotal() async {
    var databasesPath = "";
    if (Platform.isMacOS) {
      final path = await getApplicationSupportDirectory();
      databasesPath = path.path.toString();
    }
    dataUsage = getTotalUsage(databasesPath);

    final document = await getApplicationDocumentsDirectory();
    mediaUsage = getTotalUsage("${document.path.toString()}/");
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: const Border(
                bottom: BorderSide(
                  color: JXColors.outlineColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              /// 普通界面
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                OpacityEffect(
                  child: GestureDetector(
                    onTap: () {
                      Get.back(id: 3);
                      Get.find<SettingController>().desktopSettingCurrentRoute =
                          '';
                      Get.find<SettingController>().selectedIndex.value =
                          101010;
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/svgs/Back.svg',
                            width: 18,
                            height: 18,
                            color: JXColors.blue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            localized(buttonBack),
                            style: const TextStyle(
                              fontSize: 13,
                              color: JXColors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  localized(dataStorage),
                  style: const TextStyle(
                    fontSize: 16,
                    color: JXColors.black,
                  ),
                ),
                const SizedBox(width: 100),
              ],
            ),
          ),
          Container(
            width: 300,
            height: 300,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                    // touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    //   setState(() {
                    //     if (!event.isInterestedForInteractions ||
                    //         pieTouchResponse == null ||
                    //         pieTouchResponse.touchedSection == null) {
                    //       touchedIndex = -1;
                    //       return;
                    //     }
                    //     touchedIndex =
                    //         pieTouchResponse.touchedSection!.touchedSectionIndex;
                    //   });
                    // },
                    ),
                borderData: FlBorderData(
                  show: false,
                ),
                sectionsSpace: 0,
                centerSpaceRadius: 0,
                sections: showingSections(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Total Usage: ${bytesToMB(dataUsage + mediaUsage).toStringAsFixed(2)} MB",
              style: jxTextStyle.textStyleBold24(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      backgroundColor: accentColor,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      splashFactory: NoSplash.splashFactory,
                      animationDuration: const Duration(milliseconds: 1),
                    ),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return DesktopDialog(
                                dialogSize: const Size(400, 150),
                                child: DesktopDialogWithButton(
                                  title: localized(clearCache),
                                  subtitle: localized(clearDescription),
                                  buttonLeftText: localized(cancel),
                                  buttonLeftOnPress: () {
                                    Get.back();
                                  },
                                  buttonRightText: localized(clearButton),
                                  buttonRightOnPress: () {
                                    objectMgr.clearData();
                                  },
                                ));
                          });
                    },
                    child: Text(
                      'Clear all data',
                      style: jxTextStyle.textStyleBold16(
                        color: JXColors.white,
                        fontWeight: MFontWeight.bold6.value,
                      ).copyWith(height: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: objectMgr.loginMgr.isDesktop
          ? const EdgeInsets.only(left: 16, bottom: 4)
          : const EdgeInsets.only(left: 16, bottom: 4).w,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: JXColors.secondaryTextBlack,
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      final widgetSize = isTouched ? 55.0 : 40.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: JXColors.onBoardingLightPurple,
            value: mediaUsage.toDouble(),
            title:
                '${((mediaUsage / (mediaUsage + dataUsage)) * 100).toStringAsFixed(2)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
              shadows: shadows,
            ),
            badgeWidget: Container(
              width: 60,
              height: 30,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text('Media'),
            ),
            badgePositionPercentageOffset: .98,
          );
        case 1:
          return PieChartSectionData(
            color: JXColors.yellow,
            value: dataUsage.toDouble(),
            title:
                '${((dataUsage / (mediaUsage + dataUsage)) * 100).toStringAsFixed(2)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
              shadows: shadows,
            ),
            badgeWidget: Container(
              width: 60,
              height: 30,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text('Data'),
            ),
            badgePositionPercentageOffset: .98,
          );
        default:
          throw Exception('Oh no');
      }
    });
  }
}
