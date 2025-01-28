import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/object/install_info.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';

class ShareController extends GetxController {
  var installedApp = {};
  bool isWhatsappInstalled = true;
  bool isTelegramInstalled = true;
  final downloadLink = '${Config().officialUrl}downloads/'.obs;
  final isLoading = false.obs;

  final int? groupChatId;

  ShareController({this.groupChatId}) : super();

  @override
  onInit() {
    super.onInit();
    getDownloadLink();
  }

  getDownloadLink() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      InstallInfo installInfo = await getDownloadUrl(chatId: groupChatId);
      downloadLink.value = installInfo.url;
      if (downloadLink.value.startsWith("https://")) {
        downloadLink.value = downloadLink.value.replaceFirst("https://", "");
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
    isLoading.value = false;
  }

  Future<void> downloadAppQR(Widget widget, {bool isShare = false}) async {
    await saveImageWidgetToGallery(
        imageWidget: widget,
        cachePath: "app_qr_code.jpg",
        downloadLink: downloadLink.value,
        isShare: isShare);
  }
}
