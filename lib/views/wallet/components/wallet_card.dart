import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import 'package:intl/intl.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class WalletCard extends GetWidget<WalletController> {
  const WalletCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      init: controller,
      builder: (_) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wallet_background_img.png'),
                  fit: BoxFit.fill,
                  repeat: ImageRepeat.noRepeat,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${localized(walletTotalValue)} (${controller.walletBalanceCurrencyType})',
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 0.1,
                          fontWeight: MFontWeight.bold5.value,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          controller.isShowValue(!controller.isShowValue.value);
                          objectMgr.localStorageMgr.write(
                            LocalStorageMgr.HIDE_VALUE,
                            controller.isShowValue.value,
                          );
                        },
                        child: Obx(
                          () => SvgPicture.asset(
                            controller.isShowValue.value
                                ? 'assets/svgs/wallet/eye-hidden.svg'
                                : 'assets/svgs/wallet/eye-visible.svg',
                            width: 20,
                            height: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Obx(
                    () => RichText(
                      text: TextSpan(
                        text: controller.isShowValue.value
                            ? '≈ ${controller.walletBalance == 0 ? '0.00' : NumberFormat.currency(name: '').format(controller.walletBalance)} '
                            : '* ' * 6,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: MFontWeight.bold7.value,
                        ),
                        children: const <TextSpan>[],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.getUpdateTime(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: MFontWeight.bold4.value,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
