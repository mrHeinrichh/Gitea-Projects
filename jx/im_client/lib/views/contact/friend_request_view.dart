import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_alert_dialog.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/contact/components/friend_request_list.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';

class FriendRequestView extends GetWidget<ContactController> {
  const FriendRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: localized(contactFriendRequest),
        leadingWidth: 0,
        titleSpacing: 0,
        isBackButton: false,
        titleWidget: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Container(
              height: 28,
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                textAlign: TextAlign.center,
                localized(contactFriendRequest),
                style: jxTextStyle.appTitleStyle(color: colorTextPrimary),
              ),
            ),
            Positioned(
              left: 0,
              child: CustomLeadingIcon(
                buttonOnPressed: () {
                  controller.isSelectMode(false);
                  controller.selectedList.clear();
                  Get.back();
                },
                backButtonColor: themeColor,
                withBackTxt: true,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        return controller.requestFriendUserList.isEmpty
            ? const FriendRequestEmptyState()
            : FriendRequestList(controller.requestFriendUserList);
      }),
    );
  }

  Widget buildOld(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: localized(contactFriendRequest),
        leadingWidth: 0,
        titleSpacing: 0,
        isBackButton: false,
        titleWidget: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Container(
              height: 28,
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                textAlign: TextAlign.center,
                localized(contactFriendRequest),
                style: jxTextStyle.appTitleStyle(color: colorTextPrimary),
              ),
            ),
            Positioned(
              left: 0,
              child: CustomLeadingIcon(
                buttonOnPressed: () {
                  controller.isSelectMode(false);
                  controller.selectedList.clear();
                  Get.back();
                },
                backButtonColor: themeColor,
                withBackTxt: true,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        return controller.requestFriendUserList.isEmpty
            ? const FriendRequestEmptyState()
            : FriendRequestList(controller.requestFriendUserList);
      }),
      bottomNavigationBar: Obx(() {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: controller.isSelectMode.value ? 1.0 : 0.0,
          curve: Curves.easeOut,
          child: BottomAppBar(
            elevation: 0.0,
            color: colorBackground,
            child: AnimatedPadding(
              duration: Duration(
                milliseconds: controller.isSelectMode.value ? 50 : 500,
              ),
              padding: EdgeInsets.all(controller.isSelectMode.value ? 16 : 0),
              curve: Curves.easeOut,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OpacityEffect(
                    child: GestureDetector(
                      onTap: () {
                        if (controller.selectedList.isNotEmpty) {
                          if (controller.tabController?.index == 0) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CustomAlertDialog(
                                  title: controller.selectedList.length > 1
                                      ? localized(
                                          batchAcceptRequest,
                                          params: [
                                            controller.selectedList.length
                                                .toString(),
                                          ],
                                        )
                                      : localized(acceptRequest),
                                  confirmText: localized(buttonAccept),
                                  cancelText: localized(buttonCancel),
                                  confirmCallback: () =>
                                      controller.friendListAction(
                                    ContactController.ACCEPT_COLLECTION,
                                  ),
                                );
                              },
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CustomAlertDialog(
                                  title: controller.selectedList.length > 1
                                      ? localized(
                                          batchWithdrawRequest,
                                          params: [
                                            controller.selectedList.length
                                                .toString(),
                                          ],
                                        )
                                      : localized(withdrawRequest),
                                  confirmText: localized(withdraw),
                                  cancelText: localized(buttonCancel),
                                  confirmCallback: () =>
                                      controller.friendListAction(
                                    ContactController.WITHDRAW_COLLECTION,
                                  ),
                                );
                              },
                            );
                          }
                        }
                      },
                      child: controller.tabController?.index == 0
                          ? Text(
                              localized(accept),
                              style: jxTextStyle.textStyle17(
                                color: controller.selectedList.isNotEmpty
                                    ? themeColor
                                    : colorTextSupporting,
                              ),
                            )
                          : Text(
                              localized(withdraw),
                              style: jxTextStyle.textStyle17(
                                color: controller.selectedList.isNotEmpty
                                    ? themeColor
                                    : colorTextSupporting,
                              ),
                            ),
                    ),
                  ),
                  Visibility(
                    visible: controller.tabController?.index == 0,
                    child: OpacityEffect(
                      child: GestureDetector(
                        onTap: () {
                          if (controller.selectedList.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CustomAlertDialog(
                                  title: controller.selectedList.length > 1
                                      ? localized(
                                          batchRejectRequest,
                                          params: [
                                            controller.selectedList.length
                                                .toString(),
                                          ],
                                        )
                                      : localized(rejectRequest),
                                  confirmText: localized(reject),
                                  cancelText: localized(buttonNo),
                                  confirmCallback: () =>
                                      controller.friendListAction(
                                    ContactController.REJECT_COLLECTION,
                                  ),
                                );
                              },
                            );
                          }
                        },
                        child: Text(
                          localized(reject),
                          style: jxTextStyle.textStyle17(
                            color: controller.selectedList.isNotEmpty
                                ? colorRed
                                : colorTextSupporting,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class FriendRequestEmptyState extends StatelessWidget {
  const FriendRequestEmptyState({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 108.h),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/svgs/friend_request_empty.svg',
            width: 148,
            height: 148,
          ),
          Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: Text(
              localized(nothingHere),
              style: jxTextStyle.textStyleBold16(),
            ),
          ),
        ],
      ),
    );
  }
}
