import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/component/component.dart';

class CallLogView extends StatelessWidget {
  const CallLogView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final CallLogController controller = Get.find<CallLogController>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        isBackButton: false,
        titleWidget: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            // Tab bar
            Container(
              height: 32,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: colorBorder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                splashFactory: NoSplash.splashFactory,
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                controller: controller.tabController,
                dividerColor: Colors.transparent,
                isScrollable: true,
                indicator: BoxDecoration(
                  color: colorWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelStyle: TextStyle(
                  fontSize: MFontSize.size13.value,
                  fontWeight: MFontWeight.bold5.value,
                  leadingDistribution: TextLeadingDistribution.even,
                  fontFamily: appFontfamily,
                ),
                labelColor: colorTextPrimary,
                unselectedLabelColor: colorTextPrimary,
                labelPadding: EdgeInsets.zero,
                tabs: controller.callLogFilters.map((title) {
                  return Tab(
                    child: OpacityEffect(
                      child: Container(
                        alignment: Alignment.center,
                        width: 75,
                        child: Text(title),
                      ),
                    ),
                  );
                }).toList(),
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

            // New call and delete all button
            Obx(
              () => Align(
                alignment: Alignment.centerLeft,
                child: !controller.isEditing.value
                    ? const CustomLeadingIcon(needPadding: false)
                    : CustomTextButton(
                        localized(notifDeleteAll),
                        onClick: () async => controller.onDeleteMultiCallLog(),
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
