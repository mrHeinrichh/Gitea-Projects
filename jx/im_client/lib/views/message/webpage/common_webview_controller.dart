import 'dart:io';
import 'package:get/get.dart';

class CommonWebViewController extends GetxController {
  final url = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (Platform.isAndroid) {
      // WebView.platform = AndroidWebView();
    }

    final Map<String, dynamic> arguments = Get.arguments;
    url.value = arguments['url'];
  }
}
