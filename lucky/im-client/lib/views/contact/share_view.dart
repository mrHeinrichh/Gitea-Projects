import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/component/custom_tile.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/contact/download_qr_code.dart';
import 'package:jxim_client/views/contact/share_controller.dart';
import 'package:social_share/social_share.dart';
import '../../home/setting/setting_controller.dart';
import '../../main.dart';
import '../../utils/color.dart';
import '../../utils/config.dart';
import 'qr_code.dart';
import '../component/click_effect_button.dart';

class ShareView extends GetView<ShareController> {
  const ShareView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return objectMgr.loginMgr.isDesktop
        ? Scaffold(
            backgroundColor: backgroundColor,
            resizeToAvoidBottomInset: false,
            appBar: objectMgr.loginMgr.isDesktop
                ? null
                : PrimaryAppBar(
                    isBackButton: true,
                    title: localized(shareHeyTalk,params: [Config().appName]),
                    bgColor: backgroundColor,
                  ),
            body: Column(
              children: [
                if (objectMgr.loginMgr.isDesktop)
                  Container(
                    height: 52,
                    padding: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: const Border(
                        bottom: BorderSide(
                          color: JXColors.outlineColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      /// 普通界面
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        OpacityEffect(
                          child: GestureDetector(
                            onTap: () {
                              Get.back(id: 3);
                              Get.find<SettingController>()
                                  .desktopSettingCurrentRoute = '';
                              Get.find<SettingController>()
                                  .selectedIndex
                                  .value = 101010;
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              alignment: Alignment.center,
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/svgs/Back.svg',
                                    width: 18,
                                    height: 18,
                                    color: JXColors.blue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    localized(buttonBack),
                                    style: jxTextStyle.textStyle13(
                                        color: accentColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Text(
                          localized(shareHeyTalk,params: [Config().appName]),
                          style: jxTextStyle.textStyle16(),
                        ),
                        const SizedBox()
                      ],
                    ),
                  ),
                if (objectMgr.loginMgr.isDesktop) const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!objectMgr.loginMgr.isDesktop) ...[
                        Text(
                          localized(shareInvitationLink),
                          style: TextStyle(
                              color: JXColors.black.withOpacity(0.6),
                              fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            children: [
                              CustomTile(
                                onTap: () =>
                                    controller.shareSocialMedia(context),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 15.5, 8, 15.5),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Whatsapp',
                                        style: jxTextStyle.textStyle16(),
                                      ),
                                      SvgPicture.asset(
                                        'assets/svgs/right_arrow_thick.svg',
                                        color: JXColors.black32,
                                        width: 15,
                                        height: 15,
                                      ),
                                    ],
                                  ),
                                ),
                                withBorder: true,
                                dividerIndent: 16,
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12)),
                              ),
                              CustomTile(
                                onTap: () => controller.shareSocialMedia(
                                    context,
                                    isWhatsapp: false),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 15.5, 8, 15.5),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Telegram',
                                        style: jxTextStyle.textStyle16(),
                                      ),
                                      SvgPicture.asset(
                                        'assets/svgs/right_arrow_thick.svg',
                                        color: JXColors.black32,
                                        width: 15,
                                        height: 15,
                                      ),
                                    ],
                                  ),
                                ),
                                withBorder: true,
                                dividerIndent: 16,
                              ),
                              CustomTile(
                                onTap: () {
                                  Get.back();
                                  SocialShare.shareOptions(localized(
                                      invitationWithLink,
                                      params: [Config().appName,controller.downloadLink.value]));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 15.5, 8, 15.5),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        localized(otherOptions),
                                        style: jxTextStyle.textStyle16(),
                                      ),
                                      SvgPicture.asset(
                                        'assets/svgs/right_arrow_thick.svg',
                                        color: JXColors.black32,
                                        width: 15,
                                        height: 15,
                                      ),
                                    ],
                                  ),
                                ),
                                dividerIndent: 16,
                                borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomTile(
                          onTap: () {
                            copyToClipboard(localized(invitationWithLink,
                                params: [Config().appName,controller.downloadLink.value]));
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 15.5, 8, 15.5),
                            child: Row(
                              children: [
                                Text(
                                  localized(copyInvitationLink),
                                  style: jxTextStyle.textStyle16(),
                                ),
                              ],
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.45,
                              height: MediaQuery.of(context).size.width * 0.45,
                              child: Obx(() => controller.isLoading.value ? Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: accentColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              ) : QRCode(
                                qrData: controller.downloadLink.value,
                                qrSize: MediaQuery.of(context).size.width * 0.45,
                                roundEdges: false,
                              )),
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                                text: localized(download),
                                callBack: () {
                                  controller.downloadQR(DownloadQRCode(
                                      downloadLink: controller.downloadLink.value));
                                }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : _buildMobileShareView(context);
  }

  _buildMobileShareView(ctx) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: Obx(() => controller.isLoading.value ? Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: accentColor,
                                  strokeWidth: 2,
                                ),
                              )
                          )
                              : QRCode(
                            qrData: controller.downloadLink.value,
                            qrSize: 180,
                            roundEdges: false)
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localized(scanToDownloadApp),
                          style: jxTextStyle.textStyle16(),
                        ),
                      ],
                    ),
                  ),
                  _buildMobileShareButton(
                      name: 'Whatsapp',
                      onTap: () {
                        controller.shareSocialMedia(ctx);
                      }),
                  _buildMobileShareButton(
                      name: 'Telegram',
                      onTap: () {
                        controller.shareSocialMedia(ctx, isWhatsapp: false);
                      }),
                  _buildMobileShareButton(
                      name: localized(otherOptions),
                      onTap: () {
                        Get.back();
                        SocialShare.shareOptions(localized(invitationWithLink,
                            params: [Config().appName,controller.downloadLink.value]));
                      }),
                  _buildMobileShareButton(
                      name: localized(copyInvitationLink),
                      onTap: () {
                        copyToClipboard(localized(invitationWithLink,
                            params: [Config().appName,controller.downloadLink.value]));
                      }),
                  _buildMobileShareButton(
                      name: localized(addressSaveImage),
                      onTap: () {
                        controller.downloadQR(DownloadQRCode(
                            downloadLink: controller.downloadLink.value));
                      }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: ForegroundOverlayEffect(
                radius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                  bottom: Radius.circular(14),
                ),
                child: Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  child: Text(
                    localized(cancel),
                    style: jxTextStyle.textStyle17(color: accentColor),
                  ),
                  height: 56.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildMobileShareButton({required String name, required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: OverlayEffect(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: JXColors.borderPrimaryColor,
                width: 0.33,
              ),
            ),
          ),
          height: 56,
          alignment: Alignment.center,
          child: Text(
            name,
            style: jxTextStyle.textStyle17(color: accentColor),
          ),
        ),
      ),
    );
  }
}
