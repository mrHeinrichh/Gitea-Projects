import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/wallet/address/safety/address_security_setting_controller.dart';

class AddressSecuritySettingView
    extends GetView<AddressSecuritySettingController> {
  const AddressSecuritySettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(walletAddressSecuritySetting),
      ),
      body: CustomScrollableListView(
        children: [
          CustomRoundContainer(
            title: localized(walletWithdrawSafety),
            bottomText: localized(walletAddressWhitelistModeHint),
            child: CustomListTile(
              height: 56,
              text: localized(walletAddressWhitelistMode),
              textFontWeight: MFontWeight.bold5.value,
              subText: 'Tsvwl98548hjv...1tbagj',
              trailing: Obx(
                () => CustomSwitch(
                  value: controller.addressWhiteListModeSwitch.value,
                  onChanged: (bool value) async {
                    controller.setAddressWhiteListModeSwitch(value);
                  },
                ),
              ),
            ),
          ),
          CustomRoundContainer(
            title: localized(advanceSetting),
            child: CustomListTile(
              height: 56,
              text: localized(walletNewAddressWithdrawLock),
              textFontWeight: MFontWeight.bold5.value,
              subText: localized(walletNewAddressAvoidWith24hrsLock),
              trailing: Obx(
                () => CustomSwitch(
                  value: controller.newAddressWithdrawalSwitch.value,
                  onChanged: (bool value) async {
                    controller.setNewAddressWithdrawalSwitch(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
