import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/call_log/call_log_controller.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_contact_list.dart';
import 'package:jxim_client/views/component/searching_app_bar.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class CallBottomModal extends StatelessWidget {
  const CallBottomModal({super.key});

  @override
  Widget build(BuildContext context) {
    final CallLogController controller = Get.find<CallLogController>();
    return Container(
      height: ObjectMgr.screenMQ!.size.height * 0.9,
      decoration: BoxDecoration(
        color: colorBackground,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.sp),
          topLeft: Radius.circular(20.sp),
        ),
      ),
      child: Column(
        children: [
          Obx(
            () => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: !controller.isSearching.value ? 52 : 0,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: OpacityEffect(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            localized(cancel),
                            style: jxTextStyle.textStyle17(
                              color: themeColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      localized(newCall),
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: MFontWeight.bold6.value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 8,
              top: 8,
            ),
            child: Obx(() {
              return SearchingAppBar(
                onTap: () => controller.isSearching(true),
                onChanged: controller.onSearchChanged,
                onCancelTap: () {
                  controller.searchFocus.unfocus();
                  controller.clearSearching();
                },
                isSearchingMode: controller.isSearching.value,
                isAutoFocus: false,
                focusNode: controller.searchFocus,
                controller: controller.searchController,
                suffixIcon: Visibility(
                  visible: controller.searchParam.value.isNotEmpty,
                  child: GestureDetector(
                    onTap: () {
                      controller.searchController.clear();
                      controller.searchParam.value = '';
                      controller.search();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SvgPicture.asset(
                        'assets/svgs/close_round_icon.svg',
                        width: 20,
                        height: 20,
                        color: colorTextSupporting,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Container(
            height: 1.h,
            color: colorBorder,
          ),
          Expanded(
            child: Obx(
              () => controller.azFriendList.isEmpty
                  ? SizedBox(
                      height: double.infinity,
                      width: double.infinity,
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            SvgPicture.asset(
                              'assets/svgs/no_contact.svg',
                              width: 100,
                              height: 100,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localized(noResults),
                              style: jxTextStyle.textStyleBold16(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              localized(noMatchingContactsWereFound),
                              style: jxTextStyle.textStyle16(
                                color: colorTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.white,
                      child: CustomContactList(
                        isCalling: true,
                        contactList: controller.azFriendList,
                        isSearching: controller.isSearching.value,
                        isShowIndexBar: true.obs,
                        isShowingTag: true.obs,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

Future showCallBottomModalSheet(BuildContext context) {
  CallLogController controller = Get.find<CallLogController>();
  controller.getFriendList();
  return showModalBottomSheet(
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    context: context,
    builder: (context) => const CallBottomModal(),
  ).then(
    (value) => controller.clearSearching(),
  );
}
