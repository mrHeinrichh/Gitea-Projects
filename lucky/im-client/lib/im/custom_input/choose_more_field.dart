
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/net/connectivity_mgr.dart';
import '../../utils/toast.dart';
import 'custom_input_controller.dart';

class ChooseMoreField extends StatelessWidget {
  final CustomInputController controller;

  const ChooseMoreField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 16.0.w,
        horizontal: 12.0.w,
      ),
      // height: 50.h,
      child: Obx(() {
        bool hasSelect =
            controller.chatController.chooseMessage.values.isNotEmpty;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            /// 刪除
            GestureDetector(
              onTap: () {
                if (hasSelect && controller.chatController.canDelete.value) {
                  controller.onDeleteMessage(
                    context,
                    controller.chatController.chooseMessage.values.toList(),
                    isMore: true,
                  );
                }
              },
              child: Text(
                localized(buttonDelete),
                style: TextStyle(
                  color: hasSelect && controller.chatController.canDelete.value
                      ? JXColors.red
                      : const Color(0x7a121212),
                  fontSize: 17,
                ),
              ),
            ),

            /// 轉發
            GestureDetector(
              onTap: () {
                if (controller.chatController.chooseMessage.isEmpty) {
                  Toast.showToast(localized(toastSelectMessage));
                  return;
                }
                if (controller.chatController.canForward.value &&
                    connectivityMgr.connectivityResult !=
                        ConnectivityResult.none) {
                  controller.onForwardMessage();
                }
              },
              child: Text(
                localized(forward),
                style: TextStyle(
                  color: hasSelect
                      ? (controller.chatController.canForward.value &&
                      connectivityMgr.connectivityResult !=
                          ConnectivityResult.none)
                      ? accentColor
                      : const Color(0x7a121212)
                      : const Color(0x7a121212),
                  fontSize: 17,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
