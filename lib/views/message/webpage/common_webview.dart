import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/message/webpage/common_webview_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CommonWebViewPage extends GetView<CommonWebViewController> {
  const CommonWebViewPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // final gameUrl = 'https://games.cdn.famobi.com/html5games/o/om-nom-run/v1240/?fg_domain=play.famobi.com&fg_aid=A1000-100&fg_uid=abe80572-560a-444d-baf7-2fa4a7b2c02f&fg_pid=5a106c0b-28b5-48e2-ab01-ce747dda340f&fg_beat=225&original_ref=https%3A%2F%2Fhtml5games.com%2F';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: colorWhite,
        body: SafeArea(
          child: Stack(
            children: [
              Obx(
                () => WebView(
                  initialUrl: controller.url.value,
                  javascriptMode: JavascriptMode.unrestricted,
                  zoomEnabled: true,
                ),
              ),
              Positioned(
                top: 12,
                right: 20,
                child: InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorTextPrimary.withOpacity(0.5),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: colorRed,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                      ),
                    ),
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
