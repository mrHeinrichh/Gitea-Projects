import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' hide ImBottomToast, ImBottomNotifType;
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/contact/friend_request_confirm.dart';

class FriendRequestBottomSheet extends StatelessWidget {
  final User user;

  const FriendRequestBottomSheet({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.94,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          color: ImColor.bg,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12),
            topLeft: Radius.circular(12),
          ),
        ),
        child: Column(
          children: <Widget>[
            Container(
              height: 60,
              alignment: Alignment.center,
              child: NavigationToolbar(
                leading: OpacityEffect(
                  child: SizedBox(
                    width: 70,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Get.back();
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Text(
                          localized(buttonCancel),
                          style: jxTextStyle.textStyle17(color: themeColor),
                        ),
                      ),
                    ),
                  ),
                ),
                middle: Text(
                  localized(createNewContact),
                  style: jxTextStyle.textStyleBold17(),
                ),
              ),
            ),
            SizedBox(height: 30.w),
            CustomAvatar.user(user, size: 100),
            SizedBox(height: 8.w),
            Text(
              user.nickname.length > 10
                  ? subUtf8String(
                      user.nickname,
                      10,
                    )
                  : user.nickname,
              style: jxTextStyle.textStyleBold28(),
            ),
            Text(
              UserUtils.onlineStatus(user.lastOnline),
              style: jxTextStyle.textStyle17(color: ImColor.black32),
            ),
            SizedBox(height: 16.w),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ImColor.white,
                borderRadius: BorderRadius.circular(8),
              ),
              width: 358.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localized(chatProfileBio),
                    style: jxTextStyle.textStyle17(),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.profileBio.isEmpty ? '-' : user.profileBio,
                    style: jxTextStyle.textStyle17(),
                  ),
                  const SizedBox(height: 9),
                  Divider(
                    color: colorTextPrimary.withOpacity(0.2),
                    thickness: 0.33,
                    height: 1,
                  ),
                  const SizedBox(height: 11),
                  ImTextButton(
                    title: localized(sendFriendReq),
                    color: themeColor,
                    onClick: () => addFriend(context),
                  ),
                  const SizedBox(height: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void addFriend(context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: FriendRequestConfirm(
            user: user,
            confirmCallback: (remark) {
              imBottomToast(
                context,
                title: localized(sendingFriendReq, params: [user.nickname]),
                icon: ImBottomNotifType.timer,
                duration: 5,
                withCancel: true,
                timerFunction: () {
                  objectMgr.userMgr.addFriend(user, remark: remark);
                },
                undoFunction: () {
                  BotToast.removeAll(BotToast.textKey);
                },
              );
            },
            cancelCallback: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}
