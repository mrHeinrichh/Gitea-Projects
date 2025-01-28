import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify_other_confirm/friend_verify_other_confirm_controller.dart';
import 'package:jxim_client/views/component/component.dart';

class FriendVerifyOtherConfirmView
    extends GetView<FriendVerifyOtherConfirmController> {
  const FriendVerifyOtherConfirmView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: const PrimaryAppBar(
        title: '好友辅助',
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/encryption_friend_verify_icon.png',
                width: 88,
                height: 88,
              ),
              const SizedBox(height: 20),
              Text(
                '好友辅助验证',
                style:
                jxTextStyle.titleText(fontWeight: MFontWeight.bold5.value),
              ),
              const SizedBox(height: 8),
              Text(
                "帮助好友完成设备的聊天记录恢复",
                style: jxTextStyle.headerText(color: colorTextSecondary),
              ),
              const SizedBox(height: 24),
              Text(
                "请确认他/她本人通过电话或其他方式向您发起辅助请求，请防诈骗。",
                style: jxTextStyle.headerText(color: colorTextSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              CustomButton(
                text: "确认是他本人联系我",
                isBold: true,
                callBack: () => controller.onConfirmClick(),
              ),
              GestureDetector(
                onTap: () => controller.onNotSureClick(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36.0),
                  child: Text(
                    "不确定",
                    style: jxTextStyle.headerText(color: themeColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
