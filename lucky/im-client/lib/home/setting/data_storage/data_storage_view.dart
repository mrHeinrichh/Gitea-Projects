import 'package:cbb_video_player/utils/color.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/data_storage/data_storage_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

import '../../../utils/localization/app_localizations.dart';
import '../../../views/component/dot_loading_view.dart';
import '../../../views/component/new_appbar.dart';

class DataAndStorageView extends GetView<DataAndStorageController> {
  const DataAndStorageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(dataStorage),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        width: MediaQuery.of(context).size.width,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: Stack(
                children: [
                  Obx(
                    () => PieChart(
                      PieChartData(
                        sections: showingSections(),
                        sectionsSpace: 0,
                        startDegreeOffset: 270.0,
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 150),
                      swapAnimationCurve: Curves.linear,
                    ),
                  ),
                  Obx(
                    () => Positioned(
                      top: 16,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.totalSize.value.toStringAsFixed(2),
                            style: jxTextStyle.textStyleBold24(),
                          ),
                          Text(
                            'MB',
                            style: jxTextStyle.textStyle12(
                                color: JXColors.secondaryTextBlack),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  controller.dataStorageList.length,
                  (index) => dataStorageItem(controller.dataStorageList[index]),
                ),
              ),
            ),
            Obx(
              () => Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  localized(lessThanParamOfPhoneStorage, params: [
                    "${controller.totalPercentage.value.toStringAsFixed(2)}"
                  ]),
                  style: jxTextStyle.textStyle14(
                      color: JXColors.secondaryTextBlack),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => controller.isClearing.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: DotLoadingView(
                        size: 8,
                        dotColor: JXColors.primaryTextBlack,
                      ),
                    )
                  : OverlayEffect(
                      radius: const BorderRadius.all(Radius.circular(12)),
                      child: GestureDetector(
                        onTap: () => controller.showPopup(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          width: MediaQuery.of(context).size.width,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              border: Border.all(color: JXColors.outlineColor),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12))),
                          child: Text(
                            localized(clearAllCache),
                            style:
                                jxTextStyle.textStyleBold14(color: errorColor),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(
      controller.dataStorageList.length,
      (index) {
        final item = controller.dataStorageList[index];
        return PieChartSectionData(
          radius: 50,
          title: "${item.percentage?.toStringAsFixed(0) ?? "0"}%",
          titleStyle: jxTextStyle.textStyle12(color: Colors.white),
          value: item.percentage,
          color: item.color,
        );
      },
    );
  }

  Widget dataStorageItem(DataStorageModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 6,
            decoration: BoxDecoration(
                color: item.color,
                borderRadius: const BorderRadius.all(Radius.circular(20))),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              "${item.title} (${item.percentage?.toStringAsFixed(0)}%)",
              style: jxTextStyle.textStyle14(),
            ),
          ),
          Text(
            "${item.size?.toStringAsFixed(2)} MB",
            style: jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
          ),
        ],
      ),
    );
  }
}
