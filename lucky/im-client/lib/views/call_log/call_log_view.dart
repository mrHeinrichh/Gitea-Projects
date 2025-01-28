import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import 'component/call_bottom_modal.dart';

class CallLogView extends StatelessWidget {
  const CallLogView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CallLogController controller = Get.find<CallLogController>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PrimaryAppBar(
        bgColor: backgroundColor,
        isBackButton: false,
        titleWidget: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            // Tab bar
            Container(
              height: 28,
              width: double.infinity,
              alignment: Alignment.center,
              child: TabBar(
                splashFactory: NoSplash.splashFactory,
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                controller: controller.tabController,
                isScrollable: true,
                dividerColor: Colors.transparent,
                tabAlignment: TabAlignment.center,
                indicator: BoxDecoration(
                  color: JXColors.bgTertiaryColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorColor: Colors.transparent,
                labelStyle: TextStyle(
                  color: JXColors.primaryTextBlack,
                  fontSize: 14,
                  fontWeight: MFontWeight.bold5.value,
                  leadingDistribution: TextLeadingDistribution.even,
                  fontFamily: appFontfamily
                ),
                unselectedLabelColor: JXColors.secondaryTextBlack,
                labelPadding: EdgeInsets.zero,
                tabs: [localized(all), localized(missed)].map((title) {
                  return Tab(
                    child: OpacityEffect(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        child: Text(title),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Edit button
            Obx(
              () => Positioned(
                left: 0,
                child: AbsorbPointer(
                  absorbing: !controller.canEdit.value,
                  child: GestureDetector(
                    onTap: () {
                      if (controller.canEdit.value)
                        controller.isEditing.value =
                            !controller.isEditing.value;
                      if (controller.isEditing.value == false) {
                        controller.clearSelectedChannelForEdit();
                      }
                    },
                    child: OpacityEffect(
                      child: Text(
                        controller.isEditing.value && controller.canEdit.value
                            ? localized(buttonDone)
                            : localized(edit),
                        style: jxTextStyle.textStyle17(
                          color: controller.canEdit.value
                              ? accentColor
                              : JXColors.supportingTextBlack,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // New call and delete all button
            Obx(
              () => Positioned(
                right: 0,
                child: OpacityEffect(
                  child: !controller.isEditing.value
                      ? GestureDetector(
                          onTap: () => showCallBottomModalSheet(context),
                          child: SvgPicture.asset(
                            'assets/svgs/new_call.svg',
                            color: accentColor,
                            width: 24,
                            height: 24,
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            final hasSelect =
                                controller.selectedChannelIDForEdit.isNotEmpty;
                            if (hasSelect) {
                              controller.onDeleteMultiCallLog();
                            }
                          },
                          child: Text(
                            localized(notifDeleteAll),
                            style: TextStyle(
                              fontSize: 17,
                              color: controller.selectedChannelIDForEdit.isNotEmpty ? accentColor : JXColors.supportingTextBlack,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: JXColors.black24,
            height: 0.3,
          ),
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: controller.tabList,
        physics: const NeverScrollableScrollPhysics(),
      ),
    );
  }
}
