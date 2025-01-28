import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/object/InstallInfo.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:social_share/social_share.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/friends.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import '../../utils/toast.dart';

class ShareController extends GetxController {
  var installedApp = {};
  bool isWhatsappInstalled = true;
  bool isTelegramInstalled = true;
  final downloadLink = '${Config().officialUrl}downloads/'.obs;
  final isLoading = false.obs;

  final int? groupChatId;

  ShareController({this.groupChatId}): super();

  @override
  onInit(){
    super.onInit();
    checkApp();
    getDownloadLink();
  }

  checkApp() async {
    installedApp = await SocialShare.checkInstalledAppsForShare() ?? {};
    if (installedApp.isNotEmpty) {
      if (installedApp["whatsapp"] == false) {
        isWhatsappInstalled = false;
      }

      if (installedApp["telegram"] == false) {
        isTelegramInstalled = false;
      }
    }
  }

  getDownloadLink() async {
    if(isLoading.value) return;

    isLoading.value = true;
    try{
      InstallInfo installInfo = await getDownloadUrl(chatId: groupChatId);
      downloadLink.value = installInfo.url;
    } on AppException catch (e){
      Toast.showToast(e.getMessage());
    }
    isLoading.value = false;
  }

  shareSocialMedia(BuildContext context,{bool isWhatsapp = true}) async {
    if (isWhatsapp) {
      if (isWhatsappInstalled) {
        SocialShare.shareWhatsapp(localized(invitationWithLink, params: [Config().appName,downloadLink.value]));
      } else {
        Toast.showToast(localized(appCannotBeFound,params: ['Whatsapp']));
      }
    } else {
      if (isTelegramInstalled) {
        SocialShare.shareTelegram(localized(invitationWithLink, params: [Config().appName,downloadLink.value]));
      } else {
        if (Platform.isAndroid) {
          String encodedText = Uri.encodeFull(localized(invitationWithLink, params: [Config().appName,downloadLink.value]));
          Uri telegramUrl = Uri.parse('tg://share?url=$encodedText');
          if (await canLaunchUrl(telegramUrl)) {
            await launchUrl(telegramUrl,mode: LaunchMode.externalApplication);
          } else{
            Toast.showToast(localized(appCannotBeFound,params: ['Telegram']));
          }
          return;
        }
        Toast.showToast(localized(appCannotBeFound,params: ['Telegram']));
      }
    }
  }

  Future<void> downloadQR(Widget widget) async {
    final Permission permission = defaultTargetPlatform == TargetPlatform.iOS
        ? await Permission.photos
        : await Permission.storage;

    final PermissionStatus status = await permission.status;
    final bool rationale = await permission.shouldShowRequestRationale;
    if (status.isGranted) {
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: localized(imageDownloading), icon: ImBottomNotifType.loading);

      final controller = ScreenshotController();
      final bytes = await controller.captureFromWidget(Material(child: widget));
      await ImageGallerySaver.saveImage(bytes,
          quality: 100,
          name: 'image_${DateTime.now().microsecondsSinceEpoch}.png');
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: localized(imageSaved), icon: ImBottomNotifType.saved);
    } else {
      if (rationale || status.isPermanentlyDenied)
        openAppSettings();
      else {
        await permission.request();
      }
    }
  }
}
