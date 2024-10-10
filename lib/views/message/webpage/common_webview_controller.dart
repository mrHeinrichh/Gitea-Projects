import 'dart:io';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CommonWebViewController extends GetxController {

  final url = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if(Platform.isAndroid){
      WebView.platform = AndroidWebView();
    }

    final Map<String, dynamic> arguments = Get.arguments;
    url.value = arguments['url'];
  }

}
