import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/custom_tab_bar.dart';

class CallLogView extends GetView<CallLogController> {
  const CallLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        isBackButton: false,
        titleWidget: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            // New call and delete all button
            Obx(
              () => Align(
                alignment: Alignment.centerLeft,
                child: !controller.isEditing.value
                    ? OpacityEffect(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Get.back(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/svgs/Back.svg',
                                width: 24,
                                height: 24,
                                color: themeColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                localized(buttonBack),
                                style: jxTextStyle.headerText(
                                  color: themeColor,
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    : CustomTextButton(
                        localized(notifDeleteAll),
                        onClick: () async => controller.onDeleteMultiCallLog(),
                      ),
              ),
            ),

            // Tab bar
            Container(
              height: 32,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: colorBackground6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomTabBar(
                tabController: controller.tabController,
                tabList: controller.callLogFilters,
              ),
            ),

            // Edit button
            Obx(
              () => Align(
                alignment: Alignment.centerRight,
                child: Visibility(
                  visible: controller.canEdit.value,
                  child: CustomTextButton(
                    controller.isEditing.value
                        ? localized(buttonDone)
                        : localized(edit),
                    isBold: controller.isEditing.value,
                    onClick: () {
                      controller.isEditing.value = !controller.isEditing.value;

                      if (!controller.isEditing.value) {
                        controller.clearSelectedChannelForEdit();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: controller.tabList,
      ),
    );
  }
}
