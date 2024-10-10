import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/views/wallet/components/crypto_detail.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

import 'package:jxim_client/views/component/new_appbar.dart';

class CryptoView extends GetView<WalletController> {
  const CryptoView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      init: controller,
      builder: (_) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: PrimaryAppBar(
            title: '${controller.selectedTabCurrency.currencyType}',
          ),
          body: const SafeArea(
            child: CryptoDetail(),
          ),
        );
      },
    );
  }
}
