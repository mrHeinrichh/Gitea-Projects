import 'package:get/get.dart';
import 'package:jxim_client/views/wallet/controller/wallet_controller.dart';

class WalletBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WalletController());
  }
}
