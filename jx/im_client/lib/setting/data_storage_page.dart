import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/paths/app_path.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views_desktop/component/desktop_dialog.dart';

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
    databasesPath = AppPath.applicationSupportPath;
    dataUsage = getTotalUsage(databasesPath);

    mediaUsage = getTotalUsage("${AppPath.appDownloadPath}/");
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(dataStorage),
        onPressedBackBtn: () {
          Get.back(id: 3);
          Get.find<SettingController>().desktopSettingCurrentRoute = '';
          Get.find<SettingController>().selectedIndex.value = 101010;
        },
      ),
      body: Column(
        children: [
          SizedBox(
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
                      backgroundColor: themeColor,
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
                            ),
                          );
                        },
                      );
                    },
                    child: Text(
                      'Clear all data',
                      style: jxTextStyle
                          .textStyleBold16(
                            color: colorWhite,
                            fontWeight: MFontWeight.bold6.value,
                          )
                          .copyWith(height: 1.2),
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

  List<PieChartSectionData> showingSections() {
    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color(0xFF9B61E5),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Media'),
            ),
            badgePositionPercentageOffset: .98,
          );
        case 1:
          return PieChartSectionData(
            color: Colors.yellow,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Data'),
            ),
            badgePositionPercentageOffset: .98,
          );
        default:
          throw Exception('Oh no');
      }
    });
  }
}
