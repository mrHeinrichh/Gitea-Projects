import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import '../../../home/component/custom_divider.dart';
import '../../../object/user.dart';
import '../../../utils/format_time.dart';
import '../contact_controller.dart';
import 'contact_card.dart';

class FriendRequestList extends GetWidget<ContactController> {
  const FriendRequestList(this.requestList, this.isFriendRequest, {Key? key}) : super(key: key);

  final RxMap<User, int> requestList;
  final bool isFriendRequest;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView.separated(
        itemCount: requestList.length,
        itemBuilder: (BuildContext context, int index) {
          List<User> users = requestList.keys.toList();
          List<int> statusList = requestList.values.toList();
          final User user = users[index];
          final int status = statusList[index];
          return Obx(() {
            return ContactCard(
              isSelectMode: controller.isSelectMode.value,
              isDisabled: status != 0,
              onTap: controller.isSelectMode.value && status == 0 ? () {
                if (controller.isSelectMode.value) {
                  controller.selectUser(user.accountId);
                }
              } : null,
              user: user,
              subTitle:
              localized(!isFriendRequest ? contactFriendSentTime : contactFriendRequestTime, params: ['${FormatTime
                  .formatTimeFun(user.requestTime, useOnline: false)}']),
              subTitleColor: JXColors.black48,
              trailing: !isFriendRequest
                  ? [
                Obx(() {
                  return Visibility(
                    visible: !controller.isSelectMode.value,
                    child: OverlayEffect(
                      overlayColor: status == 0
                          ? JXColors.primaryTextBlack.withOpacity(0.3)
                          : Colors.transparent,
                      radius: const BorderRadius.all(Radius.circular(8.0)),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (status == 0) {
                            controller.withdrawRequest(user);
                          }
                        },
                        child: Container(
                          height: 32.h,
                          width: 84.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: status == 0
                                  ? JXColors.primaryTextBlack.withOpacity(0.2)
                                  : Colors.transparent,
                              width: 1.w,
                            ),
                          ),
                          child: Center(
                            child: Text(
                                status == 0
                                    ? localized(withdraw)
                                    : localized(withdrawn),
                                style: jxTextStyle.textStyleBold12(
                                    color: JXColors.secondaryTextBlack)
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ]
                  : [
                    Visibility(
                      visible: !controller.isSelectMode.value,
                      child:  status == 0 ?
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              controller.rejectFriend(user);
                            },
                            child: ForegroundOverlayEffect(
                              overlayColor: JXColors.primaryTextBlack
                                  .withOpacity(0.3),
                              radius: const BorderRadius.all(
                                  Radius.circular(8.0)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: JXColors.red.withOpacity(0.48),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      8),
                                ),
                                child: Text(
                                  localized(reject),
                                  style: jxTextStyle.textStyleBold12(
                                      color: JXColors.red),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              controller.acceptFriend(user);
                            },
                            child: ForegroundOverlayEffect(
                              overlayColor: JXColors.primaryTextBlack
                                  .withOpacity(0.3),
                              radius: const BorderRadius.all(
                                  Radius.circular(8.0)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  border: Border.all(
                                    color: accentColor,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      8),
                                ),
                                child: Text(
                                  localized(accept),
                                  style: jxTextStyle.textStyleBold12(
                                      color: JXColors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                          : Text(
                        status == 1
                            ? localized(accepted)
                            : localized(rejected),
                        style: jxTextStyle.textStyleBold14(color: JXColors.black48),
                      ),
                    )
              ],
              gotoChat: false,
            );
          });
        },
        separatorBuilder: (BuildContext context, int index) =>
            Padding(
              padding: EdgeInsets.only(left: 60.w),
              child: const CustomDivider(),
            ),
      );
    });
  }
}
