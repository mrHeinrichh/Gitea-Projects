import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/wallet/address/safety/address_security_setting_controller.dart';

class AddressSecuritySettingView
    extends GetView<AddressSecuritySettingController> {
  const AddressSecuritySettingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PrimaryAppBar(
        bgColor: Colors.transparent,
        title: '地址安全设置',
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 24.0,
          left: 16.0,
          right: 16.0,
          bottom: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                '提币安全',
                style: jxTextStyle.textStyle13(color: JXColors.black48),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SettingItem(
                withEffect: false,
                title: '地址白名单模式',
                subtitle: 'Tsvwl98548hjv...1tbagj',
                withArrow: false,
                withBorder: false,
                paddingVerticalMobile: 6.5,
                rightWidget: SizedBox(
                  height: 28,
                  width: 48,
                  child: Obx(() => CupertinoSwitch(
                        value: controller.addressWhiteListModeSwitch.value,
                        activeColor: JXColors.green,
                        onChanged: (bool value) {
                          pdebug("Switch state changed to: $value");
                          controller.setAddressWhiteListModeSwitch(value);
                        },
                      )),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                '启用后您只可以提币至您的地址薄内的地址。',
                style: jxTextStyle.textStyle12(color: JXColors.black48),
              ),
            ),
            ImGap.vGap24,
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                '高级设置',
                style: jxTextStyle.textStyle13(color: JXColors.black48),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SettingItem(
                withEffect: false,
                title: '新地址提币锁定',
                subtitle: '24小时内避免提币至新白名单地址',
                withArrow: false,
                withBorder: false,
                paddingVerticalMobile: 6.5,
                rightWidget: SizedBox(
                  height: 28,
                  width: 48,
                  child: Obx(() => CupertinoSwitch(
                        value: controller.newAddressWithdrawalSwitch.value,
                        activeColor: JXColors.green,
                        onChanged: (bool value) {
                          pdebug("Switch state changed to: $value");
                          controller.setNewAddressWithdrawalSwitch(value);
                        },
                      )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
